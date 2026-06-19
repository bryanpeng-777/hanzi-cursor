# 程序员助手 高频 Bug 模式知识库

记录项目中反复出现的 bug 模式、根因和修复方式。由 dev-assistant 在实际使用中自动积累。

---

<!-- 新条目示例格式：

## 模式名称（如：FBLPromise reject nil 导致 crash）

- **现象**：xxx
- **根因**：xxx
- **修复方式**：xxx
- **相关文件**：xxx
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

## FBLPromise 二次 reject/fulfill 断言 crash（WebServiceManager 重复回调）

- **现象**：`-[FBLPromise reject:]` 崩溃，堆栈经过 `WEGProtobufRequest call:req:respType:` 的 block_invoke
- **根因**：`WebServiceManager` 在超时/取消等边缘场景下 success/failure block 可能被二次调用，导致 `FBLPromise` 被重复 `reject:` 或 `fulfill:`，触发 FBLPromise 内部断言 crash
- **修复方式**：在 promise wrapper 的 completion block 外声明 `__block BOOL settled = NO;`，block 首行加 `if (settled) return; settled = YES;` 幂等保护，共 3 行改动
- **关键点**：只需在把 completion 桥接成 FBLPromise 的那一层加保护，底层 `call:req:respType:completion:` 无需改动
- **相关文件**：`social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/WEGCppBiz/request/WEGProtobufRequest.mm`（`call:req:respType:` 方法）
- **Bugly Issue**：`37224C7189B0DE44C01CFC046961AEAD`
- **首次记录**：2026-04-22
- **最后更新**：2026-04-22

## ObjC 全局静态强引用多线程竞争导致 SIGSEGV/SEGV_ACCERR

- **现象**：后台线程调用某方法时触发 `SIGSEGV SEGV_ACCERR`，堆栈指向访问全局 `static BaseRole* gXxx = nil` 等强引用变量
- **根因**：ObjC ARC 对强引用的 retain/release 不是原子操作。多线程并发读写 `static id` 变量（一个线程写 nil 触发 release，另一个线程持有旧指针做 retain）→ use-after-free
- **修复方式**：用 `@synchronized([ClassName class])` 包裹所有对这些全局变量的读写（包括方法主体、dispatch_after block、completion block 内部）。`@synchronized` 在 ObjC 中对同一线程可重入，不会死锁
- **关键点**：dispatch_after 的 block 也必须加锁——常被遗漏，但 `gCacheGameRole = nil` 在 dispatch_after 里触发的 release 正是 crash 来源
- **相关文件**：`social-ios/xcodeproj/WEGGlue/WEGGlue/Classes/Logic/MTA/MTAManager.m`（`currentGameRole` 方法，`gCacheGameRole`/`gLastCacheGameRole`/`gIsLoadingGameRole`）
- **Bugly Issue**：`0BC182C61B1CF5353B98BE3EA3975A0C`
- **首次记录**：2026-04-21
- **最后更新**：2026-04-21
