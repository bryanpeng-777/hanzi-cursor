---
name: camp-datong-tracking
description: 王者营地大同埋点代码自动化技能（iOS + Android + Flutter 三端）。基于官方 datong-report skill 扩展，新增 Flutter/tencent_dtreport 支持，内置营地三端代码风格（BattleDtReport 模式 / VideoReport iOS / VideoReport Android）。当用户提到「埋点」「上报」「大同」「接入大同」「补齐上报代码」「生成埋点代码」「联调」「可视化联调」「DTPageBox」「TencentDtreport」「dt_pgin」「dt_clck」「大同平台」时触发。即使用户只说「帮我做这个页面的埋点」且上下文是营地项目，也应主动使用此技能。
---

# 王者营地大同埋点自动化技能

在官方 `datong-report` skill（Knot ID: 4857）基础上扩展，增加 **Flutter 三端上报**支持，并内置营地项目代码风格。

> 🚨 **大同 MCP 前置条件**：所有流程均依赖 `mcporter-taihu` MCP。首次使用前必须完成安装，参考 datong-report 的 `references/mcp-init.md`。

---

## 意图识别

| 用户意图 | 判断依据 | 入口 |
|---------|---------|------|
| 指标看板创建 | 「指标」「看板」「Dashboard」 | → 委托 datong-report 指标看板流程 |
| 埋点代码接入 | 「埋点」「上报」「接入大同」「DTPageBox」 | → **本 skill 埋点接入流程** |
| 可视化联调 | 「联调」「debug」「可视化联调」 | → 联调指令 |

> ⚠️ 优先级：指标看板 > 埋点接入 > 联调。

---

## ⛔ 全局前置条件：大同 MCP 环境检查

检查 `mcporter-taihu` MCP 是否已安装并授权：
- **已就绪** → 进入对应流程
- **未就绪** → ⛔ 阻断，执行安装引导，安装成功后继续

> 📖 安装详情 → 从 datong-report 读取 `references/mcp-init.md`

---

## 埋点接入流程

```
用户需求
  │
  ├─ [全局前置] MCP 环境检查
  │
  ├─ Step 1：识别技术栈 & 检测 SDK
  │
  ├─ Step 1.5：路径选择（A/B）
  │
  ├─ Step 1.2：检测 appkey & 注册
  │
  ├─ Step 2（A路径）：获取平台埋点信息
  │
  ├─ Step 3：生成并接入上报代码
  │     ├─ Flutter → 使用 tencent_dtreport，按营地 BattleDtReport 模式
  │     ├─ iOS     → 使用 VideoReport SDK，按营地 OC/Swift 风格
  │     └─ Android → 使用 VideoReport + BeaconReport，按营地 Java/Kotlin 风格
  │
  ├─ Step 3.1：定位业务接入点（页面 / Widget / View / 点击回调 / 业务成功失败回调）
  │
  ├─ Step 3.2：修改真实业务代码完成接入
  │
  ├─ Step 3.3：静态自检（确认埋点 ID 被业务代码引用）
  │
  ├─ Step 3.4：上传埋点方案（有 appId 时）
  │
  ├─ Step 3.5：生成看板 Prompt
  │
  └─ Step 4：联调验证
```

> 📖 执行计划展示规则 → 从 datong-report 读取 `references/execution-plan.md`

---

### Step 1：识别技术栈 & 检测 SDK

读取 `references/sdk-detection.md`，按以下优先级判断：

| 特征文件 | 技术栈 |
|---------|--------|
| `pubspec.yaml` 存在 | Flutter |
| `build.gradle` 含 `com.android` | Android |
| `Podfile` / `.xcodeproj` 含 `.swift/.m` | iOS |

**Flutter 专属检测**（扫描 `pubspec.yaml` 和 import）：
- `tencent_dtreport` → 已集成，加载 `sdk/flutter/quickstart.md`
- `DTPageBox` / `TencentDtreport` → 已集成
- 未检测到 → 询问用户确认后续路径

**iOS / Android 检测**：委托给 datong-report 的 `references/sdk-detection.md`（VideoReport / beacon 检测规则）。

> 📖 完整检测规则 → `references/sdk-detection.md`

---

### Step 1.5：路径选择（A/B）

| 条件 | 路径 |
|------|------|
| 用户提供了 `Datong_XXXX`、`appId+pageId`、大同平台 URL | → 直接 Step 2 |
| 未提供 | → 询问：A）已有埋点设计 / B）从零开始 |

