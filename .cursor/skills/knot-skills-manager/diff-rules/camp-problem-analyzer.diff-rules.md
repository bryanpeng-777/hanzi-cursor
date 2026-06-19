# camp-problem-analyzer diff-rules

最后同步时间：2026-06-17

## 已删除/简化的内容（这些 diff 无需同步到 Knot）

### 1. 本地文件读取 → 替换为 camp-knowledge-base 技能调用
原文：
```
~/.claude/knowledge/camp-problem-analyzer/shared/reference.md
~/.claude/knowledge/camp-problem-analyzer/shared/problem-patterns.md
~/.claude/knowledge/camp-problem-analyzer/{project}/reference.md
```
Knot版：调用 camp-knowledge-base 技能（domain=camp）

### 2. knowledge-assistant 技能调用 → 替换为内联搜索
原文：`调用 knowledge-assistant，scope = camp-problem-analyzer`
Knot版：从 Step 1 已加载的 camp-knowledge-base 内容中直接搜索

### 3. Step 10 域知识更新 → 替换为沉淀建议输出
原文：`cd ~/.claude/skills && git add . && git commit -m "..." && git push origin main`
Knot版：输出知识沉淀建议，提示人工更新 camp-knowledge-base

### 4. 批量模式 Step B6 模式 11 → 简化
原文：使用 Galileo CLI 命令 `galileo logs analyze templates`
Knot版：使用伽利略 MCP 工具替代 CLI 命令

### 5. 分析时间窗口来自 camp-info-extractor 而非±1小时
注：Knot 版分析时间窗口改为±1小时（camp-info-extractor 的实际实现），原文为±5分钟精确时间点仅适用于伽利略子分析器的内部查询。
