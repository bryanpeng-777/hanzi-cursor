"""水晶反馈 API 客户端。

设计：
- CrystalAPIClient: 真实接口客户端 stub。接口形态（普通 HTTP REST or MCP JSON-RPC）
  尚未确定，目前调用任何检索方法即 raise CrystalNotConfiguredError，提示需要回填。
  环境变量：CRYSTAL_MCP_TOKEN / CRYSTAL_MCP_URL / CRYSTAL_RTX。
- CrystalFixtureClient: 从本地 JSON 加载，给离线 / 测试用。
- make_crystal_client: 工厂方法。

字段归一化：真实返回的水晶字段（id / cSystem / cClientVersionName / createTime ...）
会被映射成下游使用的规范键（_id / system / version / create_time ...），下游
locator/dispatcher/workdir 等保持不变。
"""
from __future__ import annotations

import json
import os
import urllib.parse
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


# ---------------- 异常 ----------------

class CrystalNotConfiguredError(Exception):
    """真实接口尚未确定 / 未注入 token；或既无 fixture 又无 token。"""


class CrystalAPIError(Exception):
    """水晶 API 返回业务错误。"""


# ---------------- 字段归一化 ----------------
#
# key = 下游约定键；value = 水晶真实字段名（按优先顺序 fallback）
_FIELD_ALIASES: dict[str, tuple[str, ...]] = {
    "_id": ("id", "feedbackId", "_id"),
    "feedback_id": ("feedbackId", "id"),
    "system": ("cSystem", "system"),
    "version": ("cClientVersionName", "version"),
    "create_time": ("createTime", "create_time", "time"),
    "uin": ("uin",),
    "user_id": ("userId", "user_id"),
    "device_model": ("cDeviceModel", "device_model"),
    "os_version": ("cSystemVersionCode", "os_version"),
    "client_ip": ("clientIp", "client_ip"),
    "content": ("content", "description"),
    "xlog_uid": ("xLogUid", "xlog_uid"),
}


def normalize_record(raw: dict[str, Any]) -> dict[str, Any]:
    """把水晶返回的单条记录归一化：保留原字段 + 补齐下游约定键。

    - 不破坏原字段（下游 extract_sources 可能直接读 logUrl / picUrl 原名）。
    - 只在下游键缺失时回填（兼容 fixture 已经用 _id/system/version 的老格式）。
    """
    if not isinstance(raw, dict):
        return raw
    out = dict(raw)
    for canonical, candidates in _FIELD_ALIASES.items():
        if out.get(canonical):
            continue
        for src_key in candidates:
            val = raw.get(src_key)
            if val:
                out[canonical] = val
                break
    return out


# ---------------- 时间转换 ----------------

def _to_epoch_seconds(value: Any) -> Optional[int]:
    """把 'YYYY-MM-DD HH:MM:SS' / 'YYYY-MM-DD' / int/str 秒级 epoch 统一成秒级 int。"""
    if value in (None, ""):
        return None
    if isinstance(value, (int, float)):
        return int(value)
    s = str(value).strip()
    if not s:
        return None
    if s.isdigit():
        return int(s)
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%Y/%m/%d %H:%M:%S",
                "%Y/%m/%d"):
        try:
            return int(datetime.strptime(s, fmt).timestamp())
        except ValueError:
            continue
    return None


# ---------------- URL → id 解析 ----------------

def _parse_id_from_feedback_url(url: str) -> Optional[str]:
    """从 feedbackDetail 链接里扒 id，例如:

    https://wzzs-manage.woa.com/#/feedback/feedbackDetail?id=202605_12348
    """
    if not url:
        return None
    parsed = urllib.parse.urlparse(url)
    q = urllib.parse.parse_qs(parsed.query)
    if "id" in q and q["id"]:
        return q["id"][0]
    frag = parsed.fragment or ""
    if "?" in frag:
        _, frag_q = frag.split("?", 1)
        fq = urllib.parse.parse_qs(frag_q)
        if "id" in fq and fq["id"]:
            return fq["id"][0]
    return None


# ---------------- 配置 ----------------

DEFAULT_MCP_URL = "https://wzzs.mcp.it.woa.com"     # 占位，待真实地址确定
TOKEN_APPLY_URL = "https://tai.it.woa.com/user/pat"


def load_token_from_env() -> tuple[Optional[str], str, Optional[str]]:
    """从环境变量读取 (token, base_url, rtx)。token 缺失返回 None。"""
    token = (os.environ.get("CRYSTAL_MCP_TOKEN") or "").strip() or None
    base_url = (os.environ.get("CRYSTAL_MCP_URL") or DEFAULT_MCP_URL).rstrip("/")
    rtx = (os.environ.get("CRYSTAL_RTX") or "").strip() or None
    return token, base_url, rtx


# ---------------- 真实接口 stub ----------------

