# Bugly Crash 模式知识库

常见 Crash 模式汇总。每个条目以「现象 → 根因 → 处置」为核心，由 bugly-assistant 在分析过程中自动积累和更新。

---

<!-- 新条目示例格式：

## 模式名称

- **现象**：xxx
- **根因**：xxx
- **处置方式**：建议修复 / 建议屏蔽 + 一句话理由
- **典型堆栈**：（可选）
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

<!-- 知识库初始为空，由 bugly-assistant 在实际使用中自动积累 -->

## 全局静态变量多线程竞态导致 SIGSEGV

- **现象**：`MTAManager.m` 中 `currentGameRole` 方法访问 `gCacheGameRole` / `gLastCacheGameRole` 时触发 SIGSEGV（野指针 crash），堆栈指向 `objc_retain` / `objc_release`，无明确业务操作路径
- **根因**：`gCacheGameRole`、`gLastCacheGameRole`、`gIsLoadingGameRole` 三个全局 `static` 变量在多线程环境下无任何锁保护；`currentGameRole` 可被任意线程调用（如 `_runtimeCommonParams`），同时 `dispatch_after` 主队列回调和 `completion` 回调从后台线程写入，导致并发读写竞态 → 野指针
- **处置方式**：使用 `@synchronized([MTAManager class])` 包裹 `currentGameRole` 方法内所有对这三个变量的读写操作（含 `dispatch_after` 回调和 `completion` 回调内的写操作）；锁对象选用类对象无需初始化，比 `NSLock` / `dispatch_queue` 改动最小
- **典型堆栈**：`[MTAManager currentGameRole]` → `objc_retain` / `objc_release`（frame 数不定，无完整调用链）
- **修复状态**：代码已修复（2026-04-28，@synchronized 全覆盖，CR 通过，待提交）；issueId 0BC182C61B1CF5353B98BE3EA3975A0C，24h 17次，下降趋势
- **首次记录**：2026-04-21
- **最后更新**：2026-04-28

## FBLPromise 重复 resolve/reject 导致断言崩溃

- **现象**：堆栈指向 `[FBLPromise reject:]`，由 `+[WEGProtobufRequest call:req:respType:]_block_invoke` 或 `call:req:respType:completion:_block_invoke` 触发；crash 次数高（近7天1266次），但在版本迭代后缓慢下降
- **根因**：`call:req:respType:` 方法创建 `FBLPromise *p` 并将其传入 completion block；当网络层（`WebServiceManager`）在超时、取消、重试等边缘场景下对同一请求**二次回调**（success + failure 各一次，或同一 callback 触发两次）时，第二次调用 `[p reject:]` 或 `[p fulfill:]` 时 Promise 已 settled → FBLPromise 内部断言失败 → crash
- **处置方式**：建议修复。在 `call:req:respType:` 的 completion block 前加 `__block BOOL settled = NO;` 幂等保护旗标，block 内首行 `if (settled) return; settled = YES;`，防止 Promise 被二次 resolve。改动 3 行，零业务逻辑影响
- **典型堆栈**：`-[FBLPromise reject:]` ← `+[WEGProtobufRequest call:req:respType:]_block_invoke` ← `+[WEGProtobufRequest call:req:respType:completion:]_block_invoke`
- **文件位置**：`social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/WEGCppBiz/request/WEGProtobufRequest.mm`
- **修复状态**：代码已修复并合入 develop（commit 5549ad3bf9，2026-03-26）；issueId 37224C7189B0DE44C01CFC046961AEAD；24h 169次（2026-04-28），老版本残留，持续下降
- **首次记录**：2026-04-22
- **最后更新**：2026-04-28

## OEEventValidator 死代码无锁并发写入导致 SIGTRAP

