# 营地用户问题模式库

已知问题根因模式，在分析前作为先验背景参考。由 camp-problem-analyzer 在遇到匹配模式时自动引用。

---

<!-- 新条目示例格式：

## 模式名称

- **现象**：用户反馈 xxx 功能无法使用 / 出现 xxx 错误
- **根因**：xxx（如：服务端接口超时 / 客户端特定版本 bug / 配置下发异常）
- **支撑证据**：通常在伽利略可看到 xxx 指标异常 / Bugly 可看到 xxx 崩溃
- **处置方式**：建议查看 xxx / 联系 xxx
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

<!-- 知识库初始为空，由 camp-problem-analyzer 在实际使用中自动积累 -->

## 王者营地不支持「登录设备/位置查询」（产品功能缺口）

- **现象**：用户反映无法在王者营地 App 内查询"账号在哪里登录了"或"登录设备列表"，疑似有他人登录账号；常伴随"为什么找不到"的功能投诉
- **根因**：王者营地 App（至少 v10.112.0429）**不提供登录设备/位置查询功能**；feedbackconfig 返回的「个人资料/账号安全」分类（firstCategory=3200）子项中无「登录设备」入口，菜单配置无 `loginDevice`/`deviceManage` 路由，xlog 全文无相关 API 调用
- **伴随情况**：用户设备上若存在微信账号 + QQ 账号两种登录方式（同一手机号绑定），用户可能误将多账号共存理解为"他人登录"
- **支撑证据**：userId=95174881（2026-05-20），iFeedback `zeA1RZ4B8N6mFuvqDbH-`，xlog 74,354 行全文扫描零命中
- **处置方式**：
  1. **客服**：告知用户「查询登录设备」需前往腾讯账号安全中心（微信安全/QQ安全中心）操作，非营地 App 功能；同时确认设备上多账号是否均为本人
  2. **产品建议 P1**：在「账号安全」页面增加「账号安全中心」外链入口，减少用户困惑
- **⚠️ 分析注意**：伽利略 Setting 模块日志仅有 `settingCellListInit`/`accountInit` 两步，无设备管理相关步骤，这是功能未上线的佐证，非埋点缺失 bug
- **首次记录**：2026-05-21
- **最后更新**：2026-05-21

## Flutter PlatformView 销毁主线程等待 ANR（Shell::OnPlatformViewDestroyed）

- **现象**：用户发生 ANR（应用无响应），Bugly 主线程堆栈为 `flutter::Shell::OnPlatformViewDestroyed()` → `fml::AutoResetWaitableEvent::Wait()` → `std::_fl::condition_variable::wait()`；伽利略侧表现为 ANR 期间**完全零日志**（主线程冻结后 SDK 无法写入），ANR 结束后冷重启携带 `AppExitReason: Error`
- **根因**：Flutter 引擎在销毁含 PlatformView 的页面时（`Shell::OnPlatformViewDestroyed`），通过 `fml::AutoResetWaitableEvent::Wait()` 在**主线程同步等待** GPU/IO Rasterizer 线程完成资源清理。若 GPU/IO 线程耗时超过 iOS Watchdog 阈值（通常 5 秒），主线程被阻断触发 ANR。这是 Flutter 引擎层面的同步等待设计问题，**与设备型号/iOS 版本无关**（iPhone 8 Plus ~ iPhone 16 Pro Max 均受影响）
- **触发上下文**：`SplashViewController` 启动期在 <1 秒内批量分发 5 条 InnerRouter 路由（`/battle` → `/user_home_flutter` → `/info_concern` → `/circle_home` → `/hippy`），触发至少 2 个 Flutter Engine 并发初始化；此时若任一含 PlatformView 的页面退出，GPU 线程资源争用加剧等待超时概率
- **支撑证据**：Bugly Issue `F016BCCD7F4C225987DA94A558790623`，单日影响 1400+ 用户，26,248 台设备，版本 10.112.0415 占 94%；伽利略侧表现为多用户出现 20-27 分钟零日志区间
- **伴随症状（非根因）**：
  - `user/getkingcalendar` 爆发式重试（18ms 内 6-9 次，shortfrequency 告警）— ANR 积压请求在重启后集中释放，**是结果而非原因**；若重试间隔过短会触发平台 shortfrequency 限频保护
  - `FlutterViewErrorShow` "这里是一片旷野..." — Flutter 页面接口失败后的兜底 UI，随 ANR 重启出现
  - 多个 `AppExitReason: Error` span — 前序 session ANR 被 Watchdog 杀死的记录
- **`vip/getprofilevipcareer` 失败导致死亡循环（2026-05-08 批量排查确认）**：
  - 当 `vip/getprofilevipcareer` 持续返回 -30372（svr_code=0，客户端超时）时，`FlutterViewErrorShow` 被触发（"这里是一片旷野..."），Flutter 错误页尝试 Engine 销毁 → `OnPlatformViewDestroyed` → ANR → 重启 → 登录后再次请求失败 → 再次 ANR
  - **表现**：同一 qimeiId 出现 2~3 个不同 device_id（重启产生 IDFV 变化），10 分钟内经历 3 次重启，每次均在 ANR 约 55 秒后冷启动
  - **处置**：在 `vip/getprofilevipcareer` 接口失败时做本地兜底（展示默认空态），避免直接触发 Flutter 错误页销毁路径
- **前后台切换触发路径（2026-05-07 新增）**：
  - 用户在含 PlatformView 的 Flutter 页面按 Home 键退后台 → Flutter Engine 进入 `AppLifecycleState.paused`，GPU 线程 VSyncWaiter 暂停，iOS 回收 Metal GPU Context 优先级，`ChildClippingView` 可能从视图层级 detach
  - 用户回到前台 → `applicationDidBecomeActive` 后存在 GPU 线程"热身窗口"（低端设备如 iPhone 8 Plus 可达 1-5 秒）
  - **危险竞态**：在热身窗口内，主线程完成导航栈恢复 → VC dealloc 触发 `OnPlatformViewDestroyed` → `fml::AutoResetWaitableEvent::Wait()`，此时 GPU 线程未完全恢复 → 等待时间远超正常值 → 超过 Watchdog 阈值 → ANR
  - 后台期间 `ChildClippingView` 被 detach 导致 `hasPlatformView` 返回 false，延迟释放保护被意外绕过，进一步加剧 ANR 概率
- **⚠️ 死代码 Bug（2026-05-07 代码审查确认）**：`ios_disable_flutter_engine_delay_release` 开关的值读入 `_disableEngineDelayRelease`（`WEGFlutterWrapperViewController.m` L316-323），但该变量**在 dealloc 及其他任何地方均未被引用**。此开关对代码行为零影响，无论开关开/关，延迟释放行为完全由 `flutter_engine_delay_release_config.enabled`（默认 YES）控制。告知 ricoyang 补充开关引用。
- **⚠️ hasPlatformView 误判 Bug（2026-05-07 确认）**：`hasPlatformView`（`WEGFlutterViewController.swift` L48-55）通过视图层级检测 `ChildClippingView` 是否存在，但后台期间 Flutter 可能 detach PlatformView，导致 dealloc 时误返回 false。修复方案：引入 `_hadPlatformView` 历史标记，一旦检测到 PlatformView 即持久化，避免误判。
- **处置方式**：
  1. 短期（立即）：修复 `ios_disable_flutter_engine_delay_release` 死代码，在 dealloc 第 464 行加入对该开关的判断
  2. 短期（立即）：修复 `hasPlatformView` 使用历史最大值检测，避免后台 detach 后误返回 false
  3. 中期：在 dealloc 中检测前台恢复窗口（`applicationDidBecomeActive` 后 3 秒内），对含 PlatformView 的 VC 延长保护时间至 3 秒
  4. 中期：移除 dealloc 中 `self.preferNewEngine` 前提条件，使共享引擎页面也受保护
  5. 长期：Flutter 引擎层改造 `OnPlatformViewDestroyed` 使 GPU 清理可异步化，跟进 ricoyang 进展
  6. 业务侧：评估 `SplashViewController` 批量路由错峰分发，减少 Flutter Engine 并发初始化压力
