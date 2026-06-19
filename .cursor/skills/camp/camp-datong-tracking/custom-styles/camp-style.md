# 王者营地上报代码风格规范

营地项目（social-ios / flutter_module）的大同上报代码约定。生成上报代码时**优先遵循本文档**。

---

## Flutter 端代码风格

### 封装层次

每个业务模块创建独立的上报管理文件，放在 `lib/{module}/shared/dt_report.dart`，包含四个常量类 + 一个管理类：

```dart
// lib/{module}/shared/dt_report.dart
import 'dart:io';
import 'package:tencent_dtreport/plugin/tencent_dtreport.dart';

/// {Module} 模块页面ID常量
class DT{Module}PageId {
  static const myPage = 'my_page_id';
}

/// {Module} 模块元素ID常量
class DT{Module}ElementId {
  static const submitButton = 'submit_button';
}

/// {Module} 模块自定义事件常量
class DT{Module}CustomEvent {
  static const clickEnter = 'xxx_click_enter';
}

/// {Module} 模块上报参数Key常量
class DT{Module}ParamKey {
  static const gameId = 'game_id';
  static const userId = 'user_id';
}

/// {Module} 模块上报管理类
class {Module}DtReport {
  {Module}DtReport._();
  static final instance = {Module}DtReport._();

  /// 上报 XXX 点击事件
  void reportXxxClick({required String gameId}) {
    _reportEvent(DT{Module}CustomEvent.clickEnter, {
      DT{Module}ParamKey.gameId: gameId,
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

### 页面曝光（声明式）

`DTPageBox` 包裹页面最外层，参数静态不变时直接在 constructor 里传：

```dart
DTPageBox(
  pageId: DT{Module}PageId.myPage,
  params: const {'source': 'home'},
  child: /* 页面内容 */,
)
```

### 元素曝光（声明式）

```dart
DTElementBox(
  elementId: DT{Module}ElementId.submitButton,
  params: {'is_enabled': isEnabled},
  child: /* 元素内容 */,
)
```

### 命名规范

- PageId / ElementId：`snake_case`，如 `multi_game_page`、`battle_game_switcher`
- 自定义事件名：`snake_case`，如 `dt_multi_game_page`、`game_zone_pull_to_refresh`
- 参数 key：`snake_case`，全小写，如 `game_id`、`module_from`
- Dart 常量字段：`camelCase`，如 `multiGamePage`、`gameSwitcher`

---

## iOS 端代码风格

### SDK 类型

营地 iOS 使用 VideoReport SDK（`pod 'VideoReport'`），通过 `vr_pageId` / `vr_elementId` 属性声明式接入。

### 页面曝光

```objc
#import "UIView+VideoReport.h"

// 在 viewDidLoad 或 view 配置阶段
self.view.vr_pageId = @"my_page_id";
self.view.vr_setPageParams(@{@"game_id": gameId});
```

### 元素曝光 / 点击（声明式）

```objc
someButton.vr_elementId = @"submit_button";
someButton.vr_setElementParams(@{@"is_enabled": @(isEnabled)});
```

### 自定义事件（手动上报）

```objc
// iOS 端自定义事件通过灯塔 SDK 上报
#import <BeaconAPI_Base/BeaconReport.h>

BeaconEvent *event = [[BeaconEvent alloc] initWithAppKey:appKey
                                                   code:@"custom_event_name"
                                                   type:BeaconEventTypeDTRealTime
                                                success:YES
                                                 params:@{@"game_id": gameId}];
[BeaconReport.sharedInstance reportEvent:event];
```

---

## Android 端代码风格

### SDK 类型

营地 Android 使用大同采集 SDK（`videoreport-DT`）+ 灯塔上报 SDK（`BeaconReport`）。

### 页面曝光（声明式）

```java
VideoReport.setPageId(view, "my_page_id");
VideoReport.setPageParams(view, new HashMap<String, Object>() {{
    put("game_id", gameId);
}});
```

### 元素曝光 / 点击（声明式）

```java
VideoReport.setElementId(button, "submit_button");
```

### 自定义事件（手动上报）

```java
BeaconEvent event = new BeaconEvent.Builder()
    .withCode("custom_event_name")
    .withType(BeaconEvent.TypeEnum.NORMAL)
    .withParams(params)
    .build();
BeaconReport.getInstance().report(event);
```

---

## 注意事项

- **不要修改已有的 SDK 初始化代码**，只新增上报调用
- **保持现有代码风格一致**：扫描同模块已有的上报文件作为参考
- Flutter 端两个平台参数名不同：iOS 用 `udfParams`，Android 用 `params`
- 所有上报参数 value 避免传 `null`，用空字符串或 `0` 代替
