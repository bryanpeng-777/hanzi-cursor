# Layer 2 详情：技术基础设施

> **归属超级分类**：E - 技术基础设施  
> **覆盖域**：启动/初始化/路由、Flutter-Native通信层、网络/OneAPI/接口层、基础组件/公共模块、性能监控/埋点、设置/隐私、数据库/本地存储  
> **路径根**：Flutter `flutter_module/lib/` | iOS `social-ios/src/GameApp/`  
> iOS xcodeproj 根：`social-ios/xcodeproj/`

---

## 1. 启动 / 初始化 / 路由 　　　📄 [场景展开 → L3_launch.md](L3_launch.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| Flutter 路由（内部导航） | `lib/navigator/` | — |
| TRouter 路由注册 / 跳转 | `lib/trouter/`<br>`lib/trouter/t_router_register.t_router.dart` | `Features/FlutterRouteUtils/`<br>`Features/RouteAction/` |
| 启动器（App 启动序列） | — | `Features/WEGLauncher/`<br>`xcodeproj/WEGLauncher/` |
| 模块注册逻辑 | — | `Features/ModuleLogic/` |
| ABTest 分组 / 分流判断 | — | `Features/ABTest/`<br>`Features/Imps/WEGABTestImp.m` |
| 任务系统 | — | `Features/Task/` |
| 开屏页 / 广告 | — | `Features/WEGLauncher/`（splash 子目录） |
| 冷启动性能 | `lib/performance/`（启动相关） | `Features/APM/` |
| App 壳层基础（主窗口/反馈服务提示） | — | `Features/Imps/WEGSmobaHelperImp.m` |
| 最小化 / 小窗（广场/语音/直播等场景） | — | `Features/Imps/WEGSmobaHelperMinimizeImp.m` |
| Cube 模块化容器 | — | `xcodeproj/WEGCube/` |
| iOS 路由拦截 / OpenURL | — | `Features/Manager/WEGRouteManager/` |
| 路由切换（A/B 路由选择） | — | `Features/Manager/WEGRouteSwitcher/` |
| 强制启动遮罩 | — | `Features/Component/ForcedLauchingMask/` |
| iOS 扩展（App Clip） | — | `xcodeproj/SmobaClip/` |
| iOS 扩展（桌面小组件） | — | `xcodeproj/SmobaWidget/` |
| iOS 扩展（Siri Intent） | — | `xcodeproj/SmobaIntent/` |
| Flutter 业务路由入口层 | `lib/business/`（58个子目录） | — |

**关键文件**：  
- `lib/trouter/t_router_register.t_router.dart`（Flutter 路由注册表）  
- `Features/WEGLauncher/`（iOS 启动序列入口）  
- `xcodeproj/WEGCube/`（Cube 模块化容器）  
- `Features/Manager/WEGRouteManager/`（iOS 路由/OpenURL/拦截管理）

---

## 2. Flutter-Native 通信层 / 胶水层 　　　📄 [场景展开 → L3_bridge.md](L3_bridge.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| Flutter-Native 胶水（Pigeon 接口调用侧） | `lib/camp_business/`（Pigeon 生成代码） | `Features/WEGGlue/`<br>`xcodeproj/WEGGlue/` |
| Flutter 业务胶水（业务扩展） | — | `Features/WEGFlutterBiz/`<br>`xcodeproj/WEGFlutterBiz/` |
| Flutter 集成模块 | — | `xcodeproj/WEGFlutter/` |
| Flutter 路由通信（TRouter 跨端） | `lib/trouter/` | `Features/FlutterRouteUtils/` |
| ZTSDK 通信管理 | — | `xcodeproj/WEGGlue/WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m` |
| 染色 / 染色数据（ZTSDK） | — | `xcodeproj/WEGGlue/WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m`<br>`xcodeproj/OneAPIBiz/OneAPIBiz/Classes/ZTSDK/WEGZTSDKOneAPI.m` |
| Pigeon 接口定义（源） | `flutter_module/pigeons/` | — |
| C++ 桥接层 | — | `Features/WEGCpp/` |
| Flutter 业务管理器 | — | `Features/Manager/WEGFlutterBusinessManager/` |

