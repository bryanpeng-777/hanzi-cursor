# 营地反馈日志分析 Skill 包

给定一条用户反馈（反馈 ID / iFeedback URL / 营地 uid / 日志链接），自动拉取日志和截图、解码 mars xlog、由 LLM 输出根因分析报告。

## 快速上手

### 方式一：通过 iFeedback URL 分析（推荐）

```bash
export IFEEDBACK_MCP_TOKEN=tai_pat_xxx   # 太湖令牌，申请：https://tai.it.woa.com/user/pat

# 1. 初始化工作目录
WD=$(python3 camp-feedback-analyzer/scripts/feedback_analyze.py init \
    --feedback-id <id> --create-time "2026-05-13 18:28:05")

# 2. 检索反馈 + 下载附件
python3 camp-ifeedback-feedback-fetcher/scripts/ifeedback.py locate \
    --ifeedback-url "https://ifeedback.qq.com/feedback/?app_id=772&..." \
    --workdir $WD --first
python3 camp-ifeedback-feedback-fetcher/scripts/ifeedback.py fetch --workdir $WD

# 3. 解码 xlog
/usr/bin/python3 camp-xlog-decoder/scripts/decode.py decode --workdir $WD

# 4. 主 LLM 读 $WD/decoded_logs/ + $WD/attachments/ 写 $WD/report.md
```

### 方式二：通过水晶反馈 ID 分析

```bash
export CRYSTAL_MCP_TOKEN=tai_pat_xxx     # 水晶接口当前为 stub，用 fixture 模式调试

WD=$(python3 camp-feedback-analyzer/scripts/feedback_analyze.py init \
    --feedback-id 202605_12352 --create-time "2026-05-11 20:35:56")

python3 camp-crystal-feedback-fetcher/scripts/crystal.py locate \
    --fixture-record /path/to/feedback.json \
    --feedback-id 202605_12352 --workdir $WD --first
python3 camp-crystal-feedback-fetcher/scripts/crystal.py fetch --workdir $WD

# logs 为空时自动走 lego 兜底
/usr/bin/python3 camp-xlog-decoder/scripts/decode.py decode --workdir $WD
```

### 方式三：直传日志链接 + 截图（最快）

已有 COS 日志链接和截图 URL，跳过反馈检索直接分析：

```bash
WD=$(python3 camp-feedback-analyzer/scripts/feedback_analyze.py init-direct \
    --content "登录后闪退" \
    --log-url "https://cltlog-xxx.cos-internal.../key" \
    --pic-url "https://report-xxx.file.myqcloud.com/.../pic.jpg" \
    --user-id 1644128013 --platform android)

/usr/bin/python3 camp-xlog-decoder/scripts/decode.py decode --workdir $WD
# 直接写报告
```

## 架构

```
camp-feedback-analyzer/              顶层编排（init / init-direct）
  ├─ 路径 A: camp-crystal-feedback-fetcher    水晶反馈检索 + 附件下载
  ├─ 路径 B: camp-ifeedback-feedback-fetcher  iFeedback 反馈检索 + 附件下载
  ├─ 路径 C: init-direct                      直传日志/截图链接
  ├─ camp-lego-log-fetcher                    lego 日志补拉（logs 为空时兜底）
  └─ camp-xlog-decoder                       mars xlog 解码（Android nocrypt + iOS ECC）

ifeedback/                           官方 iFeedback 查询 skill（只读依赖）
```

所有路径产出统一的 workdir 契约：

```
<workdir>/
├── feedback.json      反馈记录（归一化字段）
├── manifest.json      日志/截图/状态元数据
├── attachments/       原始附件（zip / xlog / 截图）
├── decoded_logs/      解码后的明文日志
└── report.md          LLM 生成的根因分析报告
```

## Skill 清单

| Skill | 用途 | 入口 |
|-------|------|------|
| `camp-feedback-analyzer` | 顶层编排 + 直传模式 | `init` / `init-direct` |
| `camp-crystal-feedback-fetcher` | 水晶反馈检索 + 附件下载 | `locate` / `fetch` / `show` |
| `camp-ifeedback-feedback-fetcher` | iFeedback 反馈检索 + 附件下载 | `locate` / `fetch` / `show` |
| `camp-lego-log-fetcher` | lego 日志补拉（fail-soft） | `pull` / `status` |
| `camp-xlog-decoder` | mars xlog 解码（双端共用） | `decode` / `decode-file` / `inspect` / `env` |
| `ifeedback` | 官方 iFeedback 查询 CLI（只读） | `search` / `search_by_url` / `parse_url` / ... |

各 Skill 详细用法见对应目录下的 `SKILL.md`。

## 环境变量

| 变量 | 用途 | 必需 |
|---|---|---|
| `IFEEDBACK_MCP_TOKEN` | iFeedback 路径（路径 B）| 真实模式必需 |
| `CRYSTAL_MCP_TOKEN` | 水晶路径（路径 A）| 接口回填后必需（当前 stub） |
| `LEGO_MCP_TOKEN` | lego 日志补拉 | 接口回填后必需（当前 stub） |
| `CAMP_XLOG_PRIV_KEY` | ECC 加密 xlog 解码私钥 | 可选（内置默认值供调试） |

Token 统一在太湖平台申请：https://tai.it.woa.com/user/pat

## 报告结构

LLM 输出的 `report.md` 包含 6 个章节：

1. **反馈基础信息**（id / uid / 平台 / 版本 / 时间 / 来源标注）
2. **日志与附件概览**（文件清单 / 解码状态 / 失败项标注）
3. **截图分析**（嵌入截图 + 与日志交叉验证）
4. **根因分析**（证据链：每条结论标注日志行号+时间戳+原文摘录）
5. **修复建议**（P0/P1/P2，按服务端/客户端/客服分角色）
6. **附录**（工作目录 / grep 命中摘要）

分析方法：三阶法（关键词提取 → grep 一级证据 → ±50 行扩展上下文）。

## 接口状态

| 接口 | 状态 | 说明 |
|---|---|---|
| iFeedback MCP | ✅ 已接入 | 通过 subprocess 调用官方 ifeedback skill |
| 水晶反馈 MCP | ⏳ stub | 待回填 `crystal_client.py` → `CrystalAPIClient`，可用 fixture 模式调试 |
| Lego MCP | ⏳ stub | 待回填 `lego_client.py` → `LegoMCPPuller`，按 uid 拉日志 |

## 注意事项

- **ifeedback 字段陷阱**：`ifeedback.uin` = 营地 uid（非微信 OpenID）；`ifeedback.platform` = 登录渠道 QQ/微信（非 OS）
- **COS 日志链接**：ifeedback 返回的 logUrl 用公网域名（403），skill 自动改写为 cos-internal 域名
- **xlog 解码**：Android nocrypt（无需密钥）+ iOS ECC（需 PRIV_KEY，内置默认值）
- **多截图**：ifeedback `picurllist` 用 `|` 分隔多 URL，全部下载
