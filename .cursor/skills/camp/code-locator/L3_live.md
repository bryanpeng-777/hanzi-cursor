# L3 场景索引：直播

> **所属域**：直播 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/watchbattle_living/` / `lib/watching/` / `Features/GameLiving/` / `Features/PLManager/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 直播间打不开 / 进入 crash | 进直播、直播间打不开 | `Features/GameLiving/`<br>`lib/watchbattle_living/` | 搜 openLiveRoom / GameLivingPage |
| 直播流无法播放 / 黑屏 | 黑屏、拉流失败、播放器 | `Features/PLManager/` | 搜 PLPlayerManager / startPlay |
| 直播清晰度切换失败 | 清晰度、蓝光 | `Features/WEGLucidityHost/` | 搜 LucidityHost / switchQuality |
| 直播弹幕不显示 / 发弹幕失败 | 弹幕、发弹幕 | `Features/Danmu/` | 搜 DanmuManager / sendDanmu |
| 直播礼物发送失败 | 礼物、送礼 | `lib/watching/`（gift 子目录） | 搜 sendGift / GiftPanel |
| 直播间互动按钮无响应 | 互动、点赞直播 | `lib/watching/` | 搜 LiveInteraction / liveAction |
| 直播预告不显示 / 订阅失败 | 预告、直播订阅 | `lib/watchbattle_living/`（预告子页） | 搜 LiveSchedule / subscribeLive |
| 直播回放打不开 | 回放 | `lib/watching/`（replay 子目录） | 搜 LiveReplay / openReplay |
| 原生直播/Hybrid 直播打不开 | 原生直播、Hybrid | `Features/Manager/NativeLivingManager/` | 搜 NativeLivingManager / WebView 代理 |
| 直播聊天室消息延迟大 | 直播聊天、消息延迟 | `Features/GameLiving/` | 看 IM 聊天室配置 |
| 观看人数 / 在线数显示异常 | 观看数、在线人数 | `lib/watching/` | 搜 viewerCount / onlineCount |

---

## 关键链路

```
进入直播间
  → Features/GameLiving/ 初始化直播间 VC
  → Features/PLManager/ 拉流播放
  → Features/WEGLucidityHost/ 清晰度管理
  → lib/watching/ Flutter 叠加层（弹幕/礼物/互动）
  → Features/Danmu/ 弹幕流
```

---

## 排查起点建议

- **播放问题（黑屏/卡顿）**：`Features/PLManager/` 播放器核心
- **直播间打不开**：`Features/GameLiving/` 初始化逻辑
- **Flutter 叠加层（礼物/互动）**：`lib/watching/` 对应功能子目录

*最后更新：2026-03-30*