- **代码责任人**：ricoyang（Flutter 引擎封装层，`WEGFlutterWrapperViewController.m`，Bugly 平台已指派）
- **版本影响范围**：10.112.0415.68220107960112（占 94%）
- **⚠️ P0 修复方向纠正（2026-05-07 代码审查确认）**：`flutter_engine_dealloc_in_thread` 开关（`WEGFlutterViewController.swift` L114-117）打开后，deinit 内 L230 的代码路径是 `DispatchQueue.main.asyncAfter`（主线程！），**仅打开此开关不能解决 ANR，只会把阻塞后移 1 秒**。正确修复 P0 必须同步将 L230 改为 `DispatchQueue.global().asyncAfter`，使 Engine 在后台线程释放。另外 `WEGFlutterWrapperViewController.m` dealloc 中的 `weg_delay_perform`（CampFoundation.m L13）也是 `dispatch_get_main_queue()`，delay_release 机制同样无法阻止主线程阻塞。告知 ricoyang 时务必指明此细节。
- **代码分工（2026-05-07 git 回溯确认）**：P0/P1 → ricoyang（WEGFlutterViewController.swift × 63次提交，WEGFlutterWrapperViewController.m × 45次提交）；P2 TabBar 懒加载 → jsagsagwen（近 1 月 2 次提交，TabBarViewController.m）；P3 Flutter 侧 user/getkingcalendar 重试限频 → xinyuming（日历模块历史主导）+ qcxiang（最新维护者）
- **userId=1840083312 验证记录（2026-05-05）**：Engine 重建 12 次（历史记录 18 次），FlutterViewErrorShow=0，Trace 1（e36fdcfd4b04b4bb59f5467a4b1dfcc7），Trace 2（c7143318847a4de21e7a561174a7f5ab），版本 1.2.22.3.11 修复未生效；ANR 时间（23:59:56）再次落在 23:45~24:00 集中窗口内，进一步验证该时间窗口规律
- **时间窗口规律（2026-05-08 5用户批量验证）**：2026-05-05 23:50~23:59 再次确认为高发窗口，5 个不同用户在 88 秒内（23:57:37~23:59:05）集中触发 ANR，与历史"23:45~24:00 集中窗口"规律完全吻合。触发时间与 App 连续运行时长无关（从不足 1 秒到 7 分钟均有触发）。
- **首次记录**：2026-05-07
- **最后更新**：2026-05-08（新增：vip/getprofilevipcareer 失败死亡循环、时间窗口 5 用户批量验证、shortfrequency 限频伴随症状）

## OneEvent DartBridge dart_methods_info_ 空指针崩溃（SIGSEGV SEGV_ACCERR）

- **现象**：用户触发 Flutter VC 销毁（如从推荐页跳转到 SuperGroupSessionViewController），App 崩溃；Bugly 报 SIGSEGV SEGV_ACCERR，fault addr: 0x10，崩溃栈顶为 `DartBridge::AsyncDart` → `DartBridge::NativeReady`，位于 `dart_bridge.cc:40`
- **根因（精确）**：`OEFlutterAPI._getEngineIdFromDart` 回调中，`_configDartBridgeIsHotRestart:NO` 在 `GetDartMethodsMapOfEngineIdentifier` 返回 nullptr 时提前 return，导致新建 `DartBridge` 的 `dart_methods_info_` 保持 nullptr；紧随其后无条件调用 `dartBridge->NativeReady()` → `AsyncDart()` → `dart_bridge.cc:40` 裸解引用 `dart_methods_info_->port`（NULL+16=0x10）
- **内存布局**：`DartMethodsInfo::port` 在结构体中 offset=16（0x10），因此 nullptr->port = 0x10，与 fault addr 完全吻合
- **调用链**：`_getEngineIdFromDart` callback → `_configDartBridgeIsHotRestart:NO`（early return，info=nullptr）→ `dartBridge->NativeReady()` → `AsyncDart()` → `NotifyDart(task, this->dart_methods_info_->port)` 💥 L40
- **激增机制（2026-05-15）**：后台 latency 升高 → `user/getkingcalendar` 连续失败 → Flutter VC 频繁重建 → 7秒内 3 个 Engine 无序创建 → 某 Engine Dart Isolate 初始化未完成时 MethodChannel 回调抢先触达 → 命中 nullptr 路径概率大幅提升 → 6次/天 激增到 1116次/天（~180倍）
- **伴随症状（伽利略）**：
  - `FlutterViewErrorShow`「这里是一片旷野...」，距 Engine 初始化完成仅 ~300ms
  - `user/getkingcalendar` 18ms 内连续失败 7 次（requestCount 连续递增，status=-1）
  - 7秒内 3 个 FlutterEngine（engineId 无序），引擎反复创建销毁
  - Crash-start 出现在新会话（87秒后重启上报），currentPage=SuperGroupSessionViewController
- **注意事项**：
  - `dart_bridge.cc` L27-30 已有一次局部修复（针对 DartBridge 自身生命周期的 weak_ptr 守卫），但守卫位置在 lambda 内部，未覆盖 L40 前置的裸解引用
  - `SyncDart` L65 存在完全对称的漏洞：`NotifyDart(wrapper, this->dart_methods_info_->port)`
  - OneEvent 1.4.4（2026-04-20，ricoyang）已包含 dart_bridge SIGSEGV 修复（TAPD #157197227），**需核实线上版本是否合入 1.4.4，以及该修复是否完整覆盖 L40 前置守卫**
- **支撑证据**：Bugly Issue `0C1CDBB7F94B24D2EF3BF60E5160B73D`，5月15日激增，影响 1006 用户/1116 次；代码文件 `Pods/OneEvent/cpp/shared/dart_bridge.cc:40`，`Pods/OneEvent/ios/Classes/Container/Flutter/OEFlutterAPI.mm:77-88`
- **修复方向**：
  1. `dart_bridge.cc` `AsyncDart`/`SyncDart` 增加 `dart_methods_info_` null 前置守卫
  2. `OEFlutterAPI._getEngineIdFromDart` 回调增加前置 guard：仅当 `GetDartMethodsMapOfEngineIdentifier` 非空才调 `NativeReady`
  3. `OEFlutterAPI.dealloc` 增加 `self.dartBridge = nullptr` 清理，防止 C++ 析构竞态
  4. 彻底方案：保证 `RegisterDartMethodsAndPort`(FFI) 严格先于 `getEngineId` MethodChannel 响应
- **代码责任人**：ricoyang（OneEvent 库唯一作者，campspecs 全部 48 次版本发布，`ricoyang@tencent.com`）
- **首次记录**：2026-05-18
- **最后更新**：2026-05-18

## TGA 电视台模块启动期崩溃（循环崩溃）

- **现象**：用户启动 App 后反复闪退，145 秒内崩溃 3 次，重现率 100%
- **根因**：AutoLogin 完成后 Tab 并发初始化阶段，`tv_page_ctrlViewDidLoad`（TGA 电视台模块）与多 Flutter 容器（battle/user_home_flutter 等）同时启动，存在线程竞态或空指针/野指针访问
- **支撑证据**：伽利略可见 Crash span × 3，崩溃时刻与 `tv_page_ctrlViewDidLoad` + `/app/txvideo/login` 接口时间戳误差 < 1ms；Bugly 因 userId 绑定缺失查无记录（需用 device_id 查堆栈）
- **处置方式**：用 device_id 在 Bugly 查具体堆栈，重点排查 `tv_page_ctrlViewDidLoad` 及 TGA 初始化代码；检查 `[Bugly setUserIdentifier:]` 调用时机
- **首次记录**：2026-04-23
- **最后更新**：2026-04-23

## 营地底部 Toast KV 持久化脏数据崩溃（NSInvalidArgumentException）

