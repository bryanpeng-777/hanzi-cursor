# Layer 2 详情：内容与创作

> **归属超级分类**：B - 内容与创作  
> **覆盖域**：动态/Feed、社区/话题/专栏、搜索、分享、内容编辑器/发布、活动/运营  
> **路径根**：Flutter `flutter_module/lib/` | iOS `social-ios/src/GameApp/`

---

## 1. 动态 / 内容 Feed 　　　📄 [场景展开 → L3_feed.md](L3_feed.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 推荐首页 / 信息流 | `lib/recommend_home/` | — |
| Feed 卡片组件（通用） | `lib/camp_business/feed_cards/` | — |
| 内容详情页 | `lib/info/`<br>`lib/info_detail/` | — |
| 评论区 | `lib/camp_business/comment_card/`<br>`lib/camp_business/comment_action_sheet/` | — |
| 收藏 | `lib/collection/`<br>`lib/my_collection/` | — |
| 投票功能 | `lib/vote_create/` | — |
| 截图投递 | `lib/screen_shot/` | `Features/ScreenShotToSubmit/` |
| 点赞 | `lib/camp_business/feed_cards/`（点赞 widget） | — |
| 内容举报（Feed 内） | `lib/report/` | — |
| 话题 Feed 流 | `lib/topic/`（详情内） | — |
| **首页路由入口** | `lib/business/homepage/` | — |

---

## 2. 社区 / 话题 / 专栏 　　　📄 [场景展开 → L3_community.md](L3_community.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 社区主页 | `lib/community/` | — |
| 话题广场 / 话题详情 | `lib/topic/` | — |
| 专题 / 专栏 | `lib/special_subject/`<br>`lib/column_detail/` | — |
| 官方资讯 / 新闻（Flutter） | `lib/official_info/` | — |
| 官方资讯 / 新闻（iOS 触发） | — | `Features/Imps/WEGNewsImp.m`<br>`Features/Imps/WEGNewsManagerImp.m`<br>`Features/Imps/WEGNewsSubjectImp.m` |
| 广告点击（资讯内广告） | — | `Features/Imps/WEGADManagerImp.m` |
| 王者棋盘官方区 | `lib/king_chess_offcial/` | — |
| AI 聊天 | `lib/ai_chat/` | — |
| 同人内容 | `lib/tongren/` | — |
| 流量券 | `lib/traffic_coupon/` | — |
| **资讯管理器** | — | `Features/Manager/NewsManager/` |
| **专题页路由入口** | `lib/business/special_topic/` | — |
| **话题权重** | `lib/business/topic_weight/` | — |

**关键 Imp**：`WEGNewsImp.m`、`WEGNewsManagerImp.m`、`WEGNewsSubjectImp.m`

---

## 3. 搜索 　　　📄 [场景展开 → L3_search.md](L3_search.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 搜索主页 | `lib/search/`<br>`lib/search_new/` | `Features/Imps/WEGSearchImp.m` |
| 游戏昵称搜索 | `lib/search_game_nickname/` | — |
| 搜索历史 / 热门词 | `lib/search/`（history 子目录） | — |
| 搜索结果分 Tab | `lib/search/`（result tabs） | — |
| 搜索路由入口 | `lib/business/search/` | — |

**关键 Imp**：`WEGSearchImp.m`

---

## 4. 分享 　　　📄 [场景展开 → L3_share.md](L3_share.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 分享组件 / 分享面板 | `lib/camp_business/share/` | `Features/CampShare/`<br>`Features/Imps/WEGShareImp2.m` |
| 转发渠道选择 | `lib/forward_channel/` | — |
| 二维码扫描 | `lib/qr_scan/` | — |
| 生成分享图 / 分享卡片 | `lib/camp_business/share/`（card 子目录） | `Features/CampShare/` |
| 下载分享面板（拉新/PC导流） | `lib/download_share_pannel/` | — |
| 微信/QQ 分享 | — | `Features/Imps/WEGShareImp2.m` |
| **分享码** | — | `Features/Component/ShareCode/` |

**关键 Imp**：`WEGShareImp2.m`

---

## 5. 内容编辑器 / 发布 　　　📄 [场景展开 → L3_editor.md](L3_editor.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 编辑器主体 | `lib/editor/` | `Features/Imps/WEGEditorImp.m` |
| 编辑器链接插入 | `lib/editor_link/` | — |
| 编辑器模板 | `lib/editor_template/` | — |
| @联系人 | `lib/at_contact/` | — |
| 文字链接 | `lib/text_link/` | — |
| 签到落地页 | `lib/checkin_landing/` | — |
| 剪贴板管理（粘贴提示） | — | `Features/ShearPlateManager/` |
| 图片选择 / 相册 | `lib/camp_business/album_picker/` | — |
| 发布确认 / 审核提示 | `lib/editor/`（submit 子目录） | — |
| 草稿箱 | `lib/editor/`（draft 子目录，如有） | — |

**关键 Imp**：`WEGEditorImp.m`

---

## 6. 活动 / 运营 　　　📄 [场景展开 → L3_activity.md](L3_activity.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 兴趣选择（新用户引导） | `lib/choose_interest/` | — |
| 签到 | `lib/checkin_landing/`<br>`lib/supplement_sign/` | — |
| 黑灯（特效互动） | `lib/black_light/` | — |
| 发光效果 | — | `Features/Emitter/` |
| 用户行为追踪 | — | `Features/UserActionTrack/` |
| 卡片 Demo / 运营位 | `lib/card_demo/` | — |
| 运营弹窗 / 公告 | `lib/camp_business/modal_sheet/` | — |
| 周年庆活动（花效果） | — | `Features/Imps/WEGAnniversaryImp.m` |
| **周年庆管理器** | — | `Features/Manager/AnniversaryManager/` |
| **十周年活动** | — | `Features/Manager/TenthAnniversary/` |

---

## 附录：常用 Imp 速查（内容创作域）

| Imp 文件 | 功能 |
|---------|------|
| `WEGSearchImp.m` | 搜索 |
| `WEGEditorImp.m` | 内容编辑器 |
| `WEGShareImp2.m` | 分享 |
| `WEGNewsImp.m` | 官方资讯 |
| `WEGNewsManagerImp.m` | 资讯管理 |
| `WEGNewsSubjectImp.m` | 资讯专题 |
| `WEGAnniversaryImp.m` | 周年庆活动 |
| `WEGADManagerImp.m` | 广告管理 |

---

*最后更新：2026-03-30（新增：NewsManager、AnniversaryManager、TenthAnniversary、ShareCode、lib/business条目）*
