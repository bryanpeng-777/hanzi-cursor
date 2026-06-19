---
name: cs-video-manager
description: 【已废弃 · 计划 2026-06-30 删除】原视频资源管理技能。逻辑已迁移到 cs-plugins/cs-video 插件，请通过 cs-plugin-host 安装 cs-video 插件代替。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：逻辑已完整迁移到 `~/.claude/skills/cs-plugins/cs-video/SKILL.md`，由 `cs-video-plugin` subAgent 执行。
>
> **此文件保留供老项目参考，计划于 2026-06-30 删除。**

---

# cs-video-manager Skill

管理项目中所有视频插槽，维护「开发期占位 → 正式视频」的完整生命周期。

## 核心设计

视频配置存储在两处：
- `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`：开发期管理视图（元数据 + 状态），**由此 Skill 维护**
- `{app_dir}/assets/default_configs.json`：运行时配置，格式 `{"url": null, "asset": "assets/videos/xxx.mp4"}`

`CsVideo` Widget 读取 `default_configs.json` 决定显示什么：
1. `url` 非空 → 远程视频（优先，支持热更新，不发版生效）
2. `asset` 非空 → 本地 asset（`.mp4` / `.mov` 等格式）
3. 两者均 null → 占位视频（`CsPlaceholderVideo`，带脉冲播放图标，与图片/动画占位明显不同）

## 文件路径

```
manifest:      ~/.claude/knowledge/ui-assistant/{project}/video_manifest.json
assets_dir:    {app_dir}/assets/videos/
default_cfg:   {app_dir}/assets/default_configs.json
pubspec:       {app_dir}/pubspec.yaml
```

`{workspace}` 来自 `user_info` 中的 `Workspace Path`。  
`{project}` 为 `Workspace Path` 最后一段目录名（如 `work_tree_bugfix`）。  
`{app_dir}` 默认为 `{workspace}/cs_infra/demo`，如有其他 app 目录则由用户指定。

> **旧路径迁移**：若历史台账仍在 `{workspace}/aiworkspace/video_manifest.json`，或 `~/.claude/knowledge/video-assistant/{project}/video_manifest.json`，或 `~/.claude/skills/video-assistant/knowledge/{project}/video_manifest.json`，自动读取其内容写入新路径 `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`，提示用户旧文件可删除。

---

## Step 0：初始化检查

**每次触发时按顺序检查以下文件：**

### 0-A：检查 hook 文件（自动同步能力）

检查以下三个文件是否存在：
- `.cursor/hooks.json`（应包含 `sync-video-manifest.sh`）
- `.cursor/hooks/sync-video-manifest.sh`
- `aiworkspace/sync_video_manifest.py`

若**任一缺失**，提示用户：

```
⚠️ 视频管理 Hook 文件不完整，建议执行初始化。
   告诉我「帮我初始化视频管理 Hook」，我来逐一补全缺失文件。
```

> **注意**：`sync_video_manifest.py` 默认写入 `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`。若需临时回退旧路径，可设置 `CS_VIDEO_MANIFEST_LEGACY_PATH=1`，或使用 `VIDEO_MANIFEST_PATH` / `CS_VIDEO_MANIFEST_PATH` 指向绝对路径。

### 0-B：检查 manifest 是否存在

检查路径：`~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`

- 存在 → 直接读取
- 旧路径存在（`{workspace}/aiworkspace/video_manifest.json` 或历史 `~/.claude/knowledge/video-assistant/{project}/video_manifest.json` 或 `~/.claude/skills/video-assistant/knowledge/{project}/video_manifest.json`）→ 自动迁移到新路径，提示用户旧文件可删除，然后继续
- 均不存在 → 自动创建空 manifest：

```json
{
  "_version": "1.0.0",
  "_comment": "视频注册表。优先级：url > asset > 占位视频。由 cs-video-manager 维护，不进入 Flutter bundle。",
  "_last_updated": "YYYY-MM-DD",
  "project": "<app_id>",
  "assets_dir": "assets/videos",
  "summary": { "total": 0, "placeholder": 0, "local": 0, "remote": 0 },
  "pages": {}
}
```

---

## Step 1：查看状态（list）

**触发词**：「视频状态」「哪些视频还没有」「查看视频」「list videos」

