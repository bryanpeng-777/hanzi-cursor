# Manifest Schema 与工作目录契约

## 工作目录契约（贯穿所有 skill）

```
<workdir>/
├── feedback.json          # camp-wuji-feedback-fetcher / camp-ifeedback-feedback-fetcher 写
├── attachments/           # fetcher / camp-lego-log-fetcher 写
├── decoded_logs/          # camp-xlog-decoder 写
├── analysis/              # 主 LLM 分析过程中间产物
│   ├── notes.md           # 分析笔记（关键词 / grep 命中 / 推理过程 / 备选假设）
│   └── grep_hits/         # 可选：较长的 grep 摘录存为独立文件
├── manifest.json          # 多 skill 流式合并写入（保留各自字段）
└── report.md              # 主 LLM 写
```

## `analysis/notes.md` 写入规范

主 LLM 在 Step 4 分析过程中**应当**（推荐但非强制）将中间推理写入 `analysis/notes.md`，便于：
- 同一反馈多次分析时复用已有推理
- 审计/追溯分析过程
- 自验证（Step 4.5）时回顾证据链

**推荐格式**：

```markdown
# 分析笔记

## 关键词提取
- 用户描述："登录后闪退"
- 提取关键词：login, auth, crash, sigsegv, signal

## grep 一级命中
| 文件 | 行号 | 时间戳 | 内容摘录 |
|------|------|--------|----------|
| smoba_20260511.log | 4523 | 20:35:42 | SIGSEGV at 0x... |
| smoba_20260511.log | 4510 | 20:35:41 | login success, entering main |

## 推理过程
1. [事实] 登录成功 → 进入主界面（L4510）
2. [事实] 0.8s 后 SIGSEGV（L4523）
3. [推断] crash 发生在主界面初始化阶段

## 备选假设
- 假设A：主界面某 View 空指针 → 支持：SIGSEGV 地址在 libUI.so
- 假设B：内存不足 OOM → 反对：无 low memory warning 日志

## 置信度：高
```

**复用规则**：若 `analysis/notes.md` 已存在且与当前反馈 id 匹配，主 LLM 可跳过已完成的 grep 步骤，直接从推理继续。

## `manifest.json` 字段总览

| 字段 | 写入方 | 含义 |
|---|---|---|
| `source` | wuji-fetcher / ifeedback-fetcher / analyzer | 反馈来源（`"wuji"` / `"ifeedback"` / `"direct"` / `"local"`），主 LLM 写报告时据此标注 |
| `feedback_id` / `platform` | crystal-fetcher / ifeedback-fetcher / lego-log-fetcher | 反馈基础属性 |
| `logs[]` | crystal-fetcher / ifeedback-fetcher | 待解码 xlog |
| `plain_logs[]` | crystal-fetcher / ifeedback-fetcher / xlog-decoder | 已解码明文 log |
| `decode_failures[]` / `decode_skipped[]` | xlog-decoder | 解码失败 / 跳过项 |
| `screenshots[]` | crystal-fetcher / ifeedback-fetcher | 截图（**ifeedback 路径下可能多张**） |
| `download_failures[]` | crystal-fetcher / ifeedback-fetcher | 下载失败的 URL |
| `lego_status` / `lego_zip_path` / `lego_task_id` | lego-log-fetcher | lego 拉日志结果 |
