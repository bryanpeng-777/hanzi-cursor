---
name: dynamic-risk-verifier
description: 动态现网风险检测器。在功能上线前，通过向代码注入专项监控日志，让用户实际运行功能，再根据日志输出判断是否存在重大现网隐患。检测维度包括：初始化是否成功、是否访问正式环境、开关配置是否正确、关键业务路径是否正常执行、关键参数是否合法、异步回调是否完成等。当用户提到"动态检测"、"注入日志检查现网风险"、"上线前动态验证"、"运行一下检查有没有问题"、"dynamic risk check"，或在静态分析（production-risk-checker）后需要进一步动态验证时触发。
---

# Dynamic Risk Verifier

## 定位

静态代码审查（`production-risk-checker`）只能发现代码层面的隐患，动态验证才能发现运行时的真实问题：
- 初始化参数是否真的被正确传入？
- SDK 是否真的访问了正式环境的接口？
- 开关值在当前 App 版本/环境下是否符合预期？
- 关键路径是否真的被执行到？

本技能通过"注入日志 → 用户运行 → 分析日志"的闭环，在真实运行时验证这些问题。

---

## Workflow

### Phase 0：明确检测范围

**Step 1：读取相关代码**

让用户告知（或从上下文推断）要检测的功能模块及核心文件，然后读取代码，理解：
- 功能的初始化入口在哪里
- 核心业务路径是什么（主流程 + 失败流程）
- 涉及哪些外部依赖（SDK、接口、开关、权限）

**Step 2：生成「风险检测矩阵」**

在注入日志前，先列出要验证的检测点：

```
风险检测矩阵：
- [ ] [初始化] SDK/模块是否成功初始化，参数是否正确
- [ ] [环境]   接口/配置是否指向正式环境
- [ ] [开关]   Feature Flag 默认值和实际生效值是否符合预期
- [ ] [权限]   所需系统权限是否被正确申请和处理
- [ ] [主路径] 核心业务逻辑是否被触发并完整执行
- [ ] [参数]   关键业务参数值是否在合法范围内
- [ ] [异步]   回调/Completion 是否在所有分支都被调用
- [ ] [失败路径] 异常/失败场景是否有兜底处理
```

根据功能特性，只保留相关的检测点，不强行套用全部维度。

---

### Phase 1：注入监控日志

#### 日志规范

所有日志统一使用前缀 `[DynamicRiskCheck]`，方便过滤。格式：

```
[DynamicRiskCheck][检测维度] 描述 key=value
```

检测维度标签：
- `[INIT]` - 初始化
- `[ENV]` - 环境配置
- `[SWITCH]` - 开关/Feature Flag
- `[PERMISSION]` - 权限
- `[PATH]` - 业务路径
- `[PARAM]` - 关键参数
- `[CALLBACK]` - 异步回调
- `[FALLBACK]` - 降级兜底

#### 各维度日志注入位置和内容

**1. 初始化检测 `[INIT]`**

注入位置：初始化函数入口、初始化完成回调

```objc
// Objective-C
NSLog(@"[DynamicRiskCheck][INIT] initSDK called: appID=%@, channel=%@, env=%@", appID, channel, isRelease ? @"PRODUCTION" : @"TEST");
NSLog(@"[DynamicRiskCheck][INIT] initSDK result: success=%d, isInitialized=%d", success, self.isSDKInitialized);
```

```swift
// Swift
print("[DynamicRiskCheck][INIT] init called: param=\(param), env=\(isRelease ? "PRODUCTION" : "TEST")")
```

```dart
// Dart/Flutter
debugPrint('[DynamicRiskCheck][INIT] service init: param=$param, env=${kReleaseMode ? "PRODUCTION" : "TEST"}');
```

**2. 环境检测 `[ENV]`**

注入位置：接口请求构造处、环境判断分支

```objc
NSLog(@"[DynamicRiskCheck][ENV] request URL: %@", requestURL);
NSLog(@"[DynamicRiskCheck][ENV] env flag: isRelease=%d, baseURL=%@", isRelease, baseURL);
```

重点关注：URL 中是否含 `test`、`stg`、`dev`、`sandbox`、`oa.com` 等测试标识。

**3. 开关检测 `[SWITCH]`**

注入位置：读取 Feature Flag / RDelivery / Shiply 的地方

```objc
NSLog(@"[DynamicRiskCheck][SWITCH] key=%@, value=%d, defaultValue=%d, source=%@", switchKey, value, defaultValue, source);
```

**4. 权限检测 `[PERMISSION]`**

注入位置：权限申请回调

```objc
NSLog(@"[DynamicRiskCheck][PERMISSION] type=%@, status=%ld, granted=%d", permType, (long)status, granted);
```

**5. 业务主路径 `[PATH]`**

注入位置：核心业务函数的入口、关键分支节点、出口

```objc
NSLog(@"[DynamicRiskCheck][PATH] %@ entered: %@", NSStringFromSelector(_cmd), paramDesc);
NSLog(@"[DynamicRiskCheck][PATH] branch: condition=%d, taking=%@", condition, @"xxx路径");
NSLog(@"[DynamicRiskCheck][PATH] %@ completed: result=%@", NSStringFromSelector(_cmd), result);
```

**6. 关键参数 `[PARAM]`**

注入位置：参数被使用前的关键节点

```objc
NSLog(@"[DynamicRiskCheck][PARAM] appID=%@, storeID=%@, sceneid=%@, isEmpty_appID=%d", appID, storeID, sceneid, !appID.length);
```

