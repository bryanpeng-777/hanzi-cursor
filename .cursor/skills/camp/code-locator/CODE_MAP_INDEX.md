# CODE MAP 总索引（Layer 1）

> **用法**：扫描关键词列 / 逆向查找表，命中后读对应 L2 或直接读 L3 文件。  
> **根目录**：`/Users/bryanpeng/work_tree_bugfix/`  
> Flutter 根：`flutter_module/lib/` | iOS 根：`social-ios/src/GameApp/`

---

## A. 用户与社交 → `L2_USER_SOCIAL.md`

| 域 | 关键词（快速匹配用） | 主路径提示 |
|----|-------------------|-----------|
| 登录 / 账号 | 登录、注销、退出、手机绑定、游戏授权、账号、token、session、隐私协议弹窗、实名 | `lib/camp_login/` / `Features/CampLogin/` |
| 用户中心 / 个人主页 | 个人主页、名片、个人卡片、备注、关注、粉丝、资料编辑、勋章、我的页面、mine | `lib/user_center/` / `WEGProfileImp.m` |
| 社交 / 好友关系 | 好友、加好友、白名单、推荐用户、游戏昵称搜索、好友申请详情、联系人 | `lib/social/` / `lib/add_game_friends/` |
| 聊天 / 消息 | 单聊、多人聊天、弹幕、频道、群、IM、消息撤回、语音消息、@提及、TCP | `lib/chat/` / `WEGChatRoomImp.m` / `Features/Channel/` |
| 通知 / 消息中心 | 系统通知、推送、消息中心、Push、通知设置、角标 | `lib/system_notify/` / `Features/XGPush/` |
| 举报 / 黑名单 | 举报、拉黑、屏蔽、黑名单管理 | `lib/report/` / `lib/blacklist_user/` |

---

## B. 内容与创作 → `L2_CONTENT.md`

| 域 | 关键词（快速匹配用） | 主路径提示 |
|----|-------------------|-----------|
| 动态 / Feed | 推荐首页、动态卡片、内容详情、评论、收藏、投票、截图投递、点赞、Feed 卡片 | `lib/recommend_home/` / `lib/camp_business/feed_cards/` |
| 社区 / 话题 / 专栏 | 社区、话题、专栏、资讯、同人、AI聊天、王者棋盘、流量券、专题 | `lib/community/` / `lib/topic/` |
| 搜索 | 搜索、全局搜索、昵称搜索、搜索历史、热门词 | `lib/search/` / `WEGSearchImp.m` |
| 分享 | 分享、转发、二维码、分享渠道、分享卡片、下载分享 | `lib/camp_business/share/` / `Features/CampShare/` |
| 内容编辑器 / 发布 | 编辑器、发帖、@联系人、文字链接、签到落地页、剪贴板、草稿、图片选择 | `lib/editor/` / `WEGEditorImp.m` |
| 活动 / 运营 | 兴趣选择、签到、活动、黑灯、发光、用户行为追踪、运营弹窗、周年庆 | `lib/checkin_landing/` / `Features/Emitter/` |

---

## C. 媒体与游戏 → `L2_GAME.md`

| 域 | 关键词（快速匹配用） | 主路径提示 |
|----|-------------------|-----------|
| 直播 | 直播、看战、直播间、拉流、推流、原生直播、直播礼物、直播预告、直播回放 | `lib/watchbattle_living/` / `Features/GameLiving/` |
| 短视频 | 短视频、视频播放、高光、精彩时刻、剧本生成、视频封面 | `lib/short_video/` / `Features/VideoPlayer/` |
| 战绩 / 对局 | 战绩、对局、KOH、OS、NGR、好友战绩、AI分析、军功、荣耀排行、阵容 | `lib/battle/` / `lib/os/` / `lib/friends-record/` |
| 英雄 / 装备 | 英雄、装备、连招、英雄排行、出场率、套装同步、OS阵容、皮肤 | `lib/hero_rank/` / `WEGEquipImp.m` |
| 赛事 | 赛事、赛程、回放、赛事列表、精彩赛段、赛事订阅 | `lib/match/` / `lib/match_all_list/` |
| 组队 / 约战 | 组队、约战、语音匹配、副本、游戏伙伴、组队加速、预制组队、段位匹配 | `lib/gangup/` / `Features/WEGGangUp/` |
| 游戏广场 / 游戏区 | 游戏功能、游戏矩阵、多游戏、新用户、新手引导、摇一摇、赛季战力、段位、启动游戏 | `lib/game/` / `Features/GameZone/` |
| 战队 / 俱乐部主页 | 战队、俱乐部、战队资料、战队荣誉、战队动态、圈子 | `lib/team_profile/` |

