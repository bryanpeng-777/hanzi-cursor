---
name: cs-lottie-manager
description: 【已废弃 · 计划 2026-06-30 删除】原 Lottie 动画管理技能。逻辑已迁移到 cs-plugins/cs-lottie 插件，请通过 cs-plugin-host 安装 cs-lottie 插件代替。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：逻辑已完整迁移到 `~/.claude/skills/cs-plugins/cs-lottie/SKILL.md`，由 `cs-lottie-plugin` subAgent 执行。
>
> **此文件保留供老项目参考，计划于 2026-06-30 删除。**

---

# cs-lottie-manager Skill

管理项目中所有 Lottie 动画插槽，维护「开发期占位 → 正式动画」的完整生命周期。

## 核心设计

动画配置存储在两处：
- `~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json`：开发期管理视图（元数据 + 状态），**由此 Skill 维护**
- `{app_dir}/assets/default_configs.json`：运行时配置，格式 `{"url": null, "asset": "assets/animations/xxx.json"}`

`CsLottie` Widget 读取 `default_configs.json` 决定显示什么：
1. `url` 非空 → 远程动画（优先，支持热更新，不发版生效）
2. `asset` 非空 → 本地 asset（`.json` 或 `.lottie` 格式）
3. 两者均 null → 占位动画（`CsPlaceholderLottie`，带脉冲图标，与图片占位明显不同）

## 文件路径

```
manifest:      ~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json
assets_dir:    {app_dir}/assets/animations/
default_cfg:   {app_dir}/assets/default_configs.json
pubspec:       {app_dir}/pubspec.yaml
```

`{workspace}` 来自 `user_info` 中的 `Workspace Path`。  
`{project}` 为 `Workspace Path` 最后一段目录名（如 `work_tree_bugfix`）。  
`{app_dir}` 默认为 `{workspace}/cs_infra/demo`，如有其他 app 目录则由用户指定。

> **旧路径迁移**：若历史台账仍在 `{workspace}/aiworkspace/lottie_manifest.json`，或更早的 `~/.claude/skills/ui-assistant/knowledge/{project}/lottie_manifest.json`，自动读取其内容写入新路径 `~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json`，提示用户旧文件可删除。

---

## Step 0：初始化检查

**每次触发时按顺序检查以下文件：**

### 0-A：检查 hook 文件（自动同步能力）

检查以下三个文件是否存在：
- `.cursor/hooks.json`（应包含 `sync-lottie-manifest.sh`）
- `.cursor/hooks/sync-lottie-manifest.sh`
- `aiworkspace/sync_lottie_manifest.py`

若**任一缺失**，提示用户：

```
⚠️ Lottie 管理 Hook 文件不完整，建议执行初始化。
   告诉我「帮我初始化 lottie 管理 Hook」，我来逐一补全缺失文件。
```

> **注意**：`sync_lottie_manifest.py` 默认写入 `~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json`。若需临时回退旧路径，可设置 `CS_LOTTIE_MANIFEST_LEGACY_PATH=1`，或使用 `LOTTIE_MANIFEST_PATH` / `CS_LOTTIE_MANIFEST_PATH` 指向绝对路径。

### 0-B：检查 manifest 是否存在

检查路径：`~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json`

- 存在 → 直接读取
- 旧路径存在（`{workspace}/aiworkspace/lottie_manifest.json` 或历史 `~/.claude/skills/ui-assistant/knowledge/{project}/lottie_manifest.json`）→ 自动迁移到新路径，提示用户旧文件可删除，然后继续
- 均不存在 → 自动创建空 manifest：

```json
{
  "_version": "1.0.0",
  "_comment": "Lottie 动画注册表。优先级：url > asset > 占位动画。由 cs-lottie-manager 维护，不进入 Flutter bundle。",
  "_last_updated": "YYYY-MM-DD",
  "project": "<app_id>",
  "assets_dir": "assets/animations",
  "summary": { "total": 0, "placeholder": 0, "local": 0, "remote": 0 },
  "pages": {}
}
```

---

## Step 1：查看状态（list）

**触发词**：「动画状态」「哪些动画还没有」「查看动画」「list animations」

读取 manifest，按页面分组输出状态表：

```
🎬 动画状态：N 个 / ⬜ X 占位 / 📁 Y 本地 / 🌐 Z 远程

🏠 首页 (home)
  ⬜ home_loading_animation    首页加载动画    → 待提供
  📁 home_success_animation    成功反馈动画    → assets/animations/home_success.json
  🌐 home_empty_animation      空状态动画      → https://...

🧪 动画示例页 (lottie_demo)
  ⬜ demo_placeholder_lottie   占位动画示例    → 待提供
  📁 demo_local_lottie         本地动画示例    → assets/animations/demo_local.json
  🌐 demo_remote_lottie        远程动画示例    → https://assets5.lottiefiles.com/...
```

状态图标：⬜ 占位 / 📁 本地 / 🌐 远程

---

## Step 2：设置本地动画（set local）

**触发词**：「把 X 设为 Y」「设置本地动画」「用本地 lottie」「这个 json 对应 XXX」

### 单个设置

```
用户：把 /Downloads/loading.json 设为 home_loading_animation
```

执行步骤：

1. **复制文件**：将源文件复制到 `{app_dir}/assets/animations/`，文件名用 `{configKey}.json`
   - 示例：`/Downloads/loading.json` → `assets/animations/home_loading_animation.json`

2. **更新 pubspec.yaml**：检查 `flutter.assets` 是否已声明 `assets/animations/`，未声明则追加：
   ```yaml
   flutter:
     assets:
       - assets/animations/
   ```

3. **更新 default_configs.json**：写入或更新该 key：
   ```json
   "home_loading_animation": {
     "url": null,
     "asset": "assets/animations/home_loading_animation.json"
   }
   ```
   ⚠️ 保留已有的 `url` 字段，不覆盖。

