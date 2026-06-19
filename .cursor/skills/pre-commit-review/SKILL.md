---
name: pre-commit-review
description: 审查准备提交的 Git 变更代码，检查逻辑问题、复杂注释、内存泄漏、潜在 crash、未完成 TODO 和测试代码误提交。支持 Dart/Flutter、Swift、Objective-C。当用户提到"提交前审查"、"代码检查"、"review 变更"、"老师检查作业了"或准备 git commit 时触发。
---

# 提交前代码审查

审查当前 Git staged/unstaged 变更，识别潜在问题，确保代码质量。

## 脚本分工

> **脚本处理**：机械检测（调试打印、TODO、测试数据、强制解包、dart analyze）（`scripts/pre_check.sh`）
> **AI 处理**：语义分析（逻辑问题、内存泄漏、潜在 Crash、业务影响评估）

```bash
# 检查 HEAD 全量变更
bash scripts/pre_check.sh

# 只检查已 staged 的变更
bash scripts/pre_check.sh --staged-only
```

**流程**：先运行脚本获取机械检测结果，AI 再对完整 diff 做语义 review，两者合并为最终报告。

---

## 审查流程

### 1. 获取变更内容

```bash
# 获取所有变更（staged + unstaged）
git diff HEAD

# 仅 staged 变更
git diff --cached

# 查看变更文件列表
git status --short
```

### 2. 执行检查清单

对每个变更文件，逐项检查以下内容：

---

## 检查项

### 逻辑问题检查

**目标**：识别代码变更中的逻辑错误、条件判断问题和执行顺序问题。

检查点：
- [ ] 条件块内的代码应该在块外执行（如设置默认值被包在 if 内导致某些情况未设置）
- [ ] 重复的赋值或操作（同一变量被多次设置相同值）
- [ ] 条件判断顺序错误（如先使用后判空）
- [ ] 逻辑运算符使用错误（`&&` 与 `||` 混淆）
- [ ] 边界条件遗漏（如 `>` 应该是 `>=`）
- [ ] 返回值未使用或被忽略
- [ ] 循环条件可能导致死循环
- [ ] switch/case 缺少 break 或 default
- [ ] 异步操作的时序问题（如回调中使用已释放的资源）
- [ ] 对原有业务逻辑的破坏性影响（如修改了公共方法的行为、改变了返回值语义、影响了调用方的预期）

**输出示例**：
```
文件: WEGGalileoOneAPI.m (L38-40)
问题: 逻辑问题
原因: status 设置在 if (params) 块内，当 params 为 nil 时不会设置
建议: 将 [startParams setObject:@(status) forKey:@"status"] 移到 if 块外部
```

---

### 复杂注释检查

**目标**：识别冗长、过时或重复代码的注释，建议精简。

检查点：
- [ ] 注释超过 3 行且可用更简洁方式表达
- [ ] 注释内容与代码逻辑重复（代码自解释）
- [ ] 注释中的 TODO 已完成但未删除
- [ ] 调试/临时注释（如 `// test`、`// debug`、`// temp`）

**输出示例**：
```
文件: xxx.dart (L42-48)
问题: 复杂注释
建议: 删除 L43-45 的冗余说明，代码已自解释
```

---

### 内存泄漏检查

**Dart/Flutter**：
- [ ] Stream 订阅未在 `dispose()` 中取消
- [ ] Timer 未在 `dispose()` 中取消
- [ ] AnimationController 未 `dispose()`
- [ ] TextEditingController 未 `dispose()`
- [ ] ScrollController 未 `dispose()`
- [ ] FocusNode 未 `dispose()`
- [ ] ChangeNotifier/ValueNotifier 未 `dispose()`
- [ ] 闭包持有 BuildContext 或 State 引用
- [ ] addListener 后未 removeListener

**Swift**：
- [ ] 闭包中使用 `self` 未标记 `[weak self]`
- [ ] delegate 未声明为 `weak`
- [ ] 循环引用（A 强引用 B，B 强引用 A）
- [ ] NotificationCenter observer 未 remove
- [ ] Timer 未 invalidate
- [ ] CADisplayLink 未 invalidate

**Objective-C**：
- [ ] block 中使用 self 未使用 weakSelf
- [ ] delegate 属性未声明为 `weak`
- [ ] NSTimer 未 invalidate
- [ ] 循环引用
- [ ] NotificationCenter observer 未移除

**输出示例**：
```
文件: user_service.dart (L85)
问题: 潜在内存泄漏
原因: StreamSubscription 未在 dispose() 中 cancel
建议: 在 dispose() 方法中添加 _subscription?.cancel()
```