---

## D. 商业化 → `L2_COMMERCE.md`

| 域 | 关键词（快速匹配用） | 主路径提示 |
|----|-------------------|-----------|
| 商城 / 道具 / 充值 | 商城、道具、充值、内购、苹果支付、限定权益、钻石、黑卡、IAP、订单 | `lib/mall/` / `WEGStoreProductImp.m` |
| 个人商城 / 橱窗 | 个人商城、橱窗、带货、商品管理、橱窗标签 | `lib/personal_mall/` |

---

## E. 技术基础设施 → `L2_INFRA.md`

| 域 | 关键词（快速匹配用） | 主路径提示 |
|----|-------------------|-----------|
| 启动 / 初始化 / 路由 | 启动器、路由、ABTest、任务系统、模块逻辑、小窗最小化、Cube容器、开屏、路由拦截 | `lib/navigator/` / `Features/WEGLauncher/` |
| Flutter-Native 通信层 | 胶水层、Pigeon、Flutter通信、ZTSDK、染色数据、WEGGlue | `lib/trouter/` / `Features/WEGGlue/` |
| 网络 / OneAPI / 接口层 | 网络请求、OneAPI、长连接、Protobuf、Webview、小程序、Hippy、Tux信息流、OpenSDK | `lib/camp_business/network/` / `xcodeproj/OneAPIBiz/` |
| 基础组件 / 公共模块 | 公共工具、UI组件、弹窗、键盘、主题、SVG、拖拽点、版本更新、红点、青少年保护、人脸核验、文件上传、数据库 | `packages/camp_common/` / `Features/Common/` |
| 性能监控 / 埋点 | 伽利略、埋点、OTTrace、TaskSpan、APM、性能服务、双通道、MTA、OneEvent、CampTools | `lib/performance/` / `Features/APM/` |
| 设置 / 隐私 | 设置、隐私、内容可见性、数据安全、环境配置、测试环境、青少年模式 | `lib/setting/` / `WEGSmobaHelperEnvironmentImp.m` |
| 数据库 / 本地存储 | 数据库、Drift、SQLite、本地存储、文件存储、缓存 | `lib/database/` / `Features/Manager/DatabaseManager/` |

---

## 快速关键词速查（模糊词 → 精确域）

