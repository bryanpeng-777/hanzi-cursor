---
name: beacon-dashboard-inspector
description: >
  灯塔看板业务指标巡检（仅 Phase 1：数据拉取 + 环比分析 + iWiki 写入 + 企微推送）。
  ⚠️ 本技能是 beacon-inspection-pipeline 的子技能（Phase 1），通常由 pipeline 内部调用。
  仅当用户明确只想跑 Phase 1、不需要综合报告时才单独触发。
  专属触发词：「beacon-dashboard-inspector」「单独跑inspector」「仅inspector」
  「灯塔日报」「看板巡检」「灯塔看板数据」「业务指标日报」「每天自动检查灯塔」。
  ⚠️ 不触发条件：用户提到「流水线」「全套」「两阶段」「beacon-inspection-pipeline」时，
  应触发 beacon-inspection-pipeline 而非本技能。
---

# beacon-dashboard-inspector — 灯塔看板日常巡检

**脚本负责**：数据拉取、CSV 解析、环比计算、阈值比对 → 输出结构化 JSON
**AI 负责**：三层证据交叉分析（时间规律 + 代码变更 + 代码逻辑）→ 根因推断 + 企微消息措辞

---

## 前置条件

- Python 3.8+、Playwright 已安装（见 beacon-data-fetcher 说明）
- 灯塔认证 JSON 已初始化（`~/.claude/skills/beacon-data-fetcher/runtime/beacon_auth_state.json`）
- 企业微信群机器人 webhook key 已填入 `inspection_config.json`
- 各看板的灯塔 URL 已填入 `inspection_config.json`

---

## ⛔ 不可违背的报告规则

> **以下规则优先级高于一切，任何情况下均不得违反：**
>
> 1. **不得以任何理由压缩报告内容。** 不论报告有多长、iWiki 写入是否困难、MCP 是否有限制，都必须输出完整内容。遇到技术限制（如 iWiki 4KB 单次写入上限），通过**分批写入**解决，而不是删减内容。
>
> 2. **每个看板模块必须列出所有指标的完整数据。** `analysis_result.json` 中 `metrics` 数组有多少项，iWiki 报告表格就必须有多少行。`status == "ok"` 的正常指标**不得省略**，不得用「其余 N 项正常」代替。
>
> 3. **版本数据缺失时用「—」占位，并注明原因，而不是直接跳过该指标行。**

---

## 核心流程

```
Step 0：读取配置 + 确定版本口径（有版本=双列对比，无版本/全量=单列）
Step 1：逐个看板拉取数据（beacon-data-fetcher）
Step 2：运行分析脚本（analyze_metrics.py）→ 结构化 JSON
  - 指定版本时：脚本内部自动同时计算全量数据，每个指标含 version_data + all_data
  - 全量模式时：每个指标只含全量数据，格式与旧版兼容
Step 2.5：拉取近期代码变更（仅当 total_anomalies > 0 时执行，用于根因推断）
Step 3：AI 交叉分析 → 根因推断，生成完整报告文本
  - has_version_comparison == true：报告中每个表格并排展示「版本」和「全量」两列数据
  - has_version_comparison == false：沿用原单列格式
  - 有异常：三层证据（时间规律 + 代码变更 + 代码逻辑）交叉推断根因；新口径指标额外判断是否为版本扩量
  - 无异常：生成"今日绿灯"简报，列出各指标环比数据
Step 4：创建 iWiki 文档（写入完整报告，获取文档链接 IWIKI_URL）
Step 5：通过 user-wework-bot MCP 推送精简摘要 + IWIKI_URL 到企业微信（无论是否异常，每日必推）
```

---

## 新增看板触发规则

> ⚠️ **强制规则**：当用户说「新增XXX看板 [URL]」或「添加XXX看板」时，**必须执行「扩展：增加新看板」中的完整 A-E 流程**，不允许只写入 URL 就停下。执行顺序：A（写入配置）→ B（拉取数据获取列名）→ C（扫描 API metadata）→ D（代码比对补全 enum_name/report_location）→ E（填写 meaning 和 threshold_pct）。**所有步骤必须在同一次对话中完成，中途不得停下等待用户催促。**

---

## Step 0：读取配置 & 确定版本口径 & 确定代码工作区

> **版本口径规则**：
> - **具体版本号**（如 `10.112.0603`）：脚本内部自动同时计算「指定版本」和「全量」两套数据，报告中并排对比展示，方便识别问题是该版本特有还是大盘共性
> - **`全量`** 或 **未指定版本**：只计算全版本聚合数据，无版本对比
>
> 若用户未指明版本，**默认走全量模式**，不再强制询问（与旧行为不同）。

读取 `SKILL_DIR/inspection_config.json`，其中 `SKILL_DIR` 为本技能目录：

```
~/.claude/skills/beacon-dashboard-inspector/
```

提取：
- `settings.output_dir`：数据临时存放目录（默认 `/tmp/beacon_inspector`）
- `settings.wework_robot_key`：企微机器人 key
- `dashboards[]`：各看板配置

**自动确定代码工作区（无需手动配置）**：

| 运行环境 | 工作区来源 |
|---------|-----------|
| 本地运行 | 对话上下文中的 `Workspace Path` |
| Knot 运行 | `$KNOT_WORKSPACE` 或 `$WORKSPACE` 环境变量 |

