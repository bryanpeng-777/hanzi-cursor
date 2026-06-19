# cs-image 插件

CS 图片资源管理：CsImage 控件 + image_manifest.json，统一管理图片生命周期（本地 asset / 远程 URL / 占位图）。

**禁止**在接入 cs-ui 的项目中直接使用 `Image.asset` / `Image.network` / `CachedNetworkImage`。

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-ui 插件已安装（依赖项，cs-image 是 cs-ui 的使用规范扩展）
2. 检查 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json` 是否存在（不存在可由 `sync_image_manifest.py` 首次运行时自动初始化）
3. 扫描直接图片引用数量：`Image.asset(` / `Image.network(` / `CachedNetworkImage(`

### 初始化图片管理文件

若 image_manifest.json 不存在，创建初始结构（pages 口径，与 cs-image-manager 兼容）：
```json
{
  "_version": "1.0.0",
  "_comment": "图片注册表。优先级：url > asset > 占位图。由 sync_image_manifest.py / cs-image 维护，不进入 Flutter bundle。",
  "_last_updated": "YYYY-MM-DD",
  "project": "<project_id>",
  "assets_dir": "assets/images",
  "summary": { "total": 0, "placeholder": 0, "local": 0, "remote": 0 },
  "pages": {}
}
```

manifest 存储路径：`~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`

`{project}` 缺省规则：取 `Workspace Path` 最后一级目录名；若以 `-cursor` 结尾则去尾缀。也可用环境变量 `UI_ASSISTANT_PROJECT` / `IMAGE_MANIFEST_PROJECT` 显式指定。

### 迁移现有图片引用

对每个直接图片引用执行：
1. 生成 configKey（根据文件名或语义，格式：`snake_case_image`，以 `_image` 结尾）
2. 在 image_manifest.json 中注册该图片插槽
3. 在 `default_configs.json` 中设置兜底（已有本地 asset 则设 `asset` 字段，无则 null）
4. 替换代码：
   ```dart
   // Before: Image.asset('assets/images/banner.png')
   // After:  CsImage(configKey: 'banner_image', description: '首页横幅')
   ```

### 配置 Cursor Hooks（自动同步 manifest）

确认 `.cursor/hooks.json` 中已有 image_manifest sync hook（由 cs-ui 插件安装时已配置）。

---

## [UPDATE] 更新步骤

cs-image 插件跟随 cs-ui 的 cs_commit 更新，执行流程同 cs-ui 更新。

扫描是否有新的直接图片引用被引入，补充到 manifest 中。

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| G4 | 图片写死用法清零 | `grep -rn "Image\.asset\|Image\.network\|CachedNetworkImage" lib/` | 零残余 |

---

## [USAGE] 使用辅助

### 添加新图片

用户说「给页面 X 新增一张图片」：
1. 生成 configKey（如 `feature_banner_image`）
2. 在 image_manifest.json 中追加插槽
3. 在 default_configs.json 中设置 null（或本地 asset 路径）
4. 提供代码片段给用户

```dart
CsImage(
  configKey: 'feature_banner_image',
  description: '功能页横幅',
  width: double.infinity,
  height: 200,
  fit: BoxFit.cover,
)
```

### 设置远程图片 URL（支持热更新）

在 Supabase app_configs 中设置（通过 cs-admin 或 ConfigManager）：
```
key: feature_banner_image
value: https://cdn.example.com/banner.webp
type: string
```

重启 App 后生效（或调用 `ConfigManager.refresh()` 动态刷新）。

### 查看所有图片插槽状态

读取 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`，输出：
- 已设置本地 asset 的插槽
- 已设置远程 URL 的插槽
- 尚未设置（显示占位图）的插槽

### CsImage 参数说明

```dart
CsImage(
  configKey: 'banner_image',  // image_manifest.json 中的 key
  description: '首页横幅',      // 无障碍文字
  width: double.infinity,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```
