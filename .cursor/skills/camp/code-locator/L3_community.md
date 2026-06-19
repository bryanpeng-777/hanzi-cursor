# L3 场景索引：社区 / 话题 / 专栏

> **所属域**：社区 / 话题 / 专栏 | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/community/` / `lib/topic/` / `Features/Imps/WEGNewsImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 社区主页加载失败 / 白屏 | 社区、社区首页 | `lib/community/` | 搜 CommunityPage / fetchCommunityData |
| 话题页面打不开 | 话题、话题广场 | `lib/topic/` | 搜 TopicPage / openTopic |
| 话题下的内容为空 | 话题内容、话题帖子 | `lib/topic/` | 搜 fetchTopicFeed / TopicDetailPage |
| 资讯 / 新闻数据为空 | 资讯、新闻、官方消息 | `WEGNewsImp.m`<br>`WEGNewsManagerImp.m` | 搜 fetchNewsList / NewsImp |
| AI 聊天无响应 / 加载失败 | AI 聊天、智能对话 | `lib/ai_chat/` | 搜 AIChatPage / sendAIMessage |
| 专栏 / 专题内容显示异常 | 专栏、专题 | `lib/column_detail/`<br>`lib/special_subject/` | 搜 ColumnDetailPage / SubjectPage |
| 王者棋盘区域内容不显示 | 棋盘、王者棋盘 | `lib/king_chess_offcial/` | 搜 KingChessPage |
| 同人内容板块异常 | 同人 | `lib/tongren/` | 搜 TongsRenPage |
| 流量券不显示 / 无法领取 | 流量券 | `lib/traffic_coupon/` | 搜 TrafficCouponPage |

---

## 关键链路

```
社区入口
  → lib/community/ 社区首页 Tab
  → 各子 Tab：话题 / 专栏 / 资讯
  → lib/topic/ 话题详情
  → WEGNewsImp.m → WEGNewsManagerImp.m 资讯数据
```

---

## 排查起点建议

- **资讯问题（iOS 端触发）**：优先看 `WEGNewsImp.m` 的 fetch 逻辑
- **社区/话题（Flutter 端）**：`lib/community/` + `lib/topic/` 对应页面

*最后更新：2026-03-30*