将工作区根目录记为 `REPO_ROOT`，后续所有 `git log` 和 `git grep` 均在此目录执行。若两者均不可用，跳过代码分析步骤（Step 2.5 整体跳过）。

若 `wework_robot_key` 为占位值 `YOUR_WEWORK_ROBOT_KEY_HERE`，提示用户填写后终止。
若某个看板 URL 为占位值，跳过该看板并告知用户。

---

## Step 1：逐个看板拉取数据（含事件名）

Read `~/.claude/skills/beacon-data-fetcher/SKILL.md`，按其流程拉取每个看板数据。

> **小时粒度看板**（灯塔侧均已配置 **相对时间 12 小时 + 小时粒度**，Panel 可不同）：
> - **版本专项 `url`**：仍在 Panel **114739**（card_id 不变），粒度已改为小时
> - **全量 `url_all`**：Panel **114800** 小时看板
> - 抓取时 **两者都不要传 `--days`**（避免把「12 小时」误改成「2 天」）
> - 分析侧固定 **同时段对比**：聚合近 `lookback_hours`（默认 12）小时，对比今日 vs 昨日同时段
> - 若需严格同时段（00:00~当前整点），建议看板相对时间设为 **≥24 小时**；仅 12h 抓取时会回退为「窗口内今日段 vs 昨日段」

拉取时需同时获取两类数据：

| 数据类型 | 用途 |
|---------|------|
| 指标数值（CSV） | Step 2 计算环比 |
| 指标对应的事件名 | Step 2.5-B 精准定位上报代码 |

**事件名提取**：灯塔 API 在返回看板数据时，响应中包含每个指标关联的 `event_name`（或 `eventName`、`metric_key` 等字段，具体字段名见 beacon-data-fetcher 的 API 响应结构）。解析后建立映射：

```json
{
  "日活用户数":   "camp_user_active_daily",
  "次日留存率":   "camp_user_next_day_retention",
  "关键CTR":      "camp_home_feed_click",
  "人均使用时长": "camp_session_duration"
}
```

将此映射写入 `<output_dir>/event_map.json`，供 Step 2.5-B 使用。

### 双 URL 下载（版本专项 + 全量，推荐）

> 每个看板有两个 URL：`url`（版本专项，Panel 114739）和 `url_all`（全量，Panel 114800）。**Panel 不同但粒度均为小时**，分别下载；全量数据使用灯塔服务端预聚合结果，避免客户端 SUM 导致率值和 NDV 失真。

对每个看板，**串行**拉取两次（版本专项 + 全量，均为小时看板）：

| 下载目标 | URL 字段 | 输出目录 |
|---------|---------|---------|
| 版本专项 | `dashboard.url` | `<output_dir>/<看板名称>/` |
| 全量 | `dashboard.url_all` | `<output_dir>_all/<看板名称>/` |

- 若 `url_all` 为占位值 `FILL_IN_ALL_VERSION_URL`：跳过全量专属下载，Step 2 自动退化为客户端 SUM 聚合（并在报告中标注）
- 全量 URL 通常是去掉版本筛选参数的同一看板链接，或灯塔上对应的无版本筛选版本

### 路径 A：MCP / CLI 模式（推荐，Knot 友好）

调用 beacon-data-fetcher 的 MCP 接口 / CLI 命令，指定看板 URL，**不传 `--days`**（使用看板默认 12 小时），同时请求返回事件元数据。

### 路径 B：Playwright 浏览器模式（本地备选）

> ⚠️ **必须串行执行，禁止并发**：多个看板并发运行 Playwright 脚本会导致进程互相抢占资源，卡死在"未匹配到任务，等待刷新"循环中。必须逐个看板顺序执行，等上一个完成后再启动下一个。

> ✅ **推荐使用页面抓取模式（`beacon_page_scrape.py`）**：多看板批量拉取场景下，页面抓取模式比下载导出模式更稳定。下载导出模式适合单看板、数据量超过 5000 行的场景。

```bash
# 版本专项（小时看板，不要传 --days）
python3 {BEACON_SKILL_DIR}/scripts/beacon_page_scrape.py \
  --auth "{BEACON_SKILL_DIR}/runtime/beacon_auth_state.json" \
  --url "<dashboard.url>" \
  --output-dir "<output_dir>/<看板名称>" \
  --wait 15

# 全量（小时看板，不要传 --days）
python3 {BEACON_SKILL_DIR}/scripts/beacon_page_scrape.py \
  --auth "{BEACON_SKILL_DIR}/runtime/beacon_auth_state.json" \
  --url "<dashboard.url_all>" \
  --output-dir "<output_dir>_all/<看板名称>" \
  --wait 15
```

若数据量超过 5000 行需要完整数据，改用下载导出模式（但仍需串行，且**不要传 `--days`**，保留看板 12 小时配置）：

```bash
python3 {BEACON_SKILL_DIR}/scripts/beacon_download_export.py \
  --auth "{BEACON_SKILL_DIR}/runtime/beacon_auth_state.json" \
  --url "<dashboard.url>" \
  --output-dir "<output_dir>/<看板名称>" \
  --trigger-export --wait-query 120
```

`{BEACON_SKILL_DIR}` = `~/.claude/skills/beacon-data-fetcher`

---

## Step 2：运行分析脚本

所有看板数据下载完成后，运行分析脚本：