- **现象**：用户出现 App 崩溃，Bugly 上报 `NSInvalidArgumentException: unrecognized selector sent to instance`，触发模块为营地通知/底部 Toast 展示路径；用户多次反复重启（伽利略 `FlutterEngineCreateToFirstFrameInit` 条数异常偏多，约重启 44 次）
- **根因（精确）**：`WEGCampBottomToastManager.m` L122，`[WEGKVStorage objectForKey:saveKey]` 返回值可能是版本升级前遗留的 `NSString`/`NSNumber` 旧格式数据（而非 `NSDictionary`），直接调用 `.mutableCopy` 后做字典下标访问 `sceneMDic[@"showTimes"]`，触发 `-objectForKeyedSubscript:` unrecognized selector crash。**根因是 KV 持久化脏数据，不是后台下发数据结构变更**
- **调用链**：`WEGCampNotifyAuthorityHelper -checkBottomToastWithScene:toastType:` (L58) → `+isNeedCampBottomToast:` (L112) → `+showBottomTypeInfoWithScene:sceneConfig:` (L122) 💥
- **受影响 scene（共 10 个）**：attentionAction / publishAction / commentAction / chat* / attentionChannel / friendBattle / dynamicRelease / subscribeNotifications / videoGeneration / commentPrizeDraw
- **支撑证据**：Bugly issue `39EEB3979A613F08EEB6E18DFA3FBBAC`；伽利略 `moduleName=Crash` × 20 条、`FlutterEngineCreateToFirstFrameInit` × 88 条、`NetRequest` error × 123 条（`user/synccampfriends` status=-1，为独立网络问题）
- **修复状态**：commit `62564487f7d`（2026-04-23）已加 `isKindOfClass:[NSDictionary class]` 守卫；else 分支末尾通过 `saveObject:forKey:` 自动写回，脏数据会自动清除（副作用：历史触发次数归 0，用户可能再次看到气泡，不 crash）；**无需额外显式 removeObjectForKey**
- **已知额外 Bug（代码深度分析发现）**：
  1. `initWithScene:` 中 `commentAction` 的 `else if` 分支（L54）是**永远无法执行的死代码**（已在前一个 if 条件命中），需清理或重新分组
  2. `checkGotoNoticeSetting:` (L108) 用户点击「去开启」后再次调用 `isNeedCampBottomToast:`，导致 actionTimes **二次累加**，建议改为直接传入 toastType 参数避免重复计数
  3. `chat_{userId}` scene 的 key 动态含 uid，历史脏 KV 条目可能最多，线上修复后脏数据将逐渐被自动覆盖
- **历史规律（三进宫）**：该模块已三次因防御性检查缺失 crash（2024-09-20 nil key、2024-09-25 nil key、2026-04-23 类型不符），强烈建议通过封装类型安全读取方法从根源治理
- **Bugly 日期边界注意**：对于 2026-04-22 19:51 首发的 crash，按 04-23 全天查 Bugly 仍可命中（该用户 04-23 上报了 10 次，Bugly 归在同一 issue），但若查无结果需改查 04-22
- **建议补充监控**：在 else 兜底分支加伽利略埋点（moduleName=WEGCampBottomToastManager，记录 scene 和实际类型），以监控线上存量脏数据清零进度
- **处置方式**：确认 commit `62564487f7d` 已合入；清理 commentAction 死代码；修复二次计数；Bugly issue 派单给 WEGGlue 负责人
- **首次记录**：2026-04-24
- **最后更新**：2026-04-24

## SKStoreProductViewController sceneDisconnected: 崩溃（ChannelReport SDK 内嵌 AppStore）

- **现象**：用户触发广告下载按钮 → 内嵌半屏/全屏 AppStore 页面，随后进行前后台切换、多任务手势、接电话等操作，App 崩溃；Bugly 报 `NSInvalidArgumentException: -[SKStoreProductViewController sceneDisconnected:]: unrecognized selector sent to instance`
- **根因**：调用路径：OneAPI `showHalfScreenAppStore` → `ZTSDKManager.showHalfScreenAppStore:` → `ChannelReport.framework addCustomStoreProductVCV4`，二进制 SDK 内部将 `SKStoreProductViewController` 实例注册为 `UIWindowScene.delegate`，scene 断开时系统发送 `sceneDisconnected:` 消息，该类未实现此方法导致 crash；全屏路径（`newPresentStoreProductViewController`）同理
- **支撑证据**：Bugly issue `491C40462D0F4579DADCC92F1EDC7CFF`；伽利略 09:28:28 Crash span status=-1；堆栈仅到主线程 RunLoop 层（无业务堆栈，是 ChannelReport SDK 二进制导致）
- **关键代码文件**：
  - 主路径：`WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m`（L512 showHalfScreenAppStore）
  - OneAPI 入口：`OneAPIBiz/Classes/ZTSDK/WEGZTSDKOneAPI.m`（L161）
  - 广告预加载：`social-ios/src/GameApp/Features/Manager/WEGADManager/WEGADManager.m`（L203 preloadAppStoreProducts，存在 SKVC 长期缓存风险）
- **处置方式**：
  1. 短期止血：开启 RDelivery 开关 `kZTSDKUseAppStoreJumpFallback = YES`，降级为跳系统 AppStore（代码已有分支）
  2. 中期修复：联系 ChannelReport SDK 方，在 `addCustomStoreProductVCV4` / `newPresentStoreProductViewController` 内补充 `sceneDisconnected:` 空实现，或改用 NSNotification 替代 scene delegate
  3. 防御修复：`WEGADManager.productViewControllerDidFinish:` 改为 dismiss 完成回调后再预加载，避免新旧 SKVC 并存
- **代码责任人**：bryanpeng（全部相关文件唯一提交者）
- **首次记录**：2026-04-29
- **最后更新**：2026-04-29

## 王者荣耀业务页面卡顿（DNS 主线程阻塞 × Hippy 超时叠加）

- **现象**：用户反映"有时候经常卡"，王者荣耀游戏区相关页面（game-zone/home、game-battle 等）加载极慢或无响应；伽利略 `startHippyLoading` span 均值 >30s（正常 <2s）；Bugly Top1 卡顿 issue `5A89E35034CE038DFC0408264B308C56` 累计 10.8 万次，56K 用户受影响
- **根因（P0）**：`CampTools/Classes/WebServiceManager/WEGHttpDnsManager.m` `-ipForHost:` 方法中，`WGGetHostByName:` 以同步方式在主线程执行，均值阻塞 580ms；`WebServiceManager.m:417` 以 `enableSync:true` 调用，每次 API 发起均触发主线程阻塞；在广电/移动混合双卡网络下耗时被进一步放大
- **根因（P1）**：`WebServiceManager+Account.m` AFNetworking success 回调（主线程）直接调用 `DatabaseManager updateUserGameAccounts:` → `WEGFMDatabaseQueue beginTransaction: dispatch_sync`，均值阻塞 678ms；Bugly issue `1A300193AF52BC4F6CA9372A09C55C9B` 记录 8.5 万次
- **Hippy 超时机制**：CDN bundle 下载弱网慢（直接原因）+ 主线程被 DNS/DB 反复阻塞拖慢 UIKit 调度（放大器），导致 `startHippyLoading` span 被拉长至 36.5s 均值、最长 4m46s
- **支撑证据**：伽利略 8 次 Hippy span 均值 36.5s；Bugly Top1/Top2 卡顿 issue；user/getkingcalendar 接口连续 8 次失败（shortfrequency 限流）
- **影响范围**：`WebServiceManager._callApiByAFNetworking` 是所有 API 请求唯一出口，DNS 阻塞影响登录、首页刷新、Hippy 初始化、推送消息处理等全部场景；56K 用户版本级问题
- **处置方式**：
  1. P0：leviyin 负责将 `enableSync:true` 改为 `false` 或将 DNS 解析移至子线程（方案A：`_callApiByAFNetworking` 整体切到 global_queue；方案B：启动时异步预热缓存后以 false 方式调用）
  2. P1：elioyin 负责将 `updateUserGameAccounts:` 调用从 success 回调改为 `dispatch_async(global_queue)` 执行
  3. P2：Hippy bundle 下载增加超时上限（30s），超时后触发降级 UI 与本地预置包回退
- **代码责任人**：leviyin（P0，权重 17）、elioyin（P1，权重 3）
- **首次记录**：2026-04-29
- **最后更新**：2026-04-29

## iOS IAP 充值 UI 状态机挂起 + 双重扣款

- **现象**：用户反馈充值"一直卡，都充不进去"（iOS，王者荣耀充值），可能出现双重扣款或全部失败两种结果；Bugly 无崩溃记录，伽利略服务端链路全部正常
- **根因**：双重放大器结构：
  1. **SDK 层主因**：`MidasIAPAppStoreDealer`（作为 `SKPaymentTransactionObserver` 实际注册类）未实现 `paymentQueueDidChangeStorefront:` optional 回调（Bugly Issue `5B7505598CDC283089BFF942DCF65822`，版本覆盖至 10.112.0415），Apple StoreKit storefront 变更时事件被静默丢弃，Midas 内部 `midas_paymentQueueDidChangeStorefront:` 无法被触发，导致支付流程阻塞、`onResp` 延迟或不触发。注：`MidasStoreKitCore` 类中有 `midas_paymentQueueDidChangeStorefront:` 内部封装方法，但不向 Apple 直接注册，是被调用方而非 observer。
  2. **业务代码放大器**：`WEGPayViewController.m confirmPay:` 使用 1 秒计时器强制解锁充值按钮（`dispatch_after 1.0s → payBtn.enabled = YES`），IAP 实际完成需 5-30 秒，按钮恢复后用户误认为未完成，重复点击；全文无任何 `isPaymentInProgress` 防重入标志，唯一防重入是 `payBtn.enabled = NO`，被 1 秒后强制覆盖
