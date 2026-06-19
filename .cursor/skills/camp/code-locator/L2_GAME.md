# Layer 2 详情：媒体与游戏

> **归属超级分类**：C - 媒体与游戏  
> **覆盖域**：直播、短视频、战绩/对局、英雄/装备、赛事、组队/约战、游戏广场、战队/俱乐部  
> **路径根**：Flutter `flutter_module/lib/` | iOS `social-ios/src/GameApp/`

---

## 1. 直播 　　　📄 [场景展开 → L3_live.md](L3_live.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 直播主逻辑 / 看战 | `lib/watchbattle_living/`<br>`lib/camp_business/live_streaming/` | `Features/GameLiving/` |
| 直播间 UI / 交互 | `lib/watching/` | — |
| 直播间弹幕 | — | `Features/Danmu/` |
| 直播组件 / 播放器 | — | `Features/PLManager/`<br>`Features/WEGLucidityHost/` |
| 原生直播管理（Hybrid 直播） | — | `Features/Manager/NativeLivingManager/` |
| 直播预告 / 订阅 | `lib/watchbattle_living/`（预告子页） | — |
| 直播礼物 / 互动 | `lib/watching/`（gift 子目录） | `Features/GameLiving/`（gift） |
| 直播回放 | `lib/watching/`（replay 子目录） | — |

---

## 2. 短视频 　　　📄 [场景展开 → L3_video.md](L3_video.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 短视频列表 / 播放器 | `lib/short_video/` | `Features/TVKSerialPlayer/`<br>`Features/VideoPlayer/` |
| 游戏高光 / 精彩集锦 | `lib/game_high_lights/` | — |
| 视频封面 / 预览 | `lib/short_video/`（thumbnail 子目录） | — |
| 全屏视频（原生↔Flutter 路由选择） | — | `Features/Imps/WEGFullScreenVideoImp.m` |
| 精彩时刻剧本生成 | `lib/moments_script/` | — |
| 视频评论 | `lib/camp_business/comment_card/` | — |
| 视频分享 | `lib/camp_business/share/` | `Features/CampShare/` |
| 短视频路由入口 | `lib/business/short_video/` | — |

---

## 3. 战绩 / 对局数据 　　　📄 [场景展开 → L3_battle.md](L3_battle.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| **战绩 Tab 主框架**（多游戏 OS/NGR/KOH 壳） | `lib/battle/` | — |
| KOH 对战列表（巅峰赛） | `lib/battle_koh_list/` | — |
| OS 模式对战列表 | `lib/os/` | — |
| OS 阵容（卡片/评论/套用） | `lib/os_line_up/` | — |
| 好友战绩查询 | `lib/friends-record/` | — |
| 战绩详情 / AI 分析 | `lib/battle_detail_ai_analysis/` | — |
| 战斗道具 / 装备数据 | `lib/battle_goods/` | — |
| 战斗排行榜 | `lib/battle_fight_rank/` | — |
| 军功 / 积分 | `lib/military_exploits/` | — |
| 荣耀排行 | `lib/honor_rank/` | — |
| 战绩角色数据（iOS） | — | `Features/BattleRole/` |
| 赛季战力 / 段位 | `lib/performance/`<br>`lib/camp_business/src/` | — |
| 战绩相关路由入口 | `lib/business/battle_detail_ai_analysis/`<br>`lib/business/battle_fight_rank/`<br>`lib/business/battle_goods/` | — |

**关键服务**：`PerformanceService`（`lib/performance/service/`）  
**多游戏模式**：OS（王者峡谷）/ KOH（巅峰赛）/ NGR（荣耀对决），各有独立子目录在 `lib/battle/`

---

## 4. 英雄 / 装备 　　　📄 [场景展开 → L3_hero.md](L3_hero.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 英雄排行榜 | `lib/hero_rank/` | — |
| 英雄出场率 / 常用英雄 | `lib/frequency_hero_list/` | — |
| 英雄连招教学 | `lib/hero_combo/` | — |
| 装备选择 / 装备详情 | `lib/equipment/` | `Features/Imps/WEGEquipImp.m` |
| 英雄详情（如有） | `lib/hero_rank/`（detail 子目录） | — |
| 英雄皮肤 | `lib/camp_business/src/`（skin 相关） | — |
| 套装同步（游戏套装→营地） | `lib/suit_sync/` | — |
| 英雄路由入口 | `lib/business/hero_rank/`<br>`lib/business/hero_combo/` | — |