```bash
# 指定版本 + 全量专属目录（推荐：全量数据来自 url_all，率值/NDV 准确）
python3 ~/.claude/skills/beacon-dashboard-inspector/scripts/analyze_metrics.py \
  --config ~/.claude/skills/beacon-dashboard-inspector/inspection_config.json \
  --data-dir <output_dir> \
  --data-dir-all <output_dir>_all \
  --version <版本号> \
  --output <output_dir>/analysis_result.json

# 指定版本（无 url_all，退化为客户端 SUM 聚合全量，率值可能失真）
python3 ~/.claude/skills/beacon-dashboard-inspector/scripts/analyze_metrics.py \
  --config ~/.claude/skills/beacon-dashboard-inspector/inspection_config.json \
  --data-dir <output_dir> \
  --version <版本号> \
  --output <output_dir>/analysis_result.json

# 全量模式（只输出全量数据，无版本对比）
python3 ~/.claude/skills/beacon-dashboard-inspector/scripts/analyze_metrics.py \
  --config ~/.claude/skills/beacon-dashboard-inspector/inspection_config.json \
  --data-dir <output_dir> \
  --version 全量 \
  --output <output_dir>/analysis_result.json
```

> `analysis_result.json` 中每个看板会包含 `"all_source"` 字段，值为 `"dedicated_url"`（使用 url_all）或 `"client_sum_fallback"`（退化为 SUM 聚合）。生成报告时，若 `all_source == "client_sum_fallback"`，在该看板的全量列旁标注「⚠️ 全量数据为客户端聚合，率值可能失真」。

读取生成的 `analysis_result.json`，根据是否有版本对比，结构略有不同。

**对比规则（仅同时段，无日粒度回退）**：

- 所有看板 CSV **必须为小时粒度**；若仍为日粒度（`dim_0` 仅 `YYYY-MM-DD`），分析脚本报错并提示去灯塔改配置
- 聚合近 `lookback_hours`（默认 12）小时，对比今日 vs 昨日同时段
- 抓取仅 12h 且跨日时，回退为抓取窗口内「今日段 vs 昨日段」（报告会注明）

报告列头：**今日近12h** vs **昨日同时段**。分布看板（iOS 占比类）逻辑不变。

**全量模式**（`has_version_comparison: false`）：

```json
{
  "run_time": "2026-06-11 09:05:23",
  "version": "全量",
  "has_version_comparison": false,
  "total_dashboards": 1,
  "total_anomalies": 1,
  "dashboards": [
    {
      "dashboard_name": "营地业务大盘",
      "metrics": [
        {
          "name": "日活用户数",
          "today": 523000,
          "yesterday": 581000,
          "change_pct": -9.98,
          "threshold_pct": 10,
          "status": "ok"
        }
      ],
      "anomalies": [...]
    }
  ]
}
```

**指定版本模式**（`has_version_comparison: true`）：每个指标含 `version_data`（指定版本）和 `all_data`（全量）两个子对象，顶层 `status` 取两者中更严重的一方：

```json
{
  "run_time": "2026-06-11 09:05:23",
  "version": "10.112.0603",
  "has_version_comparison": true,
  "total_dashboards": 1,
  "total_anomalies": 1,
  "dashboards": [
    {
      "dashboard_name": "营地业务大盘",
      "has_version_comparison": true,
      "metrics": [
        {
          "name": "次日留存率",
          "threshold_pct": 8,
          "status": "anomaly",
          "version_data": {
            "today": 31.2,
            "yesterday": 38.5,
            "change_pct": -18.96,
            "today_date": "2026-06-11",
            "yesterday_date": "2026-06-10",
            "status": "anomaly"
          },
          "all_data": {
            "today": 35.6,
            "yesterday": 37.2,
            "change_pct": -4.30,
            "today_date": "2026-06-11",
            "yesterday_date": "2026-06-10",
            "status": "ok"
          }
        },
        {
          "name": "日活用户数",
          "threshold_pct": 10,
          "status": "ok",
          "version_data": {
            "today": 98000,
            "yesterday": 102000,
            "change_pct": -3.92,
            "status": "ok"
          },
          "all_data": {
            "today": 523000,
            "yesterday": 531000,
            "change_pct": -1.51,
            "status": "ok"
          }
        }
      ],
      "anomalies": [...]
    }
  ]
}
```

---

## Step 2.5：构建代码知识库（仅当 total_anomalies > 0 时执行）

**目的**：为每个异常指标建立两层代码上下文——「近期发生了什么变化」+「这块逻辑本身是怎么工作的」。两者结合才能做出可信的根因推断。

```
2.5-A：近期变更（what changed）— git log 近 48h commits
2.5-B：相关逻辑代码（how it works）— 定位并阅读相关模块代码
```

### 2.5-A：拉取近期代码变更

对 `settings.repos[]` 中配置的每个仓库，拉取近 **48 小时**的提交记录：

```bash
git -C <repo_path> log \
  --since="2 days ago" \
  --pretty=format:"%h|%ad|%an|%s" \
  --date=short \
  --no-merges
```

提取每条 commit 的：hash（短）、时间、作者、提交信息。按时间倒序汇总。

### 2.5-B：通过事件名自动定位上报代码（精准模式）

