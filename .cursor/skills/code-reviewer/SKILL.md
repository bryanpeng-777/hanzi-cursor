---
name: code-reviewer
description: 通用代码质量审查。给定代码片段、文件或功能描述，分析安全性、潜在 Bug、性能、最佳实践，支持 Dart/Flutter、Swift、Objective-C、通用语言。当用户说「review 这段代码」「看一下这个文件」「代码质量」「帮我看看这个实现」时触发。
---

# 代码质量审查

对给定代码片段或文件进行系统性审查，输出结构化问题报告和修复建议。

---

## 审查流程

### 1. 确认审查对象

用户给出代码时，先明确：
- **语言/平台**：Dart/Flutter、Swift、Objective-C、其他
- **审查重点**（若用户未指定，全项扫描）：安全 / Bug / 性能 / 质量

### 2. 按语言执行专项检查

---

## 通用检查项

### 安全

- [ ] 硬编码凭证、密钥、Token
- [ ] 输入未做校验/清洗（SQL 注入、XSS）
- [ ] 认证/鉴权逻辑缺失
- [ ] 不安全的随机数生成
- [ ] 敏感信息打印到日志

### 潜在 Bug

- [ ] 空值/nil 未判断直接使用
- [ ] 数组/集合越界访问未防护
- [ ] 错误/异常未捕获或被吞掉
- [ ] 整数溢出/下溢
- [ ] 返回值被忽略（特别是错误码）
- [ ] 边界条件遗漏（`>` 应为 `>=` 等）
- [ ] switch/case 缺少 default 或 break

### 性能

- [ ] 循环内重复查询/初始化
- [ ] 不必要的对象创建（频繁 GC 压力）
- [ ] 同步阻塞主线程
- [ ] 无缓存的重复计算
- [ ] N+1 查询问题

### 代码质量

- [ ] 方法/函数过长（建议 > 80 行考虑拆分）
- [ ] 魔法数字未提取为常量
- [ ] 代码重复（DRY 原则）
- [ ] 命名不清晰或不一致
- [ ] 注释与代码不一致或冗余

---

## Dart / Flutter 专项

### 内存与生命周期

- [ ] `StreamSubscription` 未在 `dispose()` 中 `cancel()`
- [ ] `Timer` 未在 `dispose()` 中 `cancel()`
- [ ] `AnimationController` 未 `dispose()`
- [ ] `TextEditingController` / `ScrollController` / `FocusNode` 未 `dispose()`
- [ ] `ChangeNotifier` / `ValueNotifier` 未 `dispose()`
- [ ] `addListener` 后未 `removeListener`
- [ ] 闭包持有 `BuildContext` 或 `State` 引用（async gap 后使用 context）

### 潜在 Crash

- [ ] 强制解包 `!` 用于可能为 null 的值
- [ ] `setState` 在 `dispose()` 后调用
- [ ] `initState` 中直接使用 `context` 做导航
- [ ] 数组下标未检查 `length`
- [ ] `as` 强转未用 `as?` 保护（Dart 中 `as` 直接抛异常）

### Riverpod / 状态管理

- [ ] `ref.read` 在 `build` 方法内使用（应用 `ref.watch`）
- [ ] Provider 在 Widget 外部创建（应用 `ref.watch/listen`）
- [ ] `StateProvider` 存放复杂对象（建议 `NotifierProvider`）

### Flutter 最佳实践

- [ ] `BuildContext` 在异步操作后使用（需检查 `mounted`）
- [ ] `const` 构造函数未使用（影响重建优化）
- [ ] `ListView` 大列表未用 `ListView.builder`
- [ ] `print` / `debugPrint` 遗留在生产代码
- [ ] `Image.network` 未处理加载失败

---

## Swift 专项

### 内存与引用

- [ ] 闭包中使用 `self` 未标记 `[weak self]` 或 `[unowned self]`
- [ ] `delegate` 属性未声明为 `weak`
- [ ] 循环引用（A 强引用 B，B 强引用 A）
- [ ] `NotificationCenter` observer 未在 `deinit` 中 remove
- [ ] `Timer` 未 `invalidate`，`CADisplayLink` 未 `invalidate`

### 潜在 Crash

- [ ] 强制解包 `!` 用于 Optional（应用 `guard let` / `if let`）
- [ ] 强制类型转换 `as!`（应用 `as?`）
- [ ] 隐式解包 Optional 声明 `Type!`（除 `@IBOutlet` 外应避免）
- [ ] 数组下标访问未检查 bounds
- [ ] 主线程外更新 UI（需 `DispatchQueue.main.async`）
- [ ] `fatalError` / `preconditionFailure` 出现在生产路径

### 并发

- [ ] 共享可变状态未加保护（`DispatchQueue` / `actor` / `NSLock`）
- [ ] `async/await` 中 `MainActor` 标注缺失
- [ ] Task 未正确 cancel 导致泄漏

---

## Objective-C 专项

### 内存与引用

- [ ] block 中使用 `self` 未用 `weakSelf` / `strongSelf` 模式
- [ ] `delegate` 属性未声明为 `weak`
- [ ] `NSTimer` 未 `invalidate`（Timer 持有 target 强引用）
- [ ] `NSNotificationCenter` observer 未 `removeObserver`
- [ ] 循环引用

### 潜在 Crash

- [ ] 数组/字典操作前未检查边界/nil（`objectAtIndex:` 越界直接 crash）
- [ ] 字典取值未做 nil 判断
- [ ] 主线程外更新 UI
- [ ] `dispatch_once` token 放在栈上（应为 static）
- [ ] 未实现必要的协议方法

### 代码规范

- [ ] `NSLog` 遗留在生产代码（王者营地项目中被宏替换为 xlog，注意区分）
- [ ] 宏定义无括号保护（如 `#define A 1+2` 应改为 `(1+2)`）

---

## 输出格式

```markdown
# 代码审查报告

## 总览
- 审查语言：<Dart/Swift/OC/通用>
- 发现问题：<N> 条（严重 X / 警告 Y / 提示 Z）

## 问题清单

### 严重（必须修复）
| 位置 | 类型 | 问题描述 | 修复建议 |
|------|------|----------|---------|
| L85 | 内存泄漏 | StreamSubscription 未在 dispose 中 cancel | dispose() 中添加 _sub?.cancel() |

### 警告（建议修复）
| 位置 | 类型 | 问题描述 | 修复建议 |
|------|------|----------|---------|

### 提示（可选）
| 位置 | 类型 | 问题描述 | 修复建议 |
|------|------|----------|---------|

## 亮点
[记录实现好的地方，保持正向反馈]
```

---

## 严重等级

| 等级 | 标准 |
|------|------|
| 严重 | 内存泄漏、Crash 隐患、安全漏洞 — 必须修复 |
| 警告 | 逻辑问题、性能瓶颈、测试代码遗留 — 强烈建议修复 |
| 提示 | 代码风格、注释优化、可读性 — 评估后决定 |

---

## Related Skills

- **[pre-commit-review](../pre-commit-review/SKILL.md)**: 提交前轻量快速审查（逻辑问题、TODO、print 残留），比 code-reviewer 更快
- **[production-risk-checker](../production-risk-checker/SKILL.md)**: 功能上线前做全面现网风险扫描（16 项检查，含环境配置、兼容性等）