---

### 潜在 Crash 检查

**Dart/Flutter**：
- [ ] 强制解包 `!` 用于可能为 null 的值
- [ ] 未处理的异常（无 try-catch）
- [ ] 数组越界访问（未检查 length）
- [ ] 在 `initState` 中使用 `context` 进行导航
- [ ] BuildContext 在 async 操作后使用
- [ ] setState 在 dispose 后调用

**Swift**：
- [ ] 强制解包 `!` 用于 Optional
- [ ] 强制类型转换 `as!`
- [ ] 数组下标访问未检查 bounds
- [ ] 隐式解包 Optional 声明 `Type!`
- [ ] fatalError/preconditionFailure 在生产代码中

**Objective-C**：
- [ ] 未检查 nil 直接调用方法（特定场景）
- [ ] 数组操作未检查边界
- [ ] 字典取值未做 nil 判断
- [ ] 未实现必要的协议方法
- [ ] 主线程外更新 UI

**输出示例**：
```
文件: home_page.dart (L156)
问题: 潜在 crash
原因: 使用 list[index] 前未检查 index < list.length
建议: 添加边界检查或使用 list.elementAtOrNull(index)
```

---

### 未完成 TODO 检查

检查点：
- [ ] `TODO:` 注释
- [ ] `FIXME:` 注释
- [ ] `HACK:` 注释
- [ ] `XXX:` 注释
- [ ] `待处理`、`待实现`、`待完成` 等中文标记

**输出示例**：
```
文件: battle_service.dart (L234)
问题: 未完成 TODO
内容: // TODO: 处理网络异常情况
建议: 完成实现或移除此 TODO 后再提交
```

---

### 测试代码误提交检查

检查点：
- [ ] 硬编码的测试数据（如 `userId = "123456"`）
- [ ] print/debugPrint/NSLog 调试语句
- [ ] 测试用的 mock 数据
- [ ] 被注释掉的正式代码（保留测试代码）
- [ ] 测试用的 IP 地址或端口
- [ ] `#if DEBUG` 或 `kDebugMode` 块中的代码泄露到生产
- [ ] 测试文件命名（如 `*_test.dart`）的导入

**关键词检测**：
```
print(、debugPrint(、NSLog(、console.log(
// test、// debug、// temp、// 测试
mockData、testData、fakeData
127.0.0.1、localhost、10.0.0
```

**输出示例**：
```
文件: api_client.dart (L78)
问题: 测试代码
内容: print("debug: response = $response")
建议: 移除调试语句或使用条件编译
```

---

## 输出格式

审查完成后，按以下格式输出：

```markdown
# 提交前代码审查报告

## 总览
- 检查文件数: X
- 发现问题数: Y
- 严重问题: Z

## 问题清单

### 严重 (需修复)
| 文件 | 行号 | 类型 | 问题描述 |
|------|------|------|----------|
| xxx.dart | L85 | 内存泄漏 | Stream 未取消订阅 |

### 警告 (建议修复)
| 文件 | 行号 | 类型 | 问题描述 |
|------|------|------|----------|
| xxx.dart | L42 | 复杂注释 | 注释可精简 |

### 提示 (可选修复)
| 文件 | 行号 | 类型 | 问题描述 |
|------|------|------|----------|
| xxx.dart | L234 | TODO | 存在未完成项 |

## 修复建议
[针对严重问题的具体修复代码建议]
```

---

## 问题严重等级

| 等级 | 类型 | 说明 |
|------|------|------|
| 严重 | 内存泄漏、潜在 Crash | 必须修复后再提交 |
| 警告 | 逻辑问题、测试代码、复杂注释 | 强烈建议修复 |
| 提示 | 未完成 TODO | 评估后决定是否修复 |

---

## 快速命令

```bash
# 查看 staged 变更中的 TODO
git diff --cached | grep -n "TODO\|FIXME\|HACK"

# 查看 staged 变更中的 print 语句
git diff --cached | grep -n "print(\|debugPrint(\|NSLog("
```

---

## Related Skills

- **[code-reviewer](../code-reviewer/SKILL.md)**: 需要做全面深度代码质量审查时使用（安全漏洞、内存管理、并发等），比提交前检查更深入
- **[production-risk-checker](../production-risk-checker/SKILL.md)**: 功能上线前做全面现网风险扫描（16 项检查）
- **[bugfix](../bugfix/SKILL.md)**: 检查发现了 bug 时，切换到 bugfix skill 进行系统化修复
