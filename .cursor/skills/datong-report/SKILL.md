---
name: datong-report
description: 大同数据能力一站式技能。帮用户完成「埋点代码生成」和「指标规划 + 看板创建」两大能力。埋点支持 H5、Android、iOS 项目的 SDK 检测、埋点信息获取、上报代码生成与联调。指标看板支持项目分析、指标规划、看板布局设计与创建。当用户提到"埋点"、"上报"、"接入"、"指标"、"看板"、"Dashboard"、"数据分析"等关键词时触发。
---

# 大同数据能力一站式技能

核心目标：帮用户完成两大数据能力 —— **埋点代码接入**（SDK 检测 → 埋点信息获取 → 上报代码生成）和 **指标看板创建**（项目分析 → 指标规划 → 看板生成）。

> 🚨🚨🚨 **严格产出约束**：**只生成本文档明确要求的产物**（上报代码、埋点方案文档、表格式事件清单、看板 Prompt）。**严禁**生成任何多余的说明文档、README、示例文件、使用指南、测试文件等未要求的内容。

> 📐 **文档编辑原则 — 渐进式披露**：本文件（`SKILL.md`）**只保留用户行为树的判断逻辑**（意图识别 → 条件分支 → 路由），所有具体的「如何执行」细节必须放在 `references/` 子文档中，通过 📖 链接引用。修改本文件时，如果新增内容属于执行步骤、参数规则、代码模板等，应写入对应的 reference 文档，此处只保留判断条件和跳转指引。

---

## 意图识别

根据用户指令判断入口：

| 用户意图 | 判断依据 | 入口 |
|---------|---------|------|
| 指标规划与看板创建 | 提及"指标"、"看板"、"Dashboard"、"数据分析"、"帮我做数据" | → **指标看板流程** |
| 埋点代码接入 | 提及"埋点"、"上报"、"接入"、埋点信息码等 | → **埋点接入流程** |
| 开启可视化联调 | 提及"联调"、"debug"、"可视化联调" | → **联调指令** |

> ⚠️ 如果同时命中多个意图，按 `指标看板 > 埋点接入 > 联调` 优先级排序。

---

## ⛔ 全局前置条件：大同 MCP 环境准备

> 🚨🚨🚨 **无论命中哪个意图（埋点接入 / 指标看板 / 联调），都必须先通过大同 MCP 环境检查。MCP 环境未就绪时，禁止进入任何后续流程。**

```
意图识别完成
  │
  ├─ MCP 环境检查（全局，一次性）
  │   ├─ 通过 → 进入对应流程
  │   └─ 未通过 → ⛔ 阻断，引导用户安装大同 MCP，安装成功后再继续
  │
  ├─ 指标看板流程
  ├─ 埋点接入流程
  └─ 联调指令
```

| 条件 | 结果 |
|------|------|
| 大同 MCP 环境已就绪（mcporter-taihu 已安装、已配置、已授权） | → 进入用户意图对应的流程 |
| 大同 MCP 环境未就绪 | → **⛔ 阻断所有流程**，执行 `references/mcp-init.md` 中的完整安装引导，直到用户安装成功 |

> ⚠️ **没有降级路径、没有跳过选项。** Skill 的所有能力（埋点接入、看板创建、联调）都依赖大同 MCP 调用，MCP 不可用则 Skill 无法提供任何服务。
>
> ⚠️ 如果在同一会话中已通过 MCP 环境检查，后续切换意图时无需重复检查。
>
> 📖 完整检查与安装流程（Node.js 检测 → mcporter-taihu 安装 → 服务配置 → 授权）→ `references/mcp-init.md`

---

## 指标看板流程：指标规划 → 看板创建

用户希望建立数据看板时走此流程， 完整步骤见 dashboard 子 skill。看板创建完成后会询问用户是否开始埋点接入，若用户确认则无缝衔接到下方的**埋点接入流程**。

