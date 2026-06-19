---
name: wecom-doc-mcp
description: "Install, configure, and use the WeCom (企业微信) document MCP service. Use this skill when the user wants to: (1) install or set up the WeCom document MCP service (安装企微文档, 安装 MCP, install wecom doc), (2) read, write, screenshot, or interact with WeCom online documents hosted on doc.weixin.qq.com, (3) access 企微文档, 企业微信文档, 在线表格, 在线文档, or any URL containing doc.weixin.qq.com. This skill bundles source code and an install script — no git clone needed. Supports doc, sheet, smartsheet, slide, mindmap, and flowchart types."
license: MIT
compatibility: "Requires Node.js 18 or later and a desktop environment for first-time QR-code login. Works on macOS and Linux. Playwright Chromium is installed automatically. Source code is bundled, no git required."
metadata:
  author: baojiantang
  version: "1.0.0"
  mcp-server: "true"
  repository: "https://git.woa.com/baojiantang/wecom-doc-mcp"
---

# WeCom Document MCP Service（企业微信文档 MCP 服务）

通过 Playwright 浏览器自动化，让 AI Agent 能够读写企业微信在线文档（doc.weixin.qq.com）的内容。

## Installation（安装）

**首次使用前需要安装。** 当用户要求使用企微文档功能但尚未安装时，你（Agent）应自动执行安装。

### 自动安装（Agent 直接执行）

检测是否已安装：

```bash
test -f ~/wecom-doc-mcp/package.json && echo "已安装" || echo "未安装"
```

如果未安装，执行安装脚本。脚本位于本 SKILL.md 同级目录的 `scripts/setup.sh`：

```bash
bash scripts/setup.sh
```

> 你（Agent）已知本 skill 的目录路径（即你读取此文件的位置）。如果相对路径不生效，请使用绝对路径执行，例如 `bash /Users/xxx/.codebuddy/skills/wecom-doc-mcp/scripts/setup.sh`。
>
> 安装脚本做的事情：从内置 `source/` 目录复制源码到 `~/wecom-doc-mcp` → `npm install` → 安装 Playwright Chromium → 自动检测 AI 工具并配置 MCP。无需 git，无需用户操作终端。

### Agent 完整决策流程

当用户请求操作企微文档时，按以下顺序判断：

1. **检测是否已安装**（执行上面的命令）
   - 未安装 → 执行 `bash scripts/setup.sh` → 安装完成后告知用户：**"安装成功！请重启 AI 工具（关闭后重新打开），然后再次发送你的请求。"** → 停止，不要继续后续步骤
   - 已安装 → 继续下一步

2. **检测登录状态**（调用 `wecom_doc_status` MCP 工具）
   - 已登录 → 继续执行用户请求
   - 未登录 → 调用 `wecom_doc_login` MCP 工具，告知用户"已弹出浏览器，请用企业微信扫码" → 等待登录成功后继续执行用户请求
   - MCP 工具不可用 → 用户可能还没重启，告知用户"请先重启 AI 工具，再重新发送请求"

3. **执行用户请求**（调用 `wecom_doc_fetch` / `wecom_doc_write` 等）
   - 如果返回"未登录或登录已过期" → 回到第 2 步触发登录

### 关于登录

安装完成后用户重启 AI 工具，再次发送请求时，Agent 会按决策流程自动检测登录状态并调用 `wecom_doc_login` 弹出浏览器让用户扫码。Cookie 有效期约数天，过期后 Agent 自动触发重新登录。

> 备用方案：如果 MCP 服务未正常加载，用户可在终端执行 `cd ~/wecom-doc-mcp && npm run login`

### 手动安装（备用）

如果自动安装失败，手动操作：

```bash
# 1. 复制源码到安装目录
mkdir -p ~/wecom-doc-mcp
cp -r <skill目录>/source/* ~/wecom-doc-mcp/

# 2. 安装依赖
cd ~/wecom-doc-mcp
npm install
npx playwright install chromium
```

然后在你使用的 AI 工具的 MCP 配置中添加：

```json
"wecom-doc": {
    "command": "node",
    "args": ["/Users/yourname/wecom-doc-mcp/src/index.js"],
    "timeout": 180000
}
```

> 注意：将路径替换为实际的安装目录绝对路径。

各工具配置文件位置：

| AI Tool | Config Path |
|---------|-------------|
| CodeBuddy | `~/.codebuddy/mcp.json` |
| Cursor | `~/.cursor/mcp.json` |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| VS Code (Copilot) | `.vscode/mcp.json` (project-level) |

## Available Tools（可用工具）

| Tool | Purpose |
|------|---------|
| `wecom_doc_login` | Launch browser for QR-code login |
| `wecom_doc_status` | Check if login session is valid |
| `wecom_doc_fetch` | Read doc/sheet/slide/mindmap content |
| `wecom_doc_screenshot` | Take screenshot of document page |
| `wecom_doc_write` | Append plain text to doc documents |
| `wecom_doc_write_sheet` | Write/append content to sheet cells |

## Usage Guide（使用指南）

### Reading Documents

当用户提供 doc.weixin.qq.com 链接并要求读取内容时（按上方决策流程确认已安装且已登录后）：

1. 调用 `wecom_doc_fetch` 并传入 `url` 参数
2. 对于表格文档，返回的 `sheetList` 包含工作表列表及 tab ID，`sheets` 包含数据
3. 如需读取指定工作表，使用 `tab` 参数传入 tab ID

### Writing Documents

**doc type（在线文档）**：
- 调用 `wecom_doc_write`，传入 `url` 和 `content`
- 仅支持在末尾追加纯文本，content 支持 `\n` 换行

**sheet type（在线表格）**：
- 调用 `wecom_doc_write_sheet`，传入 `url`、`cell`（如 A1, N5）和 `content`
- `mode`: `append`（默认，追加）或 `overwrite`（覆盖）
- 使用 `tab` 参数指定工作表

### Batch Row Insert（批量写入）

1. 先 `wecom_doc_fetch(url, tab)` 确认最后一行行号 N
2. 新数据写入第 N+1 行
3. 逐单元格写入 A{N+1}, B{N+1}, ...，使用 `mode: "overwrite"`
4. 写入完成后可再次 fetch 验证

### Cookie 过期自动处理

当任何工具返回"未登录或登录已过期"时：
1. 自动调用 `wecom_doc_login` 弹出浏览器
2. 告知用户"登录已过期，已弹出浏览器窗口，请用企业微信扫码"
3. 等待登录成功后，**自动重试**刚才失败的操作

> 用户全程不需要打开终端，Agent 通过 MCP 工具完成登录。

### Key Notes

- Cookie 有效期约数天，过期后 Agent 自动触发重新登录
- 表格写入是逐单元格操作
- doc 写入仅支持末尾追加，不支持中间插入
- slide/mindmap/flowchart 为只读（slide 支持文本+截图，mindmap 支持节点提取+截图，flowchart 支持文本提取）

## References

详细的工具参数、使用场景和故障排查见 [references/tool_reference.md](references/tool_reference.md)。