| 如果用户说的是… | 对应域 | 直达 L3 |
|--------------|-------|---------|
| 崩溃、crash | 先看报错堆栈文件名，走模式B | 按堆栈文件定位 |
| 首页 | 推荐首页 / 游戏广场（看上下文） | L3_feed / L3_gamezone |
| 消息 | 聊天消息 / 通知消息（看上下文） | L3_chat / L3_notify |
| 资讯 | 官方资讯/新闻 | L3_community |
| 数据上报 | 伽利略埋点 / 性能监控 | L3_monitor |
| 开关 / RDelivery | 环境配置 / 基础组件 | L3_setting |
| ZTSDK / 染色 | Flutter-Native 通信层 | L3_bridge |
| 评论 | 动态 Feed 内的评论组件 | L3_feed |
| 隐私 | 设置/隐私 or 内容可见性 | L3_setting |
| 红点 / 角标 / Badge | 红点管理 | L3_common |
| 青少年 / 未成年人 | 青少年保护 | L3_common |
| 下载 / 拉新 | 下载分享面板 or 下载策略 | L3_share / L3_common |
| 人脸 / 实名 | 人脸核验 | L3_common |
| 版本更新 / 升级 | 版本检查 | L3_common |
| Cube / 模块容器 | Cube 模块化 | L3_launch |
| 路由管理 | WEGRouteManager | L3_launch |
| 战队 / 俱乐部 | 战队主页 | L3_team_profile |
| 阵容 / 出装方案 | OS 阵容 or 套装同步 | L3_hero |
| 好友战绩 | 好友对战记录 | L3_battle |
| 个人橱窗 | 个人商城 | L3_commerce |
| 弹幕 | 直播弹幕 / 聊天弹幕 | L3_chat / L3_live |
| 关注 / 粉丝 | 用户中心/社交 | L3_profile / L3_social |
| 个人主页 / 我的 | 用户中心 | L3_profile |
| 名片 / 卡片 | 个人名片 | L3_profile |
| 编辑器 / 发帖 | 内容编辑器 | L3_editor |
| 图片 / 相册 | 图片选择器 | L3_editor / L3_common |
| 直播间 / 看战 | 直播 | L3_live |
| 数据库 / SQLite | 数据库 | L3_common |
| 网络请求 / 接口 | 网络层 | L3_network |
| Webview / H5 | 网络/接口 | L3_network |
| 小程序 | MiniApp | L3_network |
| 推送 / Push | 通知 | L3_notify |
| 投票 | Feed 投票 | L3_feed |
| 签到 | 活动签到 | L3_activity |
| 收藏 / 我的收藏 | 动态 Feed | L3_feed |
| 陀螺仪 | 基础组件（陀螺仪管理器） | L3_common |
| 广告 | 基础组件（广告管理器） | L3_common |
| App图标 / 动态图标 | 基础组件 | L3_common |
| Widget / 桌面小组件 | iOS 扩展 | L3_launch |
| 文件上传 | 基础组件 | L3_common |
| 文件缓存 | 基础组件 | L3_common |

---

## iOS Features 目录速查（65+ 目录 → 域映射）

| Features 目录 | 所属域 | L3 文件 |
|--------------|--------|---------|
| `ABTest/` | 启动/路由 | L3_launch |
| `APM/` | 性能监控 | L3_monitor |
| `BattleRole/` | 战绩 | L3_battle |
| `CampLogin/` | 登录 | L3_login |
| `CampSVG/` | 基础组件 | L3_common |
| `CampShare/` | 分享 | L3_share |
| `CardLayout/` | 基础组件 | L3_common |
| `Channel/` | 聊天(频道) | L3_chat |
| `Common/` | 基础组件 | L3_common |
| `Controller/` | 基础组件(通用控制器) | L3_common |
| `Danmu/` | 聊天(弹幕) | L3_chat |
| `DataSecurity/` | 设置 | L3_setting |
| `Emitter/` | 活动 | L3_activity |
| `ExclusiveService/` | 基础组件 | L3_common |
| `FlutterRouteUtils/` | 启动/路由 | L3_launch |
| `GameAuth/` | 登录 | L3_login |
| `GameLiving/` | 直播 | L3_live |
| `GameMatrix/` | 游戏广场 | L3_gamezone |
| `GamePartner/` | 组队 | L3_team |
| `GameZone/` | 游戏广场 | L3_gamezone |
| `GangupVoice/` | 组队 | L3_team |
| `MiniApp/` | 网络 | L3_network |
| `MnaDoubleTunnel/` | 网络/监控 | L3_network |
| `Model/` | 基础组件(数据模型) | L3_common |
| `ModuleLogic/` | 启动/路由 | L3_launch |
| `MultipleChat/` | 聊天 | L3_chat |
| `NewUserHome/` | 游戏广场 | L3_gamezone |
| `NoviceGuide/` | 游戏广场 | L3_gamezone |
| `OneAPIBiz/` | 网络 | L3_network |
| `OneEventBiz/` | 监控 | L3_monitor |
| `OpenSDK/` | 网络 | L3_network |
| `PLManager/` | 直播 | L3_live |
| `PremadeTeam/` | 组队 | L3_team |
| `Protocol/` | 基础组件(协议定义) | L3_common |
| `RouteAction/` | 启动/路由 | L3_launch |
| `ScreenShotToSubmit/` | Feed | L3_feed |
| `Setting Willremove/` | 设置 | L3_setting |
| `ShakeDriftBottle/` | 游戏广场 | L3_gamezone |
| `ShearPlateManager/` | 编辑器 | L3_editor |
| `TGAFix/` | 基础组件 | L3_common |
| `TVKSerialPlayer/` | 短视频 | L3_video |
| `Task/` | 启动/路由 | L3_launch |
| `Tux/` | 网络 | L3_network |
| `UserActionTrack/` | 活动 | L3_activity |
| `Utils/` | 基础组件(工具) | L3_common |
| `View/` | 基础组件(视图) | L3_common |
| `VideoPlayer/` | 短视频 | L3_video |
| `WEGBase/` | 基础组件 | L3_common |
| `WEGCpp/` | 通信层(C++桥) | L3_bridge |
| `WEGDownloadStrategy/` | 基础组件 | L3_common |
| `WEGFlutterBiz/` | 通信层 | L3_bridge |
| `WEGGangUp/` | 组队 | L3_team |
| `WEGGameAuth/` | 登录 | L3_login |
| `WEGGlue/` | 通信层 | L3_bridge |
| `WEGLauncher/` | 启动/路由 | L3_launch |
| `WEGLucidityHost/` | 直播 | L3_live |
| `WEGPerformanceMonitor/` | 监控 | L3_monitor |
| `WEGUI/` | 基础组件 | L3_common |
| `XGPush/` | 通知 | L3_notify |
| `hippyHook/` | 网络 | L3_network |
| `oneAPIHook/` | 网络 | L3_network |
| `webHook/` | 网络 | L3_network |

