# cs-src-push 插件

CS 框架推送通知模块：Firebase FCM token 注册、前台/后台消息接收、silent push 配置同步。

**依赖**：cs-src-core + cs-src-auth（必须先安装）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-src-core 和 cs-src-auth 已安装
2. 检查 `pubspec.yaml` 是否已有 `cs_push:` 依赖
3. 检查项目是否配置了 Firebase（`firebase_options.dart` 存在）

### 修改 pubspec.yaml

**本地模式：**
```yaml
dependencies:
  cs_push:
    path: ../cs/cs_push
```

**远程模式：**
```yaml
dependencies:
  cs_push:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_push
      ref: main
```

### 初始化

```dart
import 'package:cs_push/cs_push.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 在 CsClient 和 AuthManager 初始化之后
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await PushManager.initialize();

// 可选：注册回调
PushManager.onForegroundMessage = (message) {
  print('前台消息: ${message.data}');
};
PushManager.onNotificationTap = (message) {
  // 处理通知点击跳转
};
```

---

## [UPDATE] 更新步骤

`flutter pub get` 获取最新版本。

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| P1 | `pubspec.yaml` 包含 cs_push 依赖 | grep `cs_push:` |
| P2 | Firebase 初始化在 PushManager 之前 | 代码顺序检查 |

---

## [USAGE] 常用 API 示例

```dart
// 获取当前 FCM token
final token = await PushManager.getToken();

// 监听前台消息
PushManager.onForegroundMessage = (message) {
  if (message.data['type'] == 'config_sync') {
    // cs_core 自动处理
    return;
  }
  // 业务处理
};
```

### 常见问题排查

- **iOS 收不到通知**：检查 Capabilities → Push Notifications 是否开启
- **Android FCM token 为 null**：确认 `google-services.json` 已放置在 `android/app/` 目录