- **现象**：堆栈指向 `OEWebViewHandler -[triggerListenerWithToken:event:]` → `OEWebAPI -[triggerListener:event:]` → `OEDispatch -[dispatchEvent:toListeners:]`，崩溃类型 SIGTRAP
- **根因**：`OEEventValidator.m` 中 `validateEventName:` 对 `NSMutableArray validEvents` 执行无锁 `addObject:`，该方法可被任意线程调用（OEDispatch 无线程约束），多线程并发写入导致内部数据结构损坏，ObjC Runtime 检测后通过 `_objc_trap()` 触发 SIGTRAP；`validEvents` 为死代码（只写不读）
- **处置方式**：建议修复。直接删除 `validateEventName:` 中两处 `addObject:` 调用（死代码），并删除 `validEvents` 属性声明和初始化；同步在 `OEEvent.m:toJsonString` 对 `identifier`/`name` 补充 `?: @""` nil 防护（防止 NSDictionary 字面量 nil 崩溃）
- **典型堆栈**：`-[OEWebViewHandler triggerListenerWithToken:event:]` ← `-[OEWebAPI triggerListener:event:]` ← `-[OEDispatch dispatchEvent:toListeners:]`
- **涉及文件**：`Pods/OneEvent/ios/Classes/Util/OEEventValidator.m`、`Pods/OneEvent/ios/Classes/Core/OEEvent.m`（OneEvent 为本地源码引用形式 Pod，Owner: ricoyang）
- **Issue ID**：32EE2B38F33DAAA7BEF32E6E0DE7A452
- **修复状态**：代码已修复（2026-04-28，删除死代码 addObject + OEEvent nil 防护，CR 通过）；24h 9次，状态已恢复（recovered）
- **首次记录**：2026-04-28
- **最后更新**：2026-04-28

## WEGKVStorage 返回非字典类型导致 mutableCopy 崩溃

- **现象**：`-[__NSCFNumber mutableCopyWithZone:]: unrecognized selector sent to instance`，崩溃点在 `WEGCampBottomToastManager.m:125`，堆栈 Key Method 为 `+[WEGCampBottomToastManager showBottomTypeInfoWithScene:sceneConfig:]`
- **根因**：`[WEGKVStorage objectForKey:saveKey]` 返回值被直接强转为 `NSDictionary *` 并调用 `.mutableCopy`，但当持久化存储中对应 key 实际存储的是 `NSNumber` 或其他非字典类型（旧版本遗留或类型变更）时，调用 `mutableCopyWithZone:` 触发 `NSInvalidArgumentException`
- **处置方式**：建议修复。在取值后增加 `isKindOfClass:[NSDictionary class]` 类型判断，若类型不符则当 nil 处理，走默认初始化字典路径；改动 2 行，零业务逻辑影响
- **典型堆栈**：`-[__NSCFNumber mutableCopyWithZone:]` ← `+[WEGCampBottomToastManager showBottomTypeInfoWithScene:sceneConfig:]` ← `+[WEGCampBottomToastManager isNeedCampBottomToast:]`
- **文件位置**：`social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/Utils/WEGCampBottomToastManager/WEGCampBottomToastManager.m:125`
- **Issue ID**：39EEB3979A613F08EEB6E18DFA3FBBAC
- **首次记录**：2026-04-23
- **最后更新**：2026-04-23

## WEGGameAuthCenter event.data 类型假设错误导致 unrecognized selector crash

