---
name: ifeedback
description: 查询和分析 iFeedback 用户反馈数据。触发场景：搜索反馈、查看趋势、分布统计、告警查询、热词分析、生成反馈链接、解析 iFeedback URL、反馈采样、字段检查。当用户发送 iFeedback 链接时触发解析和分析。当用户不知道 app_name 时，提醒用户发送 iFeedback 页面链接，通过 parse_url 反查。触发关键词：iFeedback、用户反馈、反馈趋势、反馈分布、反馈告警、ifeedback.qq.com。
version: 2.0.0
tags:
- 反馈分析
- 数据分析
category: 质量分析
---

# iFeedback 查询工具

通过 MCP 协议查询 iFeedback 用户反馈数据（零依赖 Python CLI 工具）。

## 环境变量

- `IFEEDBACK_MCP_TOKEN` — 太湖个人令牌（必需）。申请地址：https://tai.it.woa.com/user/pat ，创建令牌时授权应用搜索 ifeedback
- `IFEEDBACK_MCP_URL` — MCP Server 地址（可选，默认 `https://ifeedback.mcp.it.woa.com`）
- `IFEEDBACK_RTX` — 最终用户 RTX（可选）。当调用方使用自己的太湖 token 搭建智能体或平台服务时，可设置此变量传入最终用户的 RTX，服务端会在调用方鉴权通过后，进一步校验该用户是否有权限访问对应应用。不设置则不做二次校验

## 用法

```bash
python3 scripts/ifeedback_api.py <命令> [参数]
```

## 可用命令

| 命令 | 说明 |
|------|------|
| `search` | 搜索反馈，支持关键词、条件过滤、自动聚类 |
| `distribute` | 按字段统计分布，`--size` 控制返回条数（版本、平台等） |
| `trend` | 时间序列反馈量（PV/UV） |
| `alarm_data` | 查询告警数据 |
| `keyword_list` | 热词分布 |
| `generate_url` | 生成 iFeedback 页面链接 |
| `search_by_url` | 按 iFeedback URL 搜索反馈数据 |
| `parse_url` | 解析 iFeedback URL 为查询参数（反查 app_name） |
| `sample` | 采样原始记录（含全部字段），发现 schema |
| `fields` | 批量检查字段是否有数据 |

各命令完整参数见 [references/api_reference.md](references/api_reference.md)。

---

## 分析工作流

**重要：不要猜测字段值——先发现数据 schema。**

### 第 1 步：Schema 发现（必须先做）

不同应用填充的字段不同。过滤前先检查哪些字段有数据：

```bash
# 方式 A：批量检查
python3 scripts/ifeedback_api.py fields \
  --app_name <app> --start_time "..." --end_time "..." \
  --keys "version,platform,feedback_type,_rule_tag,model,os_version"

# 方式 B：采样原始记录
python3 scripts/ifeedback_api.py sample \
  --app_name <app> --start_time "..." --end_time "..." --size 3
```

**决策规则：**
- 字段返回 `"status": "empty"` → 不要在 conditions 中使用，改用关键词
- **Bug 过滤**：优先用标签字段（`_rule_tag`、`feedback_type`）预过滤，但始终结合 bug 关键词提升精度（标签召回高但精度低）
- **平台过滤**：有些应用用 `platform`，有些在 `version` 前缀编码平台（`0x28`=Android，`0x18`=iOS），先检查再判断

### 第 2 步：基线对比

1. 用**相同参数**查询目标和基线
2. 先按总量**归一化**（万分比 PV 率）再比较绝对数字
3. 用 `keyword_list --vip_keywords` 锁定关键词，确保度量口径一致

### 第 3 步：深入分析

1. `search` + 组合关键词找具体模式（>500 条自动聚类）
2. `keyword_list` 识别热点主题
3. `trend` 验证问题是增长还是稳定
4. 找出目标独有的、基线中没有的模式

---

## 易错提醒

- **没有 `--topk` 参数**。控制返回条数的参数名因命令而异：`distribute` 用 `--size`，`fields` 用 `--top`，`keyword_list` 用 `--size`。不要猜测参数名
- **keyword_list 没有 `--keywords` 参数**。要查特定词的反馈量，用 `--vip_keywords '["闪退","崩溃"]'`（JSON 数组格式）
- **distribute 没有 `--keywords` 参数**。只能通过 `--conditions` 过滤
- **alarm_data 没有 `--conditions`、`--keywords` 参数**
- **search_by_url / parse_url 不需要 `--app_name`、`--start_time`、`--end_time`**（从 URL 解析）
- **search 聚类行为**：当结果总数 > 500 时自动聚类，返回 `clusters` 字段，此时 `feedbacks` 为空——分析应使用 `clusters`
- **用户不知道 app_name 时**：提醒用户发送 iFeedback 页面链接，用 `parse_url` 反查

---

## 关键约定

- **时间格式**：`yyyy-MM-dd HH:mm:ss`
- **关键词语法**（仅 `search`、`trend`、`generate_url` 支持）：
  - 逗号 `,` = AND，空格 ` ` = OR
  - `"朋友圈,闪退 视频号,卡顿"` = (朋友圈 AND 闪退) OR (视频号 AND 卡顿)
- **cut_word**：`"1"`(默认)=关闭分词，wildcard 匹配，召回高但性能差；`"0"`=开启分词，精度高性能好但召回低
- **conditions**：`[{"key":"<字段>","relation":"<操作>","value":"<值>"}]`，操作符：等于、不等于、大于、小于、包含、不包含、为空、不为空
- **JSON 数组参数**（`conditions`、`return_fields`、`vip_keywords`）：作为 JSON 字符串传入

## Bug/故障关键词参考

| 分类 | 关键词 |
|------|--------|
| 闪退 | 闪退, 崩溃, crash, 闪回 |
| 卡顿/冻结 | 卡死, 卡顿, 无响应, 死机, 假死 |
| 显示异常 | 黑屏, 白屏, 花屏, 闪屏, 闪烁 |
| 功能异常 | 打不开, 进不去, 加载失败, 无法打开, 无法使用 |
| 数据问题 | 丢失, 损坏, 异常, 消失, 错乱 |
| 网络问题 | 断网, 连不上, 超时, 加载慢, 无法连接 |

## 参考文档

完整 API 参数、响应格式、条件语法见 [references/api_reference.md](references/api_reference.md)。
