# Workdir 契约与接口回填

## `locate --workdir <wd>` 写

- `<wd>/feedback.json` —— 单条命中（`--first` 或 `--max-results=1`）
- `<wd>/feedback_candidates.json` —— 多条候选

字段已**归一化**为下游约定键：`_id` / `system` / `version` / `create_time` / `device_model` / `content` / `logUrl` / `picUrl` / `xLogUid` / `uin` / `user_id`，**同时保留水晶原始字段**（`cClientVersionName` / `cSystem` / `createTime` 等）。

## `fetch --workdir <wd>` 写

读 `<wd>/feedback.json`，下载 `logUrl[]` / `picUrl[]` 附件并：

- 落盘到 `<wd>/attachments/<sub-dir>/`，xlog/zip 自动解压
- **合并写入** `<wd>/manifest.json`（保留上游字段）：

| 字段 | 含义 |
|---|---|
| `platform` | `android` / `ios`，从 feedback.json 的 `system` 推导，供下游 decoder 用 |
| `logs[]` | 待解码的 `.xlog` 路径列表 |
| `plain_logs[]` | 已是明文的 `.log` 路径列表（解压后直接可读的） |
| `screenshots[]` | 截图路径列表 |
| `download_failures[]` | 下载失败的 URL（**fail-soft，不阻塞**，由报告环节标注）|

加 `--no-download` 跳过下载，只对 `<wd>/attachments/` 下已有的文件做解压 + 分类（用于附件由 `camp-lego-log-fetcher` 拉到后的"重新分类"链路）。

## 接口回填指引

接口形态（REST 或 MCP JSON-RPC）确定后，按 `scripts/crystal_client.py` 中 `CrystalAPIClient` 类的 docstring 回填 `search_feedback` / `get_feedback_detail`，**保留 `normalize_record()` 调用**以维持下游字段契约。