- **现象**：`-[__NSDictionaryI weg_toJsonDictionary]: unrecognized selector sent to instance`，崩溃点在 `WEGGameAuthCenter.m:52` 的 `registerOneEvent` block 内
- **根因**：`registerOneEvent` 方法监听 `authCallback` 事件，block 内调用 `[event.data weg_toJsonDictionary]`，该方法是 `NSString` 的 Category 方法（定义在 `NSString+WEGMisc.mm`），但 OneEvent 实际将 `event.data` 作为 `NSDictionary` 传入，导致对 `__NSDictionaryI` 调用不存在的方法 → NSInvalidArgumentException
- **处置方式**：建议修复。在使用前增加类型判断：若是 `NSString` 则调用 `weg_toJsonDictionary` 转换，若已是 `NSDictionary` 则直接使用，其他类型打 XLOG_ERROR 并安全返回；改动约 7 行，零业务逻辑影响
- **典型堆栈**：`-[__NSDictionaryI weg_toJsonDictionary]` ← `__37-[WEGGameAuthCenter registerOneEvent]_block_invoke(WEGGameAuthCenter.m:52)` ← `-[OENativeAPI triggerListener:event:]` ← `-[OEDispatch dispatchEvent:toListeners:]`
- **涉及文件**：`social-ios/src/GameApp/Features/WEGGameAuth/WEGGameAuthCenter.m:52`，仅存在于 `feature/10.111.0128_lego_authPanel` 分支
- **Issue ID**：3222A4C4057B5AF01E91E10D945E0556
- **责任人**：qcxiang（引入 commit：3eaa413d7d4，2026-04-24，feat(模块): 111.201-[Flutter]重构授权面板）
- **首次记录**：2026-05-08
- **最后更新**：2026-05-08

## OTTraceManager activeSpansArray 野指针导致 SIGSEGV

- **现象**：`-[OTBusinessSpanImpl attributeForKey:]` 触发 SIGSEGV SEGV_ACCERR，崩溃发生在网络请求完成后的埋点上报流程中：`WebServiceManager` 回调 → `finishWithStatus:attributes:` → `analysisAttributs:` → `traceSpanStaticParams:subModuleName:` → `realLogWithLevel:` → `getSpanByModuleName:` → `attributeForKey:` 崩溃
- **根因**：`getSpanByModuleName:` 方法（OTTraceManager.m:871）从 `activeSpansArray` 遍历时，对 `entry.span` 未做 nil 检查直接调用 `attributeForKey:`；当某个 `OTBusinessSpanImpl` 对象生命周期结束后被释放，但 `activeSpansArray` 仍持有该引用，导致访问已释放内存（SEGV_ACCERR）；iOS 17+ / arm64e 架构对野指针更敏感
- **处置方式**：建议修复。在 `getSpanByModuleName:` 遍历循环中，在调用 `entry.span attributeForKey:` 前增加 `if (!entry.span) { continue; }` 空检查；同时在 `attributeForKey:` 方法内 `internalSpan` 调用前增加 `if (!self.internalSpan) { return nil; }` 防护；改动约 6 行，零业务逻辑影响
- **典型堆栈**：`objc_retain_x0` ← `-[OTBusinessSpanImpl attributeForKey:](OTTraceManager.m:104)` ← `-[OTTraceManager getSpanByModuleName:](OTTraceManager.m:871)` ← `-[OTLogManager realLogWithLevel:](OTLogManager.m:390)` ← `-[OTBusinessSpanImpl traceSpanStaticParams:subModuleName:](OTTraceManager.m:258)` ← `WebServiceManager` AFNetworking 回调
- **涉及文件**：`social-ios/xcodeproj/CampTools/CampTools/Classes/Galileo/Core/WEGOTTraceManager/OTTraceManager.m`（第 102-110 行、第 860-882 行）
- **影响数据**：上报 7 次，影响用户 7 人，版本范围 9.104.0917 ~ 10.112.0429（跨版本持续存在）
- **修复难易度**：中等（需理解 Span 生命周期管理，涉及埋点核心逻辑）
- **修复状态**：代码已修复（2026-05-12，nil 防护 6 行，CR Round 1 通过）；后续建议将 `OTSpanEntry.span` 改为 `weak` 以彻底解决野指针根因
- **修复 diff 要点**：
  1. `attributeForKey:` 末尾 `return [self.internalSpan attributeForKey:key]` 前加 `if (!self.internalSpan) { return nil; }`
  2. `getSpanByModuleName:` 遍历循环内取 `entry` 后立即加 `if (!entry.span) { continue; }`
  3. **CR 注意事项**：两处均为 `strong` 属性，nil 检查对当前野指针场景是防御性措施；根因修复需将 `OTSpanEntry.span` 改为 `weak`，待后续跟进