class CrystalAPIClient:
    """水晶真实接口客户端（stub）。

    具体协议（普通 HTTP REST vs MCP JSON-RPC）尚未确定，目前任何方法被调
    都 raise CrystalNotConfiguredError 提示"需要回填实现"。

    回填指引：
    - 若是 MCP JSON-RPC：参考 ifeedback 的 ifeedback_api.py（MCPClient 类），
      在 _call_tool() 里转发给 server，工具名约定如 'crystal.search_feedback'。
    - 若是普通 REST：在 _request() 里 urllib.request 调用，header 带
      Authorization: Bearer <token>。
    - 实现完成后保留 normalize_record 调用，确保下游字段一致。
    """

    def __init__(
        self,
        token: Optional[str] = None,
        base_url: str = DEFAULT_MCP_URL,
        rtx: Optional[str] = None,
        timeout: int = 15,
    ):
        self.token = token
        self.base_url = base_url.rstrip("/")
        self.rtx = rtx
        self.timeout = timeout

    def _ensure_token(self) -> None:
        if not self.token:
            raise CrystalNotConfiguredError(
                "未注入水晶 token。请：\n"
                f"  1. 申请太湖个人令牌：{TOKEN_APPLY_URL}\n"
                "  2. export CRYSTAL_MCP_TOKEN=tai_pat_xxx\n"
                "  或使用 fixture 模式（--fixture-record <file>）做离线调试。"
            )

    def _not_implemented(self) -> CrystalNotConfiguredError:
        return CrystalNotConfiguredError(
            "水晶真实接口（MCP / REST）尚未确定。当前为 stub 占位，"
            "请使用 --fixture-record 走离线模式。\n"
            "接口形态确认后请回填 CrystalAPIClient.search_feedback / "
            "get_feedback_detail。"
        )

    # ---- 与 CrystalFixtureClient 同形签名 ----

    def get_feedback_detail(self, feedback_id: str) -> dict[str, Any]:
        self._ensure_token()
        raise self._not_implemented()

    def search_feedback(
        self,
        uin: Optional[str] = None,
        date_from: Optional[str] = None,
        date_to: Optional[str] = None,
        version: Optional[str] = None,
        url: Optional[str] = None,
        limit: int = 20,
        *,
        user_id: Optional[str] = None,
        keywords: Optional[str] = None,
        platform: Optional[str] = None,
        first_dir: Optional[str] = None,
        second_dir: Optional[str] = None,
        reply_status: int = -1,
    ) -> list[dict[str, Any]]:
        self._ensure_token()
        # url 模式：保留对 url → id 的解析能力，方便后续真实接口接进来时复用
        if url:
            detail_id = _parse_id_from_feedback_url(url)
            if detail_id:
                try:
                    return [self.get_feedback_detail(detail_id)]
                except CrystalNotConfiguredError:
                    raise
                except KeyError:
                    return []
        raise self._not_implemented()


# ---------------- Fixture 客户端（离线调试） ----------------

class CrystalFixtureClient:
    """从本地 JSON 文件加载 record，给离线 / 测试用。"""

    def __init__(self, fixture_path: Path | str):
        self.fixture_path = Path(fixture_path)

    def _load(self) -> Any:
        if not self.fixture_path.exists():
            raise FileNotFoundError(f"fixture 不存在: {self.fixture_path}")
        return json.loads(self.fixture_path.read_text(encoding="utf-8"))

    def _unwrap(self, data: Any) -> list[dict[str, Any]]:
        """支持三种 fixture 形态：
        - 单条 dict
        - list[dict]
        - 水晶原始响应 {"data": {"list": [...]}}
        """
        if (isinstance(data, dict)
                and isinstance(data.get("data"), dict)
                and isinstance(data["data"].get("list"), list)):
            return data["data"]["list"]
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            return [data]
        return []

    def get_feedback_detail(self, feedback_id: str) -> dict[str, Any]:
        data = self._load()
        records = self._unwrap(data)
        for r in records:
            if (r.get("_id") == feedback_id
                    or r.get("id") == feedback_id
                    or str(r.get("feedbackId", "")) == feedback_id):
                return normalize_record(r)
        if len(records) == 1:
            return normalize_record(records[0])
        raise KeyError(f"fixture 中无 id={feedback_id} 的记录")

    def search_feedback(self, **kwargs: Any) -> list[dict[str, Any]]:
        data = self._load()
        records = self._unwrap(data)
        return [normalize_record(r) for r in records]


# ---------------- 工厂 ----------------

def make_crystal_client(
    fixture_path: Optional[str] = None,
    *,
    token: Optional[str] = None,
    base_url: Optional[str] = None,
    rtx: Optional[str] = None,
) -> Any:
    """工厂方法。

    优先级：fixture_path > 显式 token > 环境变量 token > 无 token 的 stub
    （调用时 raise CrystalNotConfiguredError 引导用户配置）。
    """
    if fixture_path:
        return CrystalFixtureClient(fixture_path)

    if token is None:
        env_token, env_url, env_rtx = load_token_from_env()
        token = token or env_token
        base_url = base_url or env_url
        rtx = rtx or env_rtx

    return CrystalAPIClient(
        token=token,
        base_url=base_url or DEFAULT_MCP_URL,
        rtx=rtx,
    )
