# L3 场景索引：战队 / 俱乐部主页

> **所属域**：战队 / 俱乐部主页 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/team_profile/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 战队主页打不开 / 白屏 | 战队主页、俱乐部 | `lib/team_profile/`（index.dart） | 搜 TeamProfilePage / openTeamProfile |
| 战队资料信息显示错误 | 战队资料、队伍信息 | `lib/team_profile/`（views/team_profile_header.dart） | 搜 TeamProfileHeader / clubTeamInfo |
| 战队成员列表加载失败 | 战队成员、选手 | `lib/team_profile/`（views/player_content_page.dart） | 搜 PlayerContentPage / fetchPlayers |
| 战队荣誉不显示 | 荣誉、战队奖项 | `lib/team_profile/`（entity/club_team_honor） | 搜 clubTeamHonor / HonorSection |
| 战队动态列表为空 | 战队动态、战队新闻 | `lib/team_profile/`（views/moment_content_page.dart） | 搜 MomentContentPage / teamMomentModel |
| 战队战绩 / 表现页面异常 | 战队战绩、战队表现 | `lib/team_profile/`（views/performance_content_page.dart） | 搜 PerformanceContentPage / performanceNormalCard |
| 关联圈子不显示 | 关联圈子、战队圈子 | `lib/team_profile/`（entity/team_associate_circle） | 搜 teamAssociateCircle |
| 战队新闻列表为空 | 战队新闻 | `lib/team_profile/`（entity/club_team_news） | 搜 clubTeamNews |
| 战队热度排行异常 | 战队热度、热榜 | `lib/team_profile/`（entity/club_team_hot_rank） | 搜 clubTeamHotRank |

---

## 关键链路

```
进入战队主页
  → lib/team_profile/ TeamProfilePage
  → 请求 club_profile / club_team_info 接口
  → Tab 页：成员(Player) / 动态(Moment) / 战绩(Performance) / 资讯(Info)
  → 各 Tab 独立请求和渲染
```

---

## 排查起点建议

- **全是 Flutter 实现**，iOS 侧无对应 Imp 文件
- 从 `lib/team_profile/` 的 index.dart 入手，看 Tab 页分发逻辑
- 数据问题：看各 `model/` 下的 service 层接口调用

*最后更新：2026-03-30*