- **Issue ID**：156FEB9D09464122DBAC3F0D7B0B99A7
- **责任人**：bryanpeng（最近维护者，多次修复同文件 crash）
- **首次记录**：2026-05-11
- **最后更新**：2026-05-12

## WEGSoundManager 后台线程并发写字典导致 SIGSEGV

- **现象**：`-[__NSDictionaryM setObject:forKey:]` 触发 SIGSEGV (SEGV_ACCERR)，崩溃发生在 `WEGSoundManager.m:80`（`_playSoundEffect:` 的 `dispatch_async` 后台 block 中），线程 37，进程 SmobaHelper
- **根因**：`_playSoundEffect:` 方法通过 `dispatch_async(global_queue, ...)` 在后台线程加载并缓存音效 SystemSoundID；多个音效请求并发时，多个后台线程同时读写 `soundEffectToIDMap`（NSMutableDictionary）且无任何锁保护，NSMutableDictionary 非线程安全，并发写入导致内部结构损坏 → SEGV_ACCERR
- **引入时机**：commit `b5adaa69529`（bryanpeng，2025-03-18，`fix:声音卡顿放到子线程`）将音效加载移至后台线程时未添加同步
- **处置方式**：建议修复。将 `soundEffectToIDMap` 改为在 `init` 中初始化（消除懒加载竞态），并用 `@synchronized(self)` 完整包裹 `_playSoundEffect:` 后台 block 内的 if/else 结构（含读取 + 写入 + else 赋值，改动约 12 行，零业务逻辑影响）
- **修复 diff 要点**：
  1. 新增 `- (instancetype)init` 方法直接初始化 `_soundEffectToIDMap = [NSMutableDictionary new]`
  2. 将懒加载 getter 改为直接 `return _soundEffectToIDMap`（去除 if 判断）
  3. 后台 block 内用 `@synchronized(self) { ... }` 完整包裹 `NSNumber* soundNumber = ...` + `if (!soundNumber) { ... } else { soundID = ... }` 整体结构
  4. 注意：不能在 `@synchronized` 块内声明 soundNumber 后在块外使用，必须将整个 if/else 放在块内
- **典型堆栈**：`-[__NSDictionaryM setObject:forKey:]` ← `__36-[WEGSoundManager _playSoundEffect:]_block_invoke(WEGSoundManager.m:80)` ← libdispatch
- **涉及文件**：`social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/Logic/WEGSoundManager/WEGSoundManager.m`
- **Issue ID**：A192D45BECFBA9510EF00D7E33C9BFD3
- **责任人**：bryanpeng（引入 commit `b5adaa69529`）
- **修复状态**：代码已修复（2026-05-12，@synchronized 完整包裹 if/else + init 初始化，CR 3轮通过）
- **首次记录**：2026-05-11
- **最后更新**：2026-05-12

## WEGSingleFileDirConfig 正则匹配 nil 路径导致 SIGTRAP

