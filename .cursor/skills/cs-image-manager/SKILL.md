---
name: cs-image-manager
description: 【已废弃 · 计划 2026-06-30 删除】原图片资源管理技能。逻辑已迁移到 cs-plugins/cs-image 插件，请通过 cs-plugin-host 安装 cs-image 插件代替。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：逻辑已完整迁移到 `~/.claude/skills/cs-plugins/cs-image/SKILL.md`，由 `cs-image-plugin` subAgent 执行。
>
> **此文件保留供老项目参考，计划于 2026-06-30 删除。**

---

# cs-image-manager Skill

管理项目中所有图片插槽，维护「开发期占位 → 正式图」的完整生命周期。

## 核心设计

图片配置存储在两处：
- `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`：开发期管理视图（元数据 + 状态），**由此 Skill 维护**
- `{app_dir}/assets/default_configs.json`：运行时配置，格式 `{"url": null, "asset": "assets/images/xxx.png"}`

`CsImage` Widget 读取 `default_configs.json` 决定显示什么：
1. `url` 非空 → 远程图（优先，支持热更新）
2. `asset` 非空 → 本地 asset
3. 两者均 null → 占位图

## 文件路径

```
manifest:      ~/.claude/knowledge/ui-assistant/{project}/image_manifest.json
assets_dir:    {app_dir}/assets/images/
default_cfg:   {app_dir}/assets/default_configs.json
pubspec:       {app_dir}/pubspec.yaml
```

`{workspace}` 来自 `user_info` 中的 `Workspace Path`。  
`{project}` 默认取 `{workspace}` 最后一级目录名；若以 `-cursor` 结尾则去尾缀；也可用 `UI_ASSISTANT_PROJECT` / `IMAGE_MANIFEST_PROJECT` 显式指定（当你希望 knowledge 目录名与本地文件夹名不一致时）。  
`{app_dir}` 默认为 `{workspace}/cs_infra/demo`，如有其他 app 目录则由用户指定。

> **旧路径迁移**：若 `{workspace}/aiworkspace/image_manifest.json` 仍存在，自动读取其内容写入新路径，提示用户旧文件可删除。

---

## Step 0：初始化检查

**每次触发时按顺序检查以下文件：**

### 0-A：检查 hook 文件（自动同步能力）

检查以下三个文件是否存在：
- `.cursor/hooks.json`
- `.cursor/hooks/sync-image-manifest.sh`
- `aiworkspace/sync_image_manifest.py`

> **注意**：工程内的 `aiworkspace/sync_image_manifest.py` 已默认把 manifest 写入 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`（可用 `IMAGE_MANIFEST_PATH` 覆盖；仅在不推荐的情况下可用 `CS_IMAGE_MANIFEST_LEGACY_PATH=1` 回退旧路径）。

若**任一缺失**，提示用户：

```
⚠️ 图片管理 Hook 文件不完整，建议执行 cs-ui-onboarding Step 0 完成初始化。
   也可直接告诉我「帮我初始化图片管理 Hook」，我来逐一补全缺失文件。
```

若用户确认补全，按 `cs-ui-onboarding Step 0` 的内容创建缺失的文件。

### 0-B：检查 manifest 是否存在

检查路径：`~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`

- 存在 → 直接读取
- 旧路径存在（`{workspace}/aiworkspace/image_manifest.json`）→ 自动迁移到新路径，提示用户旧文件可删除，然后继续
- 均不存在 → 自动创建，从 `default_configs.json` 中所有 image 类型 key 导入为初始插槽（status: placeholder）

创建模板（`YYYY-MM-DD` 替换为今日，`<app_id>` 替换为 pubspec name）：
```json
{
  "_version": "1.0.0",
  "_comment": "图片注册表。优先级：url > asset > 占位图。由 cs-image-manager 维护，不进入 Flutter bundle。",
  "_last_updated": "YYYY-MM-DD",
  "project": "<app_id>",
  "assets_dir": "assets/images",
  "summary": { "total": 0, "placeholder": 0, "local": 0, "remote": 0 },
  "pages": {}
}
```

---

## Step 1：查看状态（list）

**触发词**：「图片状态」「哪些图还没有」「查看图片」「list images」

读取 manifest，按页面分组输出状态表：

```
📊 图片状态：N 张 / ⬜ X 占位 / 🖼 Y 本地 / 🌐 Z 远程

