---
name: galileo-spec-checker
description: 根据伽利略指标汇总 Excel 表格，检查 iOS 代码中对应 module 的埋点上报实现是否符合规范。用户提供 xlsx 文件路径和要检查的模块名（或 moduleName），技能会解析表格中的规范定义（moduleName、campType、参数列表、平台），在代码库中定位实现，并逐项对比上报的参数是否正确、campType 是否匹配、是否有漏报或多报。当用户说"检查埋点是否正确"、"对照表格验证上报"、"check galileo spec"、"检查 moduleName 的实现"、"按照表格检查伽利略埋点"时触发。即使用户只说"结合代码检查一下 XXX 这个 module"，也应主动使用此技能。此外，当用户说"检查下 XXX 的伽利略上报"、"看一下 XXX 的伽利略上报"、"XXX 的伽利略上报对不对"、"帮我看看 XXX 上报"、"XXX 这个指标的上报"等涉及伽利略上报检查的表述时，同样触发此技能。
---

# Galileo Spec Checker

根据伽利略指标汇总表（xlsx），校验 iOS 代码中对应 module 的埋点实现是否符合规范。

## 背景知识

### 表格结构

表格的每一个 Sheet 对应一个业务域，每张 Sheet 的列含义如下：

| 列名 | 说明 |
|---|---|
| 模块 | 业务模块名（中文，合并单元格，需 ffill 填充） |
| 监控项/图表名称 | 监控项名称（合并单元格，需 ffill 填充） |
| 子项 | 日志/Trace 的类型（前置日志/后置日志/前置trace/后置trace） |
| 伽利略指标别名 | 指标的中文别名，命名规律：`moduleName-步骤名-campType`，如 `AutoLogin-start` |
| 上报名称（代码里用的） | 代码中实际传入的 moduleName |
| 参数（非通用） | 该步骤携带的额外参数，格式为 `key = value` 的描述文本 |
| 描述（目的） | 监控意图说明 |
| 平台 | ios / android / 双端 |
| 建设记录 | 是否已完成建设（ios done / android done / 双端 done） |

### 埋点上报规则

每个 module 的一次业务流程由以下步骤组成：
- **start**：流程开始
- **step**（可多个）：中间关键步骤，每个 step 有唯一的 `step="xxx"` 参数
- **end**：流程结束

除此之外还有：
- **before log / after log**：前置/后置日志，别名列显示为 `-`
- **before trace / after trace**：前置/后置 Trace，别名列显示为 `-`

### 全局约定（非常重要）

1. **所有指标均使用前置上报**：iOS 代码中 Trace 的 `traceType` 应为 `OTTraceTypeBefore`
2. **`status` 的分层要求**：
   - **Log 层（`metricLog`）**：`status` 是必传字段，封装层（如 `WEGGalileoMetricBizCenter`）通常会在组装 log 参数时自动注入。检查时确认 log 层有 `status` 即可，无论来自调用方还是封装层注入。
   - **Trace 层（`createTaskSpan` / `addAttribute`）**：`status` **不强制要求**存在于 Trace span 的 attributes 中，Trace 层缺少 `status` 不计为错误。
   - 若 Log 层和封装层均无 `status`，才判定为 ❌ 缺少必传字段
3. **`status` 取值的业务语义**：检查时需结合代码逻辑判断 status 取值是否合理：
   - **只有单个 start 步骤的 module**：该 module 仅用于上报异常/失败事件，status **必须 < 0**，无需分析代码逻辑，直接判定
   - **有完整 start-end 流程的 module**：
     - **正常逻辑上报**：status 取值应 **≥ 0**（0 表示成功，正数表示正常流程中的细分状态）
     - **异常/失败逻辑上报**：status 取值应 **< 0**（负数表示错误，如 -1 表示通用失败）
     - 判断依据：阅读调用方的业务代码，看该上报点处于 if/else 的哪个分支、是否在 error handler 里、变量名/条件是否暗示失败
   - 若封装层固定注入 `status = 0`，但 status 应为负数，则应标记 ❌ status 取值错误
