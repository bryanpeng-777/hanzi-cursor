# L3 场景索引：举报 / 黑名单

> **所属域**：举报 / 黑名单 | **上级 L2**：L2_USER_SOCIAL.md  
> **主路径**：`lib/report/` / `lib/blacklist_user/` / `lib/block_management/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 举报按钮点击无响应 | 举报、report | `lib/report/` | 搜 ReportPage / showReportSheet |
| 举报类型选择后提交失败 | 举报类型、提交举报 | `lib/report/`（type selection） | 搜 submitReport / reportType |
| 拉黑某用户后对方还能看到我 | 拉黑、黑名单 | `lib/blacklist_user/` | 搜 blockUser / addToBlacklist |
| 屏蔽后还能看到对方的内容 | 屏蔽、block | `lib/block_management/` | 搜 blockManagement / isBlocked |
| 黑名单列表加载不出来 | 黑名单列表 | `lib/blacklist_user/` | 搜 BlacklistPage / fetchBlacklist |

---

## 排查起点建议

- **举报问题**：`lib/report/` 直接入手，举报流程简单
- **黑名单不生效**：排查 `lib/blacklist_user/` 的接口调用是否成功，再看 Feed/聊天侧是否正确读取黑名单状态

*最后更新：2026-03-30*
