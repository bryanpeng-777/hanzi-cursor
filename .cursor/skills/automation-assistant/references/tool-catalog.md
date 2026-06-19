# 自动化助手工具目录

在 5 步访谈的 Step 2（知识库）、Step 3（洞察策略）、Step 5（输出分发）中参考此目录选型。

---

## 目录索引

- [静态知识源](#静态知识源)（Step 2：运行时加载类静态知识）
- [动态数据源](#动态数据源)（Step 2：实时采集的运行时数据）
- [分析层](#分析层)（Step 3：可复用的洞察工具）
- [输出层](#输出层)（Step 5：结论分发渠道）

---

## 静态知识源

> 每次运行时动态加载，内容随时间变化（代码更新、文档迭代），适合需要「最新版本」的知识。
> 与「内化进技能（直接写入 SKILL.md/references/）」相对。

| 知识源 | 调用方式 | 适用场景 | 说明 |
|--------|---------|---------|------|
| **代码仓库** | `Bash` (git/grep/find) | 定位崩溃代码位置、排查变更责任人、理解模块架构 | `git log`、`git blame`、`grep` |
| **Craft 文档** | `user-craft` MCP | 读取设计文档、需求背景、历史决策 | 支持按文档名/文件夹检索 |
| **腾讯文档** | `user-tencentdocs` MCP / `docs-assistant` agent | 读取在线表格、共享文档、历史记录 | 支持智能表格读取 |
| **企微文档** | `user-wecom-doc` MCP | 读取企业微信在线文档 | 支持 doc/sheet/mindmap 类型 |
| **各域 patterns.md** | `Read` 工具 | 匹配历史已知问题模式，加速分析 | 位于各小助手的 `knowledge/` 目录 |
| **iWiki 文档** | `user-iWiki` MCP | 读取内部 wiki 知识库 | 适合架构文档、规范文档 |
| **本地 Markdown** | `Read` / `Glob` 工具 | 读取项目内的设计文档、配置文件 | 路径需已知 |

---

## 动态数据源

> 每次运行时实时采集，数据随时间变化（日志滚动、告警触发、指标波动）。

| 数据源 | 技能/MCP | 适用场景 | 主要能力 |
|--------|---------|---------|---------|
| **伽利略告警** | `user-galileo-mcp` MCP | 监控告警分析、错误率上报、trace 追踪 | 查询告警列表、获取 trace 详情、统计错误码分布 |
| **伽利略日志** | `user-galileo-mcp` MCP + `galileo-log` skill | 用户行为日志、接口调用日志 | 按 userId/moduleName/时间窗 查询日志 |
| **Bugly 数据** | `bugly-data-analyzer` skill | Crash/ANR/FOOM 统计、版本对比、新增问题 | 调用 Bugly Agent SSE 接口查询各类指标 |
| **营地后台数据** | `user-camp` MCP | 营地用户行为、后台接口调用 | 查询用户操作日志、接口状态 |
| **营地日志（lego）** | `user-lego-mcp-server` MCP | 补拉指定 userId 的客户端日志 | 按 uid + 时间窗拉取，支持下载解压 |
| **iFeedback 用户反馈** | `ifeedback` skill | 用户投诉、问题反馈趋势分析 | 搜索反馈、趋势统计、热词分析 |
| **TAPD 看板** | `user-mcp-server-tapd` MCP | 任务进度跟踪、需求状态查询 | 查询 story/bug/task 状态 |
| **Oncall 工单** | `user-oncallplatform_prod` MCP | 查询待处理工单、工单详情 | 获取 incident 列表和详情 |

---

## 分析层

> Step 3 洞察策略可直接复用的现有分析工具。若现有工具不满足需求，考虑把领域经验直接内化进 SKILL.md。

| 分析工具 | 类型 | 适用场景 | 使用方式 |
|---------|------|---------|---------|
| **直接 LLM 推理** | AI 层 | 无明确规则、需要综合判断、数据量小 | 直接在 SKILL.md 中写分析指令 |
| **阈值规则判断** | 规则层 | 有明确数值标准（Crash 率、失败率等） | 在 SKILL.md 中硬编码判断逻辑 |
| **galileo-alert-stat-analyzer** | 专项工具 | 伽利略告警量化分析（错误码分布、版本分布、影响面统计）| Read skill 并调用 |
| **bugly-issue-analyze-agent** | 专项工具 | Bugly issue 代码级根因分析（下载仓库、结合堆栈定位代码）| Read skill 并调用 |
| **bugly-user-investigator** | 专项工具 | 按 userId 查询 Bugly 异常详情 | Read skill 并调用 |
| **galileo-alert-user-extractor** | 专项工具 | 从告警中提取代表性受影响用户 | Read skill 并调用 |
| **code-owner-assigner** | 专项工具 | 根据堆栈/代码文件找最近活跃的责任开发者 | Read skill 并调用 |
| **各域 patterns.md** | 规则层 | 匹配历史已知问题模式 | Step 0 中预加载，分析时对比 |

---

## 输出层

> **选型优先级：有专属 agent 的渠道，优先使用 agent（封装了业务逻辑和错误处理）；无专属 agent 时直接调用 MCP。**

| 渠道 | 优先使用 | 备用 | 适用场景 | 格式建议 |
|------|---------|-----|---------|---------|
| **腾讯文档** | `docs-assistant` agent | `user-tencentdocs` MCP | 记录分析结论、追加日报表格、生成报告 | 智能表格（追加行）/ 在线文档 |
| **Oncall 工单** | `oncall-assistant` agent | `user-oncallplatform_prod` MCP | 严重异常自动创建工单 | 结构化工单（含根因摘要）|
| **企业微信群** | 无专属 agent | `user-wework-bot` MCP | 实时告警、简报推送 | 简短摘要（3-5 行）+ 关键指标 |
| **iWiki** | 无专属 agent | `user-iWiki` MCP | 周报/月报归档、完整分析报告 | 完整报告（含证据链）|
| **Craft 知识库** | 无专属 agent | `user-craft` MCP | 经验沉淀、知识积累 | 结构化知识条目 |
| **企微文档** | 无专属 agent | `user-wecom-doc` MCP | 在线表格追加 | 表格行追加 |

---

## 工具适配速查

根据常见自动化场景，快速找到推荐工具组合：

| 场景 | 推荐数据源 | 推荐分析工具 | 推荐输出渠道 |
|------|-----------|------------|------------|
| Bugly 灰度/版本监控 | Bugly 数据 | 阈值规则 + bugly-issue-analyze-agent | 企业微信 + 腾讯文档 |
| 伽利略告警巡检 | 伽利略告警 | galileo-alert-stat-analyzer + 规则 | oncall-assistant（严重）+ 腾讯文档 |
| 看板进度跟进 | TAPD 看板 | 直接 LLM 判断（是否有卡点） | 企业微信 + 腾讯文档 |
| 大同埋点验证 | 伽利略日志 + 代码仓库 | 直接 LLM（对比规范 vs 实现）| 企业微信 |
| 用户投诉分析 | iFeedback + 营地日志 | 直接 LLM + patterns | 腾讯文档 + oncall（严重）|