灯塔看板的每个指标都对应具体的埋点事件名（`event_name`）。用事件名在代码仓库中 `grep`，可以**精确找到上报这个事件的那一行代码**，再向上展开读调用上下文——比关键词模糊搜索精准得多。

**Step 1：获取事件名（自动）**

读取 Step 1 生成的 `<output_dir>/event_map.json`，直接拿到各异常指标对应的事件名，无需任何手动配置。

**Step 2：grep 精确定位上报位置**

对每个异常指标，在所有配置的仓库中搜索事件名：

```bash
# 找到上报这个事件的所有位置（文件路径 + 行号）
for repo in <settings.repos[]>; do
  git -C $repo grep -n "<event_name>" -- "*.swift" "*.m" "*.dart" "*.kt" "*.java"
done
```

输出示例：
```
social-ios/Classes/Push/RetentionPushManager.swift:142:    [tracker report:@"camp_user_next_day_retention" params:@{...}]
flutter_module/lib/features/onboarding/retention_tracker.dart:67:    dtReport('camp_user_next_day_retention', params);
```

**Step 3：读取上报点的周围代码**

对每个 grep 命中位置，读取**上下各 40 行**，重点理解：
- 上报被包裹在什么条件里（`if/guard/when`）
- 哪些情况下会**跳过**上报（`return`/`continue`/`guard else`）
- 上报的参数从哪里来（是否可能为空或异常值）
- 调用这段代码的时机（是什么事件触发的）

**示例分析输出**：

```
事件 camp_user_next_day_retention 定位到：
  RetentionPushManager.swift:135-185

关键逻辑（第 138-145 行）：
  guard !user.isWeekendRegistered else { return }  // ← 周末注册用户跳过上报
  guard user.daysSinceRegister == 1 else { return }
  [tracker report:@"camp_user_next_day_retention" ...]

发现：isWeekendRegistered 判断会导致周末注册用户的次日留存不被统计
→ 今天周一，昨天（周日）注册用户较多，这条 guard 可能解释了留存率下降
```

**若某指标未配置 `event_name`**：退化为 2.5-A 的变更分析 + 时间规律推断，在通知中注明「未配置事件名，无法定位上报代码」。

---

## Step 3：AI 交叉分析（指标异常 × metadata × 代码变更）→ 根因推断

> **报告生成脚本（必须使用）**：先运行 `generate_report.py` 生成完整 Markdown 骨架（率类指标自动 ×100 展示），再在此基础上补充根因分析段落：
>
> ```bash
> python3 ~/.claude/skills/beacon-dashboard-inspector/scripts/generate_report.py \
>   --input <output_dir>/analysis_result.json \
>   --output <output_dir>/inspection_report.md
> ```
>
> ⚠️ Beacon CSV 中成功率/完成率等以 **0~1 小数**存储（如 0.99 = 99%），禁止直接加 `%` 展示。

读取 Step 2 的 `analysis_result.json`（已含各指标的 metadata）和 Step 2.5 的代码变更列表，综合分析后生成推送文本。

**分析时必须优先使用每个指标的 metadata 字段作为分析上下文：**

| metadata 字段 | 在分析中的用途 |
|--------------|--------------|
| `meaning` | 理解该指标的业务含义，判断波动是否合理 |
| `event_code` + `enum_name` | 在代码里精准定位上报调用，不靠猜测 |
| `report_location` | 直接定位到具体文件和行号，查看上报逻辑和周边条件 |
| `aggregation` | 理解聚合方式，判断异常是「人数多了」还是「次数多了」|

**含 `isLatestApp` 条件的指标（新口径）分析规则：**
- `meaning` 中若注明「灰度期/isLatestApp」，优先判断是否为**版本扩量引起的正常增长**
- 结合历史 15 天趋势，若数值持续上升而旧口径指标平稳，则判定为扩量，非业务异常
- 阈值已预设为 30%，触警时在企微消息中注明「新口径指标受版本覆盖率影响，当前为正常扩张」

### 无异常时（total_anomalies == 0）

```
✅ 灯塔日报 MM/DD

今日各看板指标正常，无环比异常（阈值 ≥10% 下降）。

[看板名] 核心指标：
• DAU：52.3万（环比 +1.2%）
• 次日留存：38.5%（环比 -2.1%）
• 7日留存：22.3%（环比 +0.8%）
```

无异常时**不输出代码变更信息**（避免信息噪音）。

### 有异常时 — 交叉分析逻辑

**第一步：理解每个异常指标的业务含义**

| 指标 | 波动敏感的代码区域 |
|------|-----------------|
| DAU / 活跃用户数 | 推送/通知模块、启动流程、登录入口 |
| 次日/7日留存率 | 新用户引导、消息提醒、核心功能可用性 |
| 关键 CTR | 首页 Feed 排序、推荐算法、Banner/入口展示 |
| 人均使用时长 | 内容加载速度、播放功能、主流程卡顿 |
| 漏斗转化率 | 关键路径上的功能变更（支付/报名/关注等） |

**第二步：三层证据交叉分析**

对每个异常指标，按以下三个维度综合推断根因：