- **现象**：崩溃类型 SIGTRAP，后台线程（Thread 27），堆栈路径为 `WEGDiskMonitor.calculateAllDiskSize` → `toReportDiskDataIfNeed` → `fileSizeAtPath:shouldStatistics:` → `matchFileIfNeed:isDir:fileSize:` → `matchFile:fileSize:` → `WEGSingleFileDirConfig.isMatchWithPath:fileSize:` → `NSString rangeOfString:options:NSRegularExpressionSearch` → `NSCache -[objectForKey:]` → `CFEqual`
- **根因**：服务器下发的磁盘清理配置中，`WEGDiskCleanMatchTypeRex` 类型条目的 `matchPath` 字段为 nil 或空字符串，调用 `[path rangeOfString:self.matchPath options:NSRegularExpressionSearch]` 时，Foundation 内部在 `NSCache` 缓存比较阶段触发 `CFEqual` 异常，最终 SIGTRAP
- **处置方式**：建议修复（双重防护）。1) 配置加载层（`WEGDiskCleanMatchConfig.m`）files/dirs 两个循环内对 `matchPath` 类型+空值校验，非 NSString 或空值则 `continue` 跳过，同时赋值时加 `?: @""` 兜底；2) 匹配使用层（`WEGSingleFileDirConfig.m`）`isMatchWithPath:fileSize:` 和 `isMatchWithDirOnlyPath:` 两个方法的 `WEGDiskCleanMatchTypeRex` case 均加 `matchPath.length == 0` 判断 + `@try-catch` + `CAMP_LOG_ERROR` 日志
- **典型堆栈**：`-[WEGSingleFileDirConfig isMatchWithPath:fileSize:]` ← `+[WEGDiskMonitor matchFile:fileSize:]` ← `+[WEGDiskMonitor matchFileIfNeed:isDir:fileSize:]` ← `+[WEGDiskMonitor fileSizeAtPath:shouldStatistics:]`
- **涉及文件**：`social-ios/src/GameApp/Features/APM/Disk/WEGSingleFileDirConfig.m:35-46`（isMatchWithPath）和 `:62-74`（isMatchWithDirOnlyPath）；`social-ios/src/GameApp/Features/APM/Disk/WEGDiskCleanMatchConfig.m:58-76`
- **CR 注意事项**：Round 1 CR 发现 `isMatchWithDirOnlyPath:` 漏修，修复 diff 需覆盖两个方法；`NSLog` 须改为 `CAMP_LOG_ERROR`
- **Issue ID**：0DEBBD0CF924C61EA541925047CE0170
- **责任人**：leviyin（最近 WEGDiskMonitor.m / WEGDiskCleanMatchConfig.m 修改者，2026-02-05）；原始作者 etundliang（2022年，已无近期提交）
- **修复状态**：代码已修复（2026-05-12，双重防护方案，CR 2 轮通过，待提交）
- **首次记录**：2026-05-11
- **最后更新**：2026-05-12

## SmobaHelper UnreadChatMessageObserver 持久化缓存类型污染

- **现象**：`-[__NSTaggedDate longLongValue]: unrecognized selector sent to instance 0xa7...`，崩溃发生在 `UnreadChatMessageObserver initOffaccsSession`，由 `sharedInstance`（单例 dispatch_once）触发，App 启动或登录时发生
- **根因**：`initOffaccsSession`（无参数）内部从持久化存储（NSUserDefaults / Keychain / 文件缓存）读取某时间戳字段，代码预期类型为 `NSNumber`，但实际存储的是 `NSDate` 对象（被 Tagged Pointer 编码为 `__NSTaggedDate`），调用 `longLongValue` 时 NSDate 不响应该 selector → NSInvalidArgumentException
- **处置方式**：需联系 SmobaHelper / SmobaPod 维护者修复；临时方案是清除用户侧脏缓存（用户退出登录重新登录可能缓解）
- **典型堆栈**：`-[UnreadChatMessageObserver initOffaccsSession]` ← `-[UnreadChatMessageObserver init]` ← `+[UnreadChatMessageObserver sharedInstance]_block_invoke`
- **特别说明**：方法名是 `initOffaccsSession`（无冒号无参数），曾有分析误写为 `initOffaccsSession:` 带冒号——后者从未在代码历史中存在
- **影响版本**：主要集中在 10.112.0415（75%）、10.111.x 系列；9.102.0212 **不在**影响版本列表中
- **Issue ID**：5C5D80644DD3C316975221BB194C29D9；24h 44 次，影响用户 6 人（2026-05-08）
- **首次记录**：2026-05-08
- **最后更新**：2026-05-08

## WEGDiskMonitor subpathsAtPath 内存分配失败导致 NSMallocException

