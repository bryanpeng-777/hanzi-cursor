# logger 接入与 print 替换规则

本文件供 `cs-stack-onboarding` Step 2-7（logger 接入）和 Step 3-J（print 迁移）使用。

---

## Step 接入-1：安装依赖

在 `pubspec.yaml` 的 `dependencies` 中添加：

```yaml
logger: ^2.4.0
```

执行 `flutter pub get`。

---

## Step 接入-2：创建 AppLogger 单例

新建 `lib/utils/app_logger.dart`：

```dart
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';

/// 全局日志单例，全项目统一使用
final appLogger = AppLogger._();

class AppLogger {
  AppLogger._();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.off : Level.trace,
  );

  void t(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  void d(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  void i(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  void f(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}
```

---

## Step 3-J：print → appLogger 迁移

### 扫描目标

扫描所有 `lib/` 下 `.dart` 文件中的以下模式：

| 扫描模式 | 说明 |
|---------|-----|
| `print(` | 标准 print，最常见 |
| `debugPrint(` | Flutter 调试用 print，同样需替换 |
| `developer.log(` | dart:developer 的 log，替换为对应级别 |
| `print('[Dio]` | Dio 日志拦截器中的 print（已在 DioClient 中，替换为 appLogger） |

### 级别判断规则

根据 print 的**内容语义**选择 logger 级别：

| 内容特征 | 推荐级别 | 说明 |
|---------|---------|-----|
| 含 `Error` / `error` / `Exception` / `failed` / `failure` | `appLogger.e(...)` | 错误，需关注 |
| 含 `Warning` / `warn` / `deprecated` | `appLogger.w(...)` | 警告 |
| 含 `[Dio]` / 网络请求 URL / response | `appLogger.d(...)` | 调试信息 |
| 含 `Init` / `Start` / `Ready` / `initialized` | `appLogger.i(...)` | 关键生命周期信息 |
| 其他普通调试信息 | `appLogger.d(...)` | 默认用 debug |
| 极细粒度追踪（循环内、频繁触发） | `appLogger.t(...)` | trace，最低级别 |

### 迁移示例

#### 普通 print

```dart
// Before
print('User loaded: $userId');
print('Error: $e');
print('Network response: ${response.statusCode}');

// After
import '../utils/app_logger.dart';

appLogger.d('User loaded: $userId');
appLogger.e('Error', error: e);
appLogger.d('Network response: ${response.statusCode}');
```

#### 带 StackTrace 的错误

```dart
// Before
try {
  await someAsyncOperation();
} catch (e, stackTrace) {
  print('Operation failed: $e');
  print(stackTrace);
}

// After
try {
  await someAsyncOperation();
} catch (e, stackTrace) {
  appLogger.e('Operation failed', error: e, stackTrace: stackTrace);
}
```

#### Dio 拦截器中的 print

```dart
// Before（在 _LoggingInterceptor 中）
print('[Dio] ${options.method} ${options.uri}');
print('[Dio] Error: ${err.message}');

// After
import '../utils/app_logger.dart';

appLogger.d('[Dio] ${options.method} ${options.uri}');
appLogger.e('[Dio] ${err.message}', error: err);
```

#### debugPrint

```dart
// Before
debugPrint('Widget built: $runtimeType');

// After
appLogger.d('Widget built: $runtimeType');
```

#### developer.log

```dart
// Before
import 'dart:developer' as developer;
developer.log('Event received', name: 'MyWidget', error: e);

// After
appLogger.i('Event received', error: e);
// 同时删除 dart:developer 导入（如无其他用途）
```

### 迁移后清理

1. 检查是否还有残留 `print(` / `debugPrint(`（通过 `flutter analyze` 或全局搜索确认）
2. 如有 `import 'dart:developer'` 仅用于 log，改造后一并删除
3. 在 `analysis_options.yaml` 中可选开启 lint 规则，防止未来误用 print：

```yaml
# analysis_options.yaml
linter:
  rules:
    avoid_print: true          # 禁止 print
```

---

## 常见踩坑

### Release 模式日志关闭

`AppLogger` 中已配置 `kReleaseMode ? Level.off : Level.trace`，Release 包不会输出任何日志，无需手动处理。

### 不要在频繁触发的 build 方法中打 info 级别

`build` 方法可能每秒调用多次，应用 `appLogger.t()`（trace）而非 `appLogger.i()`，避免日志刷屏。

### 避免在日志消息中做昂贵计算

```dart
// 不好：即使日志级别关闭，字符串插值仍会执行
appLogger.d('Items: ${items.map((e) => e.toString()).join(', ')}');

// 更好：用 lambda 延迟执行（logger 支持）
appLogger.d(() => 'Items: ${items.map((e) => e.toString()).join(', ')}');
```