```
层 1 — 时间规律（无需代码）
   今天星期几？是否节假日次日？是否月初/月末？
   → 周期性波动通常可以解释 ±10% 的自然浮动

层 2 — 代码变更（2.5-A）
   近 48h 是否有与该指标敏感模块相关的 commit？
   → 有 → 疑似该变更导致，标注作者和 commit 信息
   → 无 → 不是代码变更导致，排除此维度

层 3 — 代码逻辑（2.5-B）★ 核心新增
   阅读相关逻辑后，代码中是否存在以下情况：
   a. 某个条件分支在特定时间/用户/版本下会跳过上报
      → 「周末注册用户次日不发提醒 Push → 周一留存自然低」
   b. 某个降级或开关逻辑被意外触发
      → 「灰度开关 xxx 在版本 N 中默认关闭 → 功能未生效导致 CTR 下降」
   c. 数据采集时机或条件有误
      → 「DAU 上报在 viewDidAppear 而非 session start → 某流程改版后触发时机变了」
   d. 边界条件下的特殊处理与预期不符
      → 「首次启动用户不进入 Feed → 新版引导流程改变了首屏」
```

**第三步：生成 iWiki 报告正文（Markdown）**

报告结构如下，**不含「上报代码索引」章节**：

---

### 核心原则：完整数据表格优先

> ⚠️ **强制规则**：每个看板模块**必须先输出完整数据总表**，列出该看板的**全部指标**（`analysis_result.json` 中 `metrics` 数组的每一项，不得因 `status == "ok"` 而省略）。完整表格输出后，再单独对异常/合理波动指标做根因分析。

---

**当 `has_version_comparison == true`（指定版本巡检）时**：

```markdown
# 灯塔看板巡检日报 YYYY-MM-DD HH:mm

**巡检时间**：YYYY-MM-DD HH:mm
**数据区间**：YYYY-MM-DD（今，周X）vs YYYY-MM-DD（昨，周X）
**版本口径**：10.112.0603（版本专项）+ 全量对比

---

## 巡检概览

| 看板 | 指标总数 | 异常 | 立即排查 | 建议观察 | 状态 |
|------|--------|------|---------|---------|------|
| 营地业务大盘 | 6 | 0 | 0 | 0 | ✅ 全部正常 |
| 观战事件分析 | 4 | 4 | 0 | 4 | ⚠️ 异常（4 项建议观察） |

> 超阈值指标统一标记为 ⚠️ 异常；处理建议列区分「立即排查」与「建议观察」及判断理由。

---

## 📊 [看板名称] [整体状态emoji]

[若该看板版本数据全部缺失，在此注明原因，如：> 版本维度均无数据（版本粒度下反馈量极少，CSV 无匹配行）]

| 指标 | 版本 今日 | 版本 昨日 | 版本 环比 | 全量 今日 | 全量 昨日 | 全量 环比 | 状态 | 处理建议 |
|------|---------|---------|---------|---------|---------|---------|------|---------|
| 指标1 | 31.2% | 38.5% | **-18.96%** | 35.6% | 37.2% | -4.30% | ⚠️ | 立即排查：率值降 7.3pp |
| 指标2 | 26.1万 | 25.4万 | +2.8% | 267.9万 | 262.1万 | +2.2% | ✅ | — |
| 指标3（版本无数据） | — | — | — | 11 | 7 | +57.14% | ⚠️ | 建议观察：绝对值极小（今 11 / 昨 7） |
| ...（该看板所有指标均需列出，不得省略）... | | | | | | | |

[若某指标全量列有异常值（如超过 100% 的完成率），在表格下方加 blockquote 说明原因]
> 完成率全量昨日值 145% 不在合法范围，系分析脚本对多版本行累加率列导致，版本数据正常。

### 异常分析

[仅在该看板有 ⚠️ 异常 时输出此节，全部正常则省略]

**⚠️ [指标名] — [立即排查 / 建议观察]**

- **理由**：[脚本输出的 handling_reason，如率值下滑 / 小样本 / 周期波动 / 发版推量 等]

---

*由灯塔看板巡检自动生成 · beacon-dashboard-inspector*
```

---

**当 `has_version_comparison == false`（全量巡检）时**：

```markdown
# 灯塔看板巡检日报 YYYY-MM-DD HH:mm

**巡检时间**：YYYY-MM-DD HH:mm
**数据区间**：YYYY-MM-DD（今）vs YYYY-MM-DD（昨）
**版本口径**：全量

---

## 巡检概览

| 看板 | 指标总数 | 真实异常 | 合理波动 | 状态 |
|------|--------|---------|---------|------|
| 营地业务大盘 | 6 | 0 | 2 | 〰️ 合理波动 |

> 状态优先级：⛔ 真实异常 > 〰️ 合理波动 > ✅ 全部正常

---

## 📊 [看板名称] [整体状态emoji]

| 指标 | 今日 | 昨日 | 环比 | 状态 |
|------|------|------|------|------|
| 次日留存率 | 31.2% | 38.5% | **-18.96%** | ⛔ |
| APP启动总人数 | 267.9万 | 277.1万 | -3.32% | ✅ |
| ...（该看板所有指标均需列出，不得省略）... | | | | |

### 异常分析

[仅在该看板有 ⛔/〰️ 时输出此节]

**⛔ [指标名] — 真实异常**

- **时间规律**：...
- **代码变更**：...
- **代码逻辑**：...

**〰️ [指标名] — 合理波动**

原因：...

---

*由灯塔看板巡检自动生成 · beacon-dashboard-inspector*
```

