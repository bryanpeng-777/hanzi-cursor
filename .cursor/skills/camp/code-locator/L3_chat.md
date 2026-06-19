# L3 场景索引：聊天 / 消息

> **所属域**：聊天 / 消息 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/chat/` / `lib/single_chat_dialog/` / `Features/Imps/WEGChatRoomImp.m` / `WEGMessageImp.mm`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 进入聊天界面 crash / 打不开 | 聊天室、进聊天 | `WEGChatRoomImp.m` | 搜 `openChatRoom:` / `presentChatVC` |
| 消息发送失败 / 一直显示发送中 | 发消息、发送失败 | `lib/chat/` | 搜 sendMessage / MessageStatus.sending |
| 消息不显示 / 发出去对方看不到 | 消息消失、对方没收到 | `WEGMessageImp.mm` | 搜 receiveMessage / messageCallback |
| 消息显示乱序 / 时间戳不对 | 消息排序、乱序 | `lib/chat/` | 搜 sortMessages / messageTimestamp |
| 图片 / 视频发送失败 | 图片发送、媒体上传 | `lib/chat/` | 搜 sendImageMessage / uploadMedia |
| 消息未读数 / 角标数量不准确 | 未读数、红点 | `WEGChatMessageToolImp.m` | 搜 unreadCount / badgeCount |
| 历史消息加载失败 / 不能上滑加载更多 | 历史消息、加载更多 | `lib/single_chat_dialog/` / `lib/chat/` | 搜 fetchHistoryMessages / loadMore |
| 聊天室键盘弹起遮挡输入框 | 键盘遮挡、输入框 | `lib/camp_business/keyboard/` | 搜 KeyboardAware / keyboardHeight |
| 频道 / 群消息异常（Flutter） | 频道、群聊 | `lib/r_group/` | 搜 GroupChannel / RGroup |
| 频道功能异常（iOS 侧，含黑名单/语音/发现） | 频道 iOS | `Features/Channel/` | 搜 ChannelMessage / ChannelDiscover / ChannelVoiceGroupGame |
| 多人聊天打不开 | 多人聊天 | `Features/MultipleChat/` | iOS 侧 MultipleChat 模块 |
| 消息撤回失败 | 撤回 | `lib/chat/` | 搜 revokeMessage / recallMessage |
| 聊天室消息列表滚动异常 | 滚动、跳动 | `lib/chat/` | 看 ListView 的 scrollController |
| @人消息显示异常 | @提及、at | `lib/chat/` + `lib/at_contact/` | 搜 atMessage / mentionUser |
| IM 底层连接断开 / TCP 断连 | IM 断连、TCP、TIM | `Features/Manager/ChatEngineManager/` | 搜 ChatEngine / TCPSocket / TIMManager |
| 频道语音房进不去 / 异常（iOS） | 频道语音、voice | `Features/Channel/ChannelVoiceGroupGame/` | 搜 VoiceGroupGame |
| 频道发现页为空 | 频道发现 | `Features/Channel/ChannelDiscover/` | 搜 ChannelDiscover |
| 聊天/点赞页 crash，堆栈含 WEGDataReportBridge 或 BeaconReport | 数据上报 crash、点赞闪退 | `src/GameApp/Features/NoviceGuide/Manager/WEGDataReportBridge+Hook.m` | Hook 在 NoviceGuide 模块，swizzle 了 trackEvent/trackDatongEvent |

---

## 关键链路

```
用户点击发送
  → lib/chat/ ChatInputBar → sendMessage()
  → 调用 IM SDK 发送
  → WEGMessageImp.mm 处理回调
  → lib/chat/ 更新消息列表 UI
  → WEGChatMessageToolImp.m 更新未读数
```

---

## 排查起点建议

- **发送失败**：`lib/chat/` 的 sendMessage 逻辑 + IM SDK 错误码
- **聊天室打不开**：`WEGChatRoomImp.m` 的 openChatRoom: 参数和跳转
- **未读数异常**：`WEGChatMessageToolImp.m`
- **历史消息问题**：`lib/single_chat_dialog/` 的翻页请求逻辑

*最后更新：2026-03-30（补录 WEGDataReportBridge+Hook 聊天 crash 入口）*