- **现象**：`*** -[NSFileManager fileSystemRepresentationWithPath:]: unable to allocate memory for length (1360)`，崩溃发生在 `WEGDiskMonitor.m:264` 的 `folderSizeAtPath:shouldStatistics:` 方法中，后台计算队列（Thread 15）中触发
- **根因**：`folderSizeAtPath:shouldStatistics:` 使用 `subpathsAtPath:` 一次性递归加载目录下所有文件路径到内存，内部调用 `fileSystemRepresentationWithPath:` 对超长路径（1360字节）进行 C 字符串转换时内存分配失败 → NSMallocException
- **处置方式**：建议修复。将 `[[manager subpathsAtPath:folderPath] objectEnumerator]` 替换为 `[manager enumeratorAtPath:folderPath]`（流式遍历，避免一次性全量加载），同时在遍历循环内增加路径长度过滤（`fileName.length > 1024` 时跳过）；改动约 5 行，零业务逻辑影响
- **典型堆栈**：`toReportDiskDataIfNeed` → `calculateAllDiskSize` → `folderSizeAtPath:shouldStatistics:` → `subpathsAtPath:` → `fileSystemRepresentationWithPath:` → NSMallocException
- **涉及文件**：`social-ios/src/GameApp/Features/APM/Disk/WEGDiskMonitor.m:264`
- **责任人**：leviyin（精确匹配该文件，最近提交 2026-02-05）
- **Issue ID**：FCA3704A349DDA1B24F062A7BF65971A；崩溃设备：iPhone 16 Pro Max (iOS 18.1)
- **修复状态**：代码已修复（2026-05-11，流式遍历替代 + 路径长度过滤，CR 通过）
- **首次记录**：2026-05-11
- **最后更新**：2026-05-11

## OneEvent DartBridge Use-After-Free 导致 SIGSEGV SEGV_ACCERR（Flutter 页面销毁时野指针）

- **现象**：崩溃类型 SIGSEGV SEGV_ACCERR，fault addr: `0x0000000000000010`，崩溃点在 `oe::DartBridge::AsyncDart(std::function<void()>)`（dart_bridge.cc:40），由 `oe_watchObjectDealloc` → `Flutter InternalFlutterGpu_Texture_AsImage` 触发；主线程崩溃，触发场景为从推荐页（recommend_page）返回后 Flutter 页面销毁时
- **根因**：Use-After-Free（访问已释放内存）。Flutter ViewController 销毁时，Dart 对象被释放（`oe_watchObjectDealloc` 回调触发），但 Native 层的异步回调仍持有已释放的 `DartBridge` 实例的引用并调用其方法，导致访问无效内存地址（0x10 = 偏移量 16，典型野指针特征）
- **涉及文件**：`OneEvent.podspec`（OneEvent 库，独立仓库 `git.woa.com/koh_social/OneEvent`）中的 `cpp/shared/dart_bridge.cc:40`、`ios/Classes/Container/Flutter/OEFlutterAPI.mm`；主仓相关路径：`social-ios/xcodeproj/WEGFlutter/Classes/`
- **处置方式**：联系 OneEvent 库维护者（ricoyang）修复。修复方向：1) 在 `DartBridge::AsyncDart` 执行前增加 `weak_ptr` 有效性检查；2) 在 `OEFlutterAPI.mm` `dealloc` 中取消所有待执行的 Dart 异步回调；3) 长期方案：将 `DartBridge` 对象改为 `weak_ptr` 生命周期管理
- **典型堆栈**：`oe::DartBridge::AsyncDart(+380)` ← `oe::DartBridge::AsyncDart(+332)` ← `oe::DartBridge::NativeReady(int)` ← `oe_watchObjectDealloc` ← `Flutter InternalFlutterGpu_Texture_AsImage`
- **Issue ID**：0C1CDBB7F94B24D2EF3BF60E5160B73D
- **责任人**：ricoyang（OneEvent 库 iOS 端 Owner，podspec author，历史5次修复同类 OneEvent SIGSEGV 崩溃）；备选：owenncwang（Flutter 推荐容器方向）
- **历史修复记录（ricoyang）**：commit `beec7dcb93b`（2026-04-22）、`111a231282c`（2026-01-26）、`148124ce824`（2026-01-19）、`ae7482c139f`（2025-10-22）均为 OneEvent SIGSEGV 修复
- **修复状态**：分析完成，已给出修复方向；`dart_bridge.cc` / `OEFlutterAPI.mm` 源码在独立仓库，需 ricoyang 在 OneEvent 仓库中实施修复
- **5月15日激增原因**：当前 Bugly API 不支持直接版本分布查询，需在 Bugly Web 控制台的「版本分布」Tab 确认是否有新版本上线触发；推断可能原因：Flutter SDK 版本升级、推荐页路由逻辑变更增加页面切换频率
- **已知受影响用户**：userId 1860220455（2026-05-18 15:57:50 崩溃）
- **首次记录**：2026-05-18
- **最后更新**：2026-05-18

