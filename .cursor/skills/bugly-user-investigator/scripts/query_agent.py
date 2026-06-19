"""
Bugly Agent 查询工具：通过 SSE 接口向 Bugly Agent 发送消息并获取响应。
支持解析 SSE 流，提取 agent 最终回复的文本内容、工具调用信息等。
"""

import json
import os
import re
import uuid

import requests


# Agent 返回文本中的中间过程标记（正常模式下需要过滤）
_INTERMEDIATE_TAGS = re.compile(
    r"/\*(?:PLANNING|ACTION|REASONING)\*/",
)
_FINAL_ANSWER_TAG = "/*FINAL_ANSWER*/"


def extract_final_answer(text_messages: list) -> str:
    """
    从 Agent 返回的多条文本消息中提取最终答案。

    策略：
      1. 将所有消息拼接后，如果包含 /*FINAL_ANSWER*/ 标记，
         则只取该标记之后的内容。
      2. 如果没有 /*FINAL_ANSWER*/ 标记，则过滤掉所有
         /*PLANNING*/、/*ACTION*/、/*REASONING*/ 标记及其后紧跟的内容段落，
         只保留最后一条非中间过程的消息。
      3. 清理结果中残留的标记和多余空行。

    Args:
        text_messages: Agent 回复的文本消息列表

    Returns:
        str: 提取后的最终答案文本
    """
    if not text_messages:
        return ""

    full_text = "\n\n".join(text_messages)

    # 策略1：存在 FINAL_ANSWER 标记，直接截取其后内容
    if _FINAL_ANSWER_TAG in full_text:
        final = full_text.split(_FINAL_ANSWER_TAG, 1)[1].strip()
        if final:
            return final

    # 策略2：没有 FINAL_ANSWER 标记，从后往前找第一条不含中间标记的消息
    for msg in reversed(text_messages):
        if not _INTERMEDIATE_TAGS.search(msg):
            return msg.strip()

    # 策略3：所有消息都含中间标记，逐行过滤
    lines = full_text.split("\n")
    result_lines = []
    skip = False
    for line in lines:
        if _INTERMEDIATE_TAGS.search(line):
            skip = True
            continue
        if skip and line.strip() == "":
            continue
        skip = False
        result_lines.append(line)

    return "\n".join(result_lines).strip()


