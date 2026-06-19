# cs-src-payment 插件

CS 框架支付模块：PaymentManager（插件路由层）+ RevenueCatPlugin 内置支持（iOS App Store + Google Play 订阅/内购）。支持自定义支付插件扩展（如微信支付）。

**依赖**：cs-src-core（必须先安装）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-src-core 已安装
2. 检查 `pubspec.yaml` 是否已有 `cs_payment:` 依赖

### 修改 pubspec.yaml

**本地模式：**
```yaml
dependencies:
  cs_payment:
    path: ../cs/cs_payment
```

**远程模式：**
```yaml
dependencies:
  cs_payment:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_payment
      ref: main
```

### 初始化（RevenueCat）

```dart
import 'package:cs_payment/cs_payment.dart';

// CsClient.initialize 之后调用
await PaymentManager.useRevenueCat(
  iosApiKey: 'appl_your_ios_key',     // RevenueCat iOS API Key
  androidApiKey: 'goog_your_android_key', // RevenueCat Android API Key
);

// 用户登录后绑定（AuthManager.currentUserId）
await PaymentManager.setUserId(userId);
```

---

## [UPDATE] 更新步骤

`flutter pub get` 获取最新版本。

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| PAY1 | `pubspec.yaml` 包含 cs_payment 依赖 | grep `cs_payment:` |
| PAY2 | PaymentManager 初始化在主流程中 | 代码中有 `PaymentManager.useRevenueCat` |

---

## [USAGE] 常用 API 示例

### 检查权益
```dart
final isPremium = await PaymentManager.hasEntitlement('premium');
```

### 获取套餐并购买
```dart
final offerings = await PaymentManager.getOfferings();
final offering = offerings.first;
final package = offering.packages.first;

final result = await PaymentManager.purchase(package);
if (result.success) {
  print('购买成功，权益: ${result.entitlements}');
} else if (result.userCancelled) {
  print('用户取消');
} else {
  print('购买失败: ${result.errorMessage}');
}
```

### 恢复购买
```dart
await PaymentManager.restorePurchases();
```

### 自定义支付插件接入
```dart
class MyWechatPayPlugin implements PaymentPlugin {
  @override String get pluginId => 'wechat_pay';
  @override Future<void> initialize(Map<String, dynamic> config) async { ... }
  // 实现其他接口方法...
}

await PaymentManager.registerPlugin(MyWechatPayPlugin(), config: {'app_id': 'wx_xxx'});
```
