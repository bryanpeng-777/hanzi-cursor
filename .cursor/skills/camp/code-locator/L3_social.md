# L3 场景索引：社交 / 好友关系

> **所属域**：社交 / 好友关系 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/social/` / `lib/add_game_friends/` / `Features/Imps/WEGRecommendUserImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 添加游戏好友失败 / 按钮无响应 | 加好友、添加好友 | `lib/add_game_friends/` | 搜 addFriend / sendFriendRequest |
| 好友列表加载不出来 / 为空 | 好友列表、联系人 | `lib/social/` | 搜 FriendList / fetchFriendList |
| 推荐用户 / 可能认识的人不显示 | 推荐、可能认识 | `WEGRecommendUserImp.m` | 搜 recommendUsers / fetchRecommend |
| 搜索游戏昵称无结果 | 昵称搜索、搜好友 | `lib/search_game_nickname/` | 搜 searchByNickname |
| 白名单操作无效 / 白名单用户看不到内容 | 白名单 | `lib/whitelist_user/` | 搜 addToWhitelist / whitelist |
| 拉黑后还能被对方骚扰 | 黑名单、拉黑 | `lib/blacklist_user/`<br>`lib/block_management/` | 搜 blockUser / blacklist |
| 关注操作失败 / 关注状态不同步 | 关注、取关 | `lib/social/` | 搜 followUser / followStatus |
| 好友在线状态显示不准确 | 在线状态、离线 | `lib/social/` | 搜 onlineStatus / presenceStatus |
| 好友申请详情页异常 | 好友申请、申请详情 | `lib/business/friend_apply_detail/` | 搜 FriendApplyDetail |
| 联系人列表不显示 / 联系人异常 | 联系人、通讯录 | `lib/business/contact/` | 搜 ContactPage / ContactList |
| 好友申请通知不弹 | 申请通知 | `lib/system_notify/` | 搜 friendApplyNotification |

---

## 关键链路

```
用户发起加好友
  → lib/add_game_friends/ 搜索页
  → 发送好友申请接口
  → 对方收到通知（lib/system_notify/）
  → 对方查看申请详情（lib/business/friend_apply_detail/）
  → 对方同意后双方好友列表更新
  → lib/social/ 刷新好友列表
```

---

## 排查起点建议

- **加好友失败**：`lib/add_game_friends/` 的请求逻辑
- **列表为空**：`lib/social/` 的 fetchFriendList 接口和缓存
- **推荐不显示**：`WEGRecommendUserImp.m`（iOS 侧触发）和 `lib/social/`（Flutter 展示）
- **好友申请**：`lib/business/friend_apply_detail/` 查看申请详情
- **联系人**：`lib/business/contact/` 联系人列表

*最后更新：2026-03-30（新增：好友申请详情、联系人列表、申请通知 3 个新场景）*
