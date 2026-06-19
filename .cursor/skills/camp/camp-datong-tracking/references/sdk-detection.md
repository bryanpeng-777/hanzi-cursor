# SDK 检测与技术栈识别

## 技术栈判断（扩展版）

| 检测规则 | 技术栈 | 后续流程 |
|---------|--------|---------|
| 存在 `pubspec.yaml` | Flutter 项目 | → 走 Flutter SDK 流程 |
| 存在 `package.json` | H5 项目 | → 走 H5 SDK 选型 |
| 存在 `build.gradle` 且含 `com.android` | Android 项目 | → 走 Android SDK 流程 |
| 存在 `Podfile` 或 `.xcodeproj`，且有 `.m`/`.swift` 源码 | iOS 项目 | → 走 iOS SDK 流程 |
| 均不匹配 | 其他 | → API 上报兜底 |

---

## Flutter 项目：SDK 检测

> **营地项目约定**：Flutter 端通过 `tencent_dtreport` 包桥接原生大同 SDK，**不单独接入 iOS/Android 原生 SDK**。

扫描 `pubspec.yaml` 及源码 import：

| 检测目标 | 包名 / 关键词 | SDK 类型 |
|---------|-------------|---------|
| 大同 Flutter 桥接层 | `tencent_dtreport` | tencent_dtreport |
| 声明式组件 | `DTPageBox`、`DTElementBox` | tencent_dtreport |
| 命令式上报 | `TencentDtreport`、`DTReportFlutter` | tencent_dtreport |

**选型规则**：
1. 检测到 `tencent_dtreport` → 直接使用，加载 `sdk/flutter/quickstart.md`
2. 未检测到 → **询问用户**，营地项目标准是接入 `tencent_dtreport`
3. 优先参考 `custom-styles/camp-style.md` 生成代码

**营地 Flutter 检测关键词**：
- `tencent_dtreport`
- `DTPageBox`、`DTElementBox`
- `TencentDtreport.reportEventIOS`、`TencentDtreport.reportEventAndroid`
- `DTReportFlutter.reportClickEvent`
- `BattleDtReport`（营地 battle 模块参考实现）

---

## iOS 项目：SDK 检测

> **核心原则**：不改动已有 SDK 初始化代码，只新增上报事件调用。

扫描 `Podfile` 依赖和 import 语句：

| 检测目标 | 包名 / 关键词 | SDK 类型 |
|---------|-------------|---------|
| 大同采集 SDK | `pod 'VideoReport'` / `QLVideoReport` / `vr_pageId` | videoreport-ios |
| 灯塔上报 SDK | `pod 'Beacon'` / `BeaconReport` / `BeaconAPI_Base` | beacon-ios |

**选型规则**：
1. 同时有采集 SDK + 灯塔 → 加载 `sdk/ios/videoreport/quickstart.md`（营地标准）
2. 仅灯塔 → 加载 `sdk/ios/beacon/quickstart.md`
3. 优先参考 `custom-styles/camp-style.md` 生成 OC/Swift 代码

---

## Android 项目：SDK 检测

扫描 `build.gradle` 依赖和 import：

| 检测目标 | 包名 / 关键词 | SDK 类型 |
|---------|-------------|---------|
| 大同采集 SDK | `videoreport-DT` / `VideoReport` / `setPageId` | videoreport-android |
| 灯塔上报 SDK | `com.tencent.beacon` / `BeaconReport` | beacon-android |

**选型规则**：同 iOS，优先采集 SDK，兜底灯塔，参考 `custom-styles/camp-style.md`。

---

## 文档加载对照表

| 技术栈 | 方案 | 快速开始 |
|--------|------|---------|
| Flutter | tencent_dtreport | `sdk/flutter/quickstart.md` |
| iOS | videoreport-ios | 从 datong-report 加载 `sdk/ios/videoreport/quickstart.md` |
| iOS | beacon-ios | 从 datong-report 加载 `sdk/ios/beacon/quickstart.md` |
| Android | videoreport-android | 从 datong-report 加载 `sdk/android/videoreport/quickstart.md` |
| Android | beacon-android | 从 datong-report 加载 `sdk/android/beacon/quickstart.md` |
| H5 | universal-report | 从 datong-report 加载 `sdk/h5/universal-report/quickstart.md` |

> 营地项目没有 H5 场景，Flutter / iOS / Android 是主要技术栈。
