# L3 场景索引：组队 / 约战

> **所属域**：组队 / 约战 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/gangup/` / `Features/WEGGangUp/` / `Features/Imps/WEGGangUpImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 组队入口打不开 / crash | 组队、约战入口 | `lib/gangup/`<br>`WEGGangUpImp.m` | 搜 GangUpPage / `openGangUp:` |
| 语音匹配失败 / 进不去语音房 | 语音匹配、匹配队友 | `Features/GangupVoice/` | 搜 GangupVoice / enterVoiceRoom |
| 段位 / 筛选条件不生效 | 段位筛选、条件过滤 | `lib/gangup/`（filter 子目录） | 搜 GangUpFilter / rankFilter |
| 游戏伙伴推荐为空 | 游戏伙伴、伙伴推荐 | `Features/GamePartner/` | 搜 GamePartner / fetchPartners |
| 组队加速功能异常 | 加速、组队加速 | `lib/game_acceleration/` | 搜 GameAccelerationPage |
| 预制队伍数据为空 / 功能异常 | 预制队、固定队伍 | `Features/PremadeTeam/` | 搜 PremadeTeam / fetchPremadeTeam |
| 约战房间创建失败 | 创建房间、约战 | `lib/gangup/`（room 子目录） | 搜 createRoom / GangUpRoom |
| 队员列表显示异常 | 队员、房间成员 | `lib/gangup/`（room 子目录） | 搜 memberList / RoomMember |
| 组队语音断线 / 听不到声音 | 语音、麦克风 | `Features/GangupVoice/` | 搜 voiceChannel / micStatus |
| 组队管理器异常 | 组队管理 | `Features/Manager/Gangup/` | 搜 GangupManager |
| 预制组队曝光不上报 | 预制曝光、exposure | `Features/Manager/WEGPremadeTeamExposeManager/` | 搜 PremadeTeamExposeManager / reportExpose |
| 副本 / 协作模式异常 | 副本、协作 | `lib/coproduce/` | 搜 CoproducePage |

---

## 关键链路

```
用户点击组队
  → WEGGangUpImp.m openGangUp:（iOS 侧触发）
  → lib/gangup/ Flutter 页面
  → 创建/加入房间
  → Features/GangupVoice/ 语音匹配
  → 开始游戏

预制组队
  → Features/PremadeTeam/ 获取预设队伍
  → Features/Manager/WEGPremadeTeamExposeManager/ 曝光上报
  → 用户选择加入
```

---

## 排查起点建议

- **iOS 侧触发**：`WEGGangUpImp.m` 的 `openGangUp:` 入手
- **语音问题**：`Features/GangupVoice/` 独立模块，涉及麦克风权限
- **Flutter 侧房间逻辑**：`lib/gangup/` 的 room 子目录
- **组队管理器**：`Features/Manager/Gangup/` 和 `Features/WEGGangUp/` 是两个不同层级
- **预制组队**：`Features/PremadeTeam/` + `WEGPremadeTeamExposeManager/`

*最后更新：2026-03-30（新增：组队管理器、预制组队曝光、副本协作 3 个新场景）*
