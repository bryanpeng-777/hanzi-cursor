# L3 场景索引：游戏广场 / 游戏区

> **所属域**：游戏广场 / 游戏区 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/game/` / `lib/hok/` / `Features/Imps/WEGGameImp.m` / `Features/GameZone/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 游戏功能入口打不开 / 没反应 | 游戏、进游戏 | `WEGGameImp.m`<br>`Features/GameZone/` | 搜 `openGame:` / GameZone |
| 多游戏切换显示异常 | 多游戏、切换游戏 | `lib/multi_game/`<br>`lib/multiple_game/` | 搜 MultiGamePage / switchGame |
| 新用户首页 / 引导页不显示 | 新用户、首次进入 | `Features/NewUserHome/` | 搜 NewUserHomePage / isNewUser |
| 新手引导流程异常 | 新手引导、引导步骤 | `Features/NoviceGuide/` | 搜 NoviceGuide / guideStep |
| 摇一摇漂流瓶不触发 | 摇一摇、漂流瓶 | `Features/ShakeDriftBottle/` | 搜 ShakeDetector / driftBottle |
| 赛季战力 / 赛季信息显示错误 | 赛季战力、赛季 | `lib/performance/` | 搜 PerformanceService / seasonInfo |
| 游戏矩阵 / 多款游戏聚合页异常 | 游戏矩阵 | `Features/GameMatrix/` | 搜 GameMatrix / fetchGameList |
| 段位展示组件显示错误 | 段位、星级 | `lib/camp_business/src/` | 搜 RankWidget / userRank |
| 启动游戏失败 / 拉起游戏无响应 | 启动游戏、拉起游戏 | `lib/business/launch_game/` | 搜 LaunchGame / openScheme |
| 游戏事件未触发 / 回调异常 | 游戏事件、事件回调 | `Features/Manager/GameEventManager/` | 搜 GameEventManager / handleEvent |
| 游戏辅助功能异常 | 游戏辅助、GameHelper | `Features/Component/GameHelper/` | 搜 GameHelper |
| 角色卡片信息不更新 | 角色卡片、角色数据 | `Features/Component/RoleCardUpdaterProtocol/` | 搜 RoleCardUpdater / updateRoleCard |
| 游戏路由入口异常 | 游戏路由 | `lib/business/game/`<br>`lib/business/hok/` | 看 TRouter 注册的路由名 |

---

## 关键链路

```
进入游戏区
  → WEGGameImp.m（iOS 侧触发）/ lib/game/ (Flutter)
  → Features/GameZone/ 游戏广场聚合页
  → 各子功能分发：战绩 / 组队 / 赛季 / 矩阵

启动游戏
  → lib/business/launch_game/ 路由入口
  → 通过 URL Scheme 拉起游戏 App
```

---

## 排查起点建议

- **iOS 触发游戏功能**：`WEGGameImp.m` 的 openGame: 方法
- **Flutter 游戏区页面**：`lib/game/` + `lib/hok/`
- **新用户/引导**：`Features/NewUserHome/` + `Features/NoviceGuide/`（纯 iOS）
- **启动游戏**：`lib/business/launch_game/`（URL Scheme 拉起）
- **游戏事件**：`Features/Manager/GameEventManager/` 处理游戏回调

*最后更新：2026-03-30（新增：启动游戏、游戏事件、GameHelper、角色卡片、路由入口 5 个新场景）*
