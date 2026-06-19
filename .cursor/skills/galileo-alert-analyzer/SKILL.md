---
name: galileo-alert-analyzer
description: 分析伽利略（Galileo）监控告警图片或文本，定位告警根本原因和代码位置。当用户上传伽利略告警截图、告警卡片图片，或提供伽利略告警相关信息时触发。触发关键词：伽利略告警、Galileo告警、告警定位、告警根因、告警分析、排查告警。
---

# 伽利略告警分析定位

## 工作流程

### 步骤 1：读取告警信息

**如果用户提供图片**：
- 使用 Read 工具读取图片，识别并提取告警内容

**告警卡片的标准格式**（企业微信推送）：
```
[异常/正常]【告警级别】<告警描述>
告警数据时间: YYYY-MM-DD HH:MM:SS
平台: iOS / Android
服务: camp-app
物理环境: Production / Test

tags.<维度字段>: <维度值>          ← 触发告警的具体维度（如 imageUrl、api、errorCode）
<指标名>-<campType>(SUM/AVG): <当前值>（最大阈值: <阈值>）
开始时间: YYYY-MM-DD HH:MM:SS
已持续 X 分钟

定位分析
按照 [<指标名>-<campType>] 排序, TOP N 的 [tags.<维度>]:
| tags.<维度> | <指标名>-<campType> |
| <具体值>    | <数值>              |
```

**从卡片提取的关键字段**：
- **告警级别**：标题中的`【核心业务】`/`【基础指标】`等，对应 P0/P1
- **告警性质**：`[异常]` = 问题告警，`[正常]` = 恢复通知
- **指标名**：如 `大图加载`、`登录`、`支付`（对应代码中的 moduleName）
- **campType**：`-start`/`-step`/`-end` 后缀（如 `大图加载-start`）
- **聚合方式**：`SUM`（总量）/ `AVG`（均值）
- **触发维度**：`tags.imageUrl`、`tags.api`、`tags.errorCode` 等，是告警的精确定位线索
- **TOP N 分析**：卡片底部已附带按维度排序的 TOP N，直接揭示问题的具体对象

**如果用户提供文本**：
- 直接分析文本，提取上述字段

### 步骤 2：判断告警类型

根据告警描述文字快速分类：

| 告警描述关键词 | 告警类型 | 初步方向 |
|------------|---------|---------|
| `X小时大于N次` / `超频` | **超频告警** | 某图片/接口被重复调用，检查调用逻辑是否有循环或重复触发 |
| `量级跌幅` / `骤降` / `下跌X%` | **Start 量级骤降** | 功能入口不可用，版本更新导致代码未触达 |
| 错误类指标 `涨幅` / `骤增` | **错误量激增** | 新增异常路径触发，某错误码大量出现 |
| `转化率` / `Start->Step` | **转化率下跌** | 中间步骤失败，接口报错，逻辑判断分支问题 |
| `成功率` / `End` 跌幅 | **End 成功率跌幅** | 最终业务结果失败率升高，后端返回错误 |
| 量级为 `0` | **量级归零** | 代码未触达/上报逻辑被删除/功能完全不可用 |

**优先利用卡片中的 TOP N 分析**：如果告警卡片已经包含 `tags.*` 维度的 TOP N 列表，直接以此为线索开始排查——TOP N 中的 `imageUrl`、`api` 路径、`errorCode` 等就是问题的直接指向。

### 步骤 3：在代码库中定位埋点

根据 `moduleName` 和 `campType` 在代码库中搜索对应的上报代码：

**Flutter 端搜索**：
```bash
# 搜索模块名的上报调用
rg "moduleName.*<模块名>" flutter_module/lib --type dart -l
rg "reportMetricInfoLog.*<模块名>" flutter_module/lib --type dart
rg "<模块名>.*start\|<模块名>.*end\|<模块名>.*step" flutter_module/lib --type dart -i
```

**iOS 端搜索**：
```bash
# 搜索 metricLog 调用
rg "metricLog.*<模块名>\|<模块名>.*metricLog" social-ios/src --include="*.m" --include="*.mm" --include="*.swift" -i
rg "<模块名>" social-ios/src --include="*.m" --include="*.mm" --include="*.swift" -l
```

**按漏斗阶段过滤**：
- start → 搜索 `OTMetricLogTypeStart` / `MetricLogTypeStart` / `campType.*start`
- step → 搜索 `OTMetricLogTypeStep` / `MetricLogTypeStep` / `campType.*step`
- end → 搜索 `OTMetricLogTypeEnd` / `MetricLogTypeEnd` / `campType.*end`

### 步骤 4：分析 git 历史，关联近期变更

定位到上报代码文件后，查看最近的变更：