## JTNavigationController 插入 nil rootViewController 导致 NSInvalidArgumentException

- **现象**：`NSInvalidArgumentException: attempt to insert nil object from objects[0]`，崩溃位置 `JTNavigationController.m:412`，触发场景为用户在聊天页面点击分享链接触发路由跳转（视频播放器页面）
- **根因**：`WEGRouteHandler.m:1162-1187` 的 `kRouteAction_video` 分支中，当 `srcType` 参数既不是 `"TYPE_URL"` 也不是 `"TYPE_VID"` 时（异常服务端数据），`controller` 变量保持为 nil；后续代码未做 nil 检查，直接将 nil 传入 `[[JTNavigationController alloc] initWithRootViewController:nil]`，`JTWrapViewController wrapViewControllerWithViewController:nil` 返回 nil 后被插入 `@[nil]` 字面量 NSArray 触发 NSInvalidArgumentException
- **处置方式**：建议修复（主防御点在 `WEGRouteHandler.m`）：在 `WEGRouteHandler.m:1182` 的 `TYPE_VID` if-else 块后增加 nil 检查（`if (!controller) { CAMP_LOG_ERROR...; return NO; }`）；次防御：`JTNavigationController.m:412` 对 `wrapViewControllerWithViewController:` 返回值判 nil 后 return nil
- **修复 diff 要点**：`WEGRouteHandler.m` 第 1182 行后插入：`if (!controller) { CAMP_LOG_ERROR(@"[WEGRouteHandler]", @"video action failed: invalid srcType=%@, src=%@", srcType, src); return NO; }`（约 4 行）
- **典型堆栈**：`-[__NSPlaceholderArray initWithObjects:count:]` ← `-[JTNavigationController initWithRootViewController:]` ← `-[WEGRouteHandler handleSpecialRouteWithManager:parameters:]` ← `-[WEGRouteManager handleSpecialRoute:]` ← `MultipleChatMessageViewController+ChatTable.m:1400`
- **涉及文件**：`social-ios/src/GameApp/Features/Manager/WEGRouteManager/WEGRouteHandler.m:1162-1187`（主修）；`social-ios/xcodeproj/CampCore/CampCore/Classes/BaseUI/Vendor/JTNavigationController/JTNavigationController.m:412`（次防护）
- **Issue ID**：8FAD123699D198742B8536855AB9340D
- **影响数据**：1台设备，版本 10.112.0429（iOS 26.3，iPhone 17,1），2026-05-12 16:44 触发
- **责任人**：qcxiang（主责，WEGRouteHandler.m 6个月12次提交、3个月7次提交，是该文件最活跃维护者）；ricoyang（次责，JTNavigationController 维护者，可做二次防护）
- **修复状态**：已给出 git diff 修复方案，待 qcxiang 实施并提交
- **首次记录**：2026-05-11
- **最后更新**：2026-05-12