**特别说明**：
- `WEGGlue` 是 Flutter ↔ iOS 通信的总枢纽，问题排查从此入手
- `ZTSDK` 相关（染色、ZTSDK 请求）：两端代码分别在 `ZTSDKManager.m` 和 `WEGZTSDKOneAPI.m`
- `WEGCpp` 是 C++ 桥接代码，用于底层通信

---

## 3. 网络 / OneAPI / 接口层 　　　📄 [场景展开 → L3_network.md](L3_network.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| Flutter 网络请求封装 | `lib/camp_business/network/`<br>`lib/common/`（network 子目录） | — |
| OneAPI 业务封装（iOS） | — | `xcodeproj/OneAPIBiz/`<br>`Features/OneAPIBiz/` |
| OneAPI Hook（请求拦截） | — | `Features/oneAPIHook/` |
| OneData 数据框架 | `lib/one_data/` | — |
| 长连接（长轮询/WebSocket） | — | `xcodeproj/WEGLongLink/` |
| Protobuf 请求封装 | — | `Features/Imps/WEGProtobufRequestImp.m` |
| Webview 业务 | `lib/camp_webview/` | `Features/webHook/` |
| Hippy（腾讯跨端框架） | — | `Features/hippyHook/` |
| Tux 信息流 / 调研 | — | `Features/Tux/` |
| 小程序 / MiniApp | — | `Features/MiniApp/` |
| Open 平台 / SDK 授权 | — | `Features/OpenSDK/` |
| 网络状态监测 | `lib/common/`（network_status） | `Features/MnaDoubleTunnel/` |
| 双通道网络（MNA） | — | `Features/MnaDoubleTunnel/` |
| VPN 隧道 | — | `xcodeproj/PacketTunnel/` |
| WebService 管理 | — | `Features/Manager/WebServiceManager/` |
| CommonOpenApi 启动器 | — | `Features/Component/CommonOpenApiLauncher/` |
| WebOpenApi 启动器 | — | `Features/Component/WebOpenApiLauncher/` |

**关键 Imp**：`WEGProtobufRequestImp.m`  
**关键路径**：`xcodeproj/OneAPIBiz/`（OneAPI 核心），`lib/one_data/`（Flutter 数据层）

---

