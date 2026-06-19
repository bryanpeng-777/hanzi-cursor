#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
beacon_analyzer.py - 腾讯灯塔(Beacon)看板数据拉取与分析脚本

支持两种数据获取模式:
1. API 模式: 通过灯塔 OpenAPI / DataInsight API 拉取看板数据
2. 文件模式: 解析从灯塔导出的 CSV/Excel 数据文件

输出:
- HTML 可视化分析报告
- JSON 结构化数据文件

使用方式:
  # API 模式（需配置认证信息）
  python beacon_analyzer.py --mode api --app-id <APP_ID> --api-key <API_KEY> --dashboard <DASHBOARD_ID>

  # 文件模式（分析导出的数据文件）
  python beacon_analyzer.py --mode file --input data.csv

  # 指定输出目录
  python beacon_analyzer.py --mode file --input data.csv --output-dir ./reports

依赖: 纯标准库（API 模式），csv/json 处理无需额外安装
      文件模式分析 Excel 需要 openpyxl（可选）
"""

import argparse
import csv
import datetime
import html
import io
import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from typing import Any, Dict, List, Optional, Tuple

# ============================================================
# 常量与配置
# ============================================================

BEACON_API_HOSTS = {
    "analytics": "https://analytics.beacon.tencent.com",
    "beacon_qq": "https://beacon.qq.com",
}

DEFAULT_OUTPUT_DIR = "."
DEFAULT_TOP = 50
REPORT_TITLE = "灯塔看板数据分析报告"

# ============================================================
# API 数据拉取模块
# ============================================================


class BeaconAPIClient:
    """腾讯灯塔 API 客户端"""

    def __init__(self, app_id: str, api_key: str, host: str = "analytics"):
        self.app_id = app_id
        self.api_key = api_key
        self.base_url = BEACON_API_HOSTS.get(host, host)
        self.ctx = ssl.create_default_context()
        self.ctx.check_hostname = False
        self.ctx.verify_mode = ssl.CERT_NONE

    def _build_headers(self) -> dict:
        return {
            "Content-Type": "application/json",
            "X-Beacon-AppId": self.app_id,
            "Authorization": f"Bearer {self.api_key}",
            "User-Agent": "BeaconAnalyzer/1.0",
        }

    def _request(self, method: str, path: str, data: Optional[dict] = None) -> dict:
        url = f"{self.base_url}{path}"
        body = json.dumps(data).encode("utf-8") if data else None
        req = urllib.request.Request(url, data=body, headers=self._build_headers(), method=method)
        try:
            with urllib.request.urlopen(req, context=self.ctx, timeout=30) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8", errors="replace")
            print(f"[ERROR] API请求失败: {e.code} {e.reason}", file=sys.stderr)
            print(f"[ERROR] 响应: {error_body[:500]}", file=sys.stderr)
            return {"error": True, "code": e.code, "message": error_body}
        except urllib.error.URLError as e:
            print(f"[ERROR] 网络错误: {e.reason}", file=sys.stderr)
            return {"error": True, "message": str(e.reason)}

    def get_app_info(self) -> dict:
        """获取应用基本信息"""
        return self._request("GET", f"/api/v1/apps/{self.app_id}/info")

    def get_dashboard_list(self) -> dict:
        """获取看板列表"""
        return self._request("GET", f"/api/v1/apps/{self.app_id}/dashboards")

    def get_dashboard_data(self, dashboard_id: str, start_date: str = "", end_date: str = "") -> dict:
        """获取指定看板的数据"""
        if not start_date:
            start_date = (datetime.date.today() - datetime.timedelta(days=7)).isoformat()
        if not end_date:
            end_date = datetime.date.today().isoformat()
        params = {
            "start_date": start_date,
            "end_date": end_date,
        }
        query = urllib.parse.urlencode(params)
        return self._request("GET", f"/api/v1/apps/{self.app_id}/dashboards/{dashboard_id}/data?{query}")

    def get_realtime_stats(self) -> dict:
        """获取实时统计数据"""
        return self._request("GET", f"/api/v1/apps/{self.app_id}/realtime/overview")

    def get_event_analysis(self, event_name: str, start_date: str = "", end_date: str = "",
                           group_by: str = "", metrics: str = "count") -> dict:
        """获取事件分析数据"""
        if not start_date:
            start_date = (datetime.date.today() - datetime.timedelta(days=7)).isoformat()
        if not end_date:
            end_date = datetime.date.today().isoformat()
        data = {
            "event_name": event_name,
            "start_date": start_date,
            "end_date": end_date,
            "metrics": metrics,
        }
        if group_by:
            data["group_by"] = group_by
        return self._request("POST", f"/api/v1/apps/{self.app_id}/analysis/event", data)

    def get_retention_data(self, start_event: str, return_event: str,
                           start_date: str = "", end_date: str = "") -> dict:
        """获取留存分析数据"""
        if not start_date:
            start_date = (datetime.date.today() - datetime.timedelta(days=30)).isoformat()
        if not end_date:
            end_date = datetime.date.today().isoformat()
        data = {
            "start_event": start_event,
            "return_event": return_event,
            "start_date": start_date,
            "end_date": end_date,
        }
        return self._request("POST", f"/api/v1/apps/{self.app_id}/analysis/retention", data)

    def get_funnel_data(self, funnel_id: str, start_date: str = "", end_date: str = "") -> dict:
        """获取漏斗分析数据"""
        if not start_date:
            start_date = (datetime.date.today() - datetime.timedelta(days=7)).isoformat()
        if not end_date:
            end_date = datetime.date.today().isoformat()
        data = {
            "funnel_id": funnel_id,
            "start_date": start_date,
            "end_date": end_date,
        }
        return self._request("POST", f"/api/v1/apps/{self.app_id}/analysis/funnel", data)

    def query_sql(self, sql: str) -> dict:
        """通过 SQL 查询灯塔数据（DataInsight SQL 变量模式）"""
        data = {"sql": sql}
        return self._request("POST", f"/api/v1/apps/{self.app_id}/query/sql", data)


# ============================================================
# 文件数据解析模块
# ============================================================


def parse_csv_file(filepath: str, encoding: str = "utf-8-sig") -> Tuple[List[str], List[dict]]:
    """解析 CSV 文件，返回 (列名列表, 数据字典列表)"""
    rows = []
    headers = []
    try:
        with open(filepath, "r", encoding=encoding) as f:
            reader = csv.DictReader(f)
            headers = reader.fieldnames or []
            for row in reader:
                rows.append(dict(row))
    except UnicodeDecodeError:
        with open(filepath, "r", encoding="gbk") as f:
            reader = csv.DictReader(f)
            headers = reader.fieldnames or []
            for row in reader:
                rows.append(dict(row))
    return headers, rows


def parse_excel_file(filepath: str) -> Tuple[List[str], List[dict]]:
    """解析 Excel 文件（需要 openpyxl）"""
    try:
        import openpyxl
    except ImportError:
        print("[WARN] 需要 openpyxl 来解析 Excel 文件，尝试: pip install openpyxl", file=sys.stderr)
        raise

    wb = openpyxl.load_workbook(filepath, read_only=True, data_only=True)
    ws = wb.active
    rows_iter = ws.iter_rows(values_only=True)
    headers = [str(c) if c else f"col_{i}" for i, c in enumerate(next(rows_iter, []))]
    rows = []
    for row_vals in rows_iter:
        row_dict = {}
        for i, val in enumerate(row_vals):
            key = headers[i] if i < len(headers) else f"col_{i}"
            row_dict[key] = val
        rows.append(row_dict)
    wb.close()
    return headers, rows


def parse_data_file(filepath: str) -> Tuple[List[str], List[dict]]:
    """根据文件扩展名自动选择解析器"""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == ".csv":
        return parse_csv_file(filepath)
    elif ext in (".xlsx", ".xls"):
        return parse_excel_file(filepath)
    elif ext == ".json":
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list) and data:
            headers = list(data[0].keys())
            return headers, data
        elif isinstance(data, dict):
            return list(data.keys()), [data]
        return [], []
    elif ext == ".tsv":
        rows = []
        with open(filepath, "r", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f, delimiter="\t")
            headers = reader.fieldnames or []
            for row in reader:
                rows.append(dict(row))
        return headers, rows
    else:
        raise ValueError(f"不支持的文件格式: {ext}，支持 .csv/.xlsx/.xls/.json/.tsv")


# ============================================================
# 数据分析模块
# ============================================================


def detect_column_types(headers: List[str], rows: List[dict]) -> Dict[str, str]:
    """自动检测每列的数据类型: numeric / date / text"""
    types = {}
    for col in headers:
        sample = [r.get(col) for r in rows[:100] if r.get(col) not in (None, "", "null", "NULL")]
        if not sample:
            types[col] = "text"
            continue
        # 尝试数值
        numeric_count = 0
        for v in sample:
            try:
                float(str(v).replace(",", "").replace("%", ""))
                numeric_count += 1
            except (ValueError, TypeError):
                pass
        if numeric_count / len(sample) > 0.7:
            types[col] = "numeric"
            continue
        # 尝试日期
        date_count = 0
        for v in sample:
            sv = str(v).strip()
            if len(sv) >= 8 and any(c in sv for c in ["-", "/", "."]):
                date_count += 1
        if date_count / len(sample) > 0.7:
            types[col] = "date"
            continue
        types[col] = "text"
    return types


def to_numeric(val) -> Optional[float]:
    """安全转换为数值"""
    if val is None:
        return None
    try:
        return float(str(val).replace(",", "").replace("%", "").strip())
    except (ValueError, TypeError):
        return None


def compute_statistics(headers: List[str], rows: List[dict], col_types: Dict[str, str]) -> Dict[str, dict]:
    """计算每列的统计信息"""
    stats = {}
    for col in headers:
        ct = col_types.get(col, "text")
        col_stats = {"type": ct, "total_rows": len(rows)}
        non_null = [r[col] for r in rows if r.get(col) not in (None, "", "null", "NULL")]
        col_stats["non_null_count"] = len(non_null)
        col_stats["null_count"] = len(rows) - len(non_null)

        if ct == "numeric":
            nums = [n for n in (to_numeric(v) for v in non_null) if n is not None]
            if nums:
                col_stats["min"] = min(nums)
                col_stats["max"] = max(nums)
                col_stats["sum"] = sum(nums)
                col_stats["avg"] = sum(nums) / len(nums)
                sorted_nums = sorted(nums)
                mid = len(sorted_nums) // 2
                col_stats["median"] = sorted_nums[mid] if len(sorted_nums) % 2 else (sorted_nums[mid - 1] + sorted_nums[mid]) / 2
        elif ct == "text":
            counter = defaultdict(int)
            for v in non_null:
                counter[str(v)] += 1
            top_values = sorted(counter.items(), key=lambda x: -x[1])[:10]
            col_stats["unique_count"] = len(counter)
            col_stats["top_values"] = top_values
        elif ct == "date":
            dates_str = sorted(str(v).strip() for v in non_null)
            if dates_str:
                col_stats["min_date"] = dates_str[0]
                col_stats["max_date"] = dates_str[-1]

        stats[col] = col_stats
    return stats


def compute_trends(headers: List[str], rows: List[dict], col_types: Dict[str, str]) -> Dict[str, Any]:
    """如果存在日期列和数值列，计算趋势数据"""
    date_cols = [h for h in headers if col_types.get(h) == "date"]
    num_cols = [h for h in headers if col_types.get(h) == "numeric"]
    if not date_cols or not num_cols:
        return {}

    date_col = date_cols[0]
    trends = {}
    for nc in num_cols[:5]:  # 最多取5个数值列
        daily = defaultdict(list)
        for r in rows:
            dv = str(r.get(date_col, "")).strip()
            nv = to_numeric(r.get(nc))
            if dv and nv is not None:
                daily[dv].append(nv)
        trend_data = []
        for d in sorted(daily.keys()):
            vals = daily[d]
            trend_data.append({"date": d, "sum": sum(vals), "avg": sum(vals) / len(vals), "count": len(vals)})
        if trend_data:
            trends[nc] = trend_data
    return trends


# ============================================================
# HTML 报告生成模块
# ============================================================


def generate_html_report(
    title: str,
    headers: List[str],
    rows: List[dict],
    col_types: Dict[str, str],
    stats: Dict[str, dict],
    trends: Dict[str, Any],
    source_info: str = "",
) -> str:
    """生成完整的 HTML 分析报告"""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    num_cols = [h for h in headers if col_types.get(h) == "numeric"]
    text_cols = [h for h in headers if col_types.get(h) == "text"]
    date_cols = [h for h in headers if col_types.get(h) == "date"]

    # 构建 KPI 卡片
    kpi_cards_html = ""
    for nc in num_cols[:6]:
        s = stats.get(nc, {})
        avg_val = s.get("avg", 0)
        sum_val = s.get("sum", 0)
        fmt_avg = f"{avg_val:,.2f}" if avg_val else "N/A"
        fmt_sum = f"{sum_val:,.2f}" if sum_val else "N/A"
        kpi_cards_html += f"""
        <div class="kpi-card">
            <div class="kpi-label">{html.escape(str(nc))}</div>
            <div class="kpi-value">{fmt_sum}</div>
            <div class="kpi-sub">均值 {fmt_avg} | 非空 {s.get('non_null_count', 0)} 条</div>
        </div>"""

    # 构建趋势图表的 JS 数据
    trend_charts_js = ""
    trend_charts_html = ""
    for i, (metric_name, trend_data) in enumerate(trends.items()):
        chart_id = f"trendChart{i}"
        labels = json.dumps([d["date"] for d in trend_data])
        values = json.dumps([d["sum"] for d in trend_data])
        avg_values = json.dumps([round(d["avg"], 2) for d in trend_data])
        trend_charts_html += f"""
        <div class="chart-container">
            <h3>📈 {html.escape(str(metric_name))} 趋势</h3>
            <canvas id="{chart_id}"></canvas>
        </div>"""
        trend_charts_js += f"""
        new Chart(document.getElementById('{chart_id}'), {{
            type: 'line',
            data: {{
                labels: {labels},
                datasets: [{{
                    label: '合计',
                    data: {values},
                    borderColor: '#4fc3f7',
                    backgroundColor: 'rgba(79,195,247,0.1)',
                    fill: true,
                    tension: 0.3
                }}, {{
                    label: '均值',
                    data: {avg_values},
                    borderColor: '#ff8a65',
                    borderDash: [5,5],
                    fill: false,
                    tension: 0.3
                }}]
            }},
            options: {{
                responsive: true,
                plugins: {{ legend: {{ labels: {{ color: '#ccc' }} }} }},
                scales: {{
                    x: {{ ticks: {{ color: '#aaa', maxRotation: 45 }}, grid: {{ color: 'rgba(255,255,255,0.05)' }} }},
                    y: {{ ticks: {{ color: '#aaa' }}, grid: {{ color: 'rgba(255,255,255,0.08)' }} }}
                }}
            }}
        }});"""

    # 构建分布图表（文本列 Top 值）
    dist_charts_js = ""
    dist_charts_html = ""
    for i, tc in enumerate(text_cols[:4]):
        s = stats.get(tc, {})
        top_vals = s.get("top_values", [])
        if not top_vals:
            continue
        chart_id = f"distChart{i}"
        dist_labels = json.dumps([str(v[0])[:20] for v in top_vals])
        dist_values = json.dumps([v[1] for v in top_vals])
        colors = json.dumps(["#4fc3f7", "#ff8a65", "#81c784", "#ce93d8", "#fff176",
                              "#f48fb1", "#90a4ae", "#a1887f", "#80deea", "#e6ee9c"][:len(top_vals)])
        dist_charts_html += f"""
        <div class="chart-container">
            <h3>📊 {html.escape(str(tc))} 分布 (Top {len(top_vals)})</h3>
            <canvas id="{chart_id}"></canvas>
        </div>"""
        dist_charts_js += f"""
        new Chart(document.getElementById('{chart_id}'), {{
            type: 'doughnut',
            data: {{
                labels: {dist_labels},
                datasets: [{{ data: {dist_values}, backgroundColor: {colors} }}]
            }},
            options: {{
                responsive: true,
                plugins: {{ legend: {{ position: 'right', labels: {{ color: '#ccc', font: {{ size: 11 }} }} }} }}
            }}
        }});"""

    # 构建统计摘要表
    summary_rows_html = ""
    for col in headers:
        s = stats.get(col, {})
        ct = col_types.get(col, "text")
        type_badge = {"numeric": "🔢 数值", "date": "📅 日期", "text": "📝 文本"}.get(ct, ct)
        detail = ""
        if ct == "numeric":
            detail = f"范围 [{s.get('min',''):.4g} ~ {s.get('max',''):.4g}]  均值 {s.get('avg',0):.4g}  中位数 {s.get('median',0):.4g}"
        elif ct == "date":
            detail = f"{s.get('min_date','')} ~ {s.get('max_date','')}"
        elif ct == "text":
            detail = f"{s.get('unique_count',0)} 个唯一值"
        summary_rows_html += f"""
        <tr>
            <td>{html.escape(str(col))}</td>
            <td><span class="type-badge">{type_badge}</span></td>
            <td>{s.get('non_null_count', 0)}</td>
            <td>{s.get('null_count', 0)}</td>
            <td>{html.escape(detail)}</td>
        </tr>"""

    # 构建数据预览表
    preview_rows = rows[:20]
    preview_header_html = "".join(f"<th>{html.escape(str(h))}</th>" for h in headers)
    preview_body_html = ""
    for row in preview_rows:
        cells = "".join(f"<td>{html.escape(str(row.get(h, '')))}</td>" for h in headers)
        preview_body_html += f"<tr>{cells}</tr>"

    report_html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{html.escape(title)}</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: -apple-system, 'Segoe UI', 'Microsoft YaHei', sans-serif; background: #0d1117; color: #e6edf3; padding: 24px; }}
  .container {{ max-width: 1400px; margin: 0 auto; }}
  .header {{ background: linear-gradient(135deg, #1a237e 0%, #0d47a1 50%, #01579b 100%); border-radius: 16px; padding: 32px; margin-bottom: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.3); }}
  .header h1 {{ font-size: 28px; margin-bottom: 8px; }}
  .header .meta {{ color: rgba(255,255,255,0.7); font-size: 13px; }}
  .header .meta span {{ margin-right: 16px; }}
  .section {{ background: #161b22; border: 1px solid #30363d; border-radius: 12px; padding: 24px; margin-bottom: 20px; }}
  .section h2 {{ font-size: 18px; margin-bottom: 16px; color: #58a6ff; }}
  .kpi-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }}
  .kpi-card {{ background: #21262d; border: 1px solid #30363d; border-radius: 10px; padding: 20px; text-align: center; transition: transform 0.2s; }}
  .kpi-card:hover {{ transform: translateY(-2px); border-color: #58a6ff; }}
  .kpi-label {{ font-size: 12px; color: #8b949e; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }}
  .kpi-value {{ font-size: 26px; font-weight: bold; color: #4fc3f7; }}
  .kpi-sub {{ font-size: 11px; color: #6e7681; margin-top: 6px; }}
  .charts-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(450px, 1fr)); gap: 20px; }}
  .chart-container {{ background: #21262d; border: 1px solid #30363d; border-radius: 10px; padding: 20px; }}
  .chart-container h3 {{ font-size: 14px; color: #c9d1d9; margin-bottom: 12px; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  th {{ background: #21262d; color: #58a6ff; padding: 10px 12px; text-align: left; position: sticky; top: 0; }}
  td {{ padding: 8px 12px; border-bottom: 1px solid #21262d; }}
  tr:hover {{ background: rgba(56,139,253,0.05); }}
  .type-badge {{ display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; background: #21262d; border: 1px solid #30363d; }}
  .data-preview {{ max-height: 500px; overflow: auto; }}
  .footer {{ text-align: center; color: #6e7681; font-size: 12px; padding: 20px 0; }}
  @media (max-width: 768px) {{
    .charts-grid {{ grid-template-columns: 1fr; }}
    .kpi-grid {{ grid-template-columns: repeat(2, 1fr); }}
  }}
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>🏠 {html.escape(title)}</h1>
    <div class="meta">
      <span>📅 生成时间: {now}</span>
      <span>📊 数据量: {len(rows):,} 条</span>
      <span>📋 字段数: {len(headers)}</span>
      {f'<span>📁 来源: {html.escape(source_info)}</span>' if source_info else ''}
    </div>
  </div>

  {'<div class="section"><h2>📌 核心指标概览</h2><div class="kpi-grid">' + kpi_cards_html + '</div></div>' if kpi_cards_html else ''}

  {'<div class="section"><h2>📈 趋势分析</h2><div class="charts-grid">' + trend_charts_html + '</div></div>' if trend_charts_html else ''}

  {'<div class="section"><h2>📊 维度分布</h2><div class="charts-grid">' + dist_charts_html + '</div></div>' if dist_charts_html else ''}

  <div class="section">
    <h2>📋 字段统计摘要</h2>
    <div class="data-preview">
      <table>
        <thead><tr><th>字段名</th><th>类型</th><th>非空数</th><th>空值数</th><th>统计详情</th></tr></thead>
        <tbody>{summary_rows_html}</tbody>
      </table>
    </div>
  </div>

  <div class="section">
    <h2>🔍 数据预览 (前 {len(preview_rows)} 条)</h2>
    <div class="data-preview">
      <table>
        <thead><tr>{preview_header_html}</tr></thead>
        <tbody>{preview_body_html}</tbody>
      </table>
    </div>
  </div>

  <div class="footer">
    Generated by Beacon Dashboard Analyzer &middot; 腾讯灯塔看板数据分析 &middot; {now}
  </div>
</div>

<script>
{trend_charts_js}
{dist_charts_js}
</script>
</body>
</html>"""
    return report_html


