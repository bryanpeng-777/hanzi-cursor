# L3 场景索引：动态 / 内容 Feed

> **所属域**：动态 / 内容 Feed | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/recommend_home/` / `lib/camp_business/feed_cards/` / `lib/info/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 首页推荐 Feed 为空 / 加载失败 | 首页、Feed 为空、刷新失败 | `lib/recommend_home/` | 搜 fetchRecommendFeed / RecommendHomePage |
| 动态卡片显示异常（布局错乱/内容乱） | 卡片显示、布局 | `lib/camp_business/feed_cards/` | 搜 FeedCard / feedCardBuilder |
| 内容详情页打不开 / crash | 详情页、帖子打不开 | `lib/info/` / `lib/info_detail/` | 搜 InfoDetailPage / openInfo |
| 评论区加载失败 / 评论发不出去 | 评论、发评论 | `lib/camp_business/comment_card/`<br>`lib/camp_business/comment_action_sheet/` | 搜 CommentCard / submitComment |
| 点赞后没有反应 / 点赞状态不同步 | 点赞、like | `lib/camp_business/feed_cards/` | 搜 likeAction / toggleLike / LikeWidget |
| 收藏失败 / 我的收藏里没有 | 收藏 | `lib/collection/` / `lib/my_collection/` | 搜 collectPost / CollectionPage |
| 投票功能不显示 / 投票失败 | 投票 | `lib/vote_create/` | 搜 VoteWidget / submitVote |
| 截图投递按钮没反应 | 截图投递 | `lib/screen_shot/`<br>`Features/ScreenShotToSubmit/` | 搜 screenShotToSubmit / captureScreen |
| Feed 流滚动卡顿 / 掉帧 | 滚动卡顿、流畅度 | `lib/recommend_home/` | 看 ListView 的 itemBuilder 性能 |
| 下拉刷新没有新内容 / 一直转圈 | 下拉刷新、pull refresh | `lib/recommend_home/` | 搜 onRefresh / refreshFeed |
| 举报内容弹窗不出来 | 举报、不能举报 | `lib/report/` | 搜 showReportSheet（被 feed_cards 调用） |

---

## 关键链路

```
进入首页
  → lib/recommend_home/ RecommendHomePage
  → 请求推荐 Feed 接口
  → 渲染 lib/camp_business/feed_cards/ 各类卡片
  → 点击卡片 → lib/info/ 详情页
  → 详情页内：评论/点赞/收藏/分享各自模块处理
```

---

## 排查起点建议

- **首页为空**：`lib/recommend_home/` 的数据请求 + 错误处理逻辑
- **卡片显示异常**：`lib/camp_business/feed_cards/` 对应卡片类型的 widget
- **交互失败（点赞/评论/收藏）**：各自对应的 action 模块，大多在 `lib/camp_business/` 下

*最后更新：2026-03-30*