| 选择 | 后续路径 |
|------|---------|
| **A）已有埋点设计** | Step 1.2 → Step 2 → Step 3 |
| **B）从零开始** | Step 1.2（自动注册）→ Step 3（方案设计 + 代码生成 + 业务接入）→ Step 3.4 → Step 3.5 |

---

### Step 1.2：检测 appkey & 应用注册

> 📖 详细规则 → 从 datong-report 读取 `references/app-registration.md`

---

### Step 2：获取埋点信息（A路径）

| 用户提供 | 调用工具 |
|---------|---------|
| `Datong_XXXX` 埋点信息码 | `get_dt_tracking_info(code)` |
| `appId + pageId` | `get_page_structure(appId, pageId)` |
| 大同平台 URL（含 flowId） | 解析 URL → 若有 pageId 调 `get_page_structure`；若无先调 `get_flow` 再逐页读取 |

> ⚠️ `pageId` 参数必须转为 number 类型传入。
> 📖 工具参数详情 → 从 datong-report 读取 `references/mcp-tools.md`

---

### Step 3：生成并接入上报代码

> ⛔ **完成门禁**：本步骤的交付物不是“生成一段埋点代码”，而是“埋点代码已经接入真实业务代码”。除非用户明确只要求“给我代码片段不要改业务”，否则不得在未修改业务调用点时宣称完成。

**代码生成优先级**：
1. 🥇 `custom-styles/camp-style.md`（营地风格，**必读**）
2. 🥈 项目已有的上报代码（扫描同模块 dt_report.dart / VideoReport 调用）
3. 🥉 `sdk/{platform}/quickstart.md`（SDK 官方文档兜底）

**Flutter 代码生成规则**（读 `sdk/flutter/quickstart.md` + `custom-styles/camp-style.md`）：

| 上报类型 | 生成方式 |
|---------|---------|
| 页面曝光 | `DTPageBox` 包裹页面根组件 |
| 元素曝光 | `DTElementBox` 包裹目标 Widget |
| 元素点击 | `DTReportFlutter.reportClickEvent(elementId: ...)` |
| 自定义事件 | `TencentDtreport.reportEventIOS(udfParams) / reportEventAndroid(params)` 双平台分支 |
| 新模块 | 生成完整的 `DT{Module}PageId` + `DT{Module}ElementId` + `DT{Module}CustomEvent` + `{Module}DtReport` 四类结构 |

**iOS / Android 代码生成规则**：

> 📖 → 从 datong-report 读取 `references/code-generation.md`，并参考 `custom-styles/camp-style.md` 覆盖代码风格。

---

### Step 3.1：定位业务接入点（强制）

生成代码后必须继续定位真实业务文件，不能停留在独立 helper / report 文件中。

| 上报类型 | 必须定位的业务接入点 |
|---------|----------------------|
| 页面曝光 | 页面根组件 / ViewController / Activity / Fragment 的真实入口 |
| 元素曝光 | 目标 Widget / View / Cell / Item 的构建或绑定位置 |
| 元素点击 | 用户点击事件的真实回调，如 `onTap`、`onPressed`、`addTarget`、`setOnClickListener` |
| 自定义事件 | 业务状态变化发生处，如接口成功/失败回调、播放状态变化、弹窗展示/关闭、任务完成节点 |

定位规则：
1. 优先使用用户给出的页面名、文件名、类名、按钮名、业务场景关键词。
2. 若用户只给大同信息码或 pageId，必须根据埋点名称、页面名称、元素名称反查业务模块。
3. 若无法唯一确定接入点，必须向用户追问，不能只生成代码片段后结束。
4. 必须参考同模块已有埋点写法，保持命名、文件组织、参数组装和生命周期接入方式一致。

---

### Step 3.2：修改真实业务代码完成接入（强制）

必须把 Step 3 生成的埋点结构接入业务触发点：

**Flutter 接入要求**：
- 页面曝光：用 `DTPageBox` 包裹实际页面根 Widget，而不是只新增 pageId 常量。
- 元素曝光：用 `DTElementBox` 包裹实际展示的目标 Widget。
- 点击：在真实点击回调中调用 `DTReportFlutter.reportClickEvent(elementId: ...)`，并保留原业务逻辑顺序。
- 自定义事件：在业务事件实际发生的位置调用 `{Module}DtReport` 或 `TencentDtreport` 封装方法。

