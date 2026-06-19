---
name: beacon-dashboard-analyzer
description: >
  This skill should be used when the user wants to fetch, analyze, or visualize data from
  Tencent Beacon (腾讯灯塔) dashboards. Trigger phrases include "灯塔数据", "灯塔看板",
  "Beacon 数据分析", "灯塔报告", "看板分析", "灯塔指标", or any request about analyzing
  Beacon/DataInsight/DataTalk dashboard data. The skill supports both API-based data fetching
  and local file analysis (CSV/Excel/JSON exported from Beacon), generating comprehensive
  HTML visualization reports and structured JSON data files.
---

# Beacon Dashboard Analyzer

Analyze data from Tencent Beacon (腾讯灯塔) dashboards and generate visual analysis reports.

## Purpose

Fetch data from Tencent Beacon analytics platform via API or parse exported data files,
perform automated statistical analysis, and generate professional HTML visualization reports
with trend charts, distribution graphs, KPI dashboards, and data summaries.

## When to Use

- User requests Beacon dashboard data analysis or report generation
- User has exported CSV/Excel/JSON files from Beacon DataTalk or DataInsight
- User wants to monitor or analyze app metrics (DAU, MAU, retention, events, funnels)
- User mentions "灯塔", "Beacon", "DataTalk", "DataInsight", or "看板数据"

## Capabilities

1. **API Data Fetching**: Pull data directly from Beacon OpenAPI
   - Event analysis (by event code, with optional dimension grouping)
   - Custom SQL queries against the raw event table
   - Generates HTML visualization report + JSON data file

2. **File Data Analysis**: Parse Beacon-exported data files
   - Supported formats: CSV, Excel (.xlsx/.xls), JSON, TSV
   - Auto-detect encoding (UTF-8/GBK)

3. **Automated Analysis**:
   - Auto-detect column types (numeric/date/text)
   - Statistical summaries (min, max, avg, median, distribution)
   - Trend analysis over time dimensions
   - Dimension distribution analysis

4. **Report Generation**:
   - Dark-themed HTML dashboard with interactive Chart.js charts
   - KPI overview cards for key numeric metrics
   - Trend line charts for time-series data
   - Doughnut charts for categorical distributions
   - Field statistics summary table
   - Data preview table
   - Structured JSON data export

## Usage

### Core Script

The main analysis script is located at `scripts/beacon_analyzer.py`. It requires only
Python standard library (no pip install needed for core functionality).

### API Mode — 真实灯塔 OpenAPI

**接口地址**：`http://api.open.beacon.woa.com/beacon/analysis/card`

**鉴权方式**（每次请求在 Header 中携带）：

| Header 字段 | 说明 |
|------------|------|
| `applicationId` | 灯塔开发者账号 ID（`--app-id` 参数） |
| `bizId` | 灯塔空间 ID，URL 中 `/datainsight/{bizId}/` 的第一段（王者营地为 `camp`） |
| `timestamp` | 当前毫秒时间戳（13 位） |
| `sign` | `md5(md5(applicationId + secretKey) + timestamp)`，32 位小写 hex |

**签名算法**：
```python
import hashlib, time
ts = str(int(time.time() * 1000))
part1 = hashlib.md5((app_id + secret_key).encode()).hexdigest().lower()
sign  = hashlib.md5((part1 + ts).encode()).hexdigest().lower()
```

**⚠️ 限流**：该接口**一分钟只能调用一次**，请勿高频调用。

To pull event data and generate a report:

```bash
python scripts/beacon_analyzer.py --mode api \
  --app-id <applicationId> \
  --api-key <secretKey> \
  --biz-id camp \
  --event <EVENT_CODE> \
  --start-date 2026-06-12 \
  --end-date 2026-06-12 \
  --output-dir ./reports \
  --title "事件分析报告"
```

**API mode options**:
- `--event <CODE>`: 按事件 code 查询（按天汇总 total_count + unique_users）
- `--group-by <FIELD>`: 在事件查询基础上按字段分组（如 `c30` 按版本分组）
- `--sql "<SQL>"`: 直接执行自定义 SQL（更灵活，可加任意过滤条件）
- `--biz-id <ID>`: 灯塔空间 ID，王者营地固定为 `camp`
- `--start-date / --end-date`: 日期范围（YYYY-MM-DD）

**自定义 SQL 示例**（过滤特定版本）：
```bash
python scripts/beacon_analyzer.py --mode api \
  --app-id 2617 \
  --api-key <secretKey> \
  --biz-id camp \
  --sql "select substr(cast(ds as string),1,8) as ds_date, c30 as version,
         count(*) as total_count, count(distinct uin) as unique_users
         from beacon_olap.sgame_camp_beacon_ios_log
         where substr(cast(ds as string),1,8) = '20260612'
           and event_code = '20000'
           and c30 = '10.112.0603'
         group by ds_date, c30 order by ds_date limit 1000" \
  --output-dir ./reports
```

