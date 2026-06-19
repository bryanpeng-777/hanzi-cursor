---
name: camp-crystal-feedback-fetcher
description: 营地水晶反馈系统客户端。按 user-id / uin / 反馈 id / 时间窗等条件检索反馈记录（locate），并下载反馈附带的 logUrl / picUrl 附件（fetch）。当用户需要从水晶拉反馈、下载反馈附件、按 uin 或反馈 id 查反馈、看反馈详情时使用。触发关键词：水晶反馈检索、水晶下载、wzzs-manage、营地反馈定位、反馈详情、按 uin 查反馈、按反馈 id 拉附件。
---

# camp-crystal-feedback-fetcher

营地水晶反馈系统的独立 skill。承担两件事：**检索反馈记录**（`locate`）和**下载反馈附件**（`fetch`）；不做日志解码（参见 `camp-xlog-decoder`），也不做补充日志拉取（参见 `camp-lego-log-fetcher`）。

> ⚠️ **当前阶段重要约束**：水晶真实接口为 stub 占位，**必须使用 fixture 模式**
> （`--fixture-record /path/to/feedback.json`）。**不要**尝试无 fixture 的真实接口
> 调用——会立即返回退出码 4。接口回填后此约束自动解除。

## 入口

```bash
python3 scripts/crystal.py <subcommand> [options]
```

| 子命令 | 用途 |
|---|---|
| `locate` | 检索反馈，命中后写入 `<workdir>/feedback.json` |
| `fetch` | 读 `<workdir>/feedback.json`，下载 `logUrl` / `picUrl` 附件 → 解压 → 按类型分类，写 `<workdir>/manifest.json` |
| `show` | 打印 `<workdir>/feedback.json` 的关键字段（调试 / 链路下游） |

## 环境变量

| 变量 | 必需 | 说明 |
|---|---|---|
| `CRYSTAL_MCP_TOKEN` | 真实接口模式必需 | 太湖个人令牌（`tai_pat_xxx`），申请：https://tai.it.woa.com/user/pat |
| `CRYSTAL_MCP_URL` | 否 | 水晶 MCP/REST Server 地址（接口形态确定后回填默认值） |
| `CRYSTAL_RTX` | 否 | 最终用户 RTX，平台/智能体场景的二次校验用 |

## 用法

各子命令（fixture / 真实接口 / `--no-download`）的详细参数和用法示例见 [references/command_reference.md](references/command_reference.md)。

> **快速上手（fixture 模式）**：
> ```bash
> python3 scripts/crystal.py locate --fixture-record /path/to/feedback.json --workdir ./out --first
> python3 scripts/crystal.py fetch --workdir ./out
> ```

## 与 workdir 的契约

`locate` 写 `feedback.json`（归一化字段）/ `feedback_candidates.json`；`fetch` 下载附件 → 解压 → 写 `manifest.json`（`logs[]` / `plain_logs[]` / `screenshots[]` / `download_failures[]`）。

详细字段列表与 `--no-download` 用法见 [references/workdir_contract.md](references/workdir_contract.md)。

## 行为约束

- **部分下载失败不阻塞流程**：`download_failures[]` 非空时，脚本继续解压已下载的文件 + 写 manifest。下游主 LLM 写报告时，应在「日志与附件概览」章节如实标注下载失败的 URL 数量。
- **`locate` 多条命中后 `fetch` 不可运行**：`locate` 不带 `--first` 且命中 >1 条时，结果写入 `feedback_candidates.json`（**不是** `feedback.json`），此时 `fetch --workdir <wd>` 会因 `feedback.json` 缺失退 3。**必须**先用 `--first` 取第一条，或人工从候选中选择一条复制到 `feedback.json`。
- **`uin` 客户端筛**：接口不支持原生 uin 过滤，需配合 `--user-id` 或时间窗（≤30 天）缩小范围后客户端筛。

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | IO / 参数错误 |
| 3 | 反馈未命中 / `feedback.json` 缺失 |
| 4 | 鉴权失败（token 缺失 / 无效）或真实接口未实现 |

## 接口回填指引

见 [references/workdir_contract.md](references/workdir_contract.md)。

## 限制

- 只做"检索反馈记录 + 下载附件"，不做日志解码（参见 `camp-xlog-decoder`）、不做补充日志拉取（参见 `camp-lego-log-fetcher`）
