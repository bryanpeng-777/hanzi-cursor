---
name: galileo-module-locator
description: 伽利略代码问题定位辅助技能。当用户用自然语言描述 App 问题（如"登录失败"、"视频播放报错"、"网络请求异常"、"Flutter图片加载不出来"）时，自动翻译为对应的伽利略 moduleName，帮助定位监控指标和代码位置。触发词：「伽利略」、「监控」、「上报」、「这个问题的 module」、「查一下 moduleName」、任何描述 App 功能异常且可能需要查伽利略日志的场景。即使用户只描述了问题现象（如"用户反映启动很慢"、"支付失败了"、"闪退了"），也应主动使用此技能帮助定位 moduleName。
---

# 伽利略代码问题定位辅助

根据用户的自然语言问题描述，翻译为对应的伽利略 `moduleName`，并给出定位建议。

## 使用方式

1. 用户描述问题（中文自然语言）
2. 根据关键词匹配下方模块映射表，输出对应 `moduleName`
3. 说明该 module 监控的内容和常见参数
4. 建议下一步排查方向（查伽利略日志 or 查代码）

---

## 模块映射表

### 登录相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 自动登录、自动登录失败、自动登录超时 | `AutoLogin` | 双端 | campType=start/step/end；step: autoLoginEnd/autoLoginTimeOut |
| 手动登录、登录页面、点击登录、QQ登录、微信登录、手机号登录、隐私协议弹窗 | `ManualLogin` | 双端 | campType=start/step/end；step: showPrivacy/authStart/userLoginStart/userLoginEnd |
| 登录耗时、登录接口慢、登录接口耗时 | `LoginMetric` | iOS | 各阶段耗时：ttfb/totalTime/dnsTime/connectTime/tlsTime |
| 退出登录、切换账号、账号注销、强退 | `Login` | 双端 | 登录态变化流程 |

### 网络相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 网络请求失败、HTTP失败、接口报错、接口超时、接口失败、请求超时、DNS解析失败、证书校验失败、接口频繁调用、响应过大 | `NetRequest` | 双端 | 涵盖HTTP失败、业务失败、响应过大、频率过高、证书校验失败 |
| 换链失败、链接换链、URL换链 | `ExchangeUrl` | 双端 | 换链路径异常 |

### 路由相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 内部路由跳转失败、页面跳转失败、路由拦截 | `InnerRouter` | 双端 | status: 0成功/1被拦截/-1失败 |
| 外部路由失败、启动游戏失败、scheme跳转失败、拉起外部App | `OutRouter` | 双端 | launchGame等外部跳转 |
| 跳转外部被白名单拦截 | `JumpSchemaWhitelist` | iOS | scheme白名单拦截 |
| 专区启动游戏失败 | `GameZoneLaunchOtherGameFail` | 双端 | 游戏专区内启动其他游戏失败 |

### 视频/图片/媒体相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 视频播放失败、视频播放报错、视频黑屏、视频无法播放 | `VideoPlayFail` | 双端（iOS/Android） | 上报vid、url、清晰度、倍速等 |
| 图片加载失败、图片显示不出来、图片加载异常 | `ImageLoadFail` | 双端 | imageUrl/errorMsg/errorCode |
| 大图加载、图片体积过大、图片超过1M | `BigImage` | 双端 | 图片size超过1M |
| PAG加载失败、PAG动画加载失败 | `PAGLoadFail` | 双端 | PAG动画资源加载异常 |

### 支付相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 支付失败、支付SDK、支付拉起失败、商品列表获取失败、进入支付页面 | `Pay` | 双端 | campType=start/step/end；包含商品列表获取、拉起SDK、支付结果 |
| 视频支付、付费视频、视频付费面板 | `VideoPay` | 双端 | campType=start/end |

### Flutter相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| Flutter异常、Flutter崩溃、Flutter报错 | `FlutterErrorReport` | Flutter | campType=start；errorMsg |
| Flutter图片加载失败、Flutter图片不显示 | `FlutterImageLoadFail` | Flutter | imageUrl/rawUrl/errorMsg/errorCode |
| Flutter视频播放报错 | `FlutterVideoPlayError` | Flutter | |
| Flutter引擎初始化、Flutter首帧、Flutter启动慢 | `FlutterEngineCreateToFirstFrameInit` | Flutter | 引擎初始化到首帧上屏耗时 |
| Flutter SSE报错、Flutter SSE失败 | `FlutterSSEError` | Flutter | |
| Flutter数据解析报错 | `FlutterDataParseError` | Flutter | |
| Flutter容器生命周期、Flutter容器进入退出 | `FlutterContainerLifeCycle` | Flutter | campType=start/end |
| Flutter页面生命周期 | `FlutterPage(xxx)` | Flutter | xxx为具体页面名 |
| Flutter列表加载失败、Flutter上拉加载异常、Flutter下拉刷新异常 | `FlutterListLoad` | Flutter | |
| Flutter手势冲突 | `FlutterGestureRecognize` | Flutter | |
| Flutter内存告警、Flutter内存不足 | `FlutterMemory` | Flutter | |
| Flutter热更、Flutter conch下载 | `FlutterConch` | Flutter | |
| Flutter视图报错 | `FlutterViewErrorShow` | Flutter | |