### File Mode

To analyze a data file exported from Beacon:

```bash
python scripts/beacon_analyzer.py --mode file \
  --input exported_data.csv \
  --output-dir ./reports \
  --title "Beacon Export Analysis"
```

**Supported file formats**: .csv, .xlsx, .xls, .json, .tsv

### Output

The script generates two files in the output directory:
- `beacon_report_YYYYMMDD_HHMMSS.html` — Interactive HTML report
- `beacon_data_YYYYMMDD_HHMMSS.json` — Structured JSON data with statistics

Use `--format html` or `--format json` to generate only one format.

## 王者营地 iOS 数据表信息

**表名**：`beacon_olap.sgame_camp_beacon_ios_log`

**分区字段**：`ds`，格式为 `YYYYMMDDHH`（按小时分区）

按天过滤写法：
```sql
where substr(cast(ds as string),1,8) = '20260612'
```

**常用字段对应关系**：

| 字段名 | 含义 | 示例值 |
|--------|------|--------|
| `event_code` | 事件 code | `20000` |
| `event_time` | 事件时间 | `2026-06-12 04:45:11` |
| `uin` | 用户唯一标识（QIMEI36） | `7d39e42f-...` |
| `ds` | 分区（YYYYMMDDHH） | `2026061204` |
| `c30` | 客户端版本号（cClientVersionName） | `10.112.0603` |
| `app_version` | 完整版本号（含 build） | `10.112.0603(68220107963612)` |
| `c03` | 平台 | `iOS` / `Android` |
| `platform` | 设备类型 | `iPhone` / `iPad` |
| `c31` | 操作系统 | `ios` |
| `os_version` | 系统版本 | `OS26.5` |
| `brand` | 设备品牌 | `iPhone` |
| `model` | 设备型号 | `iPhone 14` |
| `channel` | 渠道 | `unknown` |
| `province` | 省份 | `安徽省` |
| `country` | 国家 | `中国` |
| `operator` | 运营商 | `中国移动` |
| `sdk_version` | Beacon SDK 版本 | `4.2.76.50` |
| `c01` ~ `cN` | 事件自定义参数（各事件含义不同） | — |

**常用事件 code**：

| 事件 code | 事件名称 |
|-----------|---------|
| `20000` | MTAEventIdAppStart（启动） |

## 综合监测报告二次加工（beacon_report_synthesizer.py）

在巡检日报（beacon-dashboard-inspector 生成的 Markdown）基础上，二次加工生成格式更丰富的**综合监测报告**，涵盖：
- 📊 数据概览（看板汇总表 + 核心统计）
- 📈 关键趋势分析（每看板展开，含状态图标和解读文字）
- 🔍 异常检测（分合理波动 / 真实异常，自动推断原因）
- 📋 状态分类汇总（按看板聚合）
- 📊 数据质量评估
- 📈 优化优先级排序
- 📎 附录（阈值说明、状态定义）

**脚本位置**：`scripts/beacon_report_synthesizer.py`

**用法**：
```bash
# 从文件输入，输出到文件
python scripts/beacon_report_synthesizer.py \
    --input <inspection_report.md> \
    --output <synthesis_report.md>

# 从 stdin 输入，输出到 stdout
cat inspection.md | python scripts/beacon_report_synthesizer.py
```

**典型工作流**（巡检 → 二次加工 → 写回 iWiki）：
```bash
# Step 1: 运行巡检日报生成工具，保存为 Markdown
# Step 2: 二次加工生成综合报告
python scripts/beacon_report_synthesizer.py \
    --input daily_inspection.md \
    --output synthesis_report.md
# Step 3: 用 iWiki MCP 将 synthesis_report.md 写入目标文档
```

---

## Workflow

1. **Determine data source**: Ask the user whether to use API mode or file mode
2. **For API mode**: Collect `applicationId`、`secretKey`、`bizId`（默认 `camp`）及查询参数
3. **For file mode**: Identify the data file path
4. **Run the script**: Execute `scripts/beacon_analyzer.py` with appropriate arguments
5. **Present the report**: Open the generated HTML report for the user
6. **Provide insights**: Summarize key findings from the analysis

## Limitations

- Beacon API 需要内网环境（VPN/办公网络）
- **API 限流：一分钟只能调用一次**，查询前须等待
- T+1 数据次日早上才可用；当日数据最多延迟 5-15 分钟
- Excel 解析需要 openpyxl（CSV/JSON/TSV 仅需标准库）
- `date` 是 Impala SQL 保留字，别名请用 `ds_date` 等非保留词