---

## iOS xcodeproj 子工程速查

| xcodeproj 目录 | 所属域 | L3 文件 |
|---------------|--------|---------|
| `CampCore/` | 基础组件(核心Pod) | L3_common |
| `CampCoreBase/` | 基础组件(核心基础) | L3_common |
| `CampTools/` | 监控(伽利略配置+调试) | L3_monitor |
| `DraggableDot/` | 基础组件 | L3_common |
| `OneAPIBiz/` | 网络 | L3_network |
| `WEGBase/` | 基础组件 | L3_common |
| `WEGBaseSharingLibs/` | 基础组件(共享库) | L3_common |
| `WEGBaseSharingModel/` | 基础组件(共享模型) | L3_common |
| `WEGConstant/` | 基础组件(常量定义) | L3_common |
| `WEGCube/` | 启动/路由(模块容器) | L3_launch |
| `WEGFlutter/` | 通信层(Flutter集成) | L3_bridge |
| `WEGFlutterBiz/` | 通信层(Flutter业务) | L3_bridge |
| `WEGGlue/` | 通信层(胶水层) | L3_bridge |
| `WEGLauncher/` | 启动/路由 | L3_launch |
| `WEGLongLink/` | 网络(长连接) | L3_network |
| `SmobaClip/` | iOS 扩展(App Clip) | L3_launch |
| `SmobaWidget/` | iOS 扩展(桌面小组件) | L3_launch |
| `SmobaIntent/` | iOS 扩展(Siri Intent) | L3_launch |
| `PacketTunnel/` | 网络(VPN隧道) | L3_network |
| `XGExtention/` | 通知(推送扩展) | L3_notify |

---

## iOS Features/Manager 速查（30 个管理器）

