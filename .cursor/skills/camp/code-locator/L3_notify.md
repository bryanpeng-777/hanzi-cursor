# L3 场景索引：通知 / 消息中心

> **所属域**：通知 / 消息中心 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/system_notify/` / `Features/XGPush/` / `Features/Imps/WEGCommonImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 收不到推送通知（消息/点赞/关注） | 推送、Push、没收到 | `Features/XGPush/` | 搜 registerPush / XGPush 注册逻辑 |
| 通知角标（红点）数量不对 | 角标、未读红点、badge | `Features/Imps/WEGCommonImp.m` | 搜 setBadge / applicationIconBadgeNumber |
| 系统通知列表为空 / 加载不出来 | 通知列表、消息中心 | `lib/system_notify/` | 搜 fetchNotifications / NotifyListPage |
| 点击推送通知跳转页面失败 | 点通知跳转、notification tap | `Features/Imps/WEGCommonImp.m`<br>`Features/RouteAction/` | 搜 handleNotificationAction / routeFromPush |
| 通知开关设置后不生效 | 通知设置、关闭推送 | `lib/setting/`（通知设置子页） | 搜 notificationSetting / pushSwitch |
| 某类通知（如好友申请）收不到 | 好友通知、互动通知 | `lib/system_notify/` | 看通知类型 type 的分发逻辑 |
| 本地通知不弹出 / 提醒不触发 | 本地通知、提醒 | `Features/Manager/NotificationManager/` | 搜 NotificationManager / scheduleNotification |
| 推送扩展功能异常（富推送/图片推送） | 推送扩展、富推送 | `xcodeproj/XGExtention/` | 搜 NotificationService / didReceiveNotification |
| 通知路由入口异常 | 通知路由 | `lib/business/system_notify/` | 搜 SystemNotifyRoute |

---

## 关键链路

```
iOS Push 到达
  → Features/XGPush/ 接收
  → xcodeproj/XGExtention/ 推送扩展处理（富推送/图片）
  → WEGCommonImp.m handleNotification
  → Features/RouteAction/ 解析跳转参数
  → 打开对应页面

本地通知
  → Features/Manager/NotificationManager/ 调度本地通知
  → 系统触发通知展示
  → 用户点击 → 路由跳转

通知中心拉取
  → lib/system_notify/ 请求接口
  → 展示通知列表
```

---

## 排查起点建议

- **收不到推送**：先确认 XGPush 注册成功，再看 `Features/XGPush/` 的 token 上报
- **点击跳转失败**：`WEGCommonImp.m` + `Features/RouteAction/` 的路由解析
- **角标不对**：`WEGCommonImp.m` 的 setBadge 调用时机
- **本地通知**：`Features/Manager/NotificationManager/`
- **推送扩展**：`xcodeproj/XGExtention/`

*最后更新：2026-03-30（新增：本地通知、推送扩展、通知路由入口 3 个新场景）*
