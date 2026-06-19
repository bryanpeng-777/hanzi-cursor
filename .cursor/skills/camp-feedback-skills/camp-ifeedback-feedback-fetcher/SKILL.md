---
name: camp-ifeedback-feedback-fetcher
description: 营地 iFeedback 反馈系统客户端。按 ifeedback URL / 营地 uid / ifeedback _id 检索反馈（locate）并下载附件（fetch）。当用户给出 ifeedback 链接、需要从 ifeedback 拉反馈时使用。触发关键词：iFeedback、ifeedback.qq.com、wzyd、按 uid 查 ifeedback。
---

# camp-ifeedback-feedback-fetcher

iFeedback 反馈源，与 `camp-wuji-feedback-fetcher` 平级。产出相同 workdir 契约（`feedback.json + manifest.json`），下游无感知。

通过 subprocess 调用 `../ifeedback/scripts/ifeedback_api.py`（官方 skill，只读不改）。

> **字段陷阱**：
> - ifeedback `uin` = **营地 uid**（非微信 OpenID）→ 映射到 `user_id`
> - ifeedback `platform` = 登录渠道 QQ/微信（**非 OS**）→ 下游用 `system` 字段

## 用法

```bash
# 按 ifeedback URL（最常用）
python3 scripts/ifeedback.py locate --ifeedback-url "<URL>" --workdir ./out --first
python3 scripts/ifeedback.py fetch --workdir ./out

# 按营地 uid（app_name=wzyd）
python3 scripts/ifeedback.py locate --uid 1644128013 --app-name wzyd \
    --begin-time "2026-05-13 00:00:00" --end-time "2026-05-14 23:59:59" \
    --workdir ./out --first

# 重新解压分类（不下载）
python3 scripts/ifeedback.py fetch --workdir ./out --no-download
```

## 行为约束

- **download_failures 不阻塞**：非空时继续，报告标注。
- **多条命中**：无 `--first` 写 `feedback_candidates.json`，此时 `fetch` 无法运行。
- **不调 lego**：logUrl 缺失时由 analyzer 编排 lego 兜底。
- **COS 域名自动改写**：logUrl 公网 → cos-internal（绕过 403）。
- **Token 已内置**：无需额外配置即可使用。
- **locate 返回空**：exit 3，主 LLM 应降级（如走无极路径）或提示用户核实 uid/时间窗。
- **API 超时/网络错误**：自动重试 1 次，仍失败 exit 1，stderr 输出错误详情。
- **fetch 部分下载失败**：继续执行，失败 URL 记入 manifest `download_failures[]`，不中断流水线。

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | IO / 参数错误 |
| 3 | 未命中 / feedback.json 缺失 |
| 4 | 鉴权失败 |

## 字段映射

- `ifeedback.uin` → `user_id`（营地 uid）
- `ifeedback.system` → `system`（android/ios）
- `ifeedback.logUrl` → `logUrl`（自动 cos-internal 域名改写）
- `ifeedback.picurllist` → `picUrl`（`|` 分隔多图）
- `source` = `"ifeedback"`

营地 app_name = `wzyd`。
