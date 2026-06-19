# L3 场景索引：基础组件 / 公共模块

> **所属域**：基础组件 / 公共模块 | **上级 L2**：L2_INFRA.md  
> **主路径**：`packages/camp_common/` / `packages/camp_ui/` / `Features/Common/` / `Features/WEGUI/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 全局弹窗 / Toast 不显示 | 弹窗不显示、Toast | `lib/camp_business/modal_sheet/` | 搜 showModalSheet / CampToast |
| 全局浮层显示位置异常 | 浮层、overlay | `lib/camp_business/shift_overlay/` | 搜 ShiftOverlay / overlayEntry |
| 键盘弹起遮挡内容（通用问题） | 键盘遮挡 | `lib/camp_business/keyboard/` | 搜 KeyboardAware / resizeToAvoidBottomInset |
| UI 组件（按钮/输入框等）显示异常 | UI 组件、样式 | `packages/camp_ui/` | 搜对应组件名 CampButton / CampInput |
| 暗黑模式 / 主题切换异常 | 暗黑、主题、换肤 | `lib/camp_business/theme/` | 搜 ThemeManager / isDarkMode |
| 图片选择组件 crash / 无法选图 | 图片选择 | `lib/camp_business/album_picker/` | 搜 AlbumPicker + 相册权限 |
| SVG 图片不显示（iOS） | SVG、图标不显示 | `Features/CampSVG/` | 搜 CampSVG / SVGImageView |
| 拖拽点交互不响应 | 拖拽、悬浮按钮 | `xcodeproj/DraggableDot/` | 搜 DraggableDot / panGesture |
| 卡片布局错乱（iOS） | 卡片布局、CardLayout | `Features/CardLayout/` | 搜 CardLayout / layoutCards |
| 专属服务不可用 | 专属服务 | `Features/ExclusiveService/` | 搜 ExclusiveService |
| 公共工具方法报错 | 工具函数、utils | `packages/camp_common/` | 搜对应 util 方法名 |
| iOS 基础 VC 初始化异常 | 基础页面、VC crash | `Features/Imps/WEGBaseVCImp.m` | 搜 BaseVC / viewDidLoad |
| 红点不消失 / 红点逻辑异常 | 红点、未读红点 | `Features/Manager/WEGReddotManager/` | 搜 WEGReddotManager / reddotId |
| 青少年保护弹窗 / 限制功能 | 青少年、未成年 | `Features/Manager/WEGTeenProtectManager/` | 搜 TeenProtect / teenModeCheck |
| 人脸核验失败 / 不弹出 | 人脸、实名认证 | `Features/Manager/WEGFaceVerifyManager/` | 搜 FaceVerify / startVerify |
| 版本更新弹窗不显示 | 版本检查、升级提示 | `Features/Component/UpdateChecker/` | 搜 UpdateChecker / checkVersion |
| 文件上传失败 | 文件上传、图片上传 | `Features/Manager/WEGFileUploadHandler/` | 搜 WEGFileUploadHandler / uploadFile |
| 下载策略 / 灰度资源下发异常 | 下载策略、灰度 | `Features/WEGDownloadStrategy/` | 搜 DownloadStrategy / StrategyManager |
| 面板展示管理异常 | 面板、弹窗管理 | `Features/Manager/WEGShowPanelManager/` | 搜 ShowPanelManager |
| 帧任务调度异常 / 卡顿 | 帧任务、调度 | `Features/Manager/WEGFrameTaskManager/` | 搜 FrameTaskScheduler |
| 数据库操作异常（Flutter Drift） | Drift、SQLite、数据库 | `lib/database/` | 搜 AppDatabase / drift migration |
| 数据库操作异常（iOS） | iOS 数据库 | `Features/Manager/DatabaseManager/` | 搜 DatabaseManager / sqliteExecute |
| 文件存储读写失败 | 文件存储、本地文件 | `Features/Manager/FileStorage/` | 搜 FileStorage / writeFile |
| 文件缓存问题 / 缓存清理 | 文件缓存、cache | `Features/Component/FileCache/` | 搜 FileCache / clearCache |
| App 保活失败 / 后台被杀 | 保活、后台运行 | `Features/Manager/LongLiveManager/` | 搜 LongLiveManager / keepAlive |
| 陀螺仪数据异常 | 陀螺仪、传感器 | `Features/Manager/WEGGyroscopeManager/` | 搜 WEGGyroscopeManager / gyroscope |
| 日志文件异常 / 日志不写入 | 日志、xlog | `Features/Manager/WEGLogHandler/` | 搜 WEGLogHandler / logBizManager |
| 广告不显示 / 广告异常 | 广告、AD | `Features/Manager/WEGADManager/` | 搜 WEGADManager / showAd |
| 动态 App 图标切换异常 | 动态图标、App 图标 | `Features/Manager/WEGAppIconManager/` | 搜 WEGAppIconManager / setAlternateIcon |
| 依赖注入 / Provider 创建失败 | Provider、工厂 | `Features/Component/ProviderFactory/` | 搜 ProviderFactory / createProvider |
| MVVM 表格组件异常 | MVVM 表格 | `Features/Component/WEGMVVMTable/` | 搜 MVVMTableView / cellForRow |
| 请求预加载不生效 | 预加载、预请求 | `Features/Component/CampRequestPreload/` | 搜 RequestPreload / preloadRequest |
| 功能开关 / Operator 不生效 | Operator、功能开关 | `Features/Component/Operator/` | 搜 Operator / isFeatureEnabled |
| 离线数据源异常 | 离线、OffaccBottom | `Features/Component/OffaccBottomDataSource/` | 搜 OffaccBottomDataSource |
| 粘性气泡 UI 异常 | 粘性气泡、bubble | `Features/Component/WEGStickyBubble/` | 搜 StickyBubble |
| 表格 Cell 封装异常 | 表格Cell | `Features/Component/WEGWrapperTableCell/` | 搜 WrapperTableCell |
| 公共 Imp 能力异常 | 公共能力 | `Features/Imps/WEGCommonImp.m`<br>`Features/Imps/WEGSmobaHelperCommonImp.m` | 搜对应方法名 |

---

## 排查起点建议

- **Flutter 侧公共组件**：`packages/camp_ui/` + `packages/camp_common/`
- **iOS 侧公共组件**：`Features/Common/` + `Features/WEGUI/`
- **键盘/弹窗（跨所有功能）**：直接定位 `lib/camp_business/keyboard/` 或 `lib/camp_business/modal_sheet/`
- **数据库问题**：Flutter 用 `lib/database/`（Drift ORM），iOS 用 `Features/Manager/DatabaseManager/`
- **Manager 类问题**：30 个 Manager 在 `Features/Manager/` 下，按名字搜索即可
- **Component 类问题**：15 个 Component 在 `Features/Component/` 下

*最后更新：2026-03-30（新增：数据库/文件存储/缓存/保活/陀螺仪/日志/广告/依赖注入/Operator/气泡 等 17 个新场景）*
