# 营地问题分析 常识参考

平台参数、字段说明、已知特殊行为等背景常识。由 camp-problem-analyzer 在分析前自动读取。

---

## 时间处理规范

- 用户未提供时间时，默认使用**今天**（Asia/Shanghai 时区）
- 用户说"昨天"时，取昨天全天（00:00 ~ 23:59）
- 用户说"今天下午"等模糊时间，取对应时段，分析范围可适当放宽 ±1 小时

## ⛔ 代码仓库全貌（必读，禁止错误声明「代码不在仓库」）

营地大仓 `work_tree_monorepo` 包含以下代码仓库，**分析前必须确认**：

| 平台 | 仓库目录 | 主要代码路径 |
|------|----------|------------|
| **iOS** | `social-ios/xcodeproj/` | WEGGlue、CampCore、WEGBase、WEGLauncher、WEGFlutter 等 ObjC/Swift |
| **Android** | `social-android/` | `gamehelper/src/main/java/com/tencent/gamehelper/` |
| **Flutter** | `flutter_module/lib/` | Dart，iOS/Android 共用 |
| **TGA 电视台** | `TGA_Main_Proj/` + `TGAFoundation/` | ObjC/Swift |
| **播放器** | `WEGPlayer/` + `flutter_thumbplayer/` | ObjC + Flutter |
| **C++ 网络层** | `WEGCpp/` | C++ |
| **特效/扩展** | `Fireworks/`、`PandoraEx/` | ObjC |

### Android 关键路径速查

| 功能 | 文件路径 |
|------|---------|
| **发送聊天消息（单聊/多游）** | `gamehelper/.../ui/chat/ChatModel.kt`（`sendMultiGameMessage`/`sendPrivateChat`） |
| **发消息接口定义** | `gamehelper/.../ui/contact2/api/ChatApi.kt`（`sendSingleChatMessage`/`sendMessageSuspendRx`） |
| **聊天 UI Fragment** | `gamehelper/.../ui/chat/GameChatFragment.kt`、`BaseChatFragment.kt` |
| **旧版发消息 Scene** | `gamehelper/.../netscene/GameSendMessageScene.java`（`/game/sendmessage` 旧接口） |
| **IM 消息分发** | `gamehelper/.../im/MessageDispatcher.kt`、`IMManager.kt` |

### ⛔ 强制规则

- **Step 7 前必须先确认平台**，再查对应仓库目录
- **禁止在未执行 `ls` 或 `find` 前声明「Android/iOS 代码不在本 monorepo」**
- Android 代码在 `social-android/`，iOS 代码在 `social-ios/`，两者**均在大仓中**

---

## userId 格式说明

- 营地 userId 为纯数字字符串
- 若用户提供了昵称、openid 等非 userId 格式，需提示用户提供数字 userId

## 问题描述规范

- 描述应尽量包含：功能名称、错误现象、错误码（若有）、操作步骤
- 若用户描述过于简短（如"打不开"），在五要素确认时提醒用户补充细节以提升分析准确性

---

## 伽利略 MCP 工具使用规范（数据准确性强制约束）

### ⛔ 禁止使用 tag_statistics 推断单个用户行为次数

**错误做法（禁止）**：
```
// 先查全量数据，再从 tag_statistics 读取 moduleName 的 count 值来推断用户行为次数
query: "tags.userId=xxx"
group_by_tags: ["moduleName"]
→ 读取 tag_statistics[moduleName=FlutterEngineCreateToFirstFrameInit].count = 283
→ 结论：该用户触发了 283 次 Engine 初始化
```
**错误原因**：`tag_statistics` 字段是聚合统计，其行为依赖平台实现，不应作为单用户行为次数的权威来源。即使 filters 中包含 userId，也不能保证 tag_statistics 的计数语义等同于"该用户触发了 N 次该 moduleName 的日志"。

**正确做法（强制）**：统计单个用户某 moduleName 的日志条数，必须：
1. 在 `filters` 中**同时包含** `tags.userId=xxx AND tags.moduleName=yyy`
2. 读取返回结果的 `log_count.total_count.current` 字段作为权威计数
3. 如需确认日志内容，读取 `sample_logs` 中每条日志的 `tags.userId` 字段逐一核验

```
// 正确示例
filters: "tags.userId=1848782023 AND tags.moduleName=FlutterEngineCreateToFirstFrameInit"
→ log_count.total_count.current = 283  ← 这才是该用户的权威日志条数
```

### 日志条数与行为次数的换算规则

对于具有 `-start` / `-end` 对的 span 类日志（如 `FlutterEngineCreateToFirstFrameInit`）：
- 每次行为 = 1 条 `-start` 日志 + 1 条 `-end` 日志 = **2 条日志**
- 实际行为次数 = `total_count / 2`（通过 message_templates 分别确认 start/end 条数可进一步精确）
- 示例：total_count=283 → start=142, end=141 → 实际 Engine 创建次数 ≈ **141 次**，而非 283 次

### device_id 与 qimeiId 的区别

- `tags.device_id`（IDFV）：可能因 App 重装、iOS 重置而改变，**不稳定**，不应用于设备唯一性判断
- `tags.qimeiId`（QIMEI）：腾讯设备指纹，即使 IDFV 变化也保持稳定，**用于判断同一物理设备**
- 若同一 userId 的多条日志 qimeiId 相同但 device_id 不同 → 同一设备，App 可能经历了重装或 iOS 26 Beta 的 IDFV 重置行为

<!-- 新增常识请追加到对应章节下方 -->