### 启动/生命周期相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| App启动、冷启动、启动原因、启动慢 | `AppStart` | 双端 | 启动原因、启动路径关键节点 |
| App生命周期、前后台切换、进入前台、退出后台、页面进入退出 | `AppLifecycle` | 双端 | 前后台切换/页面生命周期 |
| App后台被杀、后台自杀 | `BackGroundKill` | iOS | |
| 应用进程退出、进程退出原因 | `AppExitReason` | 双端 | |

### App更新相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| App更新、版本更新弹窗、下载更新、安装更新、强更 | `AppUpgrade` | 双端 | 拉取更新策略、弹窗、下载、安装全流程 |
| App自更新、自升级 | `SelfFullUpdate` | Android | 完整的自更新下载安装流程 |

### 崩溃/稳定性相关

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| Crash、崩溃、闪退、App崩溃 | `Crash` | 双端 | Crash发生时上报 |
| 非法Span、Span统计异常 | `SpanStatistic` | 双端 | 非法Span监控 |

### 注册/新人引导

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 注册失败、新人注册、提交用户信息失败 | `Register` | 双端 | campType=start/step/end；step: registerUserInfo/registerCompleted |

### 其他功能

| 问题描述关键词 | moduleName | 平台 | 说明 |
|---|---|---|---|
| 扫码失败、二维码扫描、扫码页面 | `QRScan` | 双端 | campType=start/end |
| 用户反馈、反馈提交失败 | `FeedBack` | 双端 | campType=start/step/end |
| Hippy加载失败、Hippy容器、Hippy页面 | `Hippy` | 双端 | campType=start/end |
| 闪屏广告、开屏广告 | `SplashAd` | 双端 | status: 0正常/1跳过/2点击/负数出错 |
| 信鸽注册失败、Push注册失败、推送注册 | `XGPush` | 双端 | 注册失败/绑定失败 |
| OneApi失败、OneApi异常 | `OneApi` | 双端 | OneApi调用失败日志 |
| 第一条日志、设备信息上报 | `galileoFirstLogWithParams`(iOS) / `DeviceInfo`(Android) | 双端 | 首条日志含所有通用参数 |
| 第一条Trace | `galileoFirstTraceWithParams` | iOS | 首条Trace |
| 人机验证、验证码弹窗、安全验证 | `SecurityCodeVerify` | 双端 | 多步骤验证流程 |
| 游戏下载、下载游戏、安装游戏 | `GameDownload` | Android | 检查更新/展示下载卡/触发下载/安装 |
| TGPA预下载、TGPA资源 | `TGPAPreDownload` | Android | |
| 加速器预下载、加速器资源 | `GameResPreDownload` | Android | |
| 游戏卸载 | `GameUninstall` | Android | |
| 打开AppStore | `AppStoreUrlOpen` | iOS | |
| 染色参数缺失、ZT染色 | `ZTParamMissing` | iOS | |
| 多游戏授权、授权面板异常 | `MultiGameAuth` | 双端 | |
| 圈子发现、打开发现圈子 | `circle_category` | - | |
| 搜索游戏昵称、搜索好友、游戏昵称搜索 | `SearchNickname` | 双端 | |
| 评论区随机头像、随机头像 | `RandomAvatar` | 双端 | |

---

## 公共参数说明

所有 moduleName 都会附带以下公共参数：

| 参数名 | 说明 |
|---|---|
| `moduleName` | 上报日志名（即本表的 moduleName） |
| `campType` | 上报类型：start/step/end/before/after |
| `status` | 结果状态：<0 错误，0 正常，>0 扩展 |
| `userId` / `uid` | 用户ID |
| `qimei36` | 设备 QIMEI ID |
| `cClientVersionName` | App 版本号（如 9.103.0625） |
| `isLatestApp` | 是否最新版App（Shiply配置） |
| `session_id` / `sessionspan_id` | 会话标识 |
| `subModuleName` | 二级模块名 |
| `step` | 具体阶段（campType=step时使用） |

---

## 输出格式

当用户描述一个问题时，输出如下结构：

```
## 问题定位结果

**用户描述**：xxx

**对应 moduleName**：`XXX`
**平台**：iOS / Android / 双端 / Flutter

**该 module 监控内容**：
- xxx

**常见参数**：
- campType = start/step/end
- step = "xxx"（如适用）
- status = 0正常 / -1失败

**排查建议**：
1. 在伽利略搜索 moduleName = XXX
2. 过滤 campType = end / status < 0 查看失败情况
3. 关注参数：xxx
4. 相关代码位置：建议用 code-locator 技能进一步定位
```

---

## 注意事项

- 如果用户描述同时匹配多个 module（如「支付页面打开后视频播放失败」），分别列出所有相关 module
- 如果描述的功能不在表中，诚实告知并建议用户提供更多上下文
- Flutter 相关问题优先匹配 Flutter 系列 module（FlutterXxx），而非 iOS/Android 的同名 module
- 平台判断：如用户提及 iOS 或 Android，优先过滤对应平台的 module
- 定位完 module 后，可配合 `code-locator` 技能进一步找到具体代码位置