```bash
# 查看文件最近提交记录（告警时间前后）
git -C <项目路径> log --since="7 days ago" --pretty=format:"%h|%an|%ad|%s" -- <文件路径>

# 查看涉及该模块的所有最近变更
git -C <项目路径> log --since="7 days ago" -S"<模块名>" --pretty=format:"%h|%an|%ad|%s"

# 查看具体 diff
git -C <项目路径> show <commit_hash>
```

### 步骤 5：结合告警类型推断根因，并联动 code-locator 定位业务代码

**超频告警**（如 `大图加载1小时大于100次`）→ 重点关注：
- TOP N 中的 `tags.imageUrl` 就是频繁被加载的具体图片，确认这张图片属于哪个页面/业务
- 是否存在页面反复刷新、列表无限滚动、定时器重复触发的逻辑
- 图片加载代码是否在生命周期内被多次调用（如 viewWillAppear 每次都触发）
- 是否有内存缓存失效导致每次都重新下载

**量级骤降** → 重点关注：
- 上报代码是否被删除或注释
- 入口条件判断是否变更（如灰度开关、权限判断）
- 是否有新增 early return 导致代码未触达

**错误量激增** → 重点关注：
- status 字段的具体错误码含义
- 对应 API 接口返回值变化
- 错误处理逻辑是否有变更

**转化率下跌** → 重点关注：
- Start 与 Step/End 之间的业务逻辑
- 某个中间步骤的成功率
- 接口调用链路（通过 subModuleName 的 API 路径定位）

**End 成功率跌幅** → 重点关注：
- End 上报时的 status 判断逻辑
- 后端接口返回码变化
- 业务流程最终结果的判断条件

### 步骤 5.5：用 code-locator 定位涉事业务代码（必须执行）

在推断出根因方向后，**必须**调用 `camp/code-locator` 技能，定位与告警 `moduleName` 直接相关的**业务逻辑代码**（不只是埋点上报代码）。

**操作方式**：读取 `~/.claude/skills/camp/code-locator/SKILL.md` 并按其流程执行，以告警的 `moduleName`、错误类型（如「图片加载失败」「接口超频」）为查询输入，找到核心业务实现文件和关键方法。

**定位目标**（按优先级）：
1. 触发上报的业务路径（如：图片下载失败 → `WEGImageLoader` 的实际下载逻辑）
2. 根因涉及的条件判断或 early return（如：灰度开关判断代码）
3. 与告警维度（`tags.imageUrl` / `tags.api` / `tags.errorCode`）直接相关的处理逻辑

从定位到的代码中提取：
- **文件路径 + 行号范围**
- **关键代码片段**（不超过 20 行，聚焦问题所在逻辑）
- **代码说明**：这段代码说明了什么，与告警的关系

### 步骤 6：输出分析报告

```
=== 伽利略告警分析报告 ===

告警信息:
  模块: [moduleName] / [subModuleName]
  阶段: [campType]
  告警类型: [量级波动/转化率/成功率]
  波动幅度: [X%]
  告警时间: [时间]

根因分析:
  可能原因1: [描述] - 置信度: [高/中/低]
  可能原因2: [描述] - 置信度: [高/中/低]

代码定位（埋点上报）:
  文件: [文件路径]:[行号]
  关键代码: [埋点相关代码片段]

代码定位（涉事业务逻辑）:
  文件: [文件路径]:[行号范围]
  关键代码:
    ```
    [业务逻辑关键代码片段，聚焦根因所在逻辑，≤20行]
    ```
  代码说明: [这段代码与告警的关系，如：此处 early return 导致 end 未触达]

近期变更关联:
  [commit hash] - [日期] - [作者]
  [提交信息]
  [变更说明]

建议排查步骤:
  1. [具体操作]
  2. [具体操作]
  3. [具体操作]
```

## 关键上报 API 速查

**Flutter 端**：
- `reportMetricInfoLogStart(moduleName, status, ...)` → Start 阶段
- `reportMetricInfoLogStep(moduleName, status, ...)` → Step 阶段
- `reportMetricInfoLogEnd(moduleName, status, ...)` → End 阶段
- `TaskSpan.campTypeBefore` → 前置上报（实时）

**iOS 端**：
- `[OTMonitor metricLog:type:OTMetricLogTypeStart ...]` → Start
- `[OTMonitor metricLog:type:OTMetricLogTypeStep ...]` → Step
- `[OTMonitor metricLog:type:OTMetricLogTypeEnd ...]` → End
- `OTTraceTypeBefore` → 前置上报（实时）

## 注意事项

- **status 状态码**：`0` = 成功，`-1` = 通用失败，其他负值查看业务定义
- **前置/后置上报**：`campTypeBefore`/`OTTraceTypeBefore` 为前置上报（实时），无采样率限制
- **subModuleName/groupName**：通常对应 API 路径或子功能，有助于精确定位
- **量级为 0**：先检查是否代码被删除，再检查入口条件
- 详细的漏斗模型和告警体系说明见 [references/alert-analysis.md](references/alert-analysis.md)