## 4. 基础组件 / 公共模块 　　　📄 [场景展开 → L3_common.md](L3_common.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 公共工具 / 基础库 | `packages/camp_common/` | `Features/Common/`<br>`Features/WEGBase/`<br>`xcodeproj/WEGBase/`<br>`xcodeproj/CampCore/` |
| UI 组件库（257+ 组件） | `packages/camp_ui/` | `Features/WEGUI/` |
| 基础 ViewController / UI 基类 | — | `Features/Imps/WEGBaseVCImp.m` |
| 全局浮层 / 弹窗 | `lib/camp_business/modal_sheet/`<br>`lib/camp_business/shift_overlay/` | — |
| 键盘处理 | `lib/camp_business/keyboard/` | — |
| 主题 / 暗黑模式 | `lib/camp_business/theme/` | — |
| SVG 渲染 | — | `Features/CampSVG/` |
| 拖拽点 | — | `xcodeproj/DraggableDot/` |
| 专属服务 | — | `Features/ExclusiveService/` |
| 图片选择 / 相册 | `lib/camp_business/album_picker/` | — |
| 卡片布局框架 | — | `Features/CardLayout/` |
| 公共 Imp（通用能力） | — | `Features/Imps/WEGCommonImp.m`<br>`Features/Imps/WEGSmobaHelperCommonImp.m` |
| **红点 / 角标管理** | — | `Features/Manager/WEGReddotManager/` |
| 版本更新检查 | — | `Features/Component/UpdateChecker/` |
| 青少年保护 / 合规 | — | `Features/Manager/WEGTeenProtectManager/` |
| 人脸核验 | — | `Features/Manager/WEGFaceVerifyManager/` |
| 路由管理器（iOS 级） | — | `Features/Manager/WEGRouteManager/` |
| 路由切换 | — | `Features/Manager/WEGRouteSwitcher/` |
| 帧任务调度 | — | `Features/Manager/WEGFrameTaskManager/` |
| 文件上传 | — | `Features/Manager/WEGFileUploadHandler/` |
| 文件缓存 | — | `Features/Component/FileCache/` |
| 请求预加载 | — | `Features/Component/CampRequestPreload/` |
| 面板展示管理 | — | `Features/Manager/WEGShowPanelManager/` |
| 日志处理 | — | `Features/Manager/WEGLogHandler/` |
| 广告管理 | — | `Features/Manager/WEGADManager/` |
| 应用图标（动态 Icon） | — | `Features/Manager/WEGAppIconManager/` |
| 下载策略 / 灰度资源下发 | — | `Features/WEGDownloadStrategy/` |
| MVVM 表格基础组件 | — | `Features/Component/WEGMVVMTable/` |
| 粘性气泡 UI | — | `Features/Component/WEGStickyBubble/` |
| 功能开关 / 特性操作 | — | `Features/Component/Operator/` |
| **数据库管理（iOS）** | — | `Features/Manager/DatabaseManager/` |
| **文件存储管理** | — | `Features/Manager/FileStorage/` |
| **保活管理** | — | `Features/Manager/LongLiveManager/` |
| **陀螺仪管理** | — | `Features/Manager/WEGGyroscopeManager/` |
| **依赖注入工厂** | — | `Features/Component/ProviderFactory/` |
| **离线底部数据源** | — | `Features/Component/OffaccBottomDataSource/` |
| **表格 Cell 封装** | — | `Features/Component/WEGWrapperTableCell/` |
| **通用控制器** | — | `Features/Controller/` |
| **数据模型** | — | `Features/Model/` |
| **协议定义** | — | `Features/Protocol/` |
| **工具类** | — | `Features/Utils/` |
| **视图基类** | — | `Features/View/` |
| **常量定义 Pod** | — | `xcodeproj/WEGConstant/` |
| **核心基础 Pod** | — | `xcodeproj/CampCoreBase/` |
| **共享库 Pod** | — | `xcodeproj/WEGBaseSharingLibs/` |
| **共享模型 Pod** | — | `xcodeproj/WEGBaseSharingModel/` |
| **TGA 修复** | — | `Features/TGAFix/` |

**关键 Imp**：`WEGCommonImp.m`、`WEGBaseVCImp.m`

---

## 5. 性能监控 / 埋点 　　　📄 [场景展开 → L3_monitor.md](L3_monitor.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 性能服务（赛季/战力数据） | `lib/performance/service/` | — |
| 伽利略埋点（iOS）| 各业务目录内调用 `OTTrace` | 各 Feature 目录内 `*.m` 文件 |
| 伽利略埋点（Flutter） | 各 `lib/` 业务目录内 `TaskSpan` 调用 | — |
| APM 监控 | — | `Features/APM/` |
| 性能监控模块（iOS） | — | `Features/WEGPerformanceMonitor/` |
| 双通道网络监控 | — | `Features/MnaDoubleTunnel/` |
| RMonitor（Flutter） | `lib/common/`（rmonitor 相关） | — |
| OneEvent 事件配置（iOS） | — | `Features/OneEventBiz/` |
| CampTools 营地工具 Pod（伽利略/WebService/调试） | — | `xcodeproj/CampTools/` |
| MTA 数据上报 | — | `Features/Manager/MTAManager/` |
| **TGA 管理** | — | `Features/Manager/WEGTgaManager/` |

**业务基座层（Flutter）**：  
`lib/camp_business/base/`：营地业务层基座（通用组件/工具/伽利略上报/统计/MethodChannel/ViewModel基类）  
`lib/camp_business/one/`：OneEvent 事件总线命名约定 + OneApi 系统 UI 调用  
`lib/camp_business/types/`：类型与协议聚合（JSON 模型/Protobuf 导出）  
`lib/business/`：Flutter 业务路由入口层（58 个子目录，每个为独立业务页面入口）