**格式规则**：
- 顶部「巡检概览」表：「真实异常」和「合理波动」两列，状态列优先级：⛔ 真实异常 > 〰️ 合理波动 > ✅ 全部正常
- **每个看板必须先输出包含所有指标的完整数据总表**，`analysis_result.json` 中 `metrics` 数组有多少项，表格就必须有多少行，`status == "ok"` 的指标不得省略
- 完整总表之后，仅对有 ⛔ 或 〰️ 的指标补充「异常分析」小节；若该看板全部正常，省略「异常分析」节
- **分布看板（`is_distribution: true`）**：`analysis_result.json` 中该看板返回 `is_distribution: true`，`metrics` 数组中每项包含 `version_data.today`（指定版本用户量）和 `all_data.today`（全版本汇总用户量），无 `yesterday`/`change_pct`。在报告中以如下格式输出，状态固定为 ✅（不参与异常计数）：
  ```markdown
  ## 📊 [看板名称] ✅（分布快照 Top3）

  > 分布型看板（dim_0 = 操作系统版本/设备机型），无时间维度，展示 Top3 维度占比。版本列为 10.112.0603 用户，全量列为所有版本汇总。

  | 排名 | OS版本/机型 | 版本 用户量 | 全量 用户量 |
  |------|-----------|-----------|-----------|
  | Top1 | OS26.5 | 346.3万 | 564.2万 |
  | Top2 | OS26.5.1 | 92.2万 | 131.1万 |
  | Top3 | OS26.4.2 | 43.0万 | 88.2万 |
  ```
  巡检概览表中该看板的「指标总数」填 `Top3`，「真实异常/合理波动」均填 `—`，状态填 `ℹ️ 分布快照`。
- 数值格式化：超过 1 万的用「X.XX万」，百分比保留两位小数，缺失数据用「—」
- 数据缺失说明：版本数据为空（`null`）时，版本今日/昨日/环比均填「—」，并在表格上方 blockquote 说明原因（如「版本粒度下该看板无数据，原因：……」）
- 全量异常值：若全量数据出现非合法数值（如率值 > 100%），在表格下方 blockquote 注明属于数据聚合问题，不影响版本数据判读
- `has_version_comparison == true` 时：表格列为「版本今日 / 版本昨日 / 版本环比 / 全量今日 / 全量昨日 / 全量环比 / 状态」共 7 列
- `has_version_comparison == false` 时：表格列为「今日 / 昨日 / 环比 / 状态」共 4 列
- 超阈值环比数字加粗；状态列用 ✅ / 〰️ / ⛔ emoji 标注
- **不输出「上报代码索引」章节**

**注意原则**：
- 代码分析结论写「发现」/「可能」/「建议确认」，不武断定责
- 找到代码证据时，明确说明文件名和逻辑位置，方便人工快速核查
- 没有代码可读时，退化为时间规律推断并注明「未读取代码逻辑」

---

## Step 4：创建 iWiki 文档

在执行企微推送前，先将完整报告写入 iWiki 文档，获取文档链接供 Step 5 使用。

### 4-A：定位「灯塔巡检报告」目录

调用 `user-iWiki` MCP 的 `getSpaceInfo` 工具获取个人空间信息（spaceKey: `"~{staff_id}"`），取得 `homepageid`。

再调用 `getSpacePageTree`（parentid = homepageid），在子文档列表中查找标题为 **「灯塔巡检报告」** 的目录节点，取其 `docid` 作为 `REPORT_DIR_ID`。

- 若目录已存在（如 `4021729814`）：直接使用
- 若目录不存在：调用 `createDocument` 创建一个 `contenttype: "FOLDER"` 的文件夹，标题为「灯塔巡检报告」，parentid = homepageid，记录新 docid 为 `REPORT_DIR_ID`

### 4-B：分批写入文档（强制使用，规避 iWiki MCP 的 4KB 单次限制）

> ⚠️ **已知限制**：iWiki MCP 单次调用传入超过约 4KB 的 Markdown 内容时，会触发 JSON 解析错误（`Bad escaped character in JSON at position XXXX`）。完整巡检报告通常远超此限制，**必须分批写入**，不得将完整报告内容一次性传入 `createDocument` 的 `body` 参数。

**标准分批流程（3 步）：**

**第 1 步：创建空文档**

调用 `createDocument`，`body` 只传第一批内容（约 4KB 以内），通常为**报告头部 + 巡检概览表 + 前几个看板的完整数据表格**：

```
- spaceid：个人空间 spaceid
- parentid：REPORT_DIR_ID
- contenttype："MD"
- title："灯塔看板巡检日报 YYYY-MM-DD HH:mm"
- body：第一批 Markdown 内容（≤ 4KB）
```

创建成功后记录 `docid`，文档链接为 `https://iwiki.woa.com/p/{docid}`，记为 `IWIKI_URL`。

**第 2 步 起：用 `saveDocumentParts` 追加后续内容**

对剩余内容，每次约 4KB 以内调用一次 `saveDocumentParts`，使用 `after` 参数追加到文档末尾：

```
- id：上一步获得的 docid
- title："灯塔看板巡检日报 YYYY-MM-DD HH:mm"（保持不变）
- after：本批次 Markdown 内容（≤ 4KB）
```

重复本步骤直到全部内容写入完毕。

