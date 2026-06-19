# L3 场景索引：搜索

> **所属域**：搜索 | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/search/` / `lib/search_new/` / `Features/Imps/WEGSearchImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 搜索页面打不开 | 搜索页、点搜索没反应 | `lib/search/` / `lib/search_new/`<br>`WEGSearchImp.m` | 搜 SearchPage / `openSearch:` |
| 搜索结果为空 / 没有数据 | 搜索没结果、搜不到 | `lib/search/` | 搜 fetchSearchResult / SearchResultPage |
| 搜索游戏昵称找不到人 | 昵称搜索、搜玩家 | `lib/search_game_nickname/` | 搜 searchNickname / GameNicknameSearchPage |
| 搜索历史记录不显示 | 搜索历史 | `lib/search/`（history 子目录） | 搜 searchHistory / HistoryList |
| 搜索推荐词 / 热门词不出来 | 热搜、推荐词 | `lib/search/`（suggestion） | 搜 hotSearch / searchSuggestion |
| 搜索结果 Tab 切换异常 | 搜索结果 Tab、分类 | `lib/search/`（result tabs） | 搜 SearchResultTab / tabController |

---

## 排查起点建议

- **iOS 侧触发搜索**：从 `WEGSearchImp.m` 的 `openSearch:` 入手
- **搜索结果为空**：先排查接口是否正常，再看 `lib/search/` 的数据处理

*最后更新：2026-03-30*