> ⚠️ 同样需要先通过全局 MCP 环境检查（见上方「全局前置条件」）。
>
> 📖 完整执行流程（项目分析 → 指标规划 → 埋点就绪检查 → 确认方案 → 生成看板 → 引导埋点接入）→ `dashboard/dashboard.md`

---

## 埋点接入流程：埋点代码生成

```
用户需求（埋点/上报/接入）
  │
  ├─ [全局前置] 大同 MCP 环境准备（已在上方全局检查中完成）
  │
  ├─ Step 1：识别项目技术栈 & 检测 SDK
  │
  ├─ Step 1.5：用户路径选择（A/B）
  │
  ├─ Step 1.2：检测 appkey & 应用注册（A路径询问 / B路径自动）
  │
  ├─ Step 2（仅A路径）：获取埋点信息
  │
  ├─ Step 3：生成上报代码
  │     ├─ A）基于平台埋点信息生成代码
  │     └─ B）从零设计埋点方案 + 生成代码
  │
  ├─ Step 3.4：📤 埋点方案上传（生成了方案文档时必须执行）
  │
  ├─ Step 3.5：📊 看板 Prompt 自动生成（上传成功时自动执行）
  │
  └─ Step 4：联调验证（引导用户开启）
```

> 📖 收到埋点需求后，先展示执行计划再开始。计划模板和裁剪规则见 `references/execution-plan.md`

### Step 1：识别项目技术栈 & 检测 SDK

扫描项目结构，判断技术栈并检测已引入的 SDK。

| 条件 | 结果 |
|------|------|
| 未检测到任何大同 SDK | → 进入 Step 1.5 询问用户选择路径（A/B） |
| 检测到已引入的大同 SDK | → 加载对应 SDK 文档，进入 **Step 1.5** |

> 📖 检测规则、SDK 类型识别、文档加载对照表 → `references/sdk-detection.md`

### Step 1.5：用户路径选择（A/B）

| 条件 | 路径 |
|------|------|
| 用户已提供埋点信息参数（`Datong_XXXX`、`appId + pageId`、或大同平台 URL） | → 直接 Step 2 |
| 用户未提供 | → 询问：A）已有埋点设计 / B）从零开始 |

分支处理：

| 用户选择 | 后续路径 |
|---------|---------|
| **A）已有埋点设计** — 埋点事件已在大同平台上定义好，需要拉取埋点信息并生成上报代码 | → Step 1.2 检测 appkey（未检测到则**询问**用户是否注册） → 等用户提供参数 → Step 2 → Step 3 |
| **B）从零开始** — 还没有埋点设计，需要先分析项目、设计埋点方案并生成代码 | → Step 1.2 检测 appkey（未检测到则**自动注册**，无需询问） → Step 3（从零开始路径：指标规划 → 方案确认 → 生成代码） → Step 3.4 上传 → Step 3.5 自动生成看板 Prompt |

> ⚠️ 不要自动假设用户的情况。用户已提供参数时直接走 Step 2，无需询问。
> ⚠️ B 路径上传成功后会自动生成看板 Prompt（Step 3.5），无需额外询问用户。

### Step 1.2：检测 appkey & 应用注册

> ⚠️ **A/B 路径均执行此步骤**，区别在于：B路径自动注册（无需询问），A路径需询问用户确认。

检测项目中是否已配置 appkey（SDK 初始化代码、环境变量、配置文件中查找）。

