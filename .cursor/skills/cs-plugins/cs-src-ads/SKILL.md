# cs-src-ads 插件

CS 框架广告模块：AdManager（插件路由层）+ AdMobPlugin 内置支持（Banner / 插屏 / 激励视频）。支持自定义广告插件扩展（如穿山甲）。

**依赖**：cs-src-core（必须先安装）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-src-core 已安装
2. 检查 `pubspec.yaml` 是否已有 `cs_ads:` 依赖
3. 检查 iOS `Info.plist` 是否有 `GADApplicationIdentifier`

### 修改 pubspec.yaml

**本地模式：**
```yaml
dependencies:
  cs_ads:
    path: ../cs/cs_ads
```

**远程模式：**
```yaml
dependencies:
  cs_ads:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_ads
      ref: main
```

### 配置 iOS Info.plist

**必须**在 `ios/Runner/Info.plist` 添加：
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXX~XXXXX</string>
```
开发期可用测试 ID：`ca-app-pub-3940256099942544~1458002511`

### 初始化（AdMob）

```dart
import 'package:cs_ads/cs_ads.dart';

// CsClient.initialize 之后调用
await AdManager.useAdMob(
  testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // 开发期防止无效点击，上线移除
);
```

---

## [UPDATE] 更新步骤

`flutter pub get` 获取最新版本。

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| AD1 | `pubspec.yaml` 包含 cs_ads 依赖 | grep `cs_ads:` |
| AD2 | `Info.plist` 包含 GADApplicationIdentifier | grep `GADApplicationIdentifier` |

---

## [USAGE] 常用 API 示例

### Banner 广告
```dart
// 在 Widget 树中放置 Banner
AdManager.buildBannerAd(
  adUnitId: 'ca-app-pub-3940256099942544/2934735716', // iOS 测试广告位
)

// Android 测试广告位：'ca-app-pub-3940256099942544/6300978111'
```

### 插屏广告
```dart
// 预加载（进入页面时调用）
await AdManager.loadInterstitialAd(
  adUnitId: 'ca-app-pub-3940256099942544/4411468910', // iOS 测试
);

// 展示（场景切换时调用）
final shown = await AdManager.showInterstitialAd(
  adUnitId: 'ca-app-pub-3940256099942544/4411468910',
);
```

### 激励视频广告
```dart
await AdManager.loadRewardedAd(
  adUnitId: 'ca-app-pub-3940256099942544/1712485313', // iOS 测试
);

await AdManager.showRewardedAd(
  adUnitId: 'ca-app-pub-3940256099942544/1712485313',
  onRewarded: (reward) {
    print('用户获得奖励 ${reward.amount} ${reward.type}');
    // 发放游戏内奖励
  },
);
```

### 常见问题排查

- **GADInvalidInitializationException**：确认 `Info.plist` 中有 `GADApplicationIdentifier`
- **广告不显示**：开发期确认使用测试广告位 ID，避免用正式 ID 触发政策限制
