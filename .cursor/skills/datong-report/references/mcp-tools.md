# MCP 工具接口说明

本项目提供 5 个可用的 MCP 工具接口，分布在两个 MCP 服务上，详细参数和返回说明由各工具接口自身返回。

## 工具列表

| 工具名 | 用途 | Python 脚本兜底 |
|--------|------|:-------------:|
| `get_dt_tracking_info` | 根据大同埋点信息码获取完整的埋点事件详情 | ✅ 支持 |
| `start_realtime_debug_mode` | 生成或检查 debugId，开启大同实时联调 | ✅ 支持 |
| `get_page_structure` | 根据 appId + pageId 获取页面结构信息（支持大同标准版 URL 自动解析） | ❌ 不支持  |
| `upload_tracking_plan` | 上传从零开始生成的埋点方案文件到大同平台 | ❌ 不支持  |
| `get_by_appkey` | 通过 appkey 获取对应的 appId | ❌ 不支持 |
| `create_app` | 注册大同应用，获取 appkey | ❌ 不支持 |

## 重要
mcp调用时，会先检查是否配置了 大同MCP 服务，并调用相应的工具接口。
注意了，仅：get_dt_tracking_info、start_realtime_debug_mode 走 python脚本调用，其他都是走 配置的MCP 调用。


### 调用前检测逻辑

当需要调用 `get_by_appkey` 或 `create_app` 时，先尝试直接调用：

- **调用成功** → 正常使用，无需额外操作
- **调用失败（工具不存在 / 401 未授权）** → 说明用户尚未配置该 MCP 服务，执行以下引导：

### 引导用户配置

向用户发送以下提示：

```
⚠️ 需要配置大同 MCP 服务才能使用此功能。

请在 CodeBuddy 中添加 MCP 服务：
1. 打开 CodeBuddy 设置 → MCP 配置（用户级别）
2. 添加新的 MCP 服务，配置填写：
"大同MCP": { url: "https://datong.mcp.it.woa.com" }

3. 添加后会自动拉起 OAuth 授权页面，完成授权即可
4. 授权完成后，请告诉我"已配置好"，我会重试操作
```

### Fallback 策略

如果用户不想配置 MCP 或配置后仍失败：

