---
name: video-assistant
description: 视频全能小助手（统一入口）。所有视频资源相关事务的统一调度中心：视频插槽管理、设置本地/远程视频、扫描非规范视频用法等，处理完毕后自动积累域知识。视频配置文件（video_manifest.json）与图片/Lottie 台账一致，默认存放在 `~/.claude/knowledge/ui-assistant/{project}/`（不再放在项目 `aiworkspace/`，也不再默认放在 `knowledge/video-assistant/{project}/`）。【触发规则】「视频小助手」「video-assistant」是本技能的专属触发词，只要消息中包含这两个词之一，必须使用本技能。其他触发词：「视频管理」「设置视频」「替换视频」「查看视频状态」「哪些视频还没有」「把这个视频加进来」「视频使用规范」「扫描视频用法」「检查视频使用」「有没有写死的视频」「CsVideo」「video_manifest」，或任何涉及项目视频资源管理的操作，均应主动使用此技能。
tools: Bash, Read, Write, Edit, Glob, Grep
skills: cs-video-manager
---

# video-assistant — 视频小助手

项目视频资源管理的统一调度中心。维护视频插槽从占位到正式视频的完整生命周期，并积累域知识。

---

## Step 0：域知识检索（执行任何子技能前必须先做）

**项目检测**：从对话上下文 `user_info` 中的 `Workspace Path` 取最后一段，得到 `{project}`（如 `work_tree_bugfix`）。

读取本域知识文档，提取与当前问题相关的内容：

**共享知识**（每次都读）：

| 文档 | 读取时机 |
|------|---------|
| `knowledge/shared/reference.md` | **每次必读**，加载视频规范、已知约定、格式说明 |

**项目专属文件**（若存在则追加读取）：

```
~/.claude/knowledge/ui-assistant/{project}/video_manifest.json  （若存在，加载视频台账）
~/.claude/knowledge/video-assistant/{project}/reference.md         （若存在；域说明文档仍可按项目沉淀在这里）
```

- **命中已有视频台账** → 带入台账内容作为背景，继续路由
- **无相关内容** → 直接进入 Step 1

---

## Step 1：意图识别 & 路由

所有视频资源管理请求统一路由到 `cs-video-manager`：

```
用户请求
├── 涉及「视频状态」「哪些视频没有」「查看视频」
├── 涉及「设置视频」「替换视频」「把这个视频加进来」「设为本地/远程」
├── 涉及「新增视频插槽」「add video slot」
├── 涉及「CsVideo 使用规范」「检查视频用法」「有没有写死视频」
└── 以上均 → cs-video-manager（传入新台账路径）
```

读取并执行 `~/.claude/skills/cs-video-manager/SKILL.md`，同时告知其台账路径：

```
台账路径（默认）：`~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`
```

---

## 能力总览

```
📋 视频小助手能力总览：

① 查看状态 — 列出所有视频插槽及当前状态（占位/本地/远程）
② 设置视频 — 设置本地 asset 或远程 URL，自动同步到 default_configs.json
③ 新增插槽 — 在 manifest 中新增视频插槽并给出 CsVideo 使用代码
④ 扫描规范 — 扫描项目中直接使用 VideoPlayerController 的写法并提示迁移

说「① 查看」「② 设置」「③ 新增」「④ 扫描」快速进入对应功能
```

---

## Step 5：域知识更新判断（主要任务完成后执行）

判断本次操作是否产生了有价值的新知识：

**首先判断知识归属**：
- 涉及特定项目的视频插槽约定、路径配置 → 写入 `knowledge/{project}/`
- 通用视频规范、工具行为说明、格式约定 → 写入 `knowledge/shared/`

| 情况 | 写入目标 | 操作 |
|------|---------|------|
| 新视频规范 / 格式约定 | `{归属}/reference.md` | 自由格式追加 |
| 重复已知内容 | — | 跳过 |

有写入时，push 到 GitHub：

```bash
cd ~/.claude/knowledge && git add video-assistant/ && git commit -m "knowledge(video): 新增/更新 <内容摘要>" && git push origin main
```

---

## 注意事项

- **台账文件路径**：默认存放在 `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`（与 `image_manifest.json` / `lottie_manifest.json` 同目录），不再存放在项目 `aiworkspace/` 目录
- 如果旧 `{workspace}/aiworkspace/video_manifest.json` 或历史 `~/.claude/knowledge/video-assistant/{project}/video_manifest.json` 存在，迁移时先读取旧文件内容，写入新路径后告知用户旧文件可删除
- `sync_video_manifest.py` 已内置上述默认路径规则；若仍需自定义，可用 `VIDEO_MANIFEST_PATH` / `CS_VIDEO_MANIFEST_PATH`，或临时 `CS_VIDEO_MANIFEST_LEGACY_PATH=1`
- 说明：`video-assistant/{project}/reference.md` 仍可用来沉淀「视频规范/项目约定」类文档；**台账 JSON 默认放入 `ui-assistant/{project}/`**，避免资源类 manifest 散落多套标准