- **两种结果**：① 重复点击穿透 Midas 防护 → 双重扣款（历史案例 02:00:53 余额 0→450，02:03:22 余额 450→900）；② Midas 重复检测机制偶发拦截（iapCode=2+midasCode=1）→ 全部失败、无双重扣款（2026-04-30 案例 userId 1821196735，4次全部 status=-1）
- **错误码信号**：`iapCode=0_500_301_301 + midasCode=4`；`iapCode=2 + midasCode=1`（Midas 重复支付防护触发）
- **iapCode=0_500_301_301 编码格式精确说明（2026-05-18 审判小助手澄清）**：`0` = Apple IAP 本地扣款成功；`500` 是 Midas HTTP 层的**固定包装状态码**，不代表每次独立触发新的服务端 500 故障；`301_301` 才是 Midas **业务层幂等拦截码**（receipt 重复核销/幂等 key 冲突）。两段并列是 SDK 的固定上报格式，⚠️ 勿误读为"每次都触发了新的 Midas 服务端故障"
- **额外 Bug**：选档为 -1 时 `confirmPay:` early return 跳过 `dispatch_after`，导致 `payBtn` 永久禁用；`onResp` 非主线程 UI 操作（SDK 头文件明确警告"回调不保证在主线程"，但业务侧 `MidasManager.onResp:` 直接 postNotification 无主线程切换）
- **高风险场景**：国际漫游/地区切换（storefront 变化概率极高），此类用户所有 IAP 支付均会触发
- **处置方式**：
  1. 客服侧：核查用户是否被双重扣款，视情况退款处理
  2. 研发 P0（可立即落地）：`confirmPay:` 删除 `dispatch_after 1.0s`，改为由支付结果回调驱动解锁；增加 `isPaymentInProgress` 防重入标志位；`onResp` 所有分支用 `dispatch_async(main_queue)` 包裹 UI 操作
  3. 研发 P1（需推动 SDK 升级）：联系 Midas SDK 方，在 `MidasIAPAppStoreDealer` 中补充 `paymentQueueDidChangeStorefront:` 实现（转发给 `midas_paymentQueueDidChangeStorefront:`），或上层添加临时 observer 吸收该回调
- **关键代码文件**：
  - `social-ios/src/GameApp/Features/Controller/WEGPayController/WEGPayViewController.m`（`confirmPay:` L455–479，1秒计时器 Bug L475–477；无防重入标志）
  - `social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/3rd/Midas/MidasManager.m`（`onResp:` L504–590，无主线程分发/无防重入）
- **代码责任人**：bryanpeng（两文件唯一近期维护者，综合权重 76）
- **修复落地状态（2026-05-18 三次实证确认）**：历史修复建议**截至 2026-05-18 仍一条都未落地**：① `isPayingInProgress` 防重入标志位从未添加；② `payEnd:` L682-686 仍只有 Galileo 埋点无回调；③ 1 秒 `dispatch_after` 依然存在于 `confirmPay:` L475-477；④ `CFAbsoluteTime` 时间差检查存在（L463-468）但只打 log、不 return，形同虚设
- **崩溃重启触发路径（2026-05-18 新增）**：App 崩溃重启后 IDFV 未持久化 Keychain → device_id 重新生成 → StoreKit 未消耗队列自动调用 `paymentQueue:updatedTransactions:` 重推旧 transactionId → Midas 首次核销时 500（幂等 key 占用）→ 后续重试全部命中 `301_301` 幂等拦截。38分钟内 device_id 变化3次（userId 1649600879，2026-05-12）是此路径的典型数据特征。**与 storefront 变化路径并列，是另一个高频触发场景**
- **登录循环触发路径（2026-05-19 新增）**：App 异常频繁重启（如全天重启 15 次）→ 每次登录后 `LoginOperator.m L909 registpay` → Midas SDK `initializeWithReq:reprovideDelegate:` 重新扫描 StoreKit pending transactions → 相同 receipt 反复提交 Midas 核销 → 命中幂等锁死循环。**典型特征**：xlog 全天 15 次 `didFinishLaunchingWithOptions` + iapCode=0_500_301_301 出现约 20 次；1.6 秒内快速失败（无需走 Apple 扣款流程，直接命中幂等锁）。此路径根因是 `MidasManager.m onResp:` `AP_MIDAS_RESP_RESULT_IAP_ERROR` 分支**从未调用 `finishTransaction`**，transaction 永久积压不清理
- **⚠️ 修复遗漏点（2026-05-19 审判核查）**：`AP_MIDAS_RESP_RESULT_IAP_ALREADY_IN_PROGRESS` 分支（`MidasManager.m` L565-572）同样无 `finishTransaction`，修复时必须一并覆盖；`SDK binary finishTransaction 行为`需向 Midas SDK 同学确认（error 路径是否调用）
- **iapCode=2 解读（2026-04-30 修正）**：`iapCode=2 + midasCode=1` 表示 Midas 检测到重复支付请求并主动拒绝，属于概率性保护。不代表 Apple 已扣款，不需要通过 Midas 后台对账系统核查收据（之前的推断有误）
- **首次记录**：2026-04-29
- **最后更新**：2026-05-19（新增：登录循环触发路径 + `finishTransaction` 永不调用机制 + `AP_MIDAS_RESP_RESULT_IAP_ALREADY_IN_PROGRESS` 分支遗漏修复点）


## iOS 用户反馈"不能用微信支付"（用户认知问题，非 Bug）

- **现象**：iOS 用户反馈王者荣耀充值无法使用微信支付
- **根因**：苹果 App Store 政策（3.1.1 条款）要求 iOS 数字内容（虚拟货币/点券）必须走 Apple IAP，**不支持微信/支付宝等第三方支付通道**，属于平台限制，非技术 Bug
- **错误码特征**：伽利略 Pay 模块日志可能出现 `iapCode=0_2009 / midasCode=4`，这是 Midas SDK 内部字段（≠ Apple StoreKit 错误码），`0_2009` 表示微信支付通道回调未返回，根因是 iOS 侧本就没有接入 WX Pay 回调（刻意为之）
- **处置方式**：客服直接回复「iOS 版本因苹果政策限制，充值只支持苹果内购，暂不支持微信/支付宝」
- **⚠️ 分析陷阱**：看到 `iapCode=0_2009 / midasCode=4` 容易误判为"微信回调链路断裂 Bug"，实际上 iOS 不接入微信支付是预期行为，代码层面无需修复
- **首次记录**：2026-04-30
- **最后更新**：2026-04-30

## 聊天禁言感知延迟（punishMessage vs messageMute 协议分裂）

- **现象**：用户正常聊天时"突然被禁言"，客户端无任何弹窗提示，只有用户下次尝试发消息时才出现 `-30098 你已被禁言` toast
- **根因（客户端）**：
  - `messageMute` action → `WEGSCRChatService.applyMuteActionMessages` → R群频道聊天室禁言 UI（仅 R 群）
  - `punishMessage` action → `ChatTimHandler.m` L411-418 → `deletePunishMessages`（只删违规消息，无任何 mute 状态写入，无 UI 通知）
  - 两条路径完全独立，`punishMessage` 收到后客户端无法感知禁言状态
  - Toggle `WEGChatPunishMessageEnable` 默认 `NO`，即使 punishMessage 到达也可能整体跳过
  - 用户进入聊天页前 observer 未注册（`WEGChatPageViewController.m` L216），punishMessages 堆积内存
