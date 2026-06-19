---
name: camp-xlog-decoder
description: mars xlog 日志解码器。双端共用一个解码脚本，自动按 magic byte 识别 nocrypt / ECC / TEA 等模式；默认只解码王者营地主进程日志（子进程需 --all）。当用户需要解码 xlog、解密 mars 日志、处理王者营地 xlog 时使用。触发关键词：xlog 解码、mars 解密、解码王者营地日志、Android xlog、iOS xlog。
allowed-tools: Bash, Read
---

# camp-xlog-decoder

mars xlog 解码 skill，作为营地反馈分析流水线的一环。**Android / iOS 共用 `scripts/decode_xlog.py`**，按 magic byte 自动选择 nocrypt / ECC / TEA / 无压缩 4 种模式。

## 使用方式

### 1. workdir 模式（流水线推荐）

读 `<workdir>/manifest.json`：

- `logs[]` — 待解码的 `.xlog` 路径列表（由 `camp-wuji-feedback-fetcher` 写入）
- `platform` — `android` / `ios`（用于判定主进程文件名模式）

写：

- `<workdir>/decoded_logs/*.log` — 解码后的明文
- `manifest.plain_logs[]` / `decode_failures[]` / `decode_skipped[]`

```bash
# 默认：只解主进程日志
python3 scripts/decode.py decode --workdir <wd>

# 解所有（含子进程）
python3 scripts/decode.py decode --workdir <wd> --all

# 状态查看
python3 scripts/decode.py inspect --workdir <wd>
```

### 2. 单文件模式

```bash
python3 scripts/decode.py decode-file /path/to/x.xlog
python3 scripts/decode.py decode-file /path/to/x.xlog --output /path/to/x.log
```

### 3. 检查解码器状态

```bash
python3 scripts/decode.py env
# [decoder]  <path>/decode_xlog.py
# [priv_key] 已配置 / 未配置（ECC 加密日志无法解码）
```

## 主进程识别规则

| 平台 | 主进程文件名模式 |
|---|---|
| Android | `com.tencent.gamehelper.smoba_<digits>.xlog` |
| iOS | `smoba_<digits>.xlog` |

非主进程（如 `_phoenix` / `_widgetProvider` / `imsdk_*`）默认跳过；用 `--all` 显式开启。

## 环境变量

| 变量 | 用途 | 必需 |
|---|---|---|
| `CAMP_XLOG_PRIV_KEY` | secp256k1 ECDH 私钥（64 hex chars），用于 ECC 加密日志 | 可选；未设置走内置默认值（nocrypt 日志不受影响）|

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功（含部分失败，详见 `manifest.decode_failures`）|
| 1 | 解码失败（非 ECC 缺密钥；如文件损坏 / IO 错）|
| 2 | `decode-file` 子命令解 ECC 加密日志时缺 `PRIV_KEY` |
| 3 | workdir / xlog / manifest 不存在 |

## 流水线协作

| 上游 | 输入 | 本 skill 处理 | 下游 |
|---|---|---|---|
| `camp-wuji-feedback-fetcher` / `camp-ifeedback-feedback-fetcher` | `manifest.logs[]` + `platform` | 解码 → `decoded_logs/` + `manifest.plain_logs[]` | 主 LLM（读 `decoded_logs/` 写 `report.md`）|

## 局限

- ECC 加密日志依赖 `CAMP_XLOG_PRIV_KEY`，内置默认值仅供本地调试；正式接入需替换为生产私钥
- ECC 模式依赖 `cryptography` 包；纯 nocrypt 场景无额外依赖
- **输出编码**：解码后的明文以 bytes 直写，可能含**非 UTF-8 片段**（mars 二进制头/损坏块）。下游读取时建议用 `errors='replace'` 或 `errors='ignore'`，不要用默认 strict 模式（会 `UnicodeDecodeError`）
- **0 字节产出**：decode 产出的 `.log` 文件为空（0 字节）时，归入 `decode_failures[]`（不进 `plain_logs[]`），报告中标注"该文件解码产出为空"
- **截断 xlog**：xlog 文件不完整（传输中断/磁盘满）时，解码器会尽量部分解码已有的完整块，截断处之后的内容丢弃；产出非空则进 `plain_logs[]`，报告中标注"⚠️ 日志可能不完整（源文件被截断）"
