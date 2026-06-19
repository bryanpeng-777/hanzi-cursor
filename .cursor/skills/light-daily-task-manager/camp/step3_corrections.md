## 纠正记录

---

### 伽利略告警分析（mqqapi://forward OutRouter 失败）
- 记录时间：2026-05-20 11:30
- 匹配关键词：伽利略告警分析，告警，OutRouter，mqqapi
- 原清单：
  1. [MCP工具] Galileo get_alert_detail — 获取告警策略配置、指标维度、时间信息
  2. [MCP工具] Galileo get_log_data / get_metric_data — 拉取日志数据，统计错误分布
  3. [AI分析] 根因推断 — 综合数据输出结构化告警分析报告
- 纠正后清单：
  1. [agent] 营地问题分析小助手 — 传入告警链接，分析根因、影响范围，输出结构化报告（跳过知识库检索）
- 纠正说明：伽利略告警分析应直接调用营地问题分析小助手，而非手动拆解 MCP 工具步骤；同时跳过 Step 4 已知问题检索

---

### 营地代码负责人查找（git show 性能）
- 记录时间：2026-06-17
- 匹配关键词：营地代码负责人，code-owner-assigner，git show，责任人分配
- 纠正说明：`git show <hash>` 不加 `--stat`/`--no-patch` 会输出完整 diff，大提交极慢。查看提交详情必须 `timeout 10 git show <hash> --no-patch --format="..."` 或 `--stat`；优先用 `scripts/git_trace.py` 的 JSON 输出，避免手动 git show
