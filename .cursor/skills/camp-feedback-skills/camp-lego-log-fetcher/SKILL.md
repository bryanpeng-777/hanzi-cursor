---
name: camp-lego-log-fetcher
description: 营地日志 lego 补拉工具：当反馈无 logUrl 或附件缺失时，通过 lego MCP 按 uid + 时间窗查询/捞取日志。主 LLM 调 MCP 拿到下载链接后，本 skill 执行下载+解压+分类。fail-soft，拉不到不阻塞流水线。触发关键词：补日志、lego 拉日志、营地日志补拉、按 uid 拉日志。
---

# camp-lego-log-fetcher

lego 日志补拉 skill。分两层协作：

1. **主 LLM 调 MCP**：`lego.queryLogs` → `lego.convertAndDecrypt` → `lego.createFetchTask`
2. **本 skill 脚本**：拿到下载 URL 后执行 `download` → zip 落盘 → 解压分类 → 写 manifest

> **fail-soft**：lego 拿不到日志不阻塞流水线。

## 主 LLM 调用流程

### Step 2a: queryLogs — 查询现有日志

调 MCP `lego.queryLogs`，有 COS 链接 → Step 2b，无日志 → Step 2c。

### Step 2b: convertAndDecrypt + download

调 MCP `lego.convertAndDecrypt` 拿到可下载 URL，然后：

```bash
python3 ../camp-lego-log-fetcher/scripts/lego.py download \
    --url "<下载URL>" --workdir $WD
```

### Step 2c: createFetchTask（fire-and-forget）

调 MCP `lego.createFetchTask` 提交捞取任务，立即返回，流水线继续。

MCP 接口详细参数见 [references/command_reference.md](references/command_reference.md)。

## CLI 入口

| 子命令 | 用途 |
|---|---|
| `download` | 下载 zip → 解压分类 → 写 manifest |
| `status` | 读 manifest.lego_status |

## 行为约束

- **MCP 调用失败不阻塞**：等价于"无补充日志"，流水线继续。
- **download 失败 fail-soft**：status=failed 写入 manifest，退出码仍为 0。
- **空 zip**：status=done 但解压无日志 → 不是错误，manifest.logs 为空。

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功（含 failed，不阻塞） |
| 1 | IO/参数错误 / `--strict` 下非 done |
| 3 | 依赖文件不存在 |