4. **更新 manifest**：
   - `asset_path`: `"assets/animations/home_loading_animation.json"`
   - `status`: `"local"`
   - `last_updated`: 今日日期

5. **更新 manifest summary** 计数

6. **汇报**：
   ```
   ✅ home_loading_animation 已设置为本地动画
      → assets/animations/home_loading_animation.json
   重新编译 App 即可看到正式动画。
   ```

---

## Step 3：设置远程 URL（set remote）

**触发词**：「设置远程动画」「用这个 URL」「url 是 xxx」「用 lottiefiles 的这个链接」

```
用户：home_loading_animation 的 url 是 https://assets5.lottiefiles.com/xxx.json
```

执行步骤：

1. **更新 default_configs.json**：
   ```json
   "home_loading_animation": {
     "url": "https://assets5.lottiefiles.com/xxx.json",
     "asset": "assets/animations/home_loading_animation.json"   ← 保留已有 asset
   }
   ```

2. **更新 manifest**：
   - `animation_url`: `"https://assets5.lottiefiles.com/xxx.json"`
   - `status`: `"remote"`
   - `last_updated`: 今日日期

3. **汇报**：
   ```
   ✅ home_loading_animation 已设置远程 URL
      → https://assets5.lottiefiles.com/xxx.json
   App 下次启动或热更新后自动使用此动画。
   ```

> **推荐来源**：[LottieFiles.com](https://lottiefiles.com) 提供大量免费动画，复制 Lottie JSON URL 即可使用。

---

## Step 4：新增动画插槽

**触发词**：「新增一个动画」「这个页面需要一个 XXX 动画」「add animation slot」

```
用户：在 profile 页面新增一个成功反馈动画，key 是 profile_success_animation
```

1. 检查 manifest 中 `pages.profile` 是否存在，不存在则创建
2. 在 `pages.profile.animations` 中追加新插槽
3. 在 `default_configs.json` 中追加 `{"url": null, "asset": null}`
4. 更新 summary
5. 汇报新增成功，并给出完整的 Widget 使用代码：

```
✅ profile_success_animation 插槽已创建

在 Dart 代码中这样使用：

import 'package:cs_ui/cs_ui.dart';

CsLottie(
  configKey: 'profile_success_animation',
  description: '成功反馈动画',   // 无动画时占位显示的描述
  width: 200,
  height: 200,
  repeat: false,                  // 成功动画通常只播一次
)

动画源通过 cs-lottie-manager 设置，代码无需改动。
```

---

## Step 5：CsLottie 使用规范

### 接入 cs_ui 的项目，所有 Lottie 动画必须通过 CsLottie 使用

**禁止直接使用**以下方式（即使文件路径已知）：

| ❌ 禁止写法 | ✅ 替换为 |
|---|---|
| `Lottie.asset('assets/animations/xxx.json')` | `CsLottie(configKey: 'xxx')` |
| `Lottie.network('https://...')` | `CsLottie(configKey: 'xxx')` |

**理由**：`CsLottie` 统一管理动画生命周期（远程热更新 > 本地 asset > 占位动画），禁止绕过它直接写死路径或 URL。

### CsLottie 参数说明

```dart
CsLottie(
  configKey: 'home_loading_animation',  // 必填，对应 default_configs.json 的 key
  description: '首页加载动画',            // 建议填写，占位时显示
  width: 200,                            // 可选
  height: 200,                           // 可选
  fit: BoxFit.contain,                   // 可选，默认 BoxFit.contain
  repeat: true,                          // 可选，默认 true（循环播放）
  animate: true,                         // 可选，默认 true（自动播放）
  reverse: false,                        // 可选，默认 false（正序播放）
)
```

### 引入方式

```dart
import 'package:cs_ui/cs_ui.dart';
```

---

## Step 6：扫描存量代码（scan）

**触发词**：「扫描一下动画用法」「有没有直接写死路径的动画」「scan lottie」「检查动画使用」

扫描项目中所有 `.dart` 文件，找出未使用 `CsLottie` 的动画引用：

1. 搜索以下模式：
   - `Lottie.asset(`
   - `Lottie.network(`

2. 过滤掉 `cs_lottie.dart` 本身（合法使用）

3. 输出报告：

```
🔍 存量动画用法扫描结果：

⚠️ 发现 2 处未使用 CsLottie 的动画引用：

  lib/pages/home/home_page.dart:55
    Lottie.asset('assets/animations/loading.json')
    → 建议：先用 cs-lottie-manager 注册 key（如 home_loading_animation），再替换为 CsLottie(configKey: 'home_loading_animation')

  lib/pages/onboarding/onboarding_page.dart:33
    Lottie.network('https://...')
    → 建议：注册 remote key 后替换为 CsLottie(configKey: '...')

✅ 修复所有问题后，动画管理将完全由 cs-lottie-manager 统一托管。
```

---

## 注意事项

- **始终保留 url 字段**：更新 asset 时不删除 url；更新 url 时不删除 asset
- **default_configs.json 是单一真相源**：所有改动都必须同步到这里，App 运行时依赖它
- **pubspec.yaml 声明检查**：每次新增本地 asset 都检查一次 `assets/animations/` 是否已声明
- **manifest summary 保持同步**：每次操作后更新 placeholder/local/remote 计数
- **不改 Widget 代码**：动画替换全程不需要修改 dart 文件里的动画源，只改 manifest / default_configs.json
- **接入 cs_ui 必用 CsLottie**：新写代码一律用 `CsLottie(configKey: ...)`，禁止写死路径或 URL
- **Lottie 文件格式**：支持 `.json`（标准）和 `.lottie`（dotLottie 压缩格式）
