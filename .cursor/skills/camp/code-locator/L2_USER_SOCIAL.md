# Layer 2 详情：用户与社交

> **归属超级分类**：A - 用户与社交  
> **覆盖域**：登录/账号、用户中心/个人主页、社交/好友、聊天/消息、通知/消息中心、举报/黑名单  
> **路径根**：Flutter `flutter_module/lib/` | iOS `social-ios/src/GameApp/`

---

## 1. 登录 / 账号 　　　📄 [场景展开 → L3_login.md](L3_login.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 登录主流程 | `lib/camp_login/` | `Features/CampLogin/`<br>`Features/Imps/WEGLoginImp.m` |
| 账号注销 / 退出登录 | `lib/account_logout/` | — |
| 手机号绑定 | `lib/phone_bind/` | — |
| 游戏账号授权 | `lib/camp_authorized/` | `Features/GameAuth/`<br>`Features/WEGGameAuth/` |
| 账号信息管理 | `lib/business/account/` | `Features/Imps/WEGUserImp.m` |
| 隐私协议弹窗 | `lib/camp_business/privacy/` | `Features/Imps/WEGSmobaHelperCommonImp.m` |
| 实名认证 | `lib/real_name/`（如有） | — |
| 登录路由入口 | `lib/business/login/` | — |

**关键服务**：`AccountService`（`packages/camp_common/lib/service/` 或 `lib/common/`）  
**关键 Imp**：`WEGLoginImp.m`、`WEGUserImp.m`

---

## 2. 用户中心 / 个人主页 　　　📄 [场景展开 → L3_profile.md](L3_profile.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 个人主页页面 | `lib/user_center/`<br>`lib/personal/` | `Features/Imps/WEGProfileImp.m` |
| 名片 / 个人卡片 | `lib/camp_business/src/business_card/`<br>`lib/choose_profile_card/` | — |
| 好友备注 | — | `Features/Imps/WEGRemarksImp.m` |
| 关注 / 粉丝列表 | `lib/social/` | `Features/Imps/WEGRecommendUserImp.m` |
| 内容可见性设置 | `lib/article_visibility/` | — |
| 用户资料编辑 | `lib/user_center/`（编辑子页） | — |
| 勋章 / 成就展示 | `lib/camp_business/src/`（如有） | — |
| 我的页面 | `lib/business/mine/` | — |
| 个人主页路由入口 | `lib/business/personal/` | — |
| 角色卡片更新 | — | `Features/Component/RoleCardUpdaterProtocol/` |
| 全局角色切换 | `lib/business/change_role_global/` | — |

**关键 Imp**：`WEGProfileImp.m`、`WEGRemarksImp.m`

---

## 3. 社交 / 好友关系 　　　📄 [场景展开 → L3_social.md](L3_social.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 社交主逻辑 | `lib/social/` | — |
| 添加游戏好友 | `lib/add_game_friends/` | — |
| 游戏昵称搜索 | `lib/search_game_nickname/` | — |
| 白名单管理 | `lib/whitelist_user/` | — |
| 黑名单管理 | `lib/blacklist_user/`<br>`lib/block_management/` | — |
| 推荐用户 / 可能认识的人 | — | `Features/Imps/WEGRecommendUserImp.m` |
| 关注关系数据层 | `lib/social/`（repository / service 子目录） | — |
| 好友在线状态 | `lib/social/`（如有 online_status） | — |
| **好友申请详情** | `lib/business/friend_apply_detail/` | — |
| **联系人列表** | `lib/business/contact/` | — |

---

## 4. 聊天 / 消息 　　　📄 [场景展开 → L3_chat.md](L3_chat.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 单聊会话列表 | `lib/single_chat_dialog/` | — |
| 单聊聊天室 | `lib/chat/` | `Features/Imps/WEGChatRoomImp.m` |
| 消息工具栏 / 操作 | — | `Features/Imps/WEGChatMessageToolImp.m` |
| 消息主体（IM 核心） | — | `Features/Imps/WEGMessageImp.mm` |
| 多人聊天 | — | `Features/MultipleChat/` |
| 弹幕（直播中） | — | `Features/Danmu/` |
| 频道 / 群 | `lib/r_group/` | `Features/Channel/` |
| **IM 聊天引擎**（TCP/TIM/推送分发） | — | `Features/Manager/ChatEngineManager/` |
| 消息已读/未读状态 | `lib/chat/`（状态管理子目录） | — |
| 消息撤回 | `lib/chat/` or `lib/single_chat_dialog/` | — |
| 语音消息 | `lib/chat/`（voice 子目录，如有） | — |
| 图片/视频消息 | `lib/chat/`（media 子目录） | — |
| @提及 | `lib/at_contact/` | — |

**关键 Imp**：`WEGChatRoomImp.m`、`WEGMessageImp.mm`、`WEGChatMessageToolImp.m`

---

## 5. 通知 / 消息中心 　　　📄 [场景展开 → L3_notify.md](L3_notify.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 系统通知列表 | `lib/system_notify/` | — |
| Push 推送注册 / 接收 | — | `Features/XGPush/` |
| 通知设置 | `lib/setting/`（通知子模块） | — |
| 角标 / 红点计数 | `lib/camp_business/`（badge 相关） | `Features/Imps/WEGCommonImp.m` |
| **本地通知管理** | — | `Features/Manager/NotificationManager/` |
| **推送扩展** | — | `xcodeproj/XGExtention/` |

---

## 6. 举报 / 黑名单 　　　📄 [场景展开 → L3_report.md](L3_report.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 内容举报 | `lib/report/` | — |
| 用户黑名单 | `lib/blacklist_user/` | — |
| 屏蔽管理 | `lib/block_management/` | — |
| 举报类型选择 | `lib/report/`（类型选择子页） | — |

---

## 附录：常用 Imp 速查（用户社交域）

| Imp 文件 | 功能 |
|---------|------|
| `WEGLoginImp.m` | 登录主流程 |
| `WEGUserImp.m` | 用户账号信息 |
| `WEGProfileImp.m` | 个人主页 |
| `WEGRemarksImp.m` | 好友备注 |
| `WEGRecommendUserImp.m` | 推荐用户 / 关注粉丝 |
| `WEGChatRoomImp.m` | 聊天室 |
| `WEGChatMessageToolImp.m` | 聊天消息工具 |
| `WEGMessageImp.mm` | 消息核心（IM） |

---

*最后更新：2026-03-30（新增：好友申请详情、联系人、lib/business条目、NotificationManager、角色卡片、全局角色切换）*
