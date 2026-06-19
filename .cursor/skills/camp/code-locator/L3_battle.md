# L3 场景索引：战绩 / 对局数据

> **所属域**：战绩 / 对局数据 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/battle/`（Tab 主框架）/ `lib/battle_koh_list/` / `lib/os/` / `lib/battle_detail_ai_analysis/` / `Features/BattleRole/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| **战绩 Tab 整体白屏 / 打不开** | 战绩页、进战绩 | `lib/battle/`（battle_app.dart） | 看 GamePanelPage / BattleApp 初始化 |
| **多游戏切换（OS/KOH）异常** | 切游戏、多游戏 | `lib/battle/`（ui/game_switcher） | 搜 GameSwitcher / switchGame |
| **KOH 对战列表为空 / 加载失败** | KOH、巅峰赛、对战记录 | `lib/battle_koh_list/` | 搜 BattleKohList / fetchKohList |
| **OS 对战记录不显示** | OS、王者峡谷、对局记录 | `lib/os/`（battle/pages） | 搜 OsMatchService / fetchOsMatch |
| **好友战绩查不到** | 好友战绩、查好友记录 | `lib/friends-record/` | 搜 FriendsRecordPage / friendsRecordService |
| **战绩详情 / AI 分析数据为空** | AI 分析、智能分析 | `lib/battle_detail_ai_analysis/` | 搜 BattleDetailPage / AIAnalysis |
| **战斗排行榜数据错误** | 战斗排行、排行 | `lib/battle_fight_rank/` | 搜 BattleFightRankPage / fetchRankData |
| **军功 / 积分显示异常** | 军功、积分 | `lib/military_exploits/` | 搜 MilitaryExploitsPage |
| **荣耀排行加载失败** | 荣耀排行 | `lib/honor_rank/` | 搜 HonorRankPage |
| **赛季战力 / 段位数据错误** | 赛季战力、段位 | `lib/performance/` | 搜 PerformanceService / seasonInfo |
| **对局道具 / 装备数据为空** | 对局装备 | `lib/battle_goods/` | 搜 BattleGoodsPage |
| **iOS 侧战绩数据接口异常** | iOS 战绩接口 | `Features/BattleRole/` | 看 BattleRole/Manager 或 WebService |
| **OS 阵容无法查看/套用** | 阵容、OS 阵容 | `lib/os_line_up/` | 搜 OsLineupCard / applyLineup |

---

## 关键链路

```
进入战绩 Tab
  → lib/battle/ BattleApp（主壳）
  → 多游戏选择：OS / KOH / NGR
    ├── OS → lib/os/ OsMatchService + lib/battle/model/os
    ├── KOH → lib/battle_koh_list/ + lib/battle/model/koh
    └── NGR → lib/battle/model/ngr
  → 点击单条战绩 → lib/battle_detail_ai_analysis/（详情 + AI 分析）
  → iOS 侧数据 → Features/BattleRole/
```

---

## 排查起点建议

- **Tab 级问题**：从 `lib/battle/battle_app.dart` 的初始化入手
- **某游戏模式数据为空**：对应的 Service（OsMatchService/koh.dart）+ 接口错误码
- **好友战绩**：`lib/friends-record/` 的 friends_record_service.dart
- **阵容功能**：`lib/os_line_up/` 的 apply 和 card 组件

*最后更新：2026-03-30（根据真实代码优化）*