4. **`status = -1` 硬编码**：部分 module 会将 status 硬编码为 -1（失败上报），这是正常模式，即使表格中没有登记此参数也无需报错
5. **表格中的参数列是"额外参数"**：`moduleName`、`campType`、`status` 是所有上报的通用参数，不会在参数列中重复列出

---

## 工作流程

### Step 0：检查前置条件（必须执行）

**在做任何代码搜索之前，必须先确认用户已提供 xlsx 表格路径。**

- 如果用户在消息中**没有提供 xlsx 文件路径**，**立即停止**，向用户发出如下请求并等待回复：

  > 请提供伽利略指标汇总表格（xlsx 文件）的路径，表格是对比规范的关键依据，缺少表格无法进行准确检查。
  >
  > 例如：`/Users/xxx/Downloads/galileo_metrics.xlsx`

- **不得在没有 xlsx 的情况下仅凭代码进行"推断式"检查**，这会导致结论不准确。
- 只有用户提供了 xlsx 路径后，才能继续执行后续步骤。

---

### Step 1：解析表格规范

使用 `scripts/parse_spec.py` 解析 xlsx，提取目标 module 的规范：

```bash
python scripts/parse_spec.py <xlsx_path> <module_name_or_moduleName> [--sheet "基础&核心指标"]
```

脚本会输出每个 moduleName 下各 campType 步骤的参数要求。

### Step 2：在代码中定位实现

用 `rg`（ripgrep）搜索 moduleName 在代码中的所有出现位置：

```bash
rg "moduleName" <codebase_path> --type objc -l
rg "moduleName" <codebase_path> --type objc -C 5
```

重点关注：
- `WEGGalileoMetricBizCenter.m`（通常是埋点封装层）
- 业务调用方（实际触发上报的代码）

### Step 3：逐项对比

对照表格规范，检查代码实现：

| 检查项 | 规范要求 | 检查方式 |
|---|---|---|
| moduleName | 与表格"上报名称"列完全一致 | 字符串精确匹配 |
| campType | start/step/end 与指标别名对应 | 检查 `OTMetricLogTypeStart/Step/End` |
| step 参数 | step 有值时需传 `step="xxx"` | 检查 attributes 字典 |
| **status（Log 层必传）** | **Log 层必须有 status；Trace 层不强制** | **检查 metricLog 参数或封装层是否注入；Trace span 缺少 status 不报错** |
| **status 取值正确性** | **正常逻辑 ≥ 0，异常逻辑 < 0** | **阅读调用方代码，判断上报点业务语义（成功路径 or 失败路径），验证 status 符合语义** |
| 额外参数 | 表格参数列中定义的 key | 逐个检查 attributes 中是否存在 |
| traceType | 必须是 `OTTraceTypeBefore` | 检查 createTaskSpan 调用 |
| 平台过滤 | `ios`/`双端` 才检查；`android` 专属直接跳过，标注 ⏭️ | 读取平台字段，android 行不进入后续检查流程 |

> ⚠️ **status 检查的重要说明**：
>
> `status` 是所有 Log 层上报的**通用必传字段**，表格参数列通常不会显式列出它（见全局约定第5条）。**不能因为表格参数列没有写 status 就跳过检查**，必须主动在代码中确认 `status` 字段存在。
>
> 特别注意**只有单个 start、没有 end 的纯异常上报 module**（如 NetRequest、BackGroundKill、Crash 等）：
> - 这类 module 完全不依赖表格参数列来提示 status
> - 必须主动检查每一处 `metricLog` 调用的 attributes 中是否有 `status`
> - status 值必须 < 0（因为这类上报全部是异常事件）
> - 若发现缺少 status，直接标记 ❌

### Step 3.5：业务逻辑分支完整性校验（仅适用于含 start-end 的流程性 module）

**仅当 module 包含 start 和 end（即流程性上报，而非单点打点）时执行此步骤。**

目标：确认代码中覆盖了所有必要的业务逻辑分支，没有漏报的路径。

#### 校验方法