**关键 Imp**：`WEGEquipImp.m`

---

## 5. 赛事 　　　📄 [场景展开 → L3_esport.md](L3_esport.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 赛事主页 | `lib/match/` | — |
| 赛程 / 赛事回放 | `lib/match.schedule_and_replay/` | — |
| 赛事全列表 | `lib/match_all_list/` | — |
| 精彩赛段 / 高光 | `lib/game_high_lights/` | — |
| 赛事订阅 / 提醒 | `lib/match/`（subscribe 子目录） | — |
| 队伍详情 | `lib/match/`（team 子目录） | — |
| 赛事路由入口 | `lib/business/match/`<br>`lib/business/match.schedule_and_replay/` | — |

---

## 6. 组队 / 约战 　　　📄 [场景展开 → L3_team.md](L3_team.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 组队主逻辑 | `lib/gangup/` | `Features/WEGGangUp/`<br>`Features/Imps/WEGGangUpImp.m` |
| 组队语音匹配 | — | `Features/GangupVoice/` |
| 预制组队（固定队伍） | — | `Features/PremadeTeam/` |
| 副本 / 协作模式 | `lib/coproduce/` | — |
| 游戏伙伴 | — | `Features/GamePartner/` |
| 组队加速 | `lib/game_acceleration/` | — |
| 约战房间 | `lib/gangup/`（room 子目录） | `Features/WEGGangUp/`（room） |
| 段位匹配条件 | `lib/gangup/`（filter 子目录） | — |
| **组队管理器** | — | `Features/Manager/Gangup/` |
| **预制组队曝光管理** | — | `Features/Manager/WEGPremadeTeamExposeManager/` |

**关键 Imp**：`WEGGangUpImp.m`

---

## 7. 游戏广场 / 游戏区 　　　📄 [场景展开 → L3_gamezone.md](L3_gamezone.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 游戏功能入口 | `lib/game/`<br>`lib/hok/` | `Features/Imps/WEGGameImp.m`<br>`Features/GameZone/` |
| 游戏矩阵（多游戏聚合） | — | `Features/GameMatrix/` |
| 多游戏切换 | `lib/multi_game/`<br>`lib/multiple_game/` | — |
| 新用户首页 | — | `Features/NewUserHome/` |
| 新手引导 | — | `Features/NoviceGuide/` |
| 摇一摇漂流瓶 | — | `Features/ShakeDriftBottle/` |
| 赛季信息 / 赛季战力 | `lib/performance/` | — |
| 段位展示 | `lib/camp_business/src/`（段位 widget） | — |
| 游戏签到 | `lib/checkin_landing/` | — |
| **游戏事件管理** | — | `Features/Manager/GameEventManager/` |
| **游戏辅助组件** | — | `Features/Component/GameHelper/` |
| **角色卡片更新** | — | `Features/Component/RoleCardUpdaterProtocol/` |
| **启动游戏** | `lib/business/launch_game/` | — |
| 游戏路由入口 | `lib/business/game/`<br>`lib/business/hok/` | — |

**关键 Imp**：`WEGGameImp.m`

---

## 8. 战队 / 俱乐部主页 　　　📄 [场景展开 → L3_team_profile.md](L3_team_profile.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 战队 / 俱乐部主页（资料/成员/荣誉） | `lib/team_profile/` | — |
| 战队动态 | `lib/team_profile/`（moment 子目录） | — |
| 战队战绩表现 | `lib/team_profile/`（performance 子目录） | — |
| 战队关联圈子 | `lib/team_profile/`（associate_circle） | — |

---

## 附录：常用 Imp 速查（媒体游戏域）

| Imp 文件 | 功能 |
|---------|------|
| `WEGGameImp.m` | 游戏功能入口 |
| `WEGGangUpImp.m` | 组队 |
| `WEGEquipImp.m` | 装备 |
| `WEGFullScreenVideoImp.m` | 全屏视频路由（Flutter/原生切换） |

---

*最后更新：2026-03-30（新增：GameEventManager、Gangup管理器、PremadeTeamExposeManager、GameHelper、RoleCardUpdater、lib/business条目）*