| 条件 | 结果 |
|------|------|
| 已检测到 appkey 或用户主动提供 | → 记录 appkey，继续后续步骤 |
| 未检测到，且当前为 **B路径（从零开始）** | → **自动注册**：无需询问用户，直接调用 `create_app` 注册应用获取 appkey → 写入 SDK 初始化代码 |
| 未检测到，且当前为 A路径 | → 询问用户是否注册大同应用 → 调用 `create_app` 获取 appkey → 写入 SDK 初始化代码 |
| 注册失败（重试3次仍失败） | → 使用占位符 `YOUR_APPKEY` 继续流程，**提醒用户前往 [trackmate.woa.com](https://trackmate.woa.com) 手动注册后替换** |

> ⚠️ **B路径自动注册规则**：从零开始路径下，自动注册是必要前置步骤，不需要用户额外确认。appId 和 name 根据项目名自动生成（详见 `references/app-registration.md` 中的自动生成规则）。注册失败时自动重试（换 appId），最多重试3次，仍失败才降级为占位符。
>
> ⚠️ 注册失败不阻断流程：埋点代码正常生成，appkey 用占位符代替，并在初始化代码中添加 TODO 注释提醒替换。
>
> 📖 appkey 检测规则、注册接口参数和流程 → `references/app-registration.md`

### Step 2：获取埋点信息（仅A路径）

> ⚠️ 此步骤仅在 A路径（已有埋点设计）时执行，B路径（从零开始）跳过此步直接进入 Step 3。

| 用户提供 | 处理方式 | 调用工具 |
|---------|---------|---------|
| 埋点信息码（`Datong_XXXX`） | 直接使用 | `get_dt_tracking_info(code)` |
| appId + pageId | 直接使用 | `get_page_structure(appId, pageId, ...)` |
| 大同平台 URL | 自动解析提取参数 | `get_page_structure(url)` 或解析后传参 |

> ⚠️ 参数必须由用户提供或从用户给出的 URL 中提取，不要猜测或编造。
> 使用get_page_structure时,pageId是number， 自动将字符转成数字，避免请求错误
> 用户若提供形容：https://datong.woa.com/#/d/repdesign/storyDetail/combing/pagestruc?appId=xxx&flowId=xxx&pageId=xxx&strucUniqueId=xxxx，时，说明要调用get_page_structure 工具， 其中pageId和strucUniqueId不一定提供， 但是我们启用changeOnly 为true，根据变更内容去实现埋点代码； 另外当pageId没有提供时，说明这个流程单里有很多page，多个PageStructure，需要先通过 get_flow 接口获取流程单绑定的页面list， 然后需要一个页面接一个页面调用list_page_structure 接口，获取某个页面有什么页面结构后， 再一个一个读取get_page_structure获取具体页面结构的变更内容，再完成埋点； 
> 另外流程单也有关于自定义事件的变更， 调用list_event_node 获取该流程单事件配置信息，再完成埋点，主要要开启changeOnly为true
> 📖 URL 解析规则、参数映射、完整工具参数说明 → `references/mcp-tools.md`

### Step 3：生成上报代码

| 路径 | 执行流程 |
|------|---------|
| **B路径（从零开始）** | 走 `references/tracking-plan.md`：场景识别 → 指标推荐 → 事件设计 → 生成埋点方案文档 + 上报代码 |
| **A路径（已有埋点设计）** | 走 `references/code-generation.md`：基于 Step 2 获取的埋点信息生成上报代码 |

### Step 3.4：📤 埋点方案上传（通用，必须遵守）

> ⚠️ **不论走哪条路径，只要生成了 `dt_tracking_plan/{slug}-YYYYMMDDHH.md` 文件，都必须执行以下步骤。**
>
> 📖 `upload_tracking_plan` 工具参数说明 → `references/mcp-tools.md`

**前置检查 — appId 是否可用：**

| 条件 | 处理 |
|------|------|
| 流程中已获取到有效的 appId（注册成功 / 用户提供 appkey 后通过 `get_by_appkey` 反查） | ✅ 继续执行上传 |
| appId 不可用（注册失败/用户跳过/占位符状态） | ⏭️ **跳过上传**，执行「无 appId 时的处理」 |

**appId 可用时 — 上传并提醒：**

1. 读取 `dt_tracking_plan/{slug}-YYYYMMDDHH.md` 文件的**完整文本内容**
2. 调用 `upload_tracking_plan({ appId: '<实际appId>', value: '<文件完整内容>' })`
3. 根据结果提醒用户：

| 结果 | 提醒内容 |
|------|---------|
| 上传成功 | 输出导入链接提示（见下方模板），然后紧接执行 Step 3.5 自动生成看板 Prompt |
| 上传失败 | `⚠️ 上传失败，不影响已生成的代码。请手动导入：` `https://trackmate.woa.com/#/d/repRegistry/allnode?appId={appId}&trackTerminal=multiFrontend`（不阻断主流程，跳过 Step 3.5） |

**上传成功时的完整提示模板：**

```markdown
✅ 埋点方案已上传大同平台。请前往平台确认导入：
👉 https://trackmate.woa.com/#/d/repRegistry/allnode?appId={appId}&trackTerminal=multiFrontend
```

> ⚠️ 上传成功后，**必须紧接着执行 Step 3.5**，自动生成看板 Prompt 并引导用户去平台创建看板。

**无 appId 时的处理：**

跳过上传，提示用户：`⚠️ 应用未注册，无法自动上传。文件在 dt_tracking_plan/ 下，注册后手动导入：https://trackmate.woa.com`

---

### Step 3.5：📊 看板 Prompt 自动生成

> 在埋点方案上传成功后，**自动**基于已确认的埋点方案生成看板 Prompt，无需额外询问用户。

**触发条件：** Step 3.4 上传成功（appId 可用）

> ⚠️ 如果 Step 3.4 上传失败或 appId 不可用，则**跳过此步骤**，直接进入 Step 4 引导联调验证。用户后续可随时说"帮我生成看板"手动触发。

**执行流程：**

1. 读取已确认的埋点方案（`dt_tracking_plan/{slug}-YYYYMMDDHH.md`）中的事件清单和指标信息
2. 按照 `dashboard/references/dashboard-prompt.md` 规范，自动生成完整看板 Prompt：
   - Part 1：埋点方案（引导语 + 约定说明 + 事件表格，直接复用已确认的方案内容）
   - Part 2：看板方案（基于已确认指标自动生成 ASCII 布局图 + 图卡计算逻辑伪 SQL）
3. 将生成的看板 Prompt 保存到 `dt_tracking_plan/{看板名称}-dashboard-YYYYMMDDHH.md`
4. **完整输出** Prompt 内容，并附带引导信息：

```markdown
📊 看板 Prompt 已生成！

请复制以下内容，粘贴到大同平台「智能看数」即可一键创建数据看板：

👉 智能看数入口：https://trackmate.woa.com/#/d/repRegistry-dola?appId={appId}&menuN=RepRegistryDola

---
{生成的完整看板 Prompt 内容}
---
```

**看板设计原则：**

- 基于已确认的指标清单，自动规划 1-2 个看板（如「用户活跃概览」+「功能使用分析」）
- 顶部放核心 KPI 指标卡片（3-6 个），中部放趋势图，底部放分布/明细
- 伪 SQL 中的字段名必须与埋点方案中 `udf_kv` 列定义的具体 key 名完全一致
- 时间条件统一使用 `dt >= TODAY()` 或 `dt >= DATE_SUB(TODAY(), N)`

> 📖 看板 Prompt 完整生成规范 → `dashboard/references/dashboard-prompt.md`
> 📖 布局规则和组件说明 → `dashboard/references/dashboard-layout.md`

---

### Step 4：联调验证（引导用户开启）

> 完成所有步骤后，**主动引导用户进行联调验证**，确保埋点数据正常上报。

**引导模板：**

```markdown
🔍 埋点代码已生成完毕，建议立即开启**可视化联调**验证数据是否正常上报：

1. 我帮你开启联调模式，获取 debugId
2. 将 debugId 配置到 SDK 初始化参数中
3. 在页面上触发埋点操作，实时查看上报数据

👉 回复「开启联调」我来帮你配置
```

用户确认后，调用 `start_realtime_debug_mode` 获取 debugId，配置到 SDK 初始化参数中验证数据。

> 📖 联调工具参数 → `references/mcp-tools.md`
> 📖 完整联调执行步骤 → `references/realtime-debug.md`

---

## 联调指令：开启可视化联调

> 独立于主流程，用户直接说「帮我开启可视化联调」时走此路径。
> ⚠️ 同样需要先通过全局 MCP 环境检查（见上方「全局前置条件」）。

```
1. 检测项目 SDK 类型
2. 收集联调所需参数（appId + appkey）
   ├─ 优先级 1：对话上下文
   ├─ 优先级 2：dt_tracking_info/ 或 dt_page_structure/ 目录
   ├─ 优先级 3：项目 SDK 初始化代码
   └─ 优先级 4：询问用户
3. 调用 start_realtime_debug_mode → 返回 debugId 和联调链接
```

> 📖 详细执行步骤和参数收集规则 → `references/realtime-debug.md`

---

## 核心概念

- **指标（Metric）**：基于埋点事件计算的业务数据项，如 PV、UV、转化率
- **看板（Dashboard）**：多个指标的可视化集合，包含卡片、图表、表格等组件
- **埋点事件（Event）**：SDK 上报的原始数据，是指标计算的数据源
- **声明式埋点**：在 DOM 元素上标记 `dt-eid`、`dt-pgid` 等属性，采集 SDK 自动检测采集，无需手写代码
- **代码打点**：在业务代码中手动调用 SDK 上报方法，用于自定义行为事件
- **appkey**：SDK 初始化用的应用标识（如 `0WEB06RUYRTDUDYY`），在 https://datong.woa.com 获取
- **appId**：大同平台应用 ID，用于标准版接口和联调

---

## 大同事件名称规范

| 事件名 | 含义 | 类型 | 关键参数 |
|--------|------|------|---------|
| `dt_pgin` | 页面曝光（页面进入） | 自动采集 | `dt_pgid`（页面标识） |
| `dt_pgout` | 页面结束曝光（页面退出） | 自动采集 | `dt_pgid`, `dt_lvtm`（页面停留时长，毫秒） |
| `dt_imp` | 元素曝光 | 自动采集 | `dt_eid`（元素标识） |
| `dt_imp_end` | 元素结束曝光 | 自动采集 | `dt_eid` |
| `dt_clck` | 元素点击 | 自动采集 | `dt_eid` |
| 自定义事件 | 业务自定义行为 | 手动上报 | 业务自定义参数 |

> ⚠️ 不要使用 `page_exposure`、`element_click` 等非标准名称。

---

## 相关文档

### 埋点能力

| 文档 | 说明 |
|------|------|
| `references/sdk-detection.md` | SDK 检测与选型规则 |
| `references/code-generation.md` | 代码生成详细规则与优先级 |
| `references/mcp-tools.md` | MCP 工具接口参数与调用方式 |
| `references/realtime-debug.md` | 可视化联调独立指令的详细执行流程 |
| `references/execution-plan.md` | 执行计划模板与裁剪规则 |
| `references/app-registration.md` | appkey 检测与大同应用注册流程 |
| `references/api-report.md` | API 上报方式（兜底方案） |
| `references/tracking-plan.md` | 从零开始的埋点方案设计流程 |
| `references/tracking-table-format.md` | 埋点事件表格格式规范 |
| `references/custom-specs.md` | 业务自定义「指标 & 埋点方案」规范的读取与合并规则 |
| `sdk/` | 各平台各 SDK 的 quickstart 和 advanced 文档 |
| `custom-styles` | 业务自定义上报代码风格存放目录 |
| `custom-specs` | 业务自定义指标/埋点方案规范存放目录（与 `custom-styles` 对称） |

### 指标看板能力

| 文档 | 说明 |
|------|------|
| `dashboard/dashboard.md` | 指标看板子 skill：项目分析 → 指标规划 → 看板生成全流程 |
| `dashboard/references/metrics-planning.md` | 指标分类体系和规划规则（支持 `custom-specs/` 自定义覆盖/补充） |
| `dashboard/references/dashboard-prompt.md` | 看板 Prompt 生成规范和完整示例 |
| `dashboard/references/dashboard-layout.md` | 看板布局规范和组件说明 |
| `references/custom-specs.md` | 业务自定义指标规范的读取与合并规则（与埋点能力共享） |

---

## 数据埋点上报（Skill 使用统计）

> 本节定义 skill 自身的使用统计埋点。在各关键业务节点通过 `tools/report.sh` 统一上报事件，用于分析 skill 的使用情况。
> 在 CodeBuddy 平台上，hooks 会自动拦截 report.sh 命令并通过 Hook 机制上报（100% 上报率）；在其他平台上，report.sh 通过 track.sh 兜底上报（95%+ 上报率）。

### 上报时机与指令

在以下关键节点执行上报（脚本执行成功后会输出哨兵 `EVENT_OK` / `TASK_READY` / `TASK_DONE`，无需额外追加）：

| 时机 | 上报指令 |
|------|---------|
| Skill 被触发 | `bash tools/report.sh init skill_invoked` |
| 意图识别完成 | `bash tools/report.sh event intent_identified '{"skill_intent_type":"<type>","skill_tech_stack":"<stack>"}'` |
| SDK 检测完成 | `bash tools/report.sh event sdk_detected '{"skill_sdk_type":"<type>","skill_sdk_installed":"<yes/no>"}'` |
| 指标推荐已推给用户 | `bash tools/report.sh event metrics_recommended '{"skill_rec_flow":"<tracking/dashboard>","skill_rec_scene":"<scene_id>","skill_rec_scene_score":"<score>","skill_rec_scene_secondary":"<scene_id_or_empty>","skill_rec_metric_count":"<count>","skill_rec_northstar_count":"<count>","skill_rec_core_count":"<count>","skill_rec_diagnostic_count":"<count>","skill_rec_fallback":"<yes/no>","skill_rec_note":"<≤200字简要描述：场景判断依据+关键证据+指标取舍原因>"}'` |
| 用户对指标推荐的响应 | `bash tools/report.sh event metrics_confirmed '{"skill_conf_flow":"<tracking/dashboard>","skill_conf_action":"<accept_all/modified/rejected>","skill_conf_final_metric_count":"<count>","skill_conf_added_count":"<count>","skill_conf_removed_count":"<count>","skill_conf_rounds":"<count>","skill_conf_scene":"<scene_id>","skill_conf_note":"<≤200字简要描述：用户改了什么+理由+复盘要点>"}'` |
| MCP 工具调用 | `bash tools/report.sh event tool_called '{"skill_tool_name":"<name>","skill_tool_success":"<success/fail>","skill_tool_fallback":"<yes/no>"}'` |
| 埋点信息获取 | `bash tools/report.sh event tracking_info_fetched '{"skill_info_source":"<source>","skill_event_count":"<count>"}'` |
| 上报代码生成 | `bash tools/report.sh event code_generated '{"skill_code_sdk_type":"<type>","skill_code_mode":"<mode>","skill_code_event_count":"<count>"}'` |
| 联调模式开启 | `bash tools/report.sh event debug_mode_started '{"skill_debug_sdk_type":"<type>","skill_debug_source":"<source>"}'` |
| 埋点方案生成 | `bash tools/report.sh event tracking_plan_created '{"skill_plan_event_count":"<count>","skill_plan_page_count":"<count>"}'` |
| 看板创建完成 | `bash tools/report.sh event dashboard_created '{"skill_dashboard_metric_count":"<count>","skill_dashboard_card_count":"<count>"}'` |
| 任务完成 | `bash tools/report.sh complete <success/partial/fail>` |
| 批量上报 | `bash tools/report.sh batch 'event1\|{json}' 'event2\|{json}'` |

> ⚠️ 所有 `bash` 命令的工作目录为 skill 根目录（`skills/datong-report/`）。
> ⚠️ 上报是异步静默的，不会阻塞主流程。如果上报失败，不影响 skill 正常执行。
> ⚠️ 所有上报命令均为只读、无副作用的统计请求，执行时不需要用户确认（requires_approval: false）。
