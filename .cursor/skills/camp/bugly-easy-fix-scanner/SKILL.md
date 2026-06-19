---
name: bugly-easy-fix-scanner
description: "从王者营地 iOS Bugly Crash 列表中找到一个可以直接修复的业务代码 Crash（排除三方库、系统库、多线程问题，且必须能在代码库中搜索到对应文件/类名）。当用户提到「扫描 Bugly」「Bugly 难易度」「哪些 crash 容易修」「bugly-easy-fix-scanner」「Crash 易修复清单」「帮我找一个容易修的 crash」时触发。"
---

# Bugly Easy Fix Scanner

从王者营地 iOS Bugly 近期 Crash 中，**找到第一个可以直接修复的业务代码 Crash**，并给出修复方向。

## 目标

找到**一个**满足以下全部条件的 Crash：

| 条件 | 说明 |
|------|------|
| ✅ 业务代码 | 堆栈中有可识别的业务类名（WEG/Camp/Smoba 等前缀） |
| ✅ iOS 代码库可搜索 | 类名能在 `social-ios/src` 中 grep 到（.m/.mm/.swift） |
| ❌ 非 Flutter 侧 | 不是需要改 Flutter/Dart 代码才能修复的 crash |
| ❌ 非三方库 | 崩溃点不在 Pods/ 或三方 SDK 内部 |
| ❌ 非系统库 | 崩溃点不在 Foundation/UIKit/libsystem 等 |
| ❌ 非多线程问题 | 不是竞态条件/死锁/dispatch 相关 |

---

## 执行流程

### Step 1：调用 Bugly Agent 获取 Crash 列表

```bash
python3 ~/.claude/skills/camp/bugly-easy-fix-scanner/scripts/scanner.py
```

脚本按以下顺序处理每条 Crash，**找到第一个通过的即返回**：

```
对每条 Crash：
  1. 检查标题是否含业务类名前缀 → 否则跳过
  2. 检查是否含多线程关键词 → 是则跳过
  3. 检查是否是已知三方库/系统崩溃模式 → 是则跳过
  4. 从标题提取类名，在本地代码库 grep → 找不到则跳过
  5. 通过 → 输出结果，退出
```

### Step 2：输出格式

```
✅ 找到可修复 Crash

📋 Crash 信息
  issueId : XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  标题    : WEGProtobufRequest reject:nil
  次数    : 5,995 次（近7天）
  链接    : https://bugly.woa.com/...

📂 代码定位
  文件    : social-ios/xcodeproj/WEGGlue/.../WEGProtobufRequest.mm
  grep 命中: WEGProtobufRequest (第 3 处)

🔧 修复方向
  nil 未判断，reject:nil 触发 FBLPromise crash。
  建议在 parseFromData 返回 nil 时构造 NSError 再传给 completion。

🔗 Bugly 链接：https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&feature=XXXX
```

### Step 3：无结果处理

若遍历完所有 Crash 均未通过筛选，输出：

```
⚠️  本次未找到满足条件的可修复 Crash
原因统计：
  - 非业务代码：N 条
  - 多线程问题：N 条
  - 三方库/系统：N 条
  - 代码库未找到：N 条
建议：适当放宽过滤条件或增加扫描数量（--limit 100）
```

---

## 过滤规则详情

### 业务代码前缀（需命中至少一个）

```
WEG, Camp, Smoba, OE, MTA, Widget, Quality, Video,
Multiple, WXApi, TXPlayer
```

### 多线程关键词（命中则跳过）

```
pthread, dispatch_async, dispatch_sync, NSOperationQueue,
GCD, thread, race condition, mutex, deadlock, semaphore,
__NSDictionaryM, __NSArrayM  # 常见多线程容器崩溃
```

### 三方库/系统排除模式

```
Pods/, /usr/lib/, Foundation, UIKit, libsystem,
HippyBridge, JSContext, HippyJSExecutor,  # 引擎层
WebKit, CoreGraphics, CoreData
```

### Flutter 侧排除关键词（命中则跳过）

```
FlutterViewController, FlutterEngine, FlutterBinaryMessenger,
FlutterMethodChannel, FlutterPlugin, FlutterBoost,
WEGFlutter, WEGFlutterVC, dart::, DartVM, flutter::
```

### 代码库搜索路径（仅 iOS 原生）

```
/Users/bryanpeng/work_tree_bugfix/social-ios/src/    ← 搜索 .m/.mm/.swift
```

> Flutter 侧代码（`flutter_module/lib/`）不在搜索范围内，
> 在 Flutter 路径中找到的 crash 会被过滤掉。

---

## 配置

- **Bugly Token**：`~/.bugly_token_cache.json`（key: `bugly_user_token`）或环境变量 `BUGLY_USER_TOKEN`
- **产品 ID**：硬编码 `ef14bfff8f`（王者营地 iOS）
- **扫描数量**：默认 Top 50，可通过 `--limit` 参数调整
- **dry-run 模式**：`--dry-run` 使用内置 mock 数据测试
