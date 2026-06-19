# L3 场景索引：赛事

> **所属域**：赛事 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/match/` / `lib/match_all_list/` / `lib/match.schedule_and_replay/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 赛事主页列表不显示 | 赛事、赛事列表 | `lib/match/` / `lib/match_all_list/` | 搜 MatchPage / fetchMatchList |
| 赛程数据为空 / 不更新 | 赛程、比赛时间 | `lib/match.schedule_and_replay/` | 搜 SchedulePage / fetchSchedule |
| 比赛回放打不开 | 回放、录像 | `lib/match.schedule_and_replay/`（replay） | 搜 ReplayPage / openReplay |
| 精彩赛段视频不播放 | 精彩赛段、高光 | `lib/game_high_lights/` | 搜 GameHighLightsPage（同短视频） |
| 赛事订阅 / 提醒不生效 | 订阅赛事、关注比赛 | `lib/match/`（subscribe 子目录） | 搜 subscribeMatch / matchReminder |
| 队伍详情加载失败 | 队伍、战队详情 | `lib/match/`（team 子目录） | 搜 TeamDetailPage / fetchTeamInfo |

---

## 排查起点建议

- **所有赛事功能均在 Flutter 侧实现**，iOS 侧无对应 Imp
- 排查起点：`lib/match/` 对应功能的数据请求 + 错误处理

*最后更新：2026-03-30*