| 工具 | Fallback 方式 |
|------|-------------|
| `get_by_appkey` | 提示用户前往 [trackmate.woa.com](https://trackmate.woa.com) 查询 appId，或手动提供 |
| `create_app` | 使用占位符 `YOUR_APPKEY` 继续流程，提示用户前往 [trackmate.woa.com](https://trackmate.woa.com) 手动注册应用 |

### `get_page_structure` 参数说明

| 参数 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `appId` | ✅ | string | 大同应用 ID |
| `pageId` | ✅ | integer | 页面 ID |
| `structureUniqueId` | ❌ | string | 多页面结构 ID。页面有多种情况（多页面结构）时，传入对应情况的 uniqueId |
| `versionId` | ❌ | integer | 需求单 ID（对应大同 URL 中的 `flowId`），默认取最新需求单 |
| `changeOnly` | ❌ | boolean | 仅返回变更内容，不传代表不过滤 |

**从大同平台 URL 中提取参数**：

用户在使用大同标准版时，经常直接粘贴平台 URL 而非手动输入参数。URL 格式示例：

```
https://datong.woa.com/#/d/devtest/develop/detail/view/element-event?appId=RUiWu5Po&menuN=RepDev&flowId=55073&taskId=3Dc2HrSX
```

参数映射：

| URL 参数 | 工具参数 | 说明 |
|---------|---------|------|
| `appId` | `appId` | 大同应用 ID |
| `pageId` | `pageId` | 页面 ID（URL 中可能存在） |
| `flowId` | `versionId` | 需求单号 |
| `strucUniqueId` | `structureUniqueId` | 多页面结构 ID（URL 中可能存在） |

> ⚠️ URL 路径中 `/#/d/{appId}/` 的 appId 与 query 参数中的 `appId` 相同，优先使用 query 参数中的值。
> 如果 URL 中没有 `pageId`，需要询问用户提供。

### `start_realtime_debug_mode` 参数说明

| 参数 | 必填 | 说明 |
|------|------|------|
| `appId` | ✅ | 应用在大同平台的唯一标识 |
| `appkey` | ✅ | SDK 初始化使用的应用密钥 |
| `existingDebugId` | ❌ | 用户项目中已存在的 debugId（如有） |
| `source` | ❌ | 用户埋点信息的来源方式，影响联调链接的选择 |
| `sdkType` | ❌ | 用户项目使用的 SDK 类型，影响生成的配置代码 |

**`source` 取值规则**：
- `trackmate`：用户通过大同埋点标识码（`Datong_XXXX`）获取的埋点信息 → 使用 **trackmate** 联调链接
- `datong`：用户通过 appId + pageId 获取的埋点信息 → 使用 **datong** 联调链接
- 未提供或无法确认 → 默认使用 **trackmate** 联调链接

**`sdkType` 取值规则**：
- `beacon`：轻量版 SDK（BeaconAction），debugId 和 appId 直接作为初始化参数传入
- `universal_report`：标准版 SDK（@tencent/universal-report），debugId 和 appId 通过 `beaconOptions` 传入
- 未提供 → 默认使用 `beacon`（轻量版）

### `start_realtime_debug_mode` 独立使用说明

该工具可独立于完整的埋点接入流程使用。当用户直接要求"开启可视化联调"时，无需走完整主流程。

> 📖 详细执行步骤（SDK 检测、参数收集、source 推断）见 `realtime-debug.md`

### `get_by_appkey` 参数说明

| 参数 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `appKey` | ✅ | string | SDK 初始化使用的应用密钥（即 appkey） |

**返回值**：`appId`（应用在大同平台的唯一标识）

> 属于大同测试网关，调用前需确认用户已配置（见上方"MCP 配置检测"章节）。
>
> 典型场景：Step 4 实时联调时，已有 appkey 但缺少 appId，用此工具自动转换，无需用户手动查询。

### `create_app` 参数说明

| 参数 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `appName` | ✅ | string | 应用名称（建议使用项目名，如 package.json 的 name 字段） |
| `platform` | ✅ | string | 平台类型：`web`、`android`、`ios` |
| `description` | ❌ | string | 应用描述 |

> 属于大同测试网关，调用前需确认用户已配置（见上方"MCP 配置检测"章节）。
>
> 📖 完整的 appkey 检测与注册流程见 `app-registration.md`

### `upload_tracking_plan` 参数说明

| 参数 | 必填 | 类型 | 说明 |
|------|------|------|------|
| `appId` | ✅ | string | 应用在大同平台的唯一标识|
| `value` | ✅ | string | 内容为 生成的埋点方案文件（`dt_tracking_plan/埋点事件-YYYYMMDDHH.md`）的完整文本内容 |

> ⚠️ `appId` 必须是有效值。如果 Step 1.2 中注册失败/用户跳过（appId 为占位符状态），则**不调用此工具**。

**调用示例**：

```
upload_tracking_plan({
  appId: 'xxx',
  value: '| 触发时机 trigger | 示意图 ui | 事件 event_code | 页面 dt_pgid | 元素 dt_eid | 私有参数 udf_kv | 说明 remark |
|----------|:----:|---------|---------|:------------:|-------|-------|
| 进入首页时 | — | `dt_pgin` 页面曝光 | `home` 首页 | — | — | — |
| 离开首页时（高优先级上报） | — | `dt_pgout` 页面离开 | `home` 首页 | — | — | — |
| 点击计数按钮时 | — | `dt_clck` 按钮点击 | `home` 首页 | `count_btn` | `count` 当前点击次数 | — |
| 计数按钮进入可视区域时 | — | `dt_imp` 元素曝光 | `home` 首页 | `count_btn` | — | — |
'
})
```

**使用时机**：仅在「从零开始」路径（Step 1.5 → B）中，`references/tracking-plan.md` 流程的 Step 3b 完成后调用。将最终的表格式埋点方案文件内容上传到大同平台。

> ⚠️ 属于大同测试网关工具，调用前需确认用户已配置（见上方"MCP 配置检测"章节）。调用失败时不阻断主流程，提示用户手动前往 [trackmate.woa.com](https://trackmate.woa.com) 导入。

## 调用方式

### 方式一：MCP 工具直接调用（优先）

如果用户项目已配置 MCP，直接使用工具名调用即可。

### 方式二：Python 脚本调用（兜底）

仅限**支持 py 脚本兜底**的工具（见上方工具列表）。如果 MCP 工具调用失败，使用 `scripts/mcp-caller.py` 脚本调用。

```bash
python scripts/mcp-caller.py list
python scripts/mcp-caller.py get_dt_tracking_info --code Datong_xxxxx
python scripts/mcp-caller.py get_page_structure --appId xxx --pageId 123
python scripts/mcp-caller.py start_realtime_debug_mode --appId xxx --appkey xxx
```

> 脚本使用纯标准库（`urllib`），无需安装额外依赖。

### 判断使用哪种方式

1. 先尝试直接调用 MCP 工具
2. 如果工具不存在或调用失败 → 检查该工具是否支持 py 脚本兜底
   - 支持 → 改用 Python 脚本方式通过终端调用，脚本返回的数据格式与 MCP 工具一致
   - 不支持（`get_by_appkey`、`create_app`）→ 执行上方"MCP 配置检测"章节的引导 / Fallback 策略