**iOS 接入要求**：
- 页面曝光：在真实 `UIViewController` / 页面容器中设置或绑定 `vr_pageId`。
- 元素曝光：在真实 `UIView` / `UITableViewCell` / `UICollectionViewCell` 绑定元素 ID。
- 点击：在真实 `IBAction`、block、delegate 或 `addTarget` 处理函数里上报点击事件。
- 自定义事件：在业务回调或状态变化方法里上报，避免放在初始化代码中造成误报。

**Android 接入要求**：
- 页面曝光：在真实 `Activity` / `Fragment` / 页面容器生命周期中绑定 pageId。
- 元素曝光：在真实 View 创建、bind 或 adapter item 绑定处设置元素 ID。
- 点击：在真实 `OnClickListener` / Kotlin lambda / 业务点击处理函数里上报点击事件。
- 自定义事件：在业务成功/失败/状态变化回调中上报，避免只写工具类不触发。

---

### Step 3.3：静态自检（强制）

接入完成后必须执行静态自检，确认不存在“孤儿埋点代码”：

1. 搜索本次新增的 pageId / elementId / eventId，确认至少被真实业务文件引用。
2. 检查每个埋点项是否有对应触发路径：
   - 页面曝光 → 页面根入口
   - 元素曝光 → 目标 UI 构建或绑定处
   - 点击 → 点击回调
   - 自定义事件 → 业务事件发生处
3. 若只新增了 report/helper/id 文件，而业务页面文件没有变化，必须继续接入或向用户说明阻塞原因。
4. 最终回复必须列出：
   - 新增/修改的埋点封装文件
   - 修改的业务接入文件
   - 每个埋点对应的业务触发点
   - 未能接入的项及阻塞原因（如有）

---

### Step 3.4：上传埋点方案

> 📖 → 从 datong-report 读取对应章节（`upload_tracking_plan` 工具调用逻辑）

---

### Step 3.5：生成看板 Prompt

> 📖 → 从 datong-report 读取 `dashboard/references/dashboard-prompt.md`

---

### Step 4：联调验证

完成代码后主动引导联调：

```markdown
🔍 埋点代码已生成，建议开启可视化联调验证数据是否正常上报：

Flutter 端配置：在 SDK 初始化时传入 debugId。
iOS / Android 端：在 AppDelegate/Application 初始化时传入。

👉 回复「开启联调」我来帮你配置
```

调用 `start_realtime_debug_mode` 获取 debugId。

> 📖 → 从 datong-report 读取 `references/realtime-debug.md`

---

## 联调指令（独立触发）

用户直接说「帮我开启可视化联调」时：

1. 检测技术栈
2. 收集 appId + appkey（优先从代码/上下文取，其次问用户）
3. 调用 `start_realtime_debug_mode` → 返回 debugId
4. 按技术栈指导配置位置

> 📖 → 从 datong-report 读取 `references/realtime-debug.md`

---

## 相关文档

| 文档 | 说明 |
|------|------|
| `sdk/flutter/quickstart.md` | Flutter tencent_dtreport 上报文档（本 skill 新增）|
| `custom-styles/camp-style.md` | 营地三端代码风格（本 skill 新增）|
| `references/sdk-detection.md` | 技术栈与 SDK 检测规则（含 Flutter，本 skill 新增）|
| datong-report `references/mcp-tools.md` | MCP 工具接口参数 |
| datong-report `references/mcp-init.md` | 大同 MCP 安装引导 |
| datong-report `references/realtime-debug.md` | 可视化联调步骤 |
| datong-report `references/code-generation.md` | iOS/Android 代码生成规则 |
| datong-report `references/app-registration.md` | appkey 检测与应用注册 |
| datong-report `dashboard/dashboard.md` | 指标看板子流程 |

> 💡 读取 datong-report 相关文档时，路径为 `~/.claude/skills/datong-report/`。

---

## 大同事件名规范

| 事件 | event_code | 触发方式 |
|------|------------|---------|
| 页面曝光 | `dt_pgin` | 自动（DTPageBox / vr_pageId）|
| 页面离开 | `dt_pgout` | 自动 |
| 元素曝光 | `dt_imp` | 自动（DTElementBox / vr_elementId）|
| 元素点击 | `dt_clck` | 自动 / DTReportFlutter.reportClickEvent |
| 元素反曝光 | `dt_imp_end` | 自动 |
| 自定义事件 | 业务自定义 | TencentDtreport / BeaconReport 手动上报 |

> ⚠️ 不要使用 `page_exposure`、`element_click` 等非标准名称。
