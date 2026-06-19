# Bugly ANR 模式知识库

常见 ANR 根因模式汇总。由 bugly-assistant 在分析过程中自动积累和更新。

---

<!-- 新条目示例格式：

## 模式名称

- **现象**：xxx（如：主线程等待锁超过 5s）
- **根因**：xxx
- **处置方式**：建议修复 / 建议屏蔽 + 一句话理由
- **典型堆栈**：（可选）
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

<!-- 知识库初始为空，由 bugly-assistant 在实际使用中自动积累 -->

## Flutter Shell::OnPlatformViewDestroyed 主线程等待 ANR

- **现象**：多用户在退出含 PlatformView 的 Flutter 页面时，iOS Watchdog 检测到主线程被 `AutoResetWaitableEvent::Wait()` 阻塞超时，触发 ANR
- **根因**：Flutter 引擎在销毁 PlatformView 时（`Shell::OnPlatformViewDestroyed`）通过 `fml::AutoResetWaitableEvent::Wait()` 等待 GPU/IO 线程完成清理，若清理耗时超过 Watchdog 阈值（通常 5s），主线程被阻断触发 ANR
- **处置方式**：**已在处理中（repairing）** — 由 ricoyang 跟进；短期可考虑通过 `ios_disable_flutter_engine_delay_release` 开关控制延迟释放；长期需评估 Flutter PlatformView 销毁链路是否可异步化
- **典型堆栈**：`flutter::Shell::OnPlatformViewDestroyed()` → `fml::AutoResetWaitableEvent::Wait()` → `std::_fl::condition_variable::wait()`
- **已知涉及文件**：`WEGFlutterWrapperViewController.m`（`dealloc` 中含 `flutterViewController.hasPlatformView` 检测 + 延迟释放逻辑）
- **Bugly Issue ID**：`F016BCCD7F4C225987DA94A558790623`
- **规模**：累计 27,012 次，26,248 台设备（截至 2026-05-07）；主版本 10.112.0415.68220107960112 占 80%；首次上报 2026-03-22，最近上报 2026-05-07
- **Bugly 负责人**：ricoyang
- **收敛进展（2026-05-10~11）**：版本 10.112.0429（2026-05-08 发布）上线后，该 issue 显著收敛；5月10日~11日收敛幅度 **-74%**（1,995次→517次），本周 vs 上周整体下降 **37%**。同期 Flutter PlatformView NotifyCreated issue（CE5EA0C04F5D60B3367FD285365CA69A）也收敛 -73%，说明新版本包含系统性 PlatformView 修复
- **版本爬坡背景**：10.112.0415 用户从 25.9%（5月9日）降至 11.3%（5月11日），新版 10.112.0429 用户升至 75%，是 ANR 大盘下降的主驱动
- **首次记录**：2026-04-30
- **最后更新**：2026-05-14

## WEGFMDatabaseQueue 主线程 dispatch_sync 阻塞

- **现象**：主线程直接调用 `WEGFMDatabaseQueue.inTransaction:` 或 `inDatabase:`，内部 `dispatch_sync` 到 DB 串行队列，导致主线程被阻塞触发 Watchdog ANR
- **根因**：网络回调（AFNetworking success 回调）或 viewDidLoad/生命周期方法中，未切换线程直接执行数据库写入操作
- **处置方式**：建议修复 — 将 DB 写入操作改为 `dispatch_async(global_queue)` 异步执行，UI 回调再 `dispatch_async(main_queue)`
- **典型堆栈**：`DatabaseManager.updateUserGameAccounts` / `AccountManager.updateAccount` → `WEGFMDatabaseQueue.inTransaction:` → `dispatch_sync`
- **已知涉及文件**：`DatabaseManager.m`、`AccountManager.m`、`WebServiceManager+Account.m`、`WEGMultiGameServiceImp.m`、`WEGNewRoleManageViewController.m`、`LoginOperator.m`
- **首次记录**：2026-04-28
- **最后更新**：2026-04-28

## iOS 16+ Pasteboard IPC 阻塞主线程

- **现象**：主线程（viewDidLoad 或其他生命周期方法）中同步读取 `UIPasteboard.string`，在 iOS 16+ 触发 Pasteboard daemon IPC 调用，主线程等待系统响应导致 ANR
- **根因**：`WEGCampOpenSDKDataReport.parseCampSdkPasteboard` 在 iOS 14 以下直接在主线程读 UIPasteboard；iOS 14+ completionHandler 路径也可能回主线程同步读，均阻塞主线程
- **处置方式**：建议修复 — 将 pasteboard 读取全部异步化，使用 `UIPasteboard.general.detectPatterns` 异步 API 或 `dispatch_async(global_queue)` 异步读取后回调
- **典型堆栈**：`SideViewController.viewDidLoad` → `WEGCampOpenSDKDataReport.parseCampSdkPasteboard` → `UIPasteboard.string`
- **已知涉及文件**：`SideViewController.m`、`WEGCampOpenSDKDataReport.m`
- **首次记录**：2026-04-28
- **最后更新**：2026-04-28
