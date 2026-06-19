# logger 插件

日志系统接入：logger 包替代 print/debugPrint，分级输出，Release 模式自动关闭。

**详细规则见** `references/transform-logger.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 logger 依赖
2. 扫描统计：`print(` / `debugPrint(` / `developer.log(` 调用数量

### 添加依赖

```yaml
dependencies:
  logger: ^2.4.0
```

运行 `flutter pub get`

### 创建全局 Logger 实例

新建 `lib/utils/app_logger.dart`（详见 references/transform-logger.md）：

```dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kReleaseMode ? Level.off : Level.verbose,
);
```

### 批量替换 print 调用

按语义判断日志级别替换（详见 references/transform-logger.md）：

| 原写法 | 替换为 | 场景 |
|--------|--------|------|
| `print('xxx')` | `appLogger.d('xxx')` | 调试信息 |
| `print('Error: $e')` | `appLogger.e('xxx', error: e)` | 错误 |
| `debugPrint('xxx')` | `appLogger.i('xxx')` | 一般信息 |
| `developer.log('xxx')` | `appLogger.d('xxx')` | 调试 |

在每个替换文件顶部添加：
```dart
import 'package:your_app/utils/app_logger.dart';
```

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查 logger 最新版
```

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| H1 | print/debugPrint 清零 | `grep -rn "print\|debugPrint" lib/` | 零残余 |

---

## [USAGE] 使用辅助

### 日志级别说明

```dart
appLogger.v('详细调试，仅开发时关注');          // verbose
appLogger.d('普通调试信息');                    // debug
appLogger.i('关键业务节点信息');                // info
appLogger.w('警告，潜在问题但不影响运行');        // warning
appLogger.e('错误', error: e, stackTrace: st); // error（附带异常对象）
```

Release 模式（`kReleaseMode = true`）时，Level.off 关闭所有日志，不影响性能。

### 在 catch 块中记录错误

```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  appLogger.e('操作失败', error: e, stackTrace: stackTrace);
  // 可选：上报到 Bugly 或其他监控平台
}
```

### 结构化日志（带标签）

```dart
appLogger.d('[UserProvider] 加载用户数据，userId: $userId');
appLogger.i('[ConfigManager] 同步配置完成，共 $count 条');
appLogger.e('[DioClient] 请求失败', error: e);
```