- **根因（服务端，待确认）**：服务端在执行禁言时，是否同时下发了 `messageMute` 尚未确认。若仅下发 `punishMessage` 而未发 `messageMute`，则服务端禁言通知机制存在缺口
- **支撑证据**：iFeedback O7mgO54BgkaEuDzpWumt，xlog smoba_20260518.xlog.log；`ChatTimHandler.m` 代码审查确认（2026-05-19）；用户分类"误禁言问题"（secondCategory=20600）
- **处置方式**：
  1. **客服**：核查 userId 禁言来源，用户提交了"误禁言"申诉，需核实并酌情解除
  2. **研发 P1（服务端）**：确认禁言时是否同时下发了 `messageMute`；若未下发，补充通知或通过 `punishMessage` param 携带禁言标识
  3. **研发 P2（elioyin）**：`ChatTimHandler.m` `kPunishMessageAction` 分支增加禁言 UI 触发逻辑（与服务端对齐 param 字段后实施）；确保普通单聊场景也能展示禁言遮罩（当前只有 R 群有完整 UI）
- **代码责任人**：elioyin（ChatEngineManager.m × 3次，WEGChatPageViewController.m × 3次）；备选 joinyin
- **关键代码路径**：
  - `ChatTimHandler.m` L411-418（kPunishMessageAction 处理分支）
  - `ChatEngineManager.m` L430-448（deletePunishMessages）
  - `WEGChatPageViewController.m` L216-217（addPunishMessageObserver）
- **⚠️ 分析限制（2026-05-19 首录）**：本次未确认服务端是否下发了 `messageMute`（审判小助手指出）。建议 elioyin 在 xlog/伽利略中搜索该 userId 的 `messageMute` 消息是否存在，以最终确定锅的归属（客户端 vs 服务端）
- **实证验证（2026-05-19 userId=1855389659）**：
  - iFeedback `LiqHO54Bm2bMVta-o41g` 命中，smoba_20260518.xlog（17.9 万行）完整解码
  - 22:29:30 发出微信二维码图片消息，22:29:35 收到 2 条 `TimAction:punishMessage`，全 xlog `messageMute` 零命中 → **服务端确未下发 messageMute**
  - punishMessage 到达后 全程零 UI；22:32:03 / 22:36:43 / 22:36:47 三次发消息均返回 -30098
  - Toggle `WEGChatPunishMessageEnable`：默认 `NO`，生产环境是否开启**仍待确认**
- **新增缺陷（2026-05-19 审判小助手）**：
  - `-30098` 存在**双 toast 路径**：① failure block `[self _makeToast:returnMsg]`（Chat.m L118）；② `kChatEngineErrorNotification` 通知路径 `[self makeToastWithError:error]`（Notification.m L566-573）→ Fix 2 实施需处理竞态
  - `MultipleChatMessageViewController` 无 `-30098` 触发禁言遮罩逻辑（`WEGChannelMessageViewController` L2543-2549 有完整实现，可直接参考）
  - `-30098` toast 文案"你已被禁言"依赖服务端 `returnMsg` 字段，兜底文案为"主宰进攻服务器，请稍后再试"（具有误导性），**需服务端确认**
- **修复优先级（更新）**：
  1. P1（elioyin）：`deletePunishMessages`（ChatEngineManager.m L444）后插入本地系统提示消息（参考 -30304 路径），不依赖服务端
  2. P2（elioyin）：`MultipleChatMessageViewController+Chat.m` failure block 补充 -30098 → 禁言遮罩调用，需处理 Notification.m L566 双路径竞态
  3. P3：确认 `WEGChatPunishMessageEnable` Toggle 生产状态；服务端补发 `messageMute` 或 `punishMessage` param 携带禁言时长
- **首次记录**：2026-05-19
- **最后更新**：2026-05-19（新增 userId=1855389659 实证、双 toast 路径、遮罩缺失代码确认）

## 超级群语音频道加入失败（账号风控 -40008）

- **现象**：用户在超级群的语音频道（心动语音等）点击加入时，弹出 Toast："账号存在异常，无法加入心动语音"；文字频道可正常进入；截图中语音房显示 0/10 状态
- **根因**：服务端账号安全/风控系统将该账号标记为"存在异常"，`/supergroupchat/addchatroom` 返回 `errorCode=-40008`，`errorMsg="账号存在异常，无法加入"`，触发语音功能级别拦截。客户端对 -40008 无特殊处理，仅展示服务端 errorMsg Toast
- **技术路径说明**：
  - 文字频道进入：`WEGSCRChatService.enterRoom` → `/supergroupchat/addchatroom`（-40008 时关闭整个聊天页 L1110）
  - 语音频道进入：`ChatVoiceRoomController.joinVoiceRoom` → C++ JoinChannel → `/supergroup/joinvoiceroom` + Agora SDK（-40008 时仅 Toast，不关闭界面）
  - `/supergroupchat/addchatroom` 40+ 次失败日志属于文字频道失败，不是语音失败的直接证据
- **伴随症状**：`SecurityCodeVerify` 日志出现（由 -101201 触发，独立于 -40008 分支），用户被路由到 `WEGSecurityVerifyViewController` 和 `auth-sys` 认证页
- **支撑证据**：伽利略 Trace `325aa307b6a5a9a17348ec11cba958f5`；xlog `smoba_20260518.xlog`；iFeedback `aLcQO54BI25lCglvn3bi`（userId=2144095247，版本 10.112.0429，2026-05-18）
- **处置方式**：
  1. **P0（客服/风控）**：查询 userId 在账号安全系统的具体状态，确认 -40008 触发原因（违规/误判），若属误判立即解除
  2. **P1（owenncwang）**：`ChatVoiceRoomController.swift` L392 增加 -40008 单独处理：弹申诉 Dialog 并加防抖（避免 40+ 次重复请求）
  3. **P2（elioyin）**：`WEGChannelMessageViewController.m` L1110 对 -40008 不触发 `removeChatPageWithAnimated:YES`，允许用户继续查看频道历史消息
  4. **P3（leviyin）**：`WebServiceErrorCode.h` 补充 `-40008` 枚举定义 `WebServiceErrorCodeAccountAnomaly`
- **⚠️ 分析注意**：`/supergroupchat/addchatroom` 失败日志属于文字频道，不要误认为是语音加入接口；语音侧失败应查 `/supergroup/joinvoiceroom` 返回记录
- **代码责任人**：owenncwang（ChatVoiceRoomController.swift）、elioyin（WEGChannelMessageViewController.m）、leviyin（WebServiceErrorCode.h）
- **首次记录**：2026-05-19
- **最后更新**：2026-05-19

## 账号注销实名认证阻断（hashCode 恒真 BUG + -52001 信息不匹配）

- **现象**：用户点击注销王者营地，实名认证页面（`account_logout_authentication`）持续失败，-52001（信息不匹配）或 -52003（格式错误），无法完成注销；`user/realnamecheck` 接口被反复调用（单用户可达 40+ 次）
- **根因（客户端，P0 BUG）**：`flutter_module/lib/account_logout/account_logout_protocol/view_model.dart` `gotoNextStepPage()` ~L30 中 `account.hashCode > 0` 是恒真表达式（Dart identityHashCode 返回非负整数），导致所有用户被强制路由到实名认证步骤，无论有无游戏角色；account=null 时同样进入认证页（默认值 true）。正确写法应为 `account.mainRoleList.isNotEmpty`
- **根因（服务端，待确认）**：若 `/game/authinfo` 中 `game_id=50001` 缺失 `type:1 (SnsAuth)` 实名 scope，服务端 `user/realnamecheck?scene=appUnreg` 可能因找不到对应实名记录而持续返回 -52001；因果链需服务端确认
- **伴随问题**：`authentication/view_model.dart` 无 certId 18位格式预校验（UI 只限 maxNum=18），用户输入格式错误直接透传服务端触发 -52003；连续失败后无客服兜底引导入口
- **调用链**：`account_security/index.dart` → `accountLogoutReasonPage` → `accountLogoutProtocolPage` → `gotoNextStepPage()` (hashCode恒真) → `accountLogoutAuthenticationPage` → `user/realnamecheck` 失败
- **影响范围**：所有使用新版注销流程（`account_logout_trpc_enable=true`，默认开启）的用户均被强制经过实名认证步骤
- **支撑证据**：userId=236680672，伽利略 43次 realnamecheck 全失败（-52003×5 + -52001×31），xlog smoba_20260518（iFeedback: `wjx4N54BdvlsLh3og9_J`），TraceID `7c181bbfdba65838660bb74dec746ba4`
- **修复方向**：
  1. P0（elioyin）：`view_model.dart:30` 改为 `account.mainRoleList.isNotEmpty`，同时处理 account=null 兜底
  2. P1（elioyin）：`authentication()` 增加 certId 正则格式预校验；失败≥3次显示客服入口
  3. P2（服务端）：确认 `/game/authinfo type:1` 与 `realnamecheck -52001` 因果关联
