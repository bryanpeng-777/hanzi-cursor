# L3 场景索引：登录 / 账号

> **所属域**：登录 / 账号 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/camp_login/` / `Features/CampLogin/` / `Features/Imps/WEGLoginImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 登录页面打不开 / 白屏 | 登录页、白屏 | `lib/camp_login/` | 看 CampLoginPage 的 build/initState |
| 微信登录点了没反应 / 回调无响应 | 微信登录、第三方登录 | `Features/Imps/WEGLoginImp.m` | 搜 `loginWithWeChat` / `handleOpenURL` |
| 游戏账号授权失败 | 游戏授权、GameAuth | `Features/GameAuth/`<br>`lib/camp_authorized/` | 搜 `authorize` / `authCallback` |
| 退出登录后页面状态没有刷新 | 退出、注销、状态残留 | `lib/account_logout/` | 看 logout 后的状态清理逻辑 |
| 手机号绑定失败 / 验证码不来 | 手机绑定、验证码 | `lib/phone_bind/` | 搜 `sendSmsCode` / `bindPhone` |
| 账号信息获取不到 / 用户名为空 | 用户信息、AccountService | `Features/Imps/WEGUserImp.m` | 搜 `getUserInfo` / `currentUser` |
| 登录 token 过期 / 自动跳到登录页 | token、自动登出、session | `Features/Imps/WEGLoginImp.m` | 搜 `tokenExpired` / `relogin` |
| 登录弹窗不弹出 | 登录弹窗、强登 | `Features/Imps/WEGSmobaHelperCommonImp.m` | 搜 `showLoginAlert` / `presentLogin` |
| App 启动后一直停在登录页 | 启动卡登录、首页不显示 | `Features/WEGLauncher/` + `Features/CampLogin/` | 看启动序列中的登录状态判断 |
| 切换账号后数据没有刷新 | 切号、账号切换 | `lib/account_logout/` + `AccountService` | 搜 `switchAccount` / `clearUserCache` |

---

## 关键链路

```
用户点击登录
  → WEGLoginImp.m（iOS 发起登录）
  → 第三方 SDK（微信/QQ）回调
  → WEGLoginImp.m handleLoginResult
  → AccountService 更新登录态
  → lib/camp_login/ Flutter 侧状态同步
  → 路由跳转到首页
```

---

## 排查起点建议

- **iOS 侧**：从 `WEGLoginImp.m` 的 `login` 方法入手
- **Flutter 侧**：从 `lib/camp_login/` 的页面入口 + `AccountService` 状态管理入手
- **Token 问题**：先看 `WEGUserImp.m` 的 token 刷新逻辑
- **游戏授权**：`Features/GameAuth/` 和 `lib/camp_authorized/` 两侧均需检查

*最后更新：2026-03-30*