class BuglyAgentClient:
    """Bugly Agent 客户端，封装 SSE 接口调用和响应解析"""

    DEFAULT_BASE_URL = "http://api.bugly.woa.com"
    ENDPOINT = "/agui/dynamic"

    # token 本地缓存文件路径（与 bugly-log 共用同一缓存文件）
    _TOKEN_CACHE_FILE = os.path.expanduser("~/.bugly_token_cache.json")

    def __init__(self, product_id, base_url=None):
        """
        初始化 Bugly Agent 客户端

        Args:
            product_id: 产品 ID
            base_url: API 基础地址（可选，默认使用测试环境）
        """
        self.product_id = product_id
        self.base_url = base_url or self.DEFAULT_BASE_URL
        self.url = self.base_url + self.ENDPOINT

        self.token = self._load_token()
        self.headers = {
            "Content-Type": "text/event-stream",
            "X-Bugly-User-Token": self.token,
            "X-ProductId": self.product_id,
        }

    @classmethod
    def _load_token(cls) -> str:
        """
        Token 加载优先级：
          1. 环境变量 BUGLY_USER_TOKEN（若有，同时持久化到本地缓存文件）
          2. 本地缓存文件 ~/.bugly_token_cache.json
        """
        token = os.environ.get("BUGLY_USER_TOKEN")
        if token:
            cls._save_token_cache(token)
            return token

        token = cls._read_token_cache()
        if token:
            print(f"[提示] 未检测到环境变量 BUGLY_USER_TOKEN，已从缓存文件 {cls._TOKEN_CACHE_FILE} 加载 token。")
            return token

        raise EnvironmentError(
            "未找到 BUGLY_USER_TOKEN。\n"
            "请设置环境变量后重试，例如：\n"
            "  export BUGLY_USER_TOKEN=<your_token>\n"
            f"设置后 token 将自动缓存到 {cls._TOKEN_CACHE_FILE}，后续无需重复设置。"
        )

    @classmethod
    def _save_token_cache(cls, token: str) -> None:
        """将 token 写入本地缓存文件"""
        try:
            with open(cls._TOKEN_CACHE_FILE, "w", encoding="utf-8") as f:
                json.dump({"BUGLY_USER_TOKEN": token}, f)
            os.chmod(cls._TOKEN_CACHE_FILE, 0o600)
        except OSError as e:
            print(f"[警告] token 缓存文件写入失败: {e}")

    @classmethod
    def _read_token_cache(cls) -> str:
        """从本地缓存文件读取 token，不存在或解析失败时返回空字符串"""
        try:
            with open(cls._TOKEN_CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            return data.get("BUGLY_USER_TOKEN", "")
        except (OSError, json.JSONDecodeError):
            return ""

    def query(self, message, agent_id="12", thread_id=None, run_id=None, verbose=False):
        """
        向 Bugly Agent 发送查询消息并获取响应

        Args:
            message: 用户消息文本
            agent_id: Agent ID（默认 "63"）
            thread_id: 会话线程 ID（可选，自动生成）
            run_id: 运行 ID（可选，自动生成）
            verbose: 是否输出详细的 SSE 事件信息

        Returns:
            dict: 解析后的结果，包含以下字段：
                - text_messages: list[str]  — agent 回复的所有文本消息
                - tool_calls: list[dict]    — 工具调用信息列表
                - tool_results: list[dict]  — 工具调用结果列表
                - thread_id: str            — 会话线程 ID
                - run_id: str               — 运行 ID
                - raw_events: list[dict]    — 原始 SSE 事件列表（verbose=True 时才填充）
                - success: bool             — 是否成功完成
                - error: str|None           — 错误信息
        """
        if thread_id is None:
            thread_id = str(uuid.uuid4()).replace("-", "")[:12]
        if run_id is None:
            run_id = f"run-{uuid.uuid4().hex[:8]}"

        payload = {
            "threadId": thread_id,
            "runId": run_id,
            "messages": [{"role": "user", "content": message}],
            "forwardedProps": {"agent_id": agent_id},
        }

        result = {
            "text_messages": [],
            "tool_calls": [],
            "tool_results": [],
            "thread_id": thread_id,
            "run_id": run_id,
            "raw_events": [],
            "success": False,
            "error": None,
        }

        try:
            response = requests.post(
                self.url,
                headers=self.headers,
                json=payload,
                stream=True,
                timeout=300,
            )
            response.raise_for_status()
        except requests.exceptions.RequestException as e:
            result["error"] = f"请求失败: {e}"
            if hasattr(e, "response") and e.response is not None:
                result["error"] += f"\n响应内容: {e.response.text}"
            return result

        # 强制使用 UTF-8 解码，避免 requests 默认 latin-1 导致中文乱码
        response.encoding = "utf-8"

        if verbose:
            print("=" * 50)
            print("🔍 SSE 事件流（verbose 模式）")
            print("=" * 50)

        # 解析 SSE 流
        current_text_parts = {}  # messageId -> list of deltas
        current_tool_call_args = {}  # toolCallId -> accumulated args string
        tool_call_names = {}  # toolCallId -> toolCallName

        try:
            for line in response.iter_lines(decode_unicode=True):
                if not line:
                    continue

                # SSE 格式: "id: xxx" 或 "data: xxx"
                if line.startswith("data: "):
                    data_str = line[len("data: "):]
                    try:
                        event = json.loads(data_str)
                    except json.JSONDecodeError:
                        if verbose:
                            print(f"  [WARN] 无法解析: {data_str}")
                        continue

                    event_type = event.get("type", "")

                    if verbose:
                        result["raw_events"].append(event)
                        print(f"  [{event_type}] {json.dumps(event, ensure_ascii=False)}", flush=True)

                    if event_type == "TEXT_MESSAGE_START":
                        msg_id = event.get("messageId", "")
                        current_text_parts[msg_id] = []

                    elif event_type == "TEXT_MESSAGE_CONTENT":
                        msg_id = event.get("messageId", "")
                        delta = event.get("delta", "")
                        if msg_id in current_text_parts:
                            current_text_parts[msg_id].append(delta)

                    elif event_type == "TEXT_MESSAGE_END":
                        msg_id = event.get("messageId", "")
                        if msg_id in current_text_parts:
                            full_text = "".join(current_text_parts[msg_id]).strip()
                            if full_text:
                                result["text_messages"].append(full_text)

                    elif event_type == "TOOL_CALL_START":
                        tool_call_id = event.get("toolCallId", "")
                        tool_name = event.get("toolCallName", "")
                        current_tool_call_args[tool_call_id] = ""
                        tool_call_names[tool_call_id] = tool_name

                    elif event_type == "TOOL_CALL_ARGS":
                        tool_call_id = event.get("toolCallId", "")
                        delta = event.get("delta", "")
                        if tool_call_id in current_tool_call_args:
                            current_tool_call_args[tool_call_id] += delta

                    elif event_type == "TOOL_CALL_END":
                        tool_call_id = event.get("toolCallId", "")
                        args_str = current_tool_call_args.get(tool_call_id, "")
                        try:
                            args = json.loads(args_str) if args_str else {}
                        except json.JSONDecodeError:
                            args = {"raw": args_str}
                        tool_name = tool_call_names.get(tool_call_id, "")
                        result["tool_calls"].append({
                            "toolCallId": tool_call_id,
                            "toolCallName": tool_name,
                            "arguments": args,
                        })

                    elif event_type == "TOOL_CALL_RESULT":
                        tool_call_id = event.get("toolCallId", "")
                        content_str = event.get("content", "")
                        try:
                            content = json.loads(content_str) if content_str else {}
                        except json.JSONDecodeError:
                            content = {"raw": content_str}
                        result["tool_results"].append({
                            "toolCallId": tool_call_id,
                            "content": content,
                        })

                    elif event_type == "RUN_STARTED":
                        result["thread_id"] = event.get("threadId", thread_id)
                        result["run_id"] = event.get("runId", run_id)

                    elif event_type == "RUN_FINISHED":
                        result["success"] = True

                    elif event_type == "RUN_ERROR":
                        result["error"] = event.get("message", "未知错误")

        except requests.exceptions.ChunkedEncodingError:
            # 流被截断，但已解析的数据仍然有效
            if not result["text_messages"] and not result["tool_calls"]:
                result["error"] = "SSE 流被截断且未获取到任何内容"
        except Exception as e:
            result["error"] = f"解析 SSE 流异常: {e}"

        return result

    def query_text(self, message, agent_id="12", thread_id=None, run_id=None):
        """
        简化查询，仅返回 agent 最终答案文本（自动过滤中间推理过程）

        Args:
            message: 用户消息文本
            agent_id: Agent ID
            thread_id: 会话线程 ID
            run_id: 运行 ID

        Returns:
            str: agent 最终答案文本；失败返回错误信息
        """
        result = self.query(message, agent_id=agent_id, thread_id=thread_id, run_id=run_id)
        if result["error"]:
            return f"[错误] {result['error']}"
        final = extract_final_answer(result["text_messages"])
        return final if final else "[无文本回复]"


def format_result(result, output_format="text", verbose=False):
    """
    格式化输出结果

    Args:
        result: query() 返回的结果 dict
        output_format: 输出格式 "text" | "json"
        verbose: 是否输出详细信息（工具调用、工具结果、状态等）

    Returns:
        str: 格式化后的输出
    """
    if output_format == "json":
        if verbose:
            return json.dumps(result, ensure_ascii=False, indent=2)
        # 非 verbose 的 json 模式：只返回最终答案和错误
        final = extract_final_answer(result.get("text_messages", []))
        slim = {
            "answer": final,
            "error": result.get("error"),
        }
        return json.dumps(slim, ensure_ascii=False, indent=2)

    # text 格式
    if result.get("error"):
        return f"❌ 错误: {result['error']}"

    if not verbose:
        # 正常模式：只输出最终答案，过滤中间推理过程
        final = extract_final_answer(result.get("text_messages", []))
        return final if final else "[无文本回复]"

    # verbose 模式：输出完整内容（含中间过程）
    if result.get("text_messages"):
        text = "\n\n".join(result["text_messages"])
    else:
        text = "[无文本回复]"

    lines = [text]

    if result.get("tool_calls"):
        lines.append(f"\n🔧 工具调用 ({len(result['tool_calls'])} 次):")
        for tc in result["tool_calls"]:
            lines.append(f"  - {tc['toolCallName']}({json.dumps(tc['arguments'], ensure_ascii=False)})")

    if result.get("tool_results"):
        lines.append(f"\n📋 工具结果 ({len(result['tool_results'])} 条):")
        for tr in result["tool_results"]:
            content = tr["content"]
            if isinstance(content, dict):
                lines.append(f"  - {json.dumps(content, ensure_ascii=False)}")
            else:
                lines.append(f"  - {content}")

    status = "✅ 成功" if result.get("success") else "⚠️ 未完成"
    lines.append(f"\n状态: {status}")
    lines.append(f"threadId: {result.get('thread_id', 'N/A')}")
    lines.append(f"runId: {result.get('run_id', 'N/A')}")

    return "\n".join(lines)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Bugly Agent 查询工具：向 Bugly Agent 发送消息并获取解析后的响应"
    )
    _config_file = os.path.expanduser("~/.bugly_config.json")
    _default_product_id = None
    if os.path.exists(_config_file):
        with open(_config_file) as _f:
            _default_product_id = json.load(_f).get("product_id")

    parser.add_argument(
        "--product-id",
        required=_default_product_id is None,
        default=_default_product_id,
        help="产品 ID（可省略，自动从 ~/.bugly_config.json 读取）",
    )
    parser.add_argument("--message", required=True, help="发送给 Agent 的消息内容")
    parser.add_argument("--thread-id", default=None, help="会话线程 ID（可选，自动生成）")
    parser.add_argument("--base-url", default=None, help="API 基础地址（可选，默认测试环境）")
    parser.add_argument(
        "--output", choices=["text", "json"], default="text",
        help="输出格式：text（可读文本）或 json（完整 JSON）（默认 text）"
    )
    parser.add_argument("--verbose", action="store_true", help="输出详细的 SSE 事件信息")

    args = parser.parse_args()

    client = BuglyAgentClient(
        product_id=args.product_id,
        base_url=args.base_url,
    )

    result = client.query(
        message=args.message,
        thread_id=args.thread_id,
        verbose=args.verbose,
    )

    print(format_result(result, output_format=args.output, verbose=args.verbose))
