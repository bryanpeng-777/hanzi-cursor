# 营地反馈分析报告

**生成时间**：2026-05-19 11:35  
**工作目录**：`/Users/bryanpeng/.claude/skills/camp-feedback-skills/output/uid_1633877949_20260518_20260518_230705`

---

## 一、反馈基础信息

| 字段 | 内容 |
|------|------|
| 反馈来源 | iFeedback（主动检索，uid+时间窗命中） |
| 反馈 ID | `O7mgO54BgkaEuDzpWumt` |
| userId | 1633877949 |
| 聊天对象 userId | 2139085419（roleId=824936152） |
| 本人 roleId | 3969737519 |
| 平台 | iOS |
| 版本 | 10.112.0429 |
| 反馈时间 | 2026-05-18 23:07:05 |
| 用户描述 | "跟朋友聊天突然被禁言了" |

---

## 二、日志与附件概览

| 项目 | 详情 |
|------|------|
| 日志来源 | iFeedback COS 附件下载 |
| xlog 文件 | `smoba_20260517.xlog`（149,557行，解码✅）、`smoba_20260518.xlog`（195,945行，解码✅）|
| 解码状态 | 成功 2 / 失败 0 / 跳过 0 |
| 截图 | 无 |
| 日志时间范围 | 2026-05-17 23:48 ~ 2026-05-18 23:xx（完整覆盖问题时间点）|
| download_failures | 无 |
| decode_failures | 无 |
| lego 状态 | 接口未接入，跳过 |

---

## 三、截图分析

无截图附件，跳过此章节。

---

## 四、根因分析

### 4.1 总结结论（置信度：**高**）

> **服务端在 2026-05-18 23:00:43 对 uid=1633877949 执行了聊天禁言处罚，通过 IMSDK `punishMessage` 指令 + XGPush 双通道主动推送至客户端。此后用户所有发送请求均被服务端以错误码 `-30098 "你已被禁言"` 拒绝。客户端行为完全正常，问题根因在服务端聊天审核/风控系统。**

---

### 4.2 完整事件时间轴

#### T1 — 23:00:39 | 最后一次成功发送（图片消息）

- **L207758** `[2026-05-18 +80 23:00:39.355]` `WebServiceManager.m:437`  
  向 uid=2139085419 发送图片消息（chatType=5）

- **L207766** `[2026-05-18 +80 23:00:39.777]` `WebServiceManager.m:704`  
  `[[BaseNet]resp chatserver/sendsinglechatmessage ... "returnCode":0,"returnMsg":""}` ← **成功，messageID=708496897648**

#### T2 — 23:00:43 | ⭐ 服务端下发禁言指令（punishMessage）

- **L207862** `[2026-05-18 +80 23:00:43.771]` `ChatTimHandler.m:185`  
  `[chat] imsdk onRecvNewMessage, msgId: 144115388005993729-1779116443-1779116443`

- **L207864** `[2026-05-18 +80 23:00:43.772]` `ChatTimHandler.m:271`  
  ```
  [ChatTim]TimAction:punishMessage
  ```
  > ← **关键证据 1：IMSDK 收到 punishMessage（惩罚消息），来自服务端主动下发，早于任何发送失败约 1.5 秒**

- **L（XGPush 块）** `[2026-05-18 +80 23:00:44.242]` `WEGAppLaunchEssentialServices.m:1567`  
  ```
  title  = "营地小秘书"
  body   = "您发送给[限定小秘书v]的1条消息涉嫌违规，已被系统删除"
  action = "smobagamehelper://chat_old?accountId=5&chatScence=OFFICAL_CHAT_SCENES"
  pushTime = 1779116443
  ```
  > ← **关键证据 2：XGPush 远程通知告知用户"发送内容涉嫌违规已被删除"，与 punishMessage 时刻完全吻合**

#### T3 — 23:00:45 | ⭐ 第一次发送被拒（-30098）

- **L208077** `[2026-05-18 +80 23:00:45.106]` `WebServiceManager.m:437`  
  发送文字消息（chatType=2）

- **L208086** `[2026-05-18 +80 23:00:45.342]` `WebServiceManager.m:654`  
  ```
  returnCode = "-30098";
  returnMsg  = "你已被禁言";
  ```
  > ← **关键证据 3：服务端明确返回禁言状态，traceId=3825a01e655acc34ce51bd7e89b1a248**

- **L208096** `[2026-05-18 +80 23:00:45.361]` `BaseViewController.m:768`  
  `[Login][Auth]BaseViewController -30098 ChatMessageViewController:`

#### T4 — 23:00:49 ~ 23:03:07 | 用户多次重试，均以 -30098 失败

| 时间 | 操作 | 来源 |
|------|------|------|
| 23:00:49.428 | `_resendRoleChatMessage` 重发 | L208153 |
| 23:00:53.432 | `_sendPhotoMessageWithImage` 发图片 | L208251 |
| 23:01:01.742 | 继续发送 | L209282 |
| 23:03:06.996 | 继续发送 | L226830 |

所有请求均返回 `returnCode=-30098, returnMsg="你已被禁言"`。

#### T5 — 23:04:31 | 用户进入反馈页面，选择"误禁言问题"类别 → 23:07:05 提交反馈

---

### 4.3 问题归属与客户端状态

| 维度 | 结论 |
|------|------|
| 服务端推送禁言通知 | ✅ 是，IMSDK `punishMessage` + XGPush 双通道 |
| 客户端收到通知并处理 | ✅ 正常接收，无异常 |
| 客户端是否有崩溃 | ❌ 无 |
| 客户端是否有网络异常 | ❌ 无，HTTP 2.0 正常响应 |
| 禁言生效机制 | 服务端下发 → 之后所有发送请求服务端直接拒绝 |
| 问题归属 | **服务端（chatserver 聊天审核/风控系统）** |

---

## 五、修复建议

### P0 — 客服介入（立即）
- 核实 uid=1633877949 被禁言的触发原因（人工处罚 / 自动审核 / 误触发）
- 若属于误禁言，立即解除并向用户反馈

### P1 — 服务端排查
- 查询 chatserver 侧 uid=1633877949 的禁言记录及触发原因
- 禁言下发时间：**2026-05-18 23:00:43**（IMSDK msgId=144115388005993729-1779116443-1779116443）
- XGPush 通知内容"1条消息涉嫌违规，已被系统删除"→ 确认是否为自动内容审核触发，评估规则准确性

### P2 — 客户端体验优化（可选）
- 当前 `punishMessage` 到达后客户端无主动弹窗，用户在下次发送时才感知
- 建议：接收 `punishMessage` 后即时展示禁言提示弹窗，说明禁言原因及解除时间，避免用户反复重试（本次重试 4+次）
- 在客户端收到 `punishMessage` 后可提前锁定输入框

---

## 六、附录

| 项目 | 内容 |
|------|------|
| 工作目录 | `/Users/bryanpeng/.claude/skills/camp-feedback-skills/output/uid_1633877949_20260518_20260518_230705` |
| 反馈 ID | `O7mgO54BgkaEuDzpWumt` |
| xlog 解码 | 成功 2 / 失败 0 |
| lego 补拉 | 跳过（接口未接入） |
| grep 命中关键词 | `punishMessage`, `-30098`, `你已被禁言`, `sendsinglechatmessage` |
| 关键证据行号 | L207864（punishMessage）、L208086（首次-30098）、L208096（BaseVC展示错误）、XGPush块（23:00:44.242） |