**分批切割建议**：
- 以 `\n---\n` 为自然分割点，按看板边界切割，避免在表格中间截断
- 每批 JSON 编码后 ≤ 4000 字符（中文字符 JSON 编码后约占 6 字节，需保守估算）
- 典型报告（13 个看板）分 3 批：批1=头部+概览+前6看板，批2=7-11看板，批3=12-13看板+代码变更+页脚

**特殊字符注意事项**：
- 传入 `body`/`after` 参数的内容中，`—`（em dash U+2014）、`×`（乘号 U+00D7）等特殊符号有时会触发 JSON 解析错误，若出现错误可将其替换为 `-` 和 `x`
- 中文字符本身无问题，MCP 会自动转义为 `\uXXXX`

创建成功后，文档链接为：`https://iwiki.woa.com/p/{docid}`，记为 `IWIKI_URL`。

---

## Step 5：推送企业微信（含 iWiki 链接）

通过 `user-wework-bot` MCP 发送 Markdown 消息。正文为**精简摘要 + iWiki 详情链接**，不再把完整分析塞进企微消息。

消息格式如下：

**无异常时：**
```
✅ 灯塔日报 MM/DD — 全部正常

[看板名] 今日各指标正常，无环比异常。

核心指标：
• APP启动总人数：267.9万（环比 -3.32%）
• 进入主界面总次数：812.7万（环比 -1.75%）
• ...（列出各指标一行简报）

📄 完整报告：https://iwiki.woa.com/p/XXXXX
```

**有异常时：**
```
⚠️ 灯塔日报 MM/DD — 发现 N 项指标异常

[看板名] 异常指标（超阈值）：
📉 指标名：今日值（昨日值，环比 X%，超阈值 Y%）
   → 一句话根因（时间规律 / 代码变更 / 代码逻辑 任选最可信一项）

[看板名] 正常指标：
• 指标名：值（环比 X%）

📄 完整分析报告：https://iwiki.woa.com/p/XXXXX
```

调用 `send_wework_message`，传入：
- `type`：`"markdown"`
- `content`：上述格式的摘要文本（含 iWiki 链接）

消息格式如下：

**全部正常时：**
```
✅ 灯塔日报 MM/DD — 全部正常

[看板名] 今日各指标正常，无环比异常。

核心指标：
• APP启动总人数：267.9万（环比 -3.32%）
• ...

📄 完整报告：https://iwiki.woa.com/p/XXXXX
```

**有真实异常时（最高优先级）：**

*全量模式：*
```
⛔ 灯塔日报 MM/DD — 发现 N 项真实异常，需关注！

[看板名] ⛔ 真实异常（需排查）：
📉 指标名：今日值（昨日值，环比 X%）
   → 一句话根因

[看板名] 〰️ 合理波动（已知原因，无需处理）：
• 指标名：今日值（昨日值，环比 X%）— 版本扩量/小样本波动

📄 完整分析报告：https://iwiki.woa.com/p/XXXXX
```

*版本对比模式（has_version_comparison == true）：*
```
⛔ 灯塔日报 MM/DD（10.112.0603 vs 全量）— 发现 N 项真实异常，需关注！

[看板名] ⛔ 真实异常（需排查）：
📉 指标名：版本 31.2% / 全量 35.6%（昨：版本 38.5% / 全量 37.2%）
   版本环比 -18.96% ⚠️ / 全量环比 -4.30%
   → 一句话根因（问题集中在该版本，大盘正常/异常）

[看板名] 〰️ 合理波动：
• 指标名：版本 X / 全量 X（环比 版本 X% / 全量 X%）— 版本扩量

📄 完整分析报告：https://iwiki.woa.com/p/XXXXX
```

**仅有合理波动（无真实异常）时：**

*全量模式：*
```
〰️ 灯塔日报 MM/DD — 无真实异常，N 项合理波动

[看板名] 所有核心指标正常，以下波动均有已知原因：
• 指标名：今日值（昨日值，环比 X%）— 版本扩量/小样本波动

正常指标：
• 指标名：值（环比 X%）

📄 完整报告：https://iwiki.woa.com/p/XXXXX
```

*版本对比模式：*
```
〰️ 灯塔日报 MM/DD（10.112.0603 vs 全量）— 无真实异常，N 项合理波动

[看板名] 合理波动：
• 指标名：版本 X / 全量 X（环比 版本 X% / 全量 X%）— 原因

正常指标：
• 指标名：版本 X / 全量 X（版本环比 X% / 全量环比 X%）

📄 完整报告：https://iwiki.woa.com/p/XXXXX
```

---

## 代码分析：无需任何配置

代码分析所需的一切都自动获取：

| 需要什么 | 来源 | 方式 |
|---------|------|------|
| 代码仓库路径 | 当前工作区 | 本地用 `Workspace Path`，Knot 用 `$KNOT_WORKSPACE` |
| 事件名 | 灯塔 API 响应 | Step 1 取数时自动提取，写入 `event_map.json` |

**你唯一需要填写的是 `wework_robot_key` 和看板 URL。**

**降级说明**：
- 工作区不可用 → Step 2.5 整体跳过，退化为时间规律推断
- 某指标的事件名灯塔未返回 → 跳过该指标的代码定位，用变更分析兜底

---

## 扩展：增加新看板

> ⛔ **强制规则：Step A-E 全部必须执行，不可跳过任何一步。** 新看板必须补全所有 metrics 的 metadata（event_code / enum_name / report_location / aggregation / meaning）才算配置完成，不允许以空 metrics 或未补全 metadata 的状态结束。