# ============================================================
# 主流程
# ============================================================


def run_api_mode(args) -> Tuple[List[str], List[dict], str]:
    """API 模式：从灯塔拉取数据"""
    client = BeaconAPIClient(
        app_id=args.app_id,
        api_key=args.api_key,
        host=args.api_host or "analytics",
    )

    print(f"[INFO] 连接灯塔 API (AppID: {args.app_id})...")

    if args.dashboard:
        print(f"[INFO] 拉取看板数据: {args.dashboard}")
        result = client.get_dashboard_data(
            args.dashboard,
            start_date=args.start_date or "",
            end_date=args.end_date or "",
        )
    elif args.event:
        print(f"[INFO] 拉取事件分析: {args.event}")
        result = client.get_event_analysis(
            args.event,
            start_date=args.start_date or "",
            end_date=args.end_date or "",
            group_by=args.group_by or "",
        )
    elif args.sql:
        print(f"[INFO] 执行 SQL 查询...")
        result = client.query_sql(args.sql)
    elif args.retention:
        events = args.retention.split(",")
        if len(events) != 2:
            print("[ERROR] --retention 需要两个事件名，逗号分隔", file=sys.stderr)
            sys.exit(1)
        print(f"[INFO] 拉取留存数据: {events[0]} -> {events[1]}")
        result = client.get_retention_data(events[0], events[1],
                                            start_date=args.start_date or "",
                                            end_date=args.end_date or "")
    else:
        print("[INFO] 未指定查询类型，拉取看板列表...")
        result = client.get_dashboard_list()

    if isinstance(result, dict) and result.get("error"):
        print(f"[ERROR] API 返回错误: {result.get('message', 'Unknown')}", file=sys.stderr)
        # 返回错误信息作为数据
        return ["status", "message"], [result], f"API Error (AppID: {args.app_id})"

    # 尝试解析返回数据
    data_rows = []
    if isinstance(result, dict):
        # 常见数据字段
        for key in ["data", "rows", "list", "items", "records", "result"]:
            if key in result and isinstance(result[key], list):
                data_rows = result[key]
                break
        if not data_rows:
            data_rows = [result]
    elif isinstance(result, list):
        data_rows = result

    if data_rows and isinstance(data_rows[0], dict):
        headers = list(data_rows[0].keys())
    else:
        headers = ["value"]
        data_rows = [{"value": str(r)} for r in data_rows]

    source = f"Beacon API (AppID: {args.app_id})"
    return headers, data_rows, source


