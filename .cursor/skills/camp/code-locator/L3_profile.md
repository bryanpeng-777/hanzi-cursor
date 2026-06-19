# L3 场景索引：用户中心 / 个人主页

> **所属域**：用户中心 / 个人主页 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/user_center/` / `Features/Imps/WEGProfileImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 个人主页打不开 / crash | 主页打不开、个人页 | `lib/user_center/`<br>`WEGProfileImp.m` | 看 ProfilePage 初始化 / `openProfile:` |
| 头像 / 昵称显示为空或错误 | 头像、昵称、用户名 | `lib/user_center/` | 搜 UserInfoWidget / avatar / nickname |
| 关注 / 粉丝数量不对 | 关注数、粉丝数 | `lib/social/` | 搜 followCount / fansCount |
| 他人主页打不开 | 查看他人、别人主页 | `lib/user_center/` | 看跳转参数 userId 是否正确传入 |
| 个人名片展示错误 / 不显示 | 名片、个人卡片 | `lib/camp_business/src/business_card/`<br>`lib/choose_profile_card/` | 搜 BusinessCard / ProfileCard |
| 资料编辑后保存失败 | 编辑资料、保存失败 | `lib/user_center/`（edit 子页） | 搜 saveProfile / updateUserInfo |
| 内容可见性设置不生效 | 隐私、可见范围 | `lib/article_visibility/` | 搜 visibilityType / privacySetting |
| 主页加载慢 / 一直转圈 | 加载慢、卡住 | `lib/user_center/`（数据加载逻辑） | 看 fetchUserInfo 网络请求 |
| "我的"页面异常 | 我的、mine | `lib/business/mine/` | 搜 MinePage / MineRoute |
| 全局角色切换异常 | 切号、切换角色、角色切换 | `lib/business/change_role_global/` | 搜 ChangeRoleGlobal / switchRole |
| 角色卡片更新异常 | 角色卡片、角色信息更新 | `Features/Component/RoleCardUpdaterProtocol/` | 搜 RoleCardUpdater |
| 好友备注保存/显示异常 | 备注、好友名称 | `Features/Imps/WEGRemarksImp.m` | 搜 setRemarkName / remarkForUser |
| 个人主页路由入口异常 | 路由跳转 | `lib/business/personal/`<br>`lib/business/user_center/` | 看 TRouter 注册的路由名 |

---

## 关键链路

```
进入他人主页
  → WEGProfileImp.m openProfile: userId
  → Flutter 路由：lib/user_center/ UserCenterPage(userId)
  → 请求用户信息接口
  → 渲染头像/昵称/动态列表

进入自己主页
  → AccountService.currentUser
  → lib/user_center/ 直接使用本地缓存

进入"我的"页面
  → lib/business/mine/ → 路由入口
  → 展示个人信息、收藏、设置等入口
```

---

## 排查起点建议

- **iOS 侧**：从 `WEGProfileImp.m` 的 `openProfile:` 入手，看参数和跳转逻辑
- **Flutter 侧**：从 `lib/user_center/` 主页面的 `initState` + 数据加载逻辑入手
- **数据问题**：优先排查 `AccountService` 缓存是否正确，再看网络请求
- **"我的"页面**：`lib/business/mine/` 是独立路由入口

*最后更新：2026-03-30（新增：mine页面、角色切换、角色卡片、备注、路由入口 5 个新场景）*