**7. 异步回调 `[CALLBACK]`**

注入位置：所有 completion block / callback 的每个分支

```objc
// success 分支
NSLog(@"[DynamicRiskCheck][CALLBACK] %@ success callback triggered: result=%@", callbackName, result);
// failure 分支
NSLog(@"[DynamicRiskCheck][CALLBACK] %@ failure callback triggered: error=%@", callbackName, error);
// 注意：如果某个分支缺少日志，说明该分支 completion 没被调用
```

**8. 降级兜底 `[FALLBACK]`**

注入位置：fallback / 降级处理逻辑入口

```objc
NSLog(@"[DynamicRiskCheck][FALLBACK] %@ fallback triggered: reason=%@", feature, reason);
```

---

### 注入完成后：输出运行指引

注入日志后，必须输出结构化的运行步骤：

```
📋 动态风险验证运行指引

过滤关键字：[DynamicRiskCheck]
iOS 过滤方式：Xcode Console 输入 DynamicRiskCheck

场景 1：[正常主流程]
  操作：打开 xxx 页面 → 点击 xxx 按钮
  预期看到的日志维度：[INIT] [ENV] [SWITCH] [PATH] [CALLBACK]
  
场景 2：[失败/降级场景]（如有）
  操作：（描述如何构造失败场景，例如：关闭网络、使用未安装的 App）
  预期看到的日志维度：[FALLBACK] [CALLBACK]

场景 3：[权限场景]（如有）
  操作：首次运行 / 拒绝权限后再次触发
  预期看到的日志维度：[PERMISSION]

完成后，请将 Xcode Console 中过滤到的日志内容粘贴给我。
```

然后**等待用户提供日志**，不要继续执行。

---

### Phase 2：分析日志，输出风险报告

收到日志后，按检测矩阵逐项分析：

#### 分析方法

**[INIT] 初始化**
- 是否有初始化日志？（没有 = 初始化未被调用）
- 参数是否非空且合法？
- `isInitialized=1`？

**[ENV] 环境**
- URL 中是否含测试域名（`test.`、`stg.`、`dev.`、`sandbox.`、`oa.com`）？
- 发现测试域名 → 🚨 高危，立即标记

**[SWITCH] 开关**
- value 与 defaultValue 是否符合预期？
- 如果 value == defaultValue，可能是服务端配置未下发（检查 App 环境）

**[PATH] 业务路径**
- 主流程日志是否完整（入口 → 关键分支 → 出口）？
- 有无中途断掉（某个节点后没有后续日志）？
- 分支走向是否符合业务预期？

**[PARAM] 参数**
- 是否有空值（`isEmpty_xxx=1`）？
- 数值是否在合法范围？

**[CALLBACK] 回调**
- success 和 failure 分支各自是否有日志？
- 如果某个操作触发后既无 success 也无 failure 日志 → completion 未被调用 → 可能导致 loading 永不消失

**[FALLBACK] 降级**
- 降级是否按预期触发（不该触发的没触发，该触发的触发了）？

#### 风险报告格式

```
## 动态风险验证报告

**功能**：xxx
**运行环境**：xxx（从 ENV 日志判断）
**整体结论**：🚨 发现高危问题 / ⚠️ 发现需关注问题 / ✅ 未发现重大风险

### 🚨 高危（必须修复）
| 检测维度 | 问题 | 日志证据 | 修复建议 |
|---------|------|---------|---------|
| [ENV]   | 访问了测试环境 URL | `request URL: https://test.xxx.com` | 检查环境切换逻辑 |

### ⚠️ 需关注
| 检测维度 | 问题 | 日志证据 |
|---------|------|---------|
| [SWITCH] | 开关值等于默认值，可能未下发 | `value=0, defaultValue=0` |

### ✅ 通过项
- [INIT] SDK 初始化成功，参数合法
- [PATH] 主流程完整执行
- [CALLBACK] 所有分支回调均被调用

### ❓ 未覆盖（需补充运行）
- [PERMISSION] 未触发权限申请场景
```

---

### Phase 3：循环验证（如有问题）

如果发现问题：
1. 描述问题和修复建议
2. 如需代码修改，**等用户确认后再改**
3. 调整日志覆盖点（如有必要）
4. 要求用户再次运行，提供新日志
5. 重复 Phase 2 分析

---

### Phase 4：清理日志

所有问题修复并验证通过后：
1. 删除所有 `[DynamicRiskCheck]` 日志行
2. 不删除业务本身已有的日志
3. 确认代码恢复干净

---

## 快速参考

| 检测维度 | 高危信号 | 需关注信号 |
|---------|---------|---------|
| [INIT] | 无初始化日志 / isInitialized=0 | 参数为空但未 return |
| [ENV] | URL 含测试域名 | URL 为空 |
| [SWITCH] | 开关值与预期相反 | value == defaultValue（可能未下发） |
| [PATH] | 主流程中途断掉 | 分支走向与业务预期不符 |
| [PARAM] | 关键参数为空 / 越界 | 参数格式异常 |
| [CALLBACK] | 某分支无回调日志 | 回调时序异常 |
| [FALLBACK] | 不该降级时触发了降级 | 该降级时未降级 |

## 与静态检查的配合

本技能是 `production-risk-checker`（静态）的动态补充。推荐流程：
1. 先跑 `production-risk-checker` 发现代码层面隐患并修复
2. 再跑本技能，通过实际运行验证静态检查无法覆盖的运行时问题
3. 两者均通过后，方可放心上线