- **代码责任人**：elioyin（模块原始作者，commit `22e3f317` 直接引入 BUG）；CR 拉 owenncwang
- **首次记录**：2026-05-19
- **最后更新**：2026-05-19

## WKWebViewJsBridge 结构性死区导致 mqqapi scheme 拦截修复无效（OutRouter openURLFailed）

- **现象**：`OutRouter-end` 失败告警，`msg=openURLFailed`，`status=-1`，路由目标 `mqqapi://forward`，失败率同比激增（本次 +82.12%），影响数百用户；Galileo 可见大量 `OutRouter` 失败 span，但 App 无崩溃
- **根因（精确）**：`mqqapi://forward` 在 WKWebView 导航拦截层的真实执行路径是 `WKWebViewJsBridge.m decidePolicyForNavigationAction` L375（`else if (![url hasPrefix:@"http"] && ...)` 分支），该分支直接调用 `openURL` 后 return，**不再 forward 给 `strongDelegate`（即 WebViewController）**。历史修复 commit `b3d699b5b7`（2026-04-28）将 `canOpenURL` 守卫写在 `WebViewController.decidePolicyForNavigationAction` L2779，属于结构性死区，永远不可达
- **调用链**：`WKWebView` → `WKWebViewJsBridge.decidePolicyForNavigationAction`（作为 WKNavigationDelegate）→ L375 分支直接处理 `mqqapi://` 并 return → ❌ 不转发给 `WebViewController.decidePolicyForNavigationAction`（死代码区）
- **第二路径**：`window.open('mqqapi://...')` 触发 `WKUIDelegate.createWebViewWithConfiguration`，**完全绕过 WKWebViewJsBridge**，由 `WebViewController` 直接处理（同样无保护，需单独修复）
- **精确代码位置（2026-05-20 代码深度分析确认）**：
  - `WKWebViewJsBridge.m` `decidePolicyForNavigationAction:decisionHandler:` **L375-388**：else-if 分支条件 `!(http) && !(https) && !(bridge) && !(about)`，mqqapi:// 命中此分支；L384 调用 `openURL`；**L380 失败时返回 `WKNavigationActionPolicyAllow`（BUG 根源）**；L388 `return` 不转发 strongDelegate
  - `WebViewController.m` `decidePolicyForNavigationAction:` **L2776-2786**：commit b3d699b5b7 的 mqqapi 守卫，结构性死区（WKWebViewJsBridge L388 先 return，永远不可达）
  - `WebViewController.m` `createWebViewWithConfiguration:` **L2980-2986**：`window.open('mqqapi://')` 路径，直接 openURL 无 canOpenURL 守卫
  - `WEGOpenURLHook.m`：Method Swizzle hook `openURL`，每次调用均触发 OutRouter-start/end 上报（失败数放大的技术根源）
- **L380 Allow 缺陷引入者**：ricoyang（commit `c0534f41fdd`，2024-10-28，openURL API 升级时引入 completeHandle block，失败分支写了 Allow 而非 Cancel）；`createWebViewWithConfiguration` L2983 无守卫同一次提交
- **修复方案**：在 `WKWebViewJsBridge.m L375` 增加 `canOpenURL` 白名单检查（`mqqapi`/`weixin`）+ 失败时返回 Cancel（非 Allow）；同步在 `WebViewController.m createWebViewWithConfiguration` 补齐相同守卫。目标 branch `feature/10.112.0520_lego_bugfix`
- **⚠️ 死代码识别规则**：当 WebViewController 的 `decidePolicyForNavigationAction` 修复对非 http/https scheme 无效时，首先检查 WKWebViewJsBridge 是否在 L375 分支（非 http/https/bridge 协议/about 的 URL）中提前 return，导致 delegate 回调永远不触发
- **重试循环放大机制**：L380 返回 Allow → WKWebView 发起 mqqapi:// 网络请求 → NSURLErrorDomain 失败 → H5 onerror/超时触发重试 → 单次点击产生 N 次 OutRouter 失败上报
- **支撑证据**：伽利略告警 `alert_instance_id=2432787_1779244260`（2026-05-20），835 用户受影响，失败率 14.90% → 27.14%（+82.12%），mqqapi 专项失败 36→630 条（+1650%）；commit `b3d699b5b7` author: bryanpeng；排查记录 record_id=raBCsl
- **代码责任人**：bryanpeng（首选，WebViewController.m 近 3 月主力，死代码 commit 作者）；ricoyang（必须 CC 评审，WKWebViewJsBridge.m L375-388 + createWebViewWithConfiguration 实际维护者，L380 Allow 缺陷引入者）
- **首次记录**：2026-05-20
- **最后更新**：2026-05-20（代码深度分析：精确行号、L380 缺陷引入者、第二路径确认、重试放大机制）

## 微信登录 refreshToken 过期时无自动重授权（QR 弹窗缺失）

- **现象**：用户反馈微信扫码登录「更新后不弹码」；实际大多数情况下是 refreshToken 仍有效、静默登录成功（正常行为，用户误解）；真正 Bug 发生在 refreshToken 到期后，App 无自动重授权弹窗，用户须手动进登录页点击微信登录按钮
- **根因**：`WEGLauncher/Classes/LoginOperator.m` L578-596 `_autoLoginWithWechatAccount` 方法：`refreshWechatTokens:success:` 回调中，`newTickets.count <= 0`（token 过期时服务端返回空 dict）分支只调 `_loginDidFailWithError(WebServiceErrorCodeAccessToken)`，通过 `_doRelogin:` → `jumpToSelectLogin` 跳到通用登录页，**全程无任何自动微信重授权或 QR 弹窗触发**
- **额外高危缺陷**：`flutter_module/lib/camp_login/select_login/src/models/camp_login_toggles_model.dart` L23 `showWxQr = forceShowQR || isWxInstalled`；当 Shiply `ForceShowQRLogin` 关闭 + 设备未安装微信时 `showWxQr=false`，`camp_login_opeator_viewModel.dart` 中 iOS 分支直接 `loginTypes.remove(LT.wx)`，**微信登录/扫码按钮全消失**，微信账号用户完全无法登录
- **排查分析陷阱**：当日 iFeedback 反馈内容可能与「登录不弹码」描述不符（如用户实际反馈的是卡顿），xlog 中看到 refreshWX 全部 result=0 说明今日不复现，问题发生在 token 到期边界（约 30 天）
- **支撑证据**：userId 1801730293，2026-05-20 xlog 完整，4 次静默刷新均成功（result=0）；`LoginOperator.m` blame L580-595 由 leviyin 近期维护（最近 2025-12-23）
- **处置方式**：
  1. P1（leviyin）：`loginOperator:didFailWithError:` 检测到微信账号 + `WebServiceErrorCodeAccessToken` 时，跳转登录页前传入 `autoLoginType=@"wx"` 触发自动微信重授权（已有 `checkNeedAutoVerify` 机制可复用）
  2. P2（linyunxiao）：`camp_login_toggles_model.dart` `showWxQr=false` 时保留 `LT.wxQR` 入口或增加兜底提示，避免微信账号完全无法登录
- **代码责任人**：leviyin（主责，LoginOperator.m 1年14次提交，权重44）；bryanpeng（WebServiceManager+Login.m 近期维护）；linyunxiao（Flutter showWxQr 控制逻辑，权重6）
- **首次记录**：2026-05-20
- **最后更新**：2026-05-20

## SmobaWidget iOS 26 小组件空白（图片未压缩 → OOM，内存限制 30MB）