**关键说明**：
- iOS 伽利略：使用 `OTTrace`、`OTTraceTypeBefore`（前置上报）
- Flutter 伽利略：使用 `TaskSpan`、`TaskSpan.campTypeBefore`
- 默认使用**前置上报（Before Trace）**

---

## 6. 设置 / 隐私 　　　📄 [场景展开 → L3_setting.md](L3_setting.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 设置主页 | `lib/setting/` | `Features/Setting Willremove/` |
| 新版设置页 | `lib/business/new_setting/` | — |
| 设置 v2 | `lib/business/setting2/` | — |
| 内容可见性设置 | `lib/article_visibility/` | — |
| 数据安全 | — | `Features/DataSecurity/` |
| 环境配置（测试/正式环境切换） | — | `Features/Imps/WEGSmobaHelperEnvironmentImp.m` |
| 隐私协议 | `lib/camp_business/privacy/`（如有） | `Features/Imps/WEGSmobaHelperCommonImp.m` |
| 开关 / RDelivery 配置 | `lib/common/`（config 相关） | 各模块读取配置的地方 |
| 青少年模式页面 | `lib/business/teenager_mode/` | — |
| 截图设置 | `lib/business/screenshot_setting/` | — |
| 关于页面 | `lib/business/about/` | — |

**特别说明**：  
- **RDelivery / 开关配置值不符合预期**：检查当前 App 拉取开关的环境（测试 vs 正式）  
- **环境配置**：`WEGSmobaHelperEnvironmentImp.m` 控制 App 当前连接的服务器环境

---

## 7. 数据库 / 本地存储 　　　📄 [场景展开 → L3_common.md](L3_common.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| Drift ORM / SQLite（Flutter） | `lib/database/` | — |
| 数据库管理（iOS） | — | `Features/Manager/DatabaseManager/` |
| 文件存储 | — | `Features/Manager/FileStorage/` |
| 文件缓存 | — | `Features/Component/FileCache/` |

---

## 附录：常用 Imp 速查（基础设施域）

| Imp 文件 | 功能 |
|---------|------|
| `WEGProtobufRequestImp.m` | Protobuf 网络请求 |
| `WEGBaseVCImp.m` | 基础 ViewController |
| `WEGCommonImp.m` | 公共基础能力 |
| `WEGSmobaHelperCommonImp.m` | 通用公共能力（另一版） |
| `WEGSmobaHelperEnvironmentImp.m` | 环境配置（测试/正式） |
| `WEGSmobaHelperImp.m` | App 壳层（主窗口/反馈服务） |
| `WEGSmobaHelperMinimizeImp.m` | 小窗/最小化场景管理 |
| `WEGABTestImp.m` | ABTest 分流 |
| `WEGADManagerImp.m` | 广告管理 |
| `WEGAnniversaryImp.m` | 周年庆活动 |
| `WEGMTANewsReportImp.m` | MTA 资讯上报 |
| `WEGSmobaHelperTestImp.m` | 测试辅助 |

---

## 关键技术文件速查

| 场景 | 文件 |
|------|------|
| 染色 / ZTSDK 数据问题 | `xcodeproj/WEGGlue/WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m` |
| OneAPI 网络请求封装 | `xcodeproj/OneAPIBiz/OneAPIBiz/Classes/` |
| Protobuf nil crash | `xcodeproj/WEGGlue/WEGGlue/Classes/WEGCppBiz/request/WEGProtobufRequest.mm` |
| Flutter 路由注册表 | `lib/trouter/t_router_register.t_router.dart` |
| Pigeon 接口定义 | `flutter_module/pigeons/` |
| C++ 桥接层 | `Features/WEGCpp/` |

---

*最后更新：2026-03-30（新增：数据库/本地存储域、C++桥接、Manager/Component/xcodeproj完整覆盖、lib/business条目）*
