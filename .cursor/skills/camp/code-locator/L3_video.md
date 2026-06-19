# L3 场景索引：短视频

> **所属域**：短视频 | **上级 L2**：L2_GAME.md  
> **主路径**：`lib/short_video/` / `Features/VideoPlayer/` / `Features/TVKSerialPlayer/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 短视频列表加载失败 / 为空 | 短视频、视频列表 | `lib/short_video/` | 搜 ShortVideoPage / fetchVideoList |
| 视频播放卡顿 / 黑屏 / 无法播放 | 视频播放、黑屏、播放失败 | `Features/VideoPlayer/` | 搜 VideoPlayerManager / startPlay |
| 串行视频播放器异常（看精彩集锦） | 连续播放、串行 | `Features/TVKSerialPlayer/` | 搜 TVKSerialPlayer / playNext |
| 全屏视频路由（Flutter 还是原生播放） | 全屏视频、路由选择 | `Features/Imps/WEGFullScreenVideoImp.m` | 搜 WEGFullScreenVideoInterface / openFullScreen |
| 精彩时刻剧本选择 / 生成面板 | 精彩时刻、剧本、生成 | `lib/moments_script/` | 搜 MomentsScriptPage / scriptBackendService |
| 游戏高光 / 精彩集锦视频不显示 | 高光、精彩时刻 | `lib/game_high_lights/` | 搜 GameHighLightsPage / fetchHighLights |
| 视频评论加载失败 | 视频评论 | `lib/camp_business/comment_card/` | 搜 CommentCard（同 Feed 评论） |
| 视频分享失败 | 分享视频 | `lib/camp_business/share/` | 搜 shareVideo / ShareSheet |
| 短视频上滑切换卡顿 | 上滑切换、刷视频 | `lib/short_video/` | 看 PageView / preloadVideo 性能 |

---

## 排查起点建议

- **播放失败**：`Features/VideoPlayer/` 的错误码和网络状态
- **列表加载问题**：`lib/short_video/` 的数据请求
- **串行播放**：`Features/TVKSerialPlayer/` 独立组件

*最后更新：2026-03-30*