def run_file_mode(args) -> Tuple[List[str], List[dict], str]:
    """文件模式：解析本地数据文件"""
    filepath = args.input
    if not os.path.isfile(filepath):
        print(f"[ERROR] 文件不存在: {filepath}", file=sys.stderr)
        sys.exit(1)

    print(f"[INFO] 解析文件: {filepath}")
    headers, rows = parse_data_file(filepath)
    print(f"[INFO] 已加载 {len(rows)} 条数据，{len(headers)} 个字段")
    source = f"文件: {os.path.basename(filepath)}"
    return headers, rows, source


def main():
    parser = argparse.ArgumentParser(description="腾讯灯塔(Beacon)看板数据分析工具")
    parser.add_argument("--mode", choices=["api", "file"], default="file", help="数据获取模式: api 或 file")

    # API 模式参数
    parser.add_argument("--app-id", help="灯塔应用 AppID")
    parser.add_argument("--api-key", help="灯塔 API Key")
    parser.add_argument("--api-host", default="analytics", help="API Host (analytics / beacon_qq / 自定义URL)")
    parser.add_argument("--dashboard", help="看板 ID")
    parser.add_argument("--event", help="事件名称（事件分析）")
    parser.add_argument("--retention", help="留存分析事件对，逗号分隔，如 'login,active'")
    parser.add_argument("--funnel", help="漏斗 ID")
    parser.add_argument("--sql", help="SQL 查询语句")
    parser.add_argument("--group-by", help="分组维度")
    parser.add_argument("--start-date", help="开始日期 (YYYY-MM-DD)")
    parser.add_argument("--end-date", help="结束日期 (YYYY-MM-DD)")

    # 文件模式参数
    parser.add_argument("--input", "-i", help="输入数据文件路径 (.csv/.xlsx/.json/.tsv)")

    # 通用参数
    parser.add_argument("--output-dir", "-o", default=DEFAULT_OUTPUT_DIR, help="输出目录")
    parser.add_argument("--title", default=REPORT_TITLE, help="报告标题")
    parser.add_argument("--format", choices=["html", "json", "both"], default="both", help="输出格式")

    args = parser.parse_args()

    # 校验参数
    if args.mode == "api":
        if not args.app_id or not args.api_key:
            print("[ERROR] API 模式需要 --app-id 和 --api-key", file=sys.stderr)
            sys.exit(1)
    elif args.mode == "file":
        if not args.input:
            print("[ERROR] 文件模式需要 --input 参数", file=sys.stderr)
            sys.exit(1)

    # 获取数据
    if args.mode == "api":
        headers, rows, source_info = run_api_mode(args)
    else:
        headers, rows, source_info = run_file_mode(args)

    if not rows:
        print("[WARN] 没有获取到任何数据", file=sys.stderr)
        return

    # 分析数据
    print("[INFO] 分析数据中...")
    col_types = detect_column_types(headers, rows)
    stats = compute_statistics(headers, rows, col_types)
    trends = compute_trends(headers, rows, col_types)

    # 输出
    os.makedirs(args.output_dir, exist_ok=True)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

    if args.format in ("json", "both"):
        json_path = os.path.join(args.output_dir, f"beacon_data_{timestamp}.json")
        output_data = {
            "meta": {
                "title": args.title,
                "source": source_info,
                "generated_at": datetime.datetime.now().isoformat(),
                "total_rows": len(rows),
                "columns": headers,
                "column_types": col_types,
            },
            "statistics": {k: {kk: vv for kk, vv in v.items() if kk != "top_values"} for k, v in stats.items()},
            "data": rows,
        }
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2, default=str)
        print(f"[OK] JSON 数据已保存: {json_path}")

    if args.format in ("html", "both"):
        html_path = os.path.join(args.output_dir, f"beacon_report_{timestamp}.html")
        report = generate_html_report(args.title, headers, rows, col_types, stats, trends, source_info)
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"[OK] HTML 报告已保存: {html_path}")

    print("[DONE] 分析完成！")


if __name__ == "__main__":
    main()
