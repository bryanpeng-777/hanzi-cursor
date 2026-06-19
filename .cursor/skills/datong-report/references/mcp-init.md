### Phase 0：大同 MCP 环境准备（MANDATORY PREREQUISITE - BLOCKS ALL）

> **[CRITICAL] 硬性前置条件**
>
> 大同 MCP 是整个 Skill 的基础设施，用于自动注册应用、获取 Appkey、反查应用 ID、上传埋点方案等。
> **如果此 Phase 未通过，禁止进入后续任何步骤。** 没有降级路径，没有跳过选项。

大同 MCP 有**两种接入方式**，任意一种成功即可：

| 方式 | 适用场景 | 检测方法 |
|------|---------|---------|
| **方式 A：IDE MCP 配置** | CodeBuddy、Cursor 等支持 MCP 协议的 IDE | 检测 IDE 环境中是否已有大同 MCP 工具可调用 |
| **方式 B：mcporter-taihu 命令行** | 任意终端环境 | 检测 mcporter-taihu 命令是否可用 |

---

## 检测流程

```
Phase 0 开始
  │
  ├─ Step 0.1：检测方式 A（IDE MCP 配置）
  │   ├─ 成功 → ✅ MCP 环境就绪，跳过后续步骤
  │   └─ 失败 → 继续检测方式 B
  │
  ├─ Step 0.2：检测方式 B（mcporter-taihu 命令行）
  │   ├─ 已安装且已授权 → ✅ MCP 环境就绪
  │   └─ 未安装 → Step 0.3 安装
  │
  ├─ Step 0.3：安装 mcporter-taihu（含多轮重试）
  │   ├─ 安装成功 → Step 0.4 配置 → Step 0.5 授权
  │   └─ 安装失败 → Step 0.6 引导用户选择方式
  │
  └─ Step 0.6：两种方式都失败 → ⛔ 引导用户手动安装，阻断流程
```

---

## Step 0.1：检测方式 A — IDE MCP 配置

尝试直接调用大同 MCP 工具来验证 IDE 是否已配置好大同 MCP 服务。

**检测方法**：尝试调用一个轻量的大同 MCP 工具（如 `search_app`），观察是否能正常返回结果。

| 结果 | 处理 |
|------|------|
| 工具调用成功（返回正常数据或空结果） | ✅ **MCP 环境就绪**，记录接入方式为 `ide_mcp`，跳过 Step 0.2-0.5，直接进入后续流程 |
| 工具不存在 / 调用报错 / 401 未授权 | → 继续 Step 0.2 检测方式 B |

> ⚠️ 方式 A 的检测是**静默的**，不需要向用户展示检测过程。如果成功就直接继续，失败就无缝切换到方式 B。

> 💡 **IDE MCP 配置方式说明**：在 CodeBuddy 等 IDE 中，用户可以通过 MCP 配置文件（如 `.codebuddy/mcp.json`）添加大同 MCP 服务：
> ```json
> {
>   "mcpServers": {
>     "大同MCP": {
>       "url": "https://datong.mcp.it.woa.com"
>     }
>   }
> }
> ```
> 配置后 IDE 会自动处理 OAuth 授权，无需手动操作。

---

## Step 0.2：检测方式 B — mcporter-taihu 命令行

```bash
mcporter-taihu --version && echo "MCPORTER_OK"
```

| 结果 | 处理 |
|------|------|
| 输出 `MCPORTER_OK` | → 检查是否已配置并授权（Step 0.4、Step 0.5） |
| 命令不存在 | → 进入 Step 0.3 安装 |

---

## Step 0.3：安装 mcporter-taihu（含 Node.js 检查和多轮重试）

### 前置：检查 Node.js 环境

```bash
node --version && echo "NODE_OK"
```

- 输出 `NODE_OK` 且版本 >= 18 → 继续安装 mcporter-taihu
- 版本低于 18 或未安装 → 向用户展示：

```markdown
⛔ **Node.js 版本不满足要求**

mcporter-taihu 需要 Node.js 18+，当前环境不满足。

**你有两个选择：**

**选择 1（推荐）：在 IDE 中配置大同 MCP**
在 CodeBuddy 设置 → MCP 配置中添加：
```json
"大同MCP": { "url": "https://datong.mcp.it.woa.com" }
```
添加后 IDE 会自动拉起 OAuth 授权页面，完成授权即可。

**选择 2：安装 Node.js 18+**
- macOS：`brew install node@18` 或从 https://nodejs.org/ 下载
- Linux：`curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs`

完成后告诉我，我会继续后续流程。
```

**[CRITICAL] STOP 并等待用户解决。** 用户确认后：
- 如果用户选择了 IDE 配置方式 → 回到 Step 0.1 验证
- 如果用户安装了 Node.js → 重新执行 Node.js 版本检查