- **现象**：用户升级到 iOS 26.x 后，王者营地桌面小组件显示全白空白，而王者荣耀等其他 App 小组件正常
- **根因（已人工确认）**：SmobaWidget Extension 加载的图片资源未经压缩处理，导致 Widget Extension 进程内存占用超过 iOS 26 的 **30MB 硬限制**，进程被系统 OOM kill，小组件无法渲染 → 白屏
- **iOS 26 变化**：iOS 26 收紧了 Widget Extension 的内存上限（旧版 iOS 17/18 限制更宽松，超限不一定立即 kill），因此同一版本 App 在 iOS 26 上批量暴露此问题
- **误判陷阱（重要）**：
  - AI 代码分析发现了 `GameCardWidget.swift:29-34` completion 未调用、`NewsWidget.swift:62+93` group.leave() 缺失等次级 Bug，**这些 Bug 确实存在但不是本次白屏的直接根因**
  - 直接根因是内存超限 → 进程被 kill，表现与 completion 未调用（WidgetKit 超时）外观相同，需区分
  - Widget Extension 进程无伽利略日志、主进程 xlog 无相关信息，是分析盲区，容易导致根因误判
- **处置方式**：
  1. P0：压缩 SmobaWidget Extension 中所有图片资源（PNG 使用 pngcrush/zopfli，JPEG 降质量，建议通过 Image Asset Catalog 管理，避免运行时大图解码）
  2. P0：在 Widget Extension 代码中使用 `ImageRenderer` / `UIImage(named:)` 时指定 scale，避免 @3x 图被以原始分辨率加载到内存
  3. P1：修复 `GameCardWidget.swift:29-34`、`NewsWidget.swift:62+93` 等 completion 缺失 Bug（虽不是本次白屏根因，但属于存量 Bug 建议一并修复）
  4. P2：SmobaWidget Extension 进程接入伽利略监控（新建 target `iOS.camp-widget`），提升下次排查可观测性
- **⚠️ 分析注意**：Widget Extension 是独立进程，主 App 伽利略日志/xlog 中无 Widget 进程的内存/崩溃信息；确认内存问题需通过 Instruments Memory Graph 或 MetricKit MemoryDiagnosticPayload 采集 Widget 进程峰值内存
- **⚠️ iOS 平台规律**：iOS 26 对 Widget Extension 内存限制为 30MB（对比 iOS 17/18 更严），未压缩的大图（尤其是网络图、动态加载图）是超限主因；建议所有 Widget 类型在 iOS 26 Simulator 下跑 Instruments 压测
- **代码责任人**：待确认 Widget 图片资源管理负责人（willazhuang 为 SmobaWidget 最近活跃维护者，可作为首选联系人）
- **首次记录**：2026-05-26
- **最后更新**：2026-05-27（根因纠正：completion 缺失 → 图片未压缩 OOM，由用户人工确认）

## TRouterContainer 缺失 super 导致 Flutter GPU Context 失效（iOS 26 后台图片不渲染）

- **现象**：资讯推荐「热门活动」Banner 不显示，展示默认占位图；需杀端重进才恢复；无崩溃/ANR；Log 中出现大量 `Image upload failed due to loss of GPU access.`（批量 16~17 条）
- **复现条件**：iOS 26.x（Beta 或正式版）+ App 后台驻留较长时间（实测 91 分钟）+ Flutter 页面含图片渲染
- **根因（精确）**：`Pods/trouter_ios/Classes/TRouterContainer.m` 覆写了 `FlutterViewController` 的 `-applicationDidEnterBackground:` 方法（L202-206），但**未调用 `[super applicationDidEnterBackground:]`**。被阻断的 super 本应做两件事：① 向 Dart 发送 `AppLifecycleState.paused` 信号；② 调用 `surfaceUpdated:NO` 释放 Metal Surface。iOS 26 在后台对 GPU Context 实施更激进的强制回收，Flutter Engine 因未主动释放而持有已失效的 GPU Handle；前台恢复时图片纹理上传失败，降级为占位图
- **关键代码路径**：
  - `TRouterContainer.m L202-212`：缺失 `[super applicationDidEnterBackground:]` 和 `[super applicationWillEnterForeground:]`
  - `flutter_module/lib/camp_business/base/widget/banner/banner_image_item.dart L175-201`：`_ClipperImageState` 无 `resumed` 时重载逻辑
- **证据特征**：伽利略 `FlutterImageLoadFail` 模块日志在 Session A 批量出现（16+ 条），Session B（杀端重进后）为 0；服务端接口（`/info/listinfov2`）全程 200 OK；xlog 中 `AppLifecycleState` 从 `inactive` 直接跳 `resumed`，缺失 `hidden/paused`
- **支撑证据**：userId=405332661，2026-05-27，xlog `smoba_20260527.xlog.log`；伽利略 Session A Trace `3a2939bb9c933bdeccdcd093c116a708`；record_id=rmZ4iG
- **处置方式**：
  1. **P0（ricoyang）**：`TRouterContainer.m` `-applicationDidEnterBackground:` 和 `-applicationWillEnterForeground:` 方法体首行补调 `[super ...]`，更新 trouter_ios 仓库
  2. **P1（wchenzhang）**：`banner_image_item.dart` `_ClipperImageState` 混入 `WidgetsBindingObserver`，`resumed` 时重调 `_getImage()`
  3. **P2（ricoyang/skylerpfli）**：全局 AppLifecycle 监听处（`main.dart`）前台恢复时执行 `PaintingBinding.instance.imageCache.clear()` 清除失效纹理
- **⚠️ iOS 26 影响范围**：所有通过 `TRouterContainer` 继承链的 `WEGFlutterViewController` 均受影响，不限 Banner；iOS 26 正式版发布后将批量影响普通用户
- **⚠️ 分析注意**：若看到 `FlutterImageLoadFail` 大量集中于同一 Session 但接口正常，优先怀疑 GPU Context 丢失而非服务端或 CDN 问题；`AppLifecycleState` 缺失 `paused` 是判断依据
- **代码责任人**：ricoyang（TRouterContainer.m，20次历史提交，trouter_ios 仓库主维护者）；wchenzhang（banner_image_item.dart，文件作者）
- **首次记录**：2026-05-27
- **最后更新**：2026-05-27

## Android 发消息失败 / sendsinglechatmessage 接口告警（单用户突刺模式）

- **现象**：伽利略 Android.default.camp-app 的 LogToMetric 失败量级（sendsinglechatmessage）指标异常，触发告警；整体 NetRequest 失败量上涨但幅度有限（通常 +10%~+15%）
- **根因（高频）**：单一 userId 在短时间内高频发送消息，触发服务端限频保护，返回 `-30011`（发送频率超限），导致客户端侧该接口失败量激增。历次排查均可从伽利略 group_by userId 看到某个 uid 独占 30%~40%+ 失败量。**服务端保护机制正常，非服务端故障**
- **排查方法**：
  1. 查询伽利略 `NetRequest` 日志，filter `url:sendsinglechatmessage`，group_by `tags.userId` + `tags.status`
  2. 若某个 uid 的 `-30011` 次数远超其他用户（2x 以上），即为突刺用户
  3. 排除 HTTP 504 激增（需看服务端网关日志，-30011 出现时通常无 504）
- **伴随指标（正常背景）**：
  - `-30099`（内容违规）：分散多用户，正常安全拦截
  - `-100`（心跳/离线消息超时）：长期背景噪音，环比无突变时可忽略
- **错误码速查**：
  - `-30011`：发送频率超限（客户端行为，服务端正常拦截）
  - `-30099`：发送内容非法，被安全系统拒绝
  - `-30098`：账号被禁言（见「聊天禁言感知延迟」模式）
  - HTTP 504：真实服务端网关超时，需单独处置
- **处置方式**：
  1. P1：核查突刺 uid 的账号属性（机器人/脚本/异常客户端），酌情封禁或提升限频惩罚
  2. P2（Android 侧）：检查发消息失败后是否存在无限重试逻辑（收到 -30011 应展示提示并终止，禁止重试）
  3. P3：监控 `-30099` 是否有聚集趋势，防止批量营销内容投放
- **历史案例（知识来源：企业微信文档伽利略记录）**：
  - 2026-05-22 16:21~18:21，uid=536019491，-30011 共 3,923 次（37.93%），约 33 次/分钟
  - 2026-03-11、2026-02-26（uid 不同）：历次均为单用户发言太积极
  - 2026-01-26：uid 无聚集性时主因为 HTTP 504（偶发例外）
- **⚠️ 分析陷阱**：切勿将 `-30011`（限频）误判为服务端故障；`-30011` 是服务端主动保护，不代表服务端不可用
- **首次记录**：2026-05-28
- **最后更新**：2026-05-28

## Android FlutterErrorReport 激增（camp_design 组件规范违反）