### 完整流程（A-E 全部必须执行）

**Step A：初始配置**  
在 `inspection_config.json` 的 `dashboards` 末尾追加，先只填 url，`metrics` 置空：

```json
{
  "name": "视频业务看板",
  "url": "https://beacon.woa.com/datainsight/camp/PanelMax/YOUR_PANEL_ID",
  "page_type": "auto",
  "metrics": []
}
```

**Step B：拉取数据，获取 CSV 列名**（必须）  
使用 `beacon_page_scrape.py`（页面抓取模式）拉取 2 天数据，同时生成 `api_responses_*.json` 供 Step C 使用。查看 CSV 第一行，将**所有列**填入 `metrics`。

> ⚠️ **指标必须全量列举**：`metrics` 数组必须包含该看板 CSV 的**所有**数据列，不得遗漏。

**Step C：拦截 Beacon API，扫描 metadata**（必须）  
读取 Step B 生成的 `api_responses_*.json`，在 `panel_card_result` 响应的 `querySql` 字段提取：
- 各指标对应的 `event_code`
- 过滤条件（`isLatestApp`、`first`、`hasLog` 等）
- 聚合方式（`NDV`、`COUNT` 等）
- 各 index 对应的中文指标名（`result_desc[].title`）

**Step D：代码比对，补全 enum_name / report_location**（必须）  
用 event_code 在代码库搜索枚举定义和上报调用：
```bash
git grep -rn "= <event_code>" social-ios/xcodeproj/WEGGlue/
git grep -rn "MTAEventIdXxx" social-ios/ -- "*.swift" "*.m"
```
找到枚举定义（`enum_name`）和实际上报调用的文件路径与行号（`report_location`），并阅读上下文理解上报触发条件。

**Step E：填写 meaning 和调整 threshold_pct**（必须）  
- 含 `isLatestApp` 条件的指标（新口径/灰度期）：`threshold_pct` 设 **30**，`meaning` 中注明
- 数量级小、天然波动大的指标（如用户反馈）：`threshold_pct` 设 **50**
- 稳定的核心业务指标：`threshold_pct` 设 **10**

**每条 metric 的完整格式（所有字段必填）：**
```json
{
  "column_keyword": "列名（与 CSV 完全一致）",
  "display_name": "展示名",
  "threshold_pct": 10,
  "event_code": "XXXXX",
  "enum_name": "MTAEventIdXxx",
  "report_location": "XxxFile.m:行号 → 上报调用描述",
  "aggregation": "NDV(uin) / COUNT(*) / COUNT 条件...",
  "meaning": "该指标业务含义，一句话"
}
```

**无需修改任何代码**，下次运行时自动覆盖新看板。

---

## 日常使用

**手动触发**：
```
灯塔看板巡检 10.112.0603 的数据    → 指定版本，同时输出版本数据和全量对比
灯塔看板巡检全量                  → 只输出全量数据
帮我跑一下灯塔巡检                → 未指定版本，默认走全量模式
```

**版本口径说明**：

| 口径 | 输出内容 | 适用场景 |
|------|---------|---------|
| 具体版本（如 `10.112.0603`） | 指定版本数据 + 全量对比（双列） | 灰度版本专项巡检、新版上线质量监控 |
| `全量` 或 未指定 | 全量数据（单列） | 大盘整体健康度巡检（NDV 为跨版本估算） |

**定时触发**：通过 `scheduled-task-orchestrator` 技能配置每日 9:00 自动执行。

---

## 常见问题

| 问题 | 处理方式 |
|------|---------|
| 灯塔登录态过期 | 等待用户扫码，扫码后自动继续 |
| 某个看板 URL 失效 | 跳过该看板，在通知中说明 |
| CSV 无日期列 | 用最后两行作为对比行，在通知中注明 |
| CSV 仍为日粒度 | 分析报错并给出 `dim_0` 示例；请在灯塔将该看板改为「小时」+ 相对时间 12h |
| 小时 CSV 无昨日同时段 | 看板相对时间改为 ≥24h，或接受「窗口内今日段 vs 昨日段」回退 |
| 某指标列名变更 | 脚本按关键词模糊匹配，修改 column_keyword 可适配 |
| 日期/版本列识别失败（today_date=None） | `dim_0`/`dim_1` 被重命名为 `event_time`/`客户端 VersionName` 后，`find_date_column` 和 `find_version_column` 需包含这些候选名。`analyze_metrics.py` 已修复，候选列表含 `event_time`、`VersionName` |
| 分布看板（iOS系统/机型占比）首次运行无环比 | 首次运行自动写入快照到 `~/.claude/skills/beacon-dashboard-inspector/runtime/distribution_snapshots.json`，次日运行时自动与昨日快照对比。首次显示"首次运行无历史快照，环比为空" |
| 所有指标均 missing | 可能是 CSV 结构变化，提示用户检查看板格式 |


---

## 相关技能

- **[beacon-report-synthesizer](~/.claude/skills/camp/beacon-report-synthesizer/SKILL.md)**：将本技能输出的巡检日报 Markdown 二次加工为综合监测报告（数据概览 + 趋势分析 + 异常检测 + 优先级排序）。巡检完成后可直接调用。