🏠 首页 (home)
  ⬜ home_banner_image    首页顶部横幅    (800×400, 2:1)  → 待提供
  🖼 home_card_1          首页卡片 1      (400×300, 4:3)  → assets/images/home_card_1.png
  🌐 home_card_2          首页卡片 2      (400×300, 4:3)  → https://...

🧪 图片管理示例页 (image_demo)
  ⬜ demo_placeholder_image  占位图示例   (800×400, 2:1)  → 待提供
  🖼 demo_local_image        本地图示例   (800×400, 2:1)  → assets/images/demo_local.png
  🌐 demo_remote_image       远程图示例   (800×400, 2:1)  → https://picsum.photos/800/400
```

状态图标：⬜ 占位 / 🖼 本地 / 🌐 远程

---

## Step 2：设置本地图（set local）

**触发词**：「把 X 设为 Y」「设置本地图」「用本地图」「这张图对应 XXX」

### 单张设置

```
用户：把 /Downloads/banner.png 设为 home_banner_image
```

执行步骤：

1. **复制文件**：将源文件复制到 `{app_dir}/assets/images/`，文件名用 `{configKey}.{ext}`
   - 示例：`/Downloads/banner.png` → `assets/images/home_banner_image.png`

2. **更新 pubspec.yaml**：检查 `flutter.assets` 是否已声明 `assets/images/`，未声明则追加：
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```

3. **更新 default_configs.json**：写入或更新该 key：
   ```json
   "home_banner_image": {
     "url": null,
     "asset": "assets/images/home_banner_image.png"
   }
   ```
   ⚠️ 保留已有的 `url` 字段，不覆盖。

4. **更新 manifest**：
   - `asset_path`: `"assets/images/home_banner_image.png"`
   - `status`: `"local"`
   - `last_updated`: 今日日期

5. **更新 manifest summary** 计数

6. **汇报**：
   ```
   ✅ home_banner_image 已设置为本地图
      → assets/images/home_banner_image.png
   重新编译 App 即可看到正式图片。
   ```

### 批量设置

```
用户：批量设置：banner.png→home_banner_image, card1.jpg→home_card_1, card2.jpg→home_card_2
用户：把 /Downloads/designs/home/ 里的图批量加进来，banner.png→home_banner_image
```

对每一对执行上述单张流程，最后输出汇总：
```
✅ 已完成 3 张：
  🖼 home_banner_image → assets/images/home_banner_image.png
  🖼 home_card_1       → assets/images/home_card_1.jpg
  🖼 home_card_2       → assets/images/home_card_2.jpg
```

### 智能匹配模式

```
用户：/Downloads/designs/home/ 里有这些图，帮我匹配
```

1. 列出目录下所有图片文件
2. 与 manifest 中当前页面的 `description` 和 key 名做相似度匹配
3. 展示匹配建议，等待用户确认：
   ```
   📋 匹配建议（确认后执行）：
     banner.png     → home_banner_image（首页顶部横幅）✓
     card_1.jpg     → home_card_1（首页卡片 1）✓
     unknown.png    → ？（未匹配，请手动指定）
   确认执行？
   ```
4. 用户确认后批量执行

---

## Step 3：设置远程 URL（set remote）

**触发词**：「设置远程图」「用这个 URL」「url 是 xxx」

```
用户：home_banner_image 的 url 是 https://xxx.com/banner.jpg
```

执行步骤：

1. **更新 default_configs.json**：
   ```json
   "home_banner_image": {
     "url": "https://xxx.com/banner.jpg",
     "asset": "assets/images/home_banner_image.png"   ← 保留已有 asset
   }
   ```

2. **更新 manifest**：
   - `image_url`: `"https://xxx.com/banner.jpg"`
   - `status`: `"remote"`（如同时有 asset，也标 remote，因为 url 优先）
   - `last_updated`: 今日日期

3. **汇报**：
   ```
   ✅ home_banner_image 已设置远程 URL
      → https://xxx.com/banner.jpg
   App 下次启动或热更新后自动使用此图。
   ```

> **注意**：默认不上传文件到 Supabase Storage。如需上传，用户明确说「上传到 Supabase」时，再调用 MCP `upload_image` 工具并将返回的 CDN URL 写入。

---

## Step 4：新增图片插槽

**触发词**：「新增一个图片」「这个页面需要一张 XXX 图」「add image slot」

