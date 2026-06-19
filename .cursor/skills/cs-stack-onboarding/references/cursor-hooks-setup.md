# Step 2-4：Cursor hooks 初始化（cs_ui 接入时自动执行）

cs_ui 的 `CsImage` / `CsLottie` / `CsVideo` 依赖 Cursor `afterFileEdit` hooks 在每次保存 `.dart` 文件时自动同步 manifest。与 git hooks 不同，**Cursor hooks 无需任何安装命令**——只要相关文件存在于项目中，Cursor 就会自动激活。

因此本步骤的目标是：**把必要文件复制/创建到产品项目中**。

## 检测条件

同时满足以下两条才执行本步骤：
1. `cs_ui` 已安装（pubspec.yaml 有 `cs_ui:` 依赖，或本次正在安装）
2. 产品项目中 `.cursor/hooks.json` 不存在，**或**存在但缺少 `sync-image-manifest` / `sync-lottie-manifest` / `sync-video-manifest` 三个 hook

## 执行动作

### 2-4-A 创建/合并 `.cursor/hooks.json`

若文件不存在，直接创建：
```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      { "command": ".cursor/hooks/sync-image-manifest.sh" },
      { "command": ".cursor/hooks/sync-lottie-manifest.sh" },
      { "command": ".cursor/hooks/sync-video-manifest.sh" }
    ]
  }
}
```
若文件已存在，只向 `afterFileEdit` 数组追加缺少的三条，**不删除已有 hook**。

### 2-4-B 创建 `.cursor/hooks/sync-*.sh`（三个 shell 脚本）

从 `cs_infra` 仓库的 `scripts/cursor-hooks/` 复制，或从以下 GitHub raw URL 下载：
```
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/cursor-hooks/sync-image-manifest.sh
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/cursor-hooks/sync-lottie-manifest.sh
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/cursor-hooks/sync-video-manifest.sh
```
创建后执行 `chmod +x .cursor/hooks/sync-*.sh`。

### 2-4-C 创建 `aiworkspace/sync_*.py`（三个 Python 脚本）

从 `cs_infra` 仓库的 `scripts/manifest/` 复制，或从以下 GitHub raw URL 下载：
```
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/manifest/sync_image_manifest.py
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/manifest/sync_lottie_manifest.py
https://raw.githubusercontent.com/bryanpeng-777/cs_infra/main/scripts/manifest/sync_video_manifest.py
```

### 2-4-D manifest 文件（Image / Lottie / Video）

三套 `sync_*_manifest.py` 已对齐为同一套台账路径规则：

- **默认写入**：`~/.claude/knowledge/ui-assistant/{project}/`
  - `image_manifest.json`
  - `lottie_manifest.json`
  - `video_manifest.json`
- **`{project}` 推断**：默认取 `Workspace Path` 最后一级目录名；若以 `-cursor` 结尾则去尾缀；也可用环境变量 `UI_ASSISTANT_PROJECT` / `IMAGE_MANIFEST_PROJECT` 覆盖。
- **首次保存含对应 Widget 的 `.dart` 文件**时，若 knowledge 台账不存在，脚本会自动创建最小骨架（无需手工在 `aiworkspace/` 再建空 manifest）。
- **兼容旧路径（可选）**：
  - 图片：`CS_IMAGE_MANIFEST_LEGACY_PATH=1` → `{workspace}/aiworkspace/image_manifest.json`
  - Lottie：`CS_LOTTIE_MANIFEST_LEGACY_PATH=1` → `{workspace}/aiworkspace/lottie_manifest.json`
  - Video：`CS_VIDEO_MANIFEST_LEGACY_PATH=1` → `{workspace}/aiworkspace/video_manifest.json`
- **绝对路径覆盖（可选）**：`IMAGE_MANIFEST_PATH` / `LOTTIE_MANIFEST_PATH` / `VIDEO_MANIFEST_PATH`（以及对应的 `CS_*_MANIFEST_PATH` 别名）

```
产品项目/
├── .cursor/
│   ├── hooks.json          ← Cursor 自动激活，无需任何命令
│   └── hooks/
│       ├── sync-image-manifest.sh
│       ├── sync-lottie-manifest.sh
│       └── sync-video-manifest.sh
└── aiworkspace/
    ├── sync_image_manifest.py
    ├── sync_lottie_manifest.py
    └── sync_video_manifest.py
```

开发者**保存任意 `.dart` 文件**后，Cursor 会自动检测 `CsImage` / `CsLottie` / `CsVideo` 的 `configKey` 用法，并把新增 key **增量追加**到 knowledge 下的对应 manifest。

> **与 git hooks 的区别**：git post-commit hooks 需要 `make install-hooks` 或 AI 自检来激活（因为 `.git/hooks/` 不被 git 跟踪）；Cursor hooks 只要文件存在就自动生效，新成员 clone 后无需任何额外操作。
