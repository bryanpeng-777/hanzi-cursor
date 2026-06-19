"""灯塔巡检指标展示格式化工具。

Beacon DataInsight 的率类指标（成功率/完成率/失败率/加载率）在 CSV 中以 0~1 小数存储，
例如 0.916 表示 91.6%。展示时需乘以 100 再加 % 后缀。
"""
from typing import Optional

RATE_KEYWORDS = ("成功率", "完成率", "失败率", "加载率")


def is_rate_metric(name: str) -> bool:
    return any(kw in name for kw in RATE_KEYWORDS)


def ratio_to_percent(value: float) -> float:
    """将 Beacon 比率（0~1）转为展示用百分数（0~100）。"""
    v = float(value)
    if v > 1.5:
        return v
    return v * 100


def format_display_value(name: str, value) -> str:
    if value is None:
        return "—"
    if is_rate_metric(name):
        return f"{ratio_to_percent(value):.2f}%"
    v = float(value)
    if abs(v) >= 10000:
        return f"{v / 10000:.2f}万"
    if v == int(v):
        return str(int(v))
    return f"{v:.2f}"


def format_change_pct(p, threshold=10) -> str:
    if p is None:
        return "—"
    s = f"{p:+.2f}%"
    if abs(p) >= threshold:
        return f"**{s}**"
    return s


def parse_display_value(name: str, s: str) -> Optional[float]:
    """解析展示字符串；率类指标返回 0~100 量纲。"""
    if not s or s.strip() in ("-", "—", ""):
        return None
    s = s.strip().replace("，", ",")
    if s.endswith("万"):
        try:
            return float(s[:-1]) * 10000
        except ValueError:
            return None
    if s.endswith("%"):
        try:
            val = float(s[:-1])
        except ValueError:
            return None
        if is_rate_metric(name) and 0 < val <= 1.5:
            return val * 100
        return val
    try:
        val = float(s.replace(",", ""))
    except ValueError:
        return None
    if is_rate_metric(name) and 0 < val <= 1.5:
        return val * 100
    return val
