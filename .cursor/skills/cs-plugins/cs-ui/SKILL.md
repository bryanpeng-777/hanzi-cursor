# cs-ui 插件

CS UI 组件系统接入：shadcn_ui 封装组件替换 Material 原生组件，统一主题风格。

**参考文档见** `references/` 目录（step-details.md / common-issues.md / hooks-setup.md）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-backend 插件已安装（依赖项）
2. 检查 pubspec.yaml 是否已有 cs_ui 依赖
3. 根据 `cs_dir_exists` 决定引用方式（path: 或 git:）
4. 扫描代码，统计待改造数量：
   - `ElevatedButton` / `TextButton` / `OutlinedButton` 数量
   - `AppBar(` 数量
   - `Card(` 数量
   - `TabBar` / `TabBarView` 数量
   - `Image.asset(` / `Image.network(` / `CachedNetworkImage(` 数量

### 初始化图片管理系统（Step 0）

在执行任何 UI 迁移前，先为目标项目生成图片管理所需基础文件（见 references/hooks-setup.md）：
- `.cursor/hooks.json`
- `.cursor/hooks/sync-image-manifest.sh`
- `aiworkspace/sync_image_manifest.py`
- `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`（由 `sync_image_manifest.py` 维护；不在业务仓库）

已存在的文件跳过创建。

### 添加依赖

在 `pubspec.yaml` 添加 cs_ui 依赖（path: 或 git: 根据环境决定），运行 `flutter pub get`

### 替换根 Widget（MaterialApp → CsApp）

```dart
import 'package:cs_ui/cs_ui.dart';
// Before: MaterialApp(title: '...', theme: AppTheme.theme, home: const Home())
// After:  CsApp(title: '...', home: const Home())
```

在 `cs_ui/lib/src/theme/cs_app_theme.dart` 设置主题风格：
```dart
static const CsThemeStyle activeStyle = CsThemeStyle.cartoon; // 或 freshMinimal
```

### 组件替换

按以下规则逐一替换（详细示例见 references/step-details.md）：

| 原组件 | 替换为 | 备注 |
|--------|--------|------|
| `ElevatedButton` | `ShadButton` | |
| `ElevatedButton.icon` | `ShadButton(leading: icon)` | |
| `OutlinedButton` | `ShadButton.outline` | |
| `IconButton` | `ShadButton.ghost` | |
| `AppBar(` | `CsAppBar(` | 若 cs_ui 无 CsAppBar 则先创建 |
| `Card(` | `ShadCard(` | 自定义 _XxxCard 不改 |
| `Chip(` | `ShadBadge(` | 自定义 _XxxChip 不改 |
| `TabBar` + `TabBarView` | `ShadTabs<String>` | 仅限内容定高场景，全屏滚动不适用 |

### 图片迁移（Image.asset/network → CsImage）

扫描所有直接图片引用，调用 cs-image-manager 注册 configKey 后替换：
```dart
// Before: Image.asset('assets/images/banner.png')
// After:  CsImage(configKey: 'banner_image', description: '横幅')
```

### 清理 app_theme.dart

移除 Material 组件主题覆盖（cardTheme / elevatedButtonTheme 等），保留业务色常量。

### 验证

```bash
flutter analyze lib/   # 零 error
flutter pub get
```

---

## [UPDATE] 更新步骤

### 版本对比

读取 cs_commit，执行 `git -C ../cs/cs_ui log --oneline {cs_commit}..HEAD`，列出新 commit。

### 迁移步骤

- 检查 shadcn_ui 版本约束变化（`cs_ui/pubspec.yaml` 中的 shadcn_ui 版本）
- 处理 appBuilder 签名变更等 Breaking Change（见 references/common-issues.md）
- 重新运行 `flutter pub get`

### 验证

执行 VERIFY 段落全部检查点

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| A2 | cs_ui path 路径规范 | `grep "cs_ui:" pubspec.yaml` | 含 `path: ../cs/cs_ui`（若为本地引用） |
| G1 | ElevatedButton/TextButton 清零 | `grep -rn "ElevatedButton\|TextButton\|OutlinedButton" lib/` | 零残余 |
| G2 | AppBar 清零 | `grep -rn "AppBar(" lib/` | 零残余 |
| G3 | Card 清零 | `grep -rn "Card(" lib/` | 零残余 |
| G4 | 图片写死用法清零 | `grep -rn "Image\.asset\|Image\.network\|CachedNetworkImage" lib/` | 零残余 |

---

## [USAGE] 使用辅助

### 添加新页面的 AppBar

```dart
import 'package:cs_ui/cs_ui.dart';

CsAppBar(
  title: '页面标题',
  leading: ShadButton.ghost(onPressed: () => context.pop(), child: const Icon(Icons.arrow_back)),
  actions: [ShadButton.ghost(onPressed: () {}, child: const Icon(Icons.more_vert))],
)
```

### 常用 ShadButton 变体

```dart
ShadButton(onPressed: () {}, child: const Text('主要按钮'))
ShadButton.outline(onPressed: () {}, child: const Text('描边按钮'))
ShadButton.ghost(onPressed: () {}, child: const Icon(Icons.close))
ShadButton(leading: const Icon(Icons.add), onPressed: () {}, child: const Text('带图标'))
```

### 切换主题风格

在 `cs_ui/lib/src/theme/cs_app_theme.dart` 修改：
```dart
static const CsThemeStyle activeStyle = CsThemeStyle.freshMinimal; // 或 cartoon
```

### ShadTabs 用法（适合固定高度内容）

```dart
ShadTabs<String>(
  value: _selected,
  onChanged: (v) => setState(() => _selected = v),
  tabs: [
    ShadTab(value: 'A', child: const Text('标签A'), content: const WidgetA()),
    ShadTab(value: 'B', child: const Text('标签B'), content: const WidgetB()),
  ],
)
```

> **注意**：TabBarView 内容是 GridView/ListView（全屏滚动）时，保留原生 TabBar，不用 ShadTabs。

### 常见问题

- **shadcn_ui 版本冲突**：见 references/common-issues.md
- **appBuilder 签名报错**：见 references/common-issues.md
- **CardTheme → CardThemeData**：Flutter 新版本的 API 变更，见 references/common-issues.md
