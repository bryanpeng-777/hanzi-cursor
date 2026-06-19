# 命令参考

## init

```bash
python3 scripts/feedback_analyze.py init \
    --feedback-id 202605_12352 \
    --create-time "2026-05-11 20:35:56" \
    [--root /path/to/output] [--force] [--json]
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--feedback-id` | 是 | 反馈 id（如 `202605_12352`） |
| `--create-time` | 否 | 反馈创建时间 `YYYY-MM-DD HH:MM:SS`（用于目录命名） |
| `--root` | 否 | 工作目录根（默认 `../output`） |
| `--force` | 否 | 目录已存在则清空重建 |
| `--json` | 否 | 输出 JSON（`{"workdir":"...","feedback_id":"...","subdirs":[...]}`） |

## init-direct（路径 C：URL 直传）

用户直接给出"问题描述 + 日志链接 + 截图"，无需经过水晶或 ifeedback 检索：

```bash
WD=$(python3 scripts/feedback_analyze.py init-direct \
    --content "登录后闪退，请帮忙排查" \
    --log-url "https://cltlog-xxx.cos-internal.../uid/20001/key1" \
    --log-url "https://cltlog-xxx.cos-internal.../uid/20001/key2" \
    --pic-url "https://report-xxx.file.myqcloud.com/uid/20001/pic.jpg" \
    --user-id 1644128013 \
    --create-time "2026-05-14 10:00:00" \
    --platform android)

# 直传模式已自动完成：feedback.json + 下载 + 解压 + manifest
# 直接从 Step 3 开始：
python3 ../camp-xlog-decoder/scripts/decode.py decode --workdir $WD
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--content` | 是 | 问题描述 / 反馈正文 |
| `--log-url` | 否 | COS 日志链接，可多次指定（自动做 cos-internal 域名规范化） |
| `--pic-url` | 否 | 截图链接，可多次指定 |
| `--user-id` | 否 | 营地 uid（缺省报告标注"⚠️ user_id 未提供"） |
| `--create-time` | 否 | 反馈时间（缺省用当前时刻） |
| `--platform` | 否 | `android` / `ios`（缺省留空，decoder 按文件名推断） |
| `--feedback-id` | 否 | 缺省自动生成 `direct_<timestamp>` |
| `--timeout` | 否 | 单个 URL 下载超时秒数（默认 60） |

## init-local（路径 D：本地文件）

用户手头已有日志文件（zip/xlog/log/截图），无需网络下载：

```bash
# 指定单个或多个文件
WD=$(python3 scripts/feedback_analyze.py init-local \
    --file /path/to/logs.zip \
    --file /path/to/smoba_20260512.xlog \
    --content "登录闪退" \
    --platform android)

# 或扫描整个目录（递归识别 zip/xlog/log/截图）
WD=$(python3 scripts/feedback_analyze.py init-local \
    --dir /path/to/log_folder \
    --content "精彩时刻问题" \
    --platform android)

# 本地模式已自动完成：复制 + 解压 + 分类 + feedback.json + manifest
# 直接从 Step 3 开始：
python3 ../camp-xlog-decoder/scripts/decode.py decode --workdir $WD
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--file` | 否* | 本地文件路径（zip/xlog/log/png/jpg），可多次指定 |
| `--dir` | 否* | 本地目录路径（递归扫描），可多次指定 |
| `--content` | 否 | 问题描述（缺省为空） |
| `--user-id` | 否 | 营地 uid |
| `--platform` | 否 | `android` / `ios`（缺省留空） |
| `--feedback-id` | 否 | 缺省自动生成 `local_<timestamp>` |

\* `--file` 和 `--dir` 至少指定一个，可混合使用。

### 智能分类机制

- **扩展名优先**：`.xlog`→待解码，`.log/.txt`→明文，`.png/.jpg`→截图，`.zip`→自动解压
- **magic byte 兜底**：无扩展名或扩展名不匹配时，按文件头 magic byte 探测是否为 mars xlog（加密/未加密均自动识别）
- **明文探测**：非 xlog 的无扩展名文件若为可读 UTF-8 文本则归为明文日志
- **交叉验证**：`.log` 扩展名文件若文件头匹配 xlog magic → 归入 `logs[]` 走 decoder（防止扩展名误标）

## CI / JSON 输出

```bash
WD=$(python3 scripts/feedback_analyze.py init \
    --feedback-id 202605_12352 --create-time "..." --json | jq -r '.workdir')
```

## cache-clean — 批量清理旧 workdir

按 TTL + 容量上限 LRU 淘汰，释放磁盘空间。

```bash
# 预览（不实际删除）
python3 scripts/feedback_analyze.py cache-clean --dry-run

# 清理超过 3 天的 + 总容量超过 1GB 的
python3 scripts/feedback_analyze.py cache-clean --max-age 3 --max-size 1024

# JSON 输出
python3 scripts/feedback_analyze.py cache-clean --json
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--root` | 否 | 工作目录根（默认自动检测） |
| `--max-age` | 否 | 最大保留天数（默认 7） |
| `--max-size` | 否 | 总容量上限 MB（默认 2048） |
| `--dry-run` | 否 | 预览模式，不实际删除 |
| `--json` | 否 | JSON 输出 |

### 自动清理策略

每次调用 `init` 时自动触发检查：
- 当 output 目录总大小 > 1GB 时，自动 LRU 淘汰
- 优先删除超过 TTL（7 天）的 workdir
- 仍超阈值则按最久未访问顺序继续删除
- 缓存索引 `.cache_index.json` 自动维护

### 缓存复用机制

`init` 自动基于 feedback_id 生成缓存键（SHA256 前 16 位），检查已有 workdir：

| 缓存键来源 | 生成规则 |
|-----------|----------|
| feedback_id | `sha256("fid:{feedback_id}")[:16]` |
| ifeedback URL | `sha256("ifb:{_id参数}")[:16]` |
| uid + create_time | `sha256("uid:{uid}@{时间精确到小时}")[:16]` |

命中判定：
- **full_hit**：manifest.json 存在 + 未过期 + decoded_logs/ 非空
- **partial_hit**：manifest.json 存在 + 未过期 + feedback.json 存在，但无 decoded_logs
- **expired**：manifest.json 修改时间 > 7 天
- **miss**：缓存键不在索引中或目录已删除
