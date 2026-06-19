# Flutter 大同上报快速开始（营地项目）

营地 Flutter 端通过 `tencent_dtreport` 包桥接 iOS / Android 原生大同 SDK，提供四类上报方式。

## 依赖检测

检查 `pubspec.yaml` 中是否包含以下依赖（任意一个即可判定已集成）：

```yaml
tencent_dtreport:   # 大同 Flutter 桥接层（推荐）
```

扫描 import 关键词：
- `package:tencent_dtreport/plugin/tencent_dtreport.dart`
- `DTPageBox`、`DTElementBox`、`DTReportFlutter`
- `TencentDtreport.reportEventIOS`、`TencentDtreport.reportEventAndroid`

---

## 四类上报方式

### 1. 页面曝光 / 反曝光 — `DTPageBox`（声明式）

用 `DTPageBox` 包裹页面根组件，SDK 自动采集 `dt_pgin` / `dt_pgout`。

```dart
import 'package:tencent_dtreport/plugin/tencent_dtreport.dart';

// 在页面最外层包一个 DTPageBox
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DTPageBox(
      pageId: 'my_page_id',           // 大同平台定义的 pageId
      params: {'game_id': gameId},    // 页面公参（可选）
      child: Scaffold(/* ... */),
    );
  }
}
```

**⚠️ 注意**：元素曝光 / 点击事件依赖外层 `DTPageBox`，使用前必须确认页面有包裹。

---

### 2. 元素曝光 / 反曝光 — `DTElementBox`（声明式）

```dart
DTElementBox(
  elementId: 'submit_button',             // 大同平台定义的 elementId
  params: {'is_open': isEnabled},         // 元素私参（可选）
  child: ElevatedButton(/* ... */),
);
```

> 列表场景中同一 elementId 有多行时，加 `reuseId` 区分：
> ```dart
> DTElementBox(
>   elementId: 'feed_card',
>   reuseId: item.id,   // 用业务唯一 ID 区分行
>   child: FeedCard(item: item),
> )
> ```

---

### 3. 点击上报 — `DTReportFlutter.reportClickEvent`

依赖外层 `DTPageBox`，自动从 Page 上下文中取公参：

```dart
import 'package:tencent_dtreport/plugin/tencent_dtreport.dart';

// 按钮 onTap 中调用
onTap: () {
  DTReportFlutter.reportClickEvent(
    elementId: 'submit_button',
    // params 可选，额外私参
  );
},
```

---

### 4. 自定义事件上报 — `TencentDtreport`（推荐方式）

自定义事件两端参数结构略有差异，**不做统一封装**，按平台判断：

```dart
import 'dart:io';
import 'package:tencent_dtreport/plugin/tencent_dtreport.dart';

if (Platform.isIOS) {
  TencentDtreport.reportEventIOS(
    event: 'custom_event_name',
    udfParams: {
      'param_key': 'param_value',
      'game_id': gameId,
    },
  );
} else if (Platform.isAndroid) {
  TencentDtreport.reportEventAndroid(
    event: 'custom_event_name',
    params: {
      'param_key': 'param_value',
      'game_id': gameId,
    },
  );
}
```

> **注意**：iOS 用 `udfParams`，Android 用 `params`，不要搞混。

---

### 5. 复杂场景：手动拼接元素信息

需要取大同元素缓存中的信息并拼入自定义事件时（如双击上报）：

```dart
import 'package:tencent_dtreport/plugin/tencent_dtreport.dart';

final elementKey = ElementManager.getElementCacheKey(
  elementId: elementId,
  reuseId: reuseId,
);
final elementInfo = ElementManager().getElementInfoByKey(elementKey);

if (elementInfo != null) {
  if (Platform.isAndroid) {
    final params = ClickReporter.buildAndroidClickParams(elementInfo, {});
    TencentDtreport.reportEventAndroid(event: 'dt_doubleclck', params: params);
  } else if (Platform.isIOS) {
    final params = ClickReporter.buildIOSClickParams(elementInfo, {});
    TencentDtreport.reportEventIOS(
      event: 'dt_doubleclck',
      elementParams: params['element'] as Map<String, dynamic>,
      parentElementParams: params['prnts'] as Map<String, dynamic>,
    );
  }
}
```

---

## 营地项目代码组织规范

营地项目对每个模块使用独立的上报管理类，包含：

1. **PageId 常量类** — `DT{Module}PageId`
2. **ElementId 常量类** — `DT{Module}ElementId`
3. **自定义事件常量类** — `DT{Module}CustomEvent`
4. **参数 Key 常量类** — `DT{Module}ParamKey`
5. **上报管理类** — `{Module}DtReport`（封装具体上报方法，内部调用 `TencentDtreport`）

示例（参考 `flutter_module/lib/battle/shared/dt_report.dart`）：

```dart
class DTBattlePageId {
  static const multiGamePage = 'multi_game_page';
}

class DTBattleElementId {
  static const gameSwitcher = 'battle_game_switcher';
}

class DTBattleCustomEvent {
  static const dtMultiGamePage = 'dt_multi_game_page';
}

class BattleDtReport {
  static final instance = BattleDtReport._();
  BattleDtReport._();

  void reportSwitchGame({required int gameId, required int moduleFrom}) {
    _reportEvent(DTBattleCustomEvent.dtMultiGamePage, {
      DTBattleParamKey.gameId: gameId,
      DTBattleParamKey.moduleFrom: moduleFrom,
    });
  }

  void _reportEvent(String event, Map<String, dynamic> params) {
    if (Platform.isIOS) {
      TencentDtreport.reportEventIOS(event: event, udfParams: params);
    } else if (Platform.isAndroid) {
      TencentDtreport.reportEventAndroid(event: event, params: params);
    }
  }
}
```

---

## 标准事件（Flutter 对应说明）

| 事件 | 触发方式 |
|------|---------|
| `dt_pgin` | `DTPageBox` 自动采集 |
| `dt_pgout` | `DTPageBox` 自动采集 |
| `dt_imp` | `DTElementBox` 自动采集 |
| `dt_imp_end` | `DTElementBox` 自动采集 |
| `dt_clck` | `DTReportFlutter.reportClickEvent()` |
| 自定义事件 | `TencentDtreport.reportEventIOS/Android()` |