1. **梳理规范中的上报结构**：从表格中统计该 module 的 end 数量和各自的 status 语义（如 end 成功 status=0、end 失败 status=-1），以及是否有 step 分支
2. **追踪代码中的调用链**：
   - 找到 start 的调用位置，理解业务入口
   - 从入口向下追踪所有可能的执行路径（正常路径、错误路径、提前退出路径、异步回调路径等）
   - 逐一确认每条路径末尾是否有对应的 end 上报
3. **重点排查以下漏报场景**：
   - 函数提前 `return` 但没有 end 上报
   - 错误回调 / failure block 里没有 end 上报
   - 异步操作超时或取消的路径没有 end 上报
   - 多个 end 应对应不同 status，但实际只上报了一种

#### 输出格式

在检查报告中新增"业务分支覆盖"章节：

```
### 业务分支覆盖
| 规范分支 | 对应代码路径 | 是否有上报 | 结论 |
|---|---|---|---|
| end（成功，status=0） | xxx 回调成功路径 | traceSpanEnd:status:0 | ✅ 已覆盖 |
| end（失败，status=-1） | xxx 回调失败路径 | 无上报 | ❌ 漏报 |
| step "xxx" | 某中间步骤 | traceSpanStep: | ✅ 已覆盖 |
```

### Step 4：输出检查报告

按以下格式输出结果：

```
## [模块名] - moduleName: XXX

### 规范定义
- start：参数 a, b, c
- step "stepName"：参数 d, e
- end：参数 f
- traceType：OTTraceTypeBefore（前置上报）

### 代码实现
- 实现位置：WEGGalileoMetricBizCenter.m:xxx
- 调用位置：SomeFile.m:xxx

### 检查结果
| 检查项 | 规范 | 实现 | 结论 |
|---|---|---|---|
| moduleName | XXX | XXX | ✅ 正确 |
| campType | start | OTMetricLogTypeStart | ✅ 正确 |
| status（Log 必传） | Log 层必须存在 | 封装层注入 status=0 | ✅ 正确 |
| status 取值 | 失败路径应 < 0 | 封装层固定注入 status=0，但调用点在 error handler | ❌ 取值错误 |
| 参数 url | url="" | url: _S(url) | ✅ 正确 |
| traceType | OTTraceTypeBefore | OTTraceTypeBefore | ✅ 正确 |

### 业务分支覆盖（仅含 start-end 的 module）
| 规范分支 | 对应代码路径 | 是否有上报 | 结论 |
|---|---|---|---|
| end（成功，status=0） | 回调成功路径 | traceSpanEnd:status:0 | ✅ 已覆盖 |
| end（失败，status=-1） | 回调失败路径 | 无上报 | ❌ 漏报 |

### 问题汇总
- ⚠️ 问题描述（若有）
- ✅ 无问题（若全部通过）
```

---

## 注意事项

- 表格中某些列使用了合并单元格，读取时需要对"模块"和"监控项名称"列做 `ffill()` 向下填充
- 表格中 `指标别名` 为 `-` 的行是日志/Trace 模板行，不需要检查 campType
- 若用户没有指定 sheet，默认检查 `基础&核心指标` 这张 sheet
- 若用户说"所有 iOS 模块"，则筛选平台为 `ios` 或 `双端` 且建设记录包含 `ios done` 的模块

### 平台过滤规则（重要）

**只检查 iOS 相关的上报，Android 专属上报一律跳过。**

| 表格平台字段 | 处理方式 |
|---|---|
| `ios` | ✅ 检查 |
| `双端` | ✅ 检查（iOS 和 Android 都需实现，只校验 iOS 侧代码） |
| `android` | ⏭️ **跳过，不检查** |

- 对于同一个 moduleName 下同时存在 `ios` 行和 `android` 行的情况，**只检查平台为 `ios` 的行**，`android` 行在报告中直接标注"Android 专属，跳过"
- 在输出报告中，对跳过的 Android 专属上报需明确说明：`⏭️ Android 专属，不在 iOS 检查范围内`
