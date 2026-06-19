# camp-verdict-agent diff-rules

最后同步时间：2026-06-17

## 已删除/简化的内容

### 1. 几乎无差异
camp-verdict-agent 原文本地版已经非常干净，无本地路径引用。

### 2. 唯一区别：Knot 版删除了 `tools: Bash, Read, Glob, Grep` frontmatter
Knot 版通过 Agent 配置界面指定可用工具，不需要 frontmatter 声明。

### 3. Galileo MCP 工具名称映射
原文：`get_metric_data`、`get_log_data`、`get_trace_data`、`get_event_data`
Knot 版：工具名称需确认 Knot 上挂载的 Galileo MCP 服务的实际工具名（部分名称可能不同）。