读取 manifest，按页面分组输出状态表：

```
🎬 视频状态：N 个 / ⬜ X 占位 / 📁 Y 本地 / 🌐 Z 远程

页面：home（N 个）
  ⬜ home_intro_video      — 首页介绍视频（无配置）
  📁 home_bg_video         — 首页背景视频 → assets/videos/home_bg.mp4
  🌐 promo_video           — 活动推广视频 → https://cdn.example.com/promo.mp4

页面：video_demo（3 个）
  ⬜ demo_placeholder_video — 占位视频示例（无配置）
  ...
```

---

## Step 2：设置视频（set）

**触发词**：「设置视频」「把 X 设为 Y」「video_url 是 Z」「把这个视频加进来」

### 2-A：设置本地 asset

用户提供本地文件路径时：

1. 读取 manifest，定位目标 configKey
2. 更新 manifest 中 `asset_path`、`status: "local"`、`last_updated`
3. 将文件复制到 `{app_dir}/assets/videos/` 目录（若尚未在目标位置）
4. 更新 `{app_dir}/pubspec.yaml` 中的 `flutter.assets`（如果尚未注册）
5. 将 `{"url": null, "asset": "assets/videos/xxx.mp4"}` 写入 `default_configs.json`

### 2-B：设置远程 URL

用户提供 URL 时：

1. 读取 manifest，定位目标 configKey
2. 更新 manifest 中 `video_url`、`status: "remote"`、`last_updated`
3. 将 `{"url": "https://...", "asset": null}` 写入 `default_configs.json`

---

## Step 3：扫描用法（scan）

**触发词**：「扫描视频用法」「哪些 CsVideo」「检查视频使用」「有没有写死的视频」

### 3-A：扫描 CsVideo 用法

扫描项目 `.dart` 文件中所有 `CsVideo(configKey: '...')` 调用，与 manifest 对比：

- **已注册**：正常显示
- **未注册**：提示新增到 manifest（可自动追加）

### 3-B：扫描违规用法

搜索 `.dart` 文件中违规的视频写死用法：

```
rg "VideoPlayerController\.(asset|networkUrl)" --type dart
```

发现违规时，输出：

```
⚠️ 发现 2 处违规视频用法（应改用 CsVideo）：
  lib/screens/profile_screen.dart:42  VideoPlayerController.asset(...)
  lib/screens/home_screen.dart:87     VideoPlayerController.networkUrl(...)
```

---

## Step 4：同步到 default_configs.json

每次修改 manifest 后，自动将所有视频配置同步写入 `default_configs.json`：

```python
# 读取现有 default_configs.json
# 对每个 configKey 写入：
config[key] = {
    "url": entry["video_url"],   # None → null
    "asset": entry["asset_path"] # None → null
}
# 保存
```

---

## 使用示例

```
用户：「视频状态」
AI：读取 manifest，输出状态表

用户：「把 /Downloads/intro.mp4 设为 home_intro_video」
AI：复制文件 → 更新 manifest → 同步 default_configs.json

用户：「demo_remote_video 的 url 是 https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4」
AI：更新 manifest → 同步 default_configs.json

用户：「扫描视频用法」
AI：扫描所有 CsVideo 用法，对比 manifest，输出未注册项
```

---

## CsVideo 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `configKey` | String | 必填 | 对应 default_configs.json 中的 key |
| `width` | double? | null | 视频宽度 |
| `height` | double? | null | 视频高度 |
| `description` | String? | null | 占位图描述文字 |
| `loop` | bool | true | 是否循环播放 |
| `autoPlay` | bool | false | 是否自动播放 |
| `showControls` | bool | true | 是否显示播放控制条 |

---

## 注意事项

- **本地视频必须注册到 pubspec.yaml**：`flutter.assets` 中需包含 `assets/videos/` 目录
- **远程视频 iOS 需要 ATS 权限**：HTTP URL 需在 Info.plist 配置 NSAllowsArbitraryLoads
- **视频文件不进入 Git**：建议在 `.gitignore` 中忽略 `assets/videos/*.mp4`（大文件）
- **manifest 文件不进入 Flutter bundle**：位于 `aiworkspace/`，仅供 AI 管理使用
