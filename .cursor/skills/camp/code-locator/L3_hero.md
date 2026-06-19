# L3 场景索引：英雄 / 装备

> **所属域**：英雄 / 装备 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/hero_rank/` / `lib/equipment/` / `Features/Imps/WEGEquipImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 英雄排行榜加载失败 / 为空 | 英雄排行、热度榜 | `lib/hero_rank/` | 搜 HeroRankPage / fetchHeroRank |
| 英雄出场率 / 常用英雄数据不对 | 出场率、常用英雄 | `lib/frequency_hero_list/` | 搜 FrequencyHeroPage / fetchFrequency |
| 英雄连招视频不播放 | 连招、技能演示 | `lib/hero_combo/` | 搜 HeroComboPage / playComboVideo |
| 装备选择界面打不开 | 装备、铭文 | `lib/equipment/`<br>`WEGEquipImp.m` | 搜 EquipmentPage / `openEquip:` |
| 装备数据显示错误 | 装备数据、属性 | `lib/equipment/` | 搜 EquipmentDetail / equipStats |
| 英雄详情页加载失败 | 英雄详情 | `lib/hero_rank/`（detail 子目录） | 搜 HeroDetailPage / fetchHeroDetail |
| 套装同步失败 / 套装不显示 | 套装、符文同步 | `lib/suit_sync/` | 搜 SuitSyncPage / syncAction / suitProfileModel |
| OS 阵容无法查看或套用 | 阵容 | `lib/os_line_up/` | 搜 OsLineupCard / applyLineup |

---

## 排查起点建议

- **iOS 侧触发装备**：`WEGEquipImp.m` 的 `openEquip:` 入手
- **排行/出场率数据问题**：对应 Flutter 模块的接口请求

*最后更新：2026-03-30*
