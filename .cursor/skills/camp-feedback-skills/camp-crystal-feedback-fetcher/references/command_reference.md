# 命令参考

## locate — 检索反馈

### fixture 模式（**当前唯一可用模式**）

```bash
python3 scripts/crystal.py locate \
  --fixture-record /path/to/feedback.json \
  --feedback-id 202605_12348 \
  --workdir ./out --first
```

`feedback.json` 支持三种形态：水晶原始响应（`{"data":{"list":[...]}}`）、`list[record]`、单条 `record`。

### 真实接口模式（接口回填后启用）

```bash
export CRYSTAL_MCP_TOKEN=tai_pat_xxx
python3 scripts/crystal.py locate --feedback-id 202605_12352 --workdir ./out --first
# 更多用法（按 user-id / uin / 时间窗 / app-version）参考：
#   python3 scripts/crystal.py locate --help
```

## fetch — 下载附件

```bash
python3 scripts/crystal.py fetch --workdir ./out
```

### --no-download 用法

当 `camp-lego-log-fetcher pull` 把新 zip 落到 `attachments/` 后，调用 `fetch --no-download` 重新解压分类 + 更新 manifest。**不要**在初次 fetch 时使用 `--no-download`（会跳过下载导致 `logs[]` 为空）。

```bash
python3 scripts/crystal.py fetch --workdir ./out --no-download
```

## show — 打印反馈关键字段

```bash
python3 scripts/crystal.py show --workdir ./out
```
