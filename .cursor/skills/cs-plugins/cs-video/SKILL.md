# cs-video 插件

CS 视频资源管理：CsVideo 控件 + video_manifest.json，统一管理视频生命周期（本地 / 远程 / 占位）。

**禁止**在接入 cs-ui 的项目中直接使用 `VideoPlayerController` 写死路径。

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-ui 插件已安装
2. 检查 `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json` 是否存在
3. 扫描直接视频引用：`VideoPlayerController.asset` / `VideoPlayerController.network`

### 初始化视频管理文件

若 video_manifest.json 不存在，创建初始结构：
```json
{
  "project": "<project_name>",
  "videos": []
}
```

manifest 存储路径：`~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`

### 迁移现有视频引用

对每个直接 VideoPlayerController 调用执行：
1. 生成 configKey（格式：`snake_case_video`，以 `_video` 结尾）
2. 在 video_manifest.json 中注册视频插槽
3. 在 `default_configs.json` 中设置兜底
4. 替换代码：
   ```dart
   // Before: VideoPlayerController.asset('assets/videos/intro.mp4')
   // After:  CsVideo(configKey: 'intro_video')
   ```

---

## [UPDATE] 更新步骤

跟随 cs-ui 的 cs_commit 更新。扫描是否有新的直接 VideoPlayerController 引用。

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| V1 | VideoPlayerController 直接用法清零 | `grep -rn "VideoPlayerController\." lib/` | 零残余 |

---

## [USAGE] 使用辅助

### 添加新视频

```dart
CsVideo(
  configKey: 'intro_video',   // video_manifest.json 中的 key
  autoPlay: false,
  looping: false,
  aspectRatio: 16 / 9,
)
```

### 三种显示模式

`CsVideo` 读取 `default_configs.json`：
1. `url` 非空 → 远程视频（支持热更新）
2. `url` 为 null，`asset` 非空 → 本地 .mp4/.mov 文件
3. 两者均 null → 占位画面（`CsPlaceholderVideo`）

### 设置远程视频 URL

通过 cs-backend ConfigManager 设置：
```
key: intro_video
value: https://cdn.example.com/intro.mp4
type: string
```

### 查看所有视频插槽状态

读取 `~/.claude/knowledge/ui-assistant/{project}/video_manifest.json`，输出各插槽状态（已设置 / 占位）。

### video_manifest.json 结构

```json
{
  "project": "my_app",
  "videos": [
    {
      "configKey": "intro_video",
      "description": "引导视频",
      "status": "remote_url",
      "asset_path": null,
      "remote_url": "https://cdn.example.com/intro.mp4"
    }
  ]
}
```
