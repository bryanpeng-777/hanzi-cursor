---
name: sync-mcp
description: 同步所有 AI 工具（Cursor、Claude Code、CodeBuddy、WorkBuddy）的 MCP 配置，取并集写回每个工具。当用户说「同步 mcp」、「mcp 同步」、「sync mcp」、「同步工具的 mcp」、「把 mcp 同步一下」时触发。
---

执行以下命令同步 MCP 配置：

```bash
~/.ai-shared/sync.sh
```

同步完成后，运行以下命令展示各工具的同步状态：

```bash
~/.ai-shared/sync.sh status
```

将状态结果以表格形式呈现给用户，注明哪些 server 是新合并进来的，并提示重启对应工具后生效。