| Manager 目录 | 所属域 | L3 文件 |
|-------------|--------|---------|
| `AnniversaryManager/` | 活动(周年庆) | L3_activity |
| `ChatEngineManager/` | 聊天(IM引擎) | L3_chat |
| `DatabaseManager/` | 基础组件(数据库) | L3_common |
| `FileStorage/` | 基础组件(文件存储) | L3_common |
| `GameEventManager/` | 游戏广场(游戏事件) | L3_gamezone |
| `Gangup/` | 组队(管理器) | L3_team |
| `LongLiveManager/` | 基础组件(保活) | L3_common |
| `MTAManager/` | 监控(MTA上报) | L3_monitor |
| `Manager/` | 基础组件(管理器基类) | L3_common |
| `NativeLivingManager/` | 直播(原生直播) | L3_live |
| `NewsManager/` | 社区(资讯管理) | L3_community |
| `NotificationManager/` | 通知(本地通知) | L3_notify |
| `TenthAnniversary/` | 活动(十周年) | L3_activity |
| `WEGADManager/` | 基础组件(广告) | L3_common |
| `WEGAppIconManager/` | 基础组件(动态图标) | L3_common |
| `WEGFaceVerifyManager/` | 基础组件(人脸核验) | L3_common |
| `WEGFileUploadHandler/` | 基础组件(文件上传) | L3_common |
| `WEGFlutterBusinessManager/` | 通信层(Flutter业务管理) | L3_bridge |
| `WEGFrameTaskManager/` | 基础组件(帧任务调度) | L3_common |
| `WEGGyroscopeManager/` | 基础组件(陀螺仪) | L3_common |
| `WEGLogHandler/` | 基础组件(日志) | L3_common |
| `WEGPremadeTeamExposeManager/` | 组队(预制组队曝光) | L3_team |
| `WEGReddotManager/` | 基础组件(红点) | L3_common |
| `WEGRouteManager/` | 启动/路由 | L3_launch |
| `WEGRouteSwitcher/` | 启动/路由 | L3_launch |
| `WEGShowPanelManager/` | 基础组件(面板展示) | L3_common |
| `WEGTeenProtectManager/` | 基础组件(青少年保护) | L3_common |
| `WEGTgaManager/` | 监控(TGA) | L3_monitor |
| `WebServiceManager/` | 网络(WebService) | L3_network |

---

## iOS Features/Component 速查（15 个组件）

| Component 目录 | 所属域 | L3 文件 |
|---------------|--------|---------|
| `CampRequestPreload/` | 基础组件(请求预加载) | L3_common |
| `CommonOpenApiLauncher/` | 网络(OpenAPI启动器) | L3_network |
| `FileCache/` | 基础组件(文件缓存) | L3_common |
| `ForcedLauchingMask/` | 启动(强制启动遮罩) | L3_launch |
| `GameHelper/` | 游戏广场(游戏辅助) | L3_gamezone |
| `OffaccBottomDataSource/` | 基础组件(离线数据) | L3_common |
| `Operator/` | 基础组件(功能开关) | L3_common |
| `ProviderFactory/` | 基础组件(依赖注入) | L3_common |
| `RoleCardUpdaterProtocol/` | 游戏广场(角色卡片) | L3_gamezone |
| `ShareCode/` | 分享(分享码) | L3_share |
| `UpdateChecker/` | 基础组件(版本更新) | L3_common |
| `WEGMVVMTable/` | 基础组件(MVVM表格) | L3_common |
| `WEGStickyBubble/` | 基础组件(粘性气泡) | L3_common |
| `WEGWrapperTableCell/` | 基础组件(表格Cell封装) | L3_common |
| `WebOpenApiLauncher/` | 网络(Web OpenAPI) | L3_network |

---

## Flutter lib/business/ 路由入口层（58个目录 → lib/ 映射）

`lib/business/` 是 **TRouter 路由入口层**，每个子目录是独立页面入口，核心逻辑在 `lib/同名目录/`。

| 仅 lib/business/ 独有（无 lib/ 对应目录） | 功能说明 |
|----------------------------------------|---------|
| `about/` | 关于页面 |
| `account/` | 账号管理 |
| `bottom_bar_web/` | 底部栏 Web 入口 |
| `change_role_global/` | 全局角色切换 |
| `contact/` | 联系人列表 |
| `friend_apply_detail/` | 好友申请详情 |
| `homepage/` | 首页入口 |
| `launch_game/` | 启动游戏 |
| `mine/` | 我的页面 |
| `new_setting/` | 新版设置 |
| `screenshot_setting/` | 截图设置 |
| `setting2/` | 设置 v2 |
| `shop/` | 商品页 |
| `special_topic/` | 专题页 |
| `teenager_mode/` | 青少年模式 |
| `topic_weight/` | 话题权重 |

---

*最后更新：2026-03-30（全面扩展：新增逆向查找表、Manager/Component/xcodeproj速查、lib/business映射、扩展关键词）*  
*维护者：bryanpeng*
