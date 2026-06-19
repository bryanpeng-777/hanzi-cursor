# L3 场景索引：活动 / 运营

> **所属域**：活动 / 运营 | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/checkin_landing/` / `lib/choose_interest/` / `Features/Emitter/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 签到失败 / 签到按钮无响应 | 签到、每日签到 | `lib/checkin_landing/` | 搜 CheckinPage / doCheckin |
| 补签功能异常 | 补签 | `lib/supplement_sign/` | 搜 SupplementSignPage |
| 兴趣选择不保存 / 不显示 | 兴趣选择、标签 | `lib/choose_interest/` | 搜 ChooseInterestPage / saveInterest |
| 运营弹窗 / 公告不弹出 | 运营弹窗、公告 | `lib/camp_business/modal_sheet/` | 搜 showModalSheet / announceDialog |
| 黑灯特效不显示 | 黑灯、暗光 | `lib/black_light/` | 搜 BlackLightPage |
| 发光 / 粒子效果不显示（iOS） | 发光、Emitter | `Features/Emitter/` | 搜 EmitterManager / startEmit |
| 用户行为追踪不上报 | 行为追踪、用户行为 | `Features/UserActionTrack/` | 搜 UserActionTracker / trackAction |
| 运营位 / 卡片 Demo 不显示 | 运营位、banner | `lib/card_demo/` | 搜 CardDemoPage / OperationBanner |
| 周年庆活动花效果不显示 | 周年庆、花效果 | `Features/Imps/WEGAnniversaryImp.m` | 搜 checkFlower / WEGAnniversaryManager |
| 资讯内广告点击无跳转 | 广告点击、NewsItem 广告 | `Features/Imps/WEGADManagerImp.m` | 搜 doClickActionWithNewsItem / WEGADManager |
| 周年庆管理器异常 | 周年庆管理 | `Features/Manager/AnniversaryManager/` | 搜 AnniversaryManager / checkAnniversary |
| 十周年活动异常 | 十周年、10 周年 | `Features/Manager/TenthAnniversary/` | 搜 TenthAnniversary |

---

## 排查起点建议

- **签到类**：`lib/checkin_landing/` + `lib/supplement_sign/`，检查接口和状态管理
- **运营弹窗**：`lib/camp_business/modal_sheet/` 的展示条件判断
- **iOS 特效**：`Features/Emitter/` 独立模块
- **周年庆活动**：`WEGAnniversaryImp.m`（Imp 入口） + `Features/Manager/AnniversaryManager/`（管理器）

*最后更新：2026-03-30（新增：周年庆管理器、十周年活动 2 个新场景）*