- **现象**：伽利略 Android.default.camp-app 的 LogToMetric 「单点指标报错」告警（P1），`moduleName=FlutterErrorReport` 日志量级激增数十倍；伽利略 group_by errorMsg 后 **95%+ 集中于同一 Dart TypeError**（混淆后类名格式：`type '_xxx' is not a subtype of type 'Yyy' of 'zzz'`）
- **根因模式**：Flutter 代码中某处使用了 Flutter SDK 原生 widget（如 `Image.network`），而 camp_design 组件树在 **Release AOT + --obfuscate** 下执行类型检查时，原生私有实现类（混淆为 `_xxx`）无法满足 camp_design 期望的接口类型（混淆为 `Yyy`），触发 `TypeError`，被全局 `FlutterError.onError` 捕获上报
- **典型案例（2026-05-26）**：
  - 错误：`type '_tgb' is not a subtype of type 'Kza' of 'jDg'`（昨日 44 条 → 当日 2687 条，+6011%）
  - 位置：`flutter_module/lib/battle/ui/container/game_page/game_page.dart`
  - 原因：`Image.network(bgUrl, ...)` 应改为 `cd.CampImage.network(bgUrl, ...)`
  - Bug 引入：commit `1076ef0174`（bobihuang，2026-03-15）；Fix：commit `5befecc50`（jiahaoxia，2026-05-22）
- **排查方法**：
  1. 查询伽利略 `FlutterErrorReport` 日志，group_by `tags.errorMsg`，若某一 TypeError 占比 >90%，即为此模式
  2. Dart TypeError 格式：`type 'X' is not a subtype of type 'Y' of 'Z'`，Release 下 X/Y/Z 均为混淆名，无法直接搜索
  3. 通过 `curPageRouter` 分布确认影响页面，注意 curPageRouter 是异常**被捕获时**用户所在页面，不一定是错误发生页
  4. 通过 `cClientVersionName` + `isLatestApp` 确认是否为新版本引入（isLatestApp=1 的版本占比高 → 新版本 bug）
  5. 通过 dev-assistant 在 flutter_module 中搜索相关页面最近的 git 提交，重点查 `fromJson`/`as`/图片组件用法
- **告警触发机制**：`grokLogName=FlutterErrorReport-start-noStep-noGroupName` 指标 1 分钟内对比波动超过 20% 触发
- **⚠️ curPageRouter 陷阱**：异常在异步回调中触发，`FlutterError.onError` 捕获时用户可能已导航离开原页面，`curPageRouter` 反映的是捕获时的页面，不一定是 bug 所在页面。应重点关注错误信息和版本分布，而非页面分布
- **⚠️ camp_design 使用规范**：在 camp_design 组件树中，**所有图片组件必须使用 `cd.CampImage.*`，禁止直接使用 `Image.network` / `Image.asset`**，否则 Release 模式下有类型检查失败风险
- **处置方式**：
  1. 确认是否已有对应 Fix commit 并通过 Shiply/热修通道下发
  2. 若无 Fix，在 `game_page.dart`（或对应文件）将原生 `Image.network` 替换为 `cd.CampImage.network`
  3. 热修生效后验证 `FlutterErrorReport` 指标回落至历史基线
- **代码责任人**：`jiahaoxia`（Fix 提交者，应跟进热修下发）；`bobihuang`（Bug 引入者）
- **首次记录**：2026-05-28
- **最后更新**：2026-05-28

## iOS Flutter Engine 累积泄漏导致 FOOM 激增（keepAlive + 嵌入式容器 + groupId==0 缓存 miss）

- **现象**：iOS FOOM 整体增高，激增拐点 2026-05-26，与版本 10.112.0520 发布高度吻合；近5天日均 FOOM 翻倍（+101%），单日影响用户 1286；P90 内存峰值 3.49GB；Bugly 堆栈收敛于 `CFRunLoopDoTimer → Flutter`；用户可单日发生 3 次 FOOM，重启后继续复现
- **根因（精确，三条路径叠加）**：
  1. **P0-主路径**：`WEGFlutterViewController.swift:205-216` `viewDidDisappear` 中 `trWillDealloc()` 只在 `jt_navigationController != nil` 时触发；嵌入式场景（`addChildViewController`）`jt_navigationController == nil`，`ContainerLifeCycle.Destroy` 不触发 → Dart 侧 `_reportContainerDestroy()` 永不调用 → FlutterContainerLifeCycle span 永不关闭（伽利略显示 INT32_MAX）→ Engine 引用链保活，`shortTermEngineId` 累积到 944（每个 Engine ~100-200MB）
  2. **P0-次路径**：`WEGChatPageViewController.m:323-341` `groupViewControllerForItem:` 中 Discover Tab（`r_group_found`）的 `item.groupId == 0`，不写入 `groupControllers` 缓存，每次点击 Discover 创建新 `WEGFlutterWrapperViewController(keepAlive:YES, preferNewEngine:YES)` → 每次新建 FlutterEngine → Engine 快速堆积
  3. **P0-辅路径**：`WEGFlutterWrapperViewController.m:620-632` `keepAlive=YES` 时跳过 `willMoveToParentViewController:nil` 中 flutter VC 的 parent/view 清理 → TRouter 状态不重置 → Engine 被强引用保活
- **伴随泄漏（H2）**：`WEGChatPageViewController` × 15 实例（OneEvent 强引用阻断 dealloc）+ `BaseViewController.dealloc` 未调 `finishWithStatus`（span 悬空为 INT32_MAX）
- **版本定位**：`10.112.0520`，battle 页相关 `feature/10.112.0520_lego_battle_animation` 改动可能引入新的 `keepAlive+preferNewEngine` 嵌入式容器
- **关键证据**：
  - 伽利略：`FlutterContainerLifeCycle(battle)` ViewAppear=39, completed=8 → 差值 31 个泄漏容器；engineId=944；单 session 38 次 FlutterEngine 创建；4 分钟内 14 次内存警告
  - Bugly：核心 Issue `30074DDDF196CC45CF4073B608805E70`（566 用户），堆栈 `CFRUNLOOP_IS_CALLING_OUT → Flutter`；P90 内存 3.49GB
  - VCCountSnapshot：每次 `AppDidReceiveMemoryWarning` 触发，`WEGViewControllerTracker.m:76-79` → `uploadSnapshotDict` → `vc_snapshot = "ClassName1:count,..."`（弱引用 NSHashTable）
- **⚠️ 诊断要点**：
  - VCCountSnapshot span 在伽利略 MCP 中 span events 为空，具体 VC 列表需在 Web 控制台查看
  - `INT32_MAX μs = 35分47秒` 是 span 从未关闭的铁证，表示 VC/Container 整个 session 未释放
  - `ViewAppear 次数 >> FlutterContainerLifeCycle completed 次数` 的差值 = 泄漏容器数量
  - 用户单日多次 FOOM（3次）是版本性缺陷的典型特征
- **修复方向**：
  1. P0（ricoyang）：`WEGFlutterViewController.swift:205-216` 补充 `jt_navigationController == nil` 时的 dealloc 判断（父容器已移出视图层级时调 `trWillDealloc()`）
  2. P0（ricoyang）：`WEGFlutterWrapperViewController.m` 在 `keepAlive=YES` 时，`willMoveToParentViewController:nil` 应手动调用 `trWillDealloc()` 通知 TRouter
  3. P0（elioyin）：`WEGChatPageViewController.m:323-341` 修复 `r_group_found` 缓存逻辑，按类型 key（非 groupId）缓存，避免重复创建 Engine
  4. P1（bryanpeng）：`BaseViewController.dealloc:272-286` 补调 `[_viewTimeSpan finishWithStatus:OTTraceStatusError]`，防止 span 悬空
  5. P1（elioyin）：恢复 `WEGChatPageViewController.viewDidDisappear` 中注释掉的 `removeTarget:self`，配合 viewWillAppear 重注册
- **代码责任人**：ricoyang（P0 Flutter 容器3个文件：WEGFlutterViewController.swift / WEGFlutterWrapperViewController.m / WEGFlutterEngineProvider.swift）、elioyin（P0 WEGChatPageViewController.m）、bryanpeng（P1 BaseViewController.m）
- **分析来源**：Bugly Issue 30074DDDF196CC45CF4073B608805E70 · 伽利略 trace 9DD7AD2C（userId=1640207937） · 伽利略 trace fF7E73ed（userId=73168972）
- **首次记录**：2026-05-29
- **最后更新**：2026-05-29