### 安装 mcporter-taihu（最多 3 轮重试）

每轮安装后都用 `mcporter-taihu --version && echo "MCPORTER_OK"` 验证，成功即跳出进入 Step 0.4：

**轮次 1：直接安装**
```bash
npm install -g @tencent/mcporter-taihu --registry=https://mirrors.tencent.com/npm/ && mcporter-taihu --version && echo "MCPORTER_OK"
```

**轮次 2（轮次 1 失败时）：清理缓存后重试**
```bash
npm cache clean --force && npm install -g @tencent/mcporter-taihu --registry=https://mirrors.tencent.com/npm/ && mcporter-taihu --version && echo "MCPORTER_OK"
```

**轮次 3（轮次 2 失败时）：延长超时重试**
```bash
npm install -g @tencent/mcporter-taihu --registry=https://mirrors.tencent.com/npm/ --prefer-online --fetch-timeout=120000 --fetch-retries=5 && mcporter-taihu --version && echo "MCPORTER_OK"
```

**3 轮均失败** → 进入 Step 0.6

---

## Step 0.4：配置大同 MCP 服务

```bash
mcporter-taihu config add datong https://datong.mcp.it.woa.com --transport http --oauth-provider taihu && echo "CONFIG_OK"
```

- 输出 `CONFIG_OK` → 进入 Step 0.5
- 失败 → 向用户展示错误信息，**STOP 并等待用户解决**

## Step 0.5：授权（一键浏览器授权）

```bash
mcporter-taihu auth datong && echo "AUTH_OK"
```

执行后自动打开浏览器，用户使用企业微信扫码完成太湖 OAuth 授权即可。**无需手动复制 authorization code**。

- 输出 `AUTH_OK` → ✅ 授权成功，大同 MCP 环境就绪，记录接入方式为 `mcporter`
- 失败 → 向用户展示：

```markdown
⛔ **大同 MCP 授权失败**

可能原因：
- 无头环境（如远程服务器）无法打开浏览器
- 网络无法访问太湖 OAuth 服务

**你有两个选择：**

**选择 1（推荐）：在 IDE 中配置大同 MCP**
在 CodeBuddy 设置 → MCP 配置中添加：
```json
"大同MCP": { "url": "https://datong.mcp.it.woa.com" }
```

**选择 2：在有浏览器的本地电脑上执行授权**
`mcporter-taihu auth datong`

完成后告诉我，我会继续后续流程。
```

**[CRITICAL] STOP 并等待用户解决。**

---

## Step 0.6：两种方式都失败 — 引导用户手动安装

当 mcporter-taihu 自动安装失败时，向用户展示两种方式，引导用户选择：

```markdown
⛔ **大同 MCP 环境未就绪，无法继续执行。**

大同 MCP 是本 Skill 所有能力（埋点接入、看板创建、联调）的基础设施，必须安装成功才能继续。

**请选择以下任一方式配置：**

---

**方式 A（推荐）：在 IDE 中配置大同 MCP**

在 CodeBuddy / Cursor 等 IDE 的 MCP 配置中添加：
```json
{
  "mcpServers": {
    "大同MCP": {
      "url": "https://datong.mcp.it.woa.com"
    }
  }
}
```
- CodeBuddy：设置 → MCP 配置（用户级别）→ 添加
- 添加后 IDE 会自动拉起 OAuth 授权页面，完成授权即可

---

**方式 B：手动安装 mcporter-taihu**

请前往太湖 MCP 平台，按照页面指引手动完成安装：

👉 https://tai.it.woa.com/mcps/dc1d89ba-1e2b-4fdb-b071-fbe4b54bebee/usage

---

⏸️ 配置完成后告诉我，我会验证并继续后续流程。
```

**[CRITICAL] STOP 并等待用户解决。** 用户告知完成后：
- 先执行 Step 0.1（检测 IDE MCP）
- 若失败再执行 Step 0.2（检测 mcporter-taihu）
- 两者都失败 → 再次展示引导信息

---

## 接入方式记录

Phase 0 通过后，记录成功的接入方式，后续工具调用时据此选择调用路径：

| 接入方式 | 记录值 | 后续工具调用方式 |
|---------|--------|----------------|
| IDE MCP 配置 | `ide_mcp` | 直接调用 MCP 工具名（IDE 自动代理） |
| mcporter-taihu 命令行 | `mcporter` | 通过 `mcporter-taihu call datong.*` 命令或 Python 脚本兜底 |

> ✅ **Phase 0 通过后，大同 MCP 环境已就绪**，后续步骤可直接调用大同 MCP 工具。