```
用户：在 profile 页面新增一个头部背景图，2:1 比例，key 是 profile_header_bg
```

1. 检查 manifest 中 `pages.profile` 是否存在，不存在则创建
2. 在 `pages.profile.images` 中追加新插槽
3. 在 `default_configs.json` 中追加 `{"url": null, "asset": null}`
4. 更新 summary
5. 汇报新增成功，并给出完整的 Widget 使用代码：

```
✅ profile_header_bg 插槽已创建

在 Dart 代码中这样使用：

import 'package:cs_ui/cs_ui.dart';

CsImage(
  configKey: 'profile_header_bg',
  description: '头部背景图',   // 无图时占位显示的描述
  width: double.infinity,
  height: 200,
  fit: BoxFit.cover,           // 可选，默认已是 cover
)

图片源通过 cs-image-manager 设置，代码无需改动。
```

---

## Step 5：CsImage 使用规范

### 接入 cs_ui 的项目，所有图片必须通过 CsImage 使用

**禁止直接使用**以下方式（即使图片路径已知）：

| ❌ 禁止写法 | ✅ 替换为 |
|---|---|
| `Image.asset('assets/images/xxx.png')` | `CsImage(configKey: 'xxx')` |
| `Image.network('https://...')` | `CsImage(configKey: 'xxx')` |
| `CachedNetworkImage(imageUrl: '...')` | `CsImage(configKey: 'xxx')` |

**理由**：`CsImage` 统一管理图片生命周期（远程热更新 > 本地 asset > 占位图），禁止绕过它直接写死路径或 URL。

### CsImage 参数说明

```dart
CsImage(
  configKey: 'home_banner_image',   // 必填，对应 default_configs.json 的 key
  description: '首页横幅',           // 建议填写，占位时显示，帮助开发者识别插槽
  width: double.infinity,            // 可选
  height: 200,                       // 可选
  fit: BoxFit.cover,                 // 可选，默认 BoxFit.cover
)
```

### 引入方式

```dart
import 'package:cs_ui/cs_ui.dart';
```

---

## Step 6：扫描存量代码（scan）

**触发词**：「扫描一下图片用法」「有没有直接写死路径的图片」「scan images」「检查图片使用」

扫描项目中所有 `.dart` 文件，找出未使用 `CsImage` 的图片引用：

1. 搜索以下模式：
   - `Image.asset(`
   - `Image.network(`
   - `CachedNetworkImage(`
   - `AssetImage(`
   - `NetworkImage(`

2. 过滤掉 `cs_image.dart` 本身（合法使用）

3. 输出报告：

```
🔍 存量图片用法扫描结果：

⚠️ 发现 3 处未使用 CsImage 的图片引用：

  lib/pages/home/home_page.dart:42
    Image.asset('assets/images/banner.png')
    → 建议：先用 cs-image-manager 注册 key（如 home_banner_image），再替换为 CsImage(configKey: 'home_banner_image')

  lib/pages/profile/profile_page.dart:88
    CachedNetworkImage(imageUrl: 'https://...')
    → 建议：注册 remote key 后替换为 CsImage(configKey: '...')

  lib/widgets/card.dart:15
    AssetImage('assets/icons/icon_star.png')
    → 如果是图标建议用 Icon，如果是业务图片请通过 CsImage 管理

✅ 修复所有问题后，图片管理将完全由 cs-image-manager 统一托管。
```

4. 每条提示对应的修复步骤：
   - 先执行 Step 4「新增图片插槽」注册 configKey
   - 再将代码中的直接引用替换为 `CsImage(configKey: '...')`
   - 如有本地 asset，再执行 Step 2「设置本地图」关联文件

---

## 注意事项

- **始终保留 url 字段**：更新 asset 时不删除 url；更新 url 时不删除 asset
- **default_configs.json 是单一真相源**：所有改动都必须同步到这里，App 运行时依赖它
- **pubspec.yaml 声明检查**：每次新增本地 asset 都检查一次，避免遗漏
- **manifest summary 保持同步**：每次操作后更新 placeholder/local/remote 计数
- **不改 Widget 代码**：图片替换全程不需要修改 dart 文件里的图片源，只改 manifest / default_configs.json
- **接入 cs_ui 必用 CsImage**：新写代码一律用 `CsImage(configKey: ...)`，禁止写死路径或 URL
