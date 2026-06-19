## 纠正记录

---

### Harness 子任务 UI 实现（T010 拼音 Hub · hanzi-ui-redesign）
- 记录时间：2026-06-05
- 匹配关键词：大需求, harness, T010, ui-design-workflow, 拼音Hub, 灵山, 编排, Figma
- 原清单：（反模式）主会话见 Figma 链接即执行 ui-design-workflow；合并 Step 2～5；执行中擅自改 Column/Stack/缩放策略
- 纠正后清单：
  1. [人工] 大需求 S1 — 构造富 TaskSpec，**仅启动灵山 Scenario B**（禁止附带 Step3令牌）
  2. [技能] light-daily-task-manager/灵山 — Step 3 execution-planner EP-3 展示清单，**等用户「开始」**
  3. [workflow] ui-design-workflow — **灵山 Step 4 当前项**，单步单回合，禁止主会话代执行
  4. [技能] ralph-loop — analyze + test
  5. [人工] App 验收 — 「T<XXX> 验证通过」
- 纠正说明：**编排只能灵山做**；**编排后只按 Step3令牌执行，禁止自行想象或跳 workflow 门禁**。详见 `big-req-harness/hanzi-cursor/hanzi-ui-redesign/lessons_learned.md`。

---

### userId 登录 Bug 排查（微信扫码登录不弹码）
- 记录时间：2026-05-20 19:50
- 匹配关键词：bug修复, 登录, 微信扫码, userId排查, 功能失效
- 原清单：
  1. [agent] user-log-investigator — 查 userId 伽利略日志
  2. [agent] bugly-user-investigator — 查该用户 crash/anr/foom
  3. [AI分析] 综合日志 + Bugly 结论，定位根因
  4. [agent] dev-assistant — 实施代码修复
  5. [人工] 编译运行验证
- 纠正后清单：
  1. [agent] 营地问题分析小助手 — 传入 userId + 问题描述，多域并行分析，输出根因报告
- 纠正说明：bug修复类功能失效问题应直接交给营地问题分析小助手做多域并行分析，不拆子工具、不预先加修复步骤

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

### 优化 Demo 首页视觉升级
- 记录时间：2026-05-19 17:06
- 匹配关键词：视觉升级, UI优化, 首页优化, Flutter界面, 视觉改进, 界面优化
- 原清单：
  1. [AI分析] Stats Island 数字改渐变色 + 微光 border
  2. [AI分析] Featured 底部渐变加深 + Explore 按钮改珊瑚橙填充
  3. [AI分析] New Arrivals 缩略图下方加文字标签
  4. [AI分析] Collections Grid 加阴影 + InkWell 波纹
  5. [AI分析] Section Header "See All" 加下划线 + 竖线改渐变
  6. [AI分析] SliverAppBar 收起时加毛玻璃 blur 效果
- 纠正后清单：
  1. [workflow] ui-design-workflow — 输入当前界面代码 + 优化方向，走完整设计→实现→测试闭环
- 纠正说明：视觉优化/界面改版类任务应优先使用 ui-design-workflow，而非直接 [AI分析] 改代码；ui-design-workflow 提供预览图确认、dev-assistant 实现、测试验证的完整闭环。
