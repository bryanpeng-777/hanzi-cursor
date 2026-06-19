> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：逻辑已完整迁移到 `~/.claude/skills/cs-plugins/cs-ui/SKILL.md`
>
> **新接入方式**：说「接入 cs 框架」→ 选择 cs-ui 插件 → cs-ui-plugin subAgent 执行
>
> **此文件保留供老项目参考，计划于 2026-06-30 删除。**

---

# cs-ui-onboarding

## 技能描述

将现有 Flutter App 的 UI 层全量迁移到 `cs_ui` 视觉主题系统，完成以下替换：
- `MaterialApp` → `CsApp`
- `ElevatedButton` / `OutlinedButton` / `IconButton` → `ShadButton`
- `AppBar` → `CsAppBar`
- `TabBar` + `TabBarView` + `TabController` → `ShadTabs`
- Material `Card` → `ShadCard`（如有原生 Card 使用）
- `Chip` → `ShadBadge`（如有原生 Chip 使用）
- 清理 `app_theme.dart` 中 Material 组件主题覆盖

**触发词**：「接入 cs_ui」「cs_ui 接入」「UI 主题迁移」「替换 UI 组件到 cs_ui」「cs-ui-onboarding」

---

## 执行流程

### Step 0 — 初始化图片管理系统

在执行任何 UI 迁移之前，先为目标项目生成图片管理所需的全部基础文件。

**检查是否已存在**（任一存在则跳过对应文件）：
- `.cursor/hooks.json`
- `.cursor/hooks/sync-image-manifest.sh`
- `aiworkspace/sync_image_manifest.py`

> 说明：图片台账 `image_manifest.json` **不再默认放在** `aiworkspace/`（避免进业务仓库）。`sync_image_manifest.py` 会写入 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`（缺失会自动初始化）。

**逐一创建**，所有文件内容和汇报格式见 [references/hooks-setup.md](references/hooks-setup.md)。

---

### Step 1 — 添加依赖

在目标 App 的 `pubspec.yaml` 中添加 `cs_ui`：
```yaml
dependencies:
  cs_ui:
    git:
      url: https://github.com/bryanpeng-777/cs_ui.git
      ref: main
```

新建 `pubspec_overrides.yaml`（本地开发用，已加入 `.gitignore`）：
```yaml
dependency_overrides:
  cs_ui:
    path: ../cs_ui
```

运行 `flutter pub get`，验证依赖解析成功。

> **注意**：`shadcn_ui >=0.26.5` 要求 `intl 0.20.2`，确认 `cs_ui/pubspec.yaml` 中的约束为 `shadcn_ui: '>=0.26.5 <1.0.0'`。

---

### Step 2 — 替换根 Widget

**目标**：`lib/main.dart` 中的 `MaterialApp` 替换为 `CsApp`。

```dart
// 添加导入
import 'package:cs_ui/cs_ui.dart';

// 替换
// Before:
MaterialApp(title: '...', theme: AppTheme.theme, home: const Home())
// After:
CsApp(title: '...', home: const Home())
```

同时在 `cs_ui/lib/src/theme/cs_app_theme.dart` 中设置目标风格：
```dart
// 可选：cartoon / freshMinimal / nature
static const CsThemeStyle activeStyle = CsThemeStyle.cartoon;
```

---

### Step 3 — 全量替换按钮

**查找所有按钮使用**：
```
flutter analyze lib/ 或 grep -r "ElevatedButton\|OutlinedButton\|IconButton" lib/
```

**替换规则**：

| 原 Widget | 替换为 | 说明 |
|-----------|--------|------|
| `ElevatedButton(onPressed, child)` | `ShadButton(onPressed, child)` | 主要按钮 |
| `ElevatedButton.icon(icon, label)` | `ShadButton(leading: icon, child: label)` | 带图标主要按钮 |
| `ElevatedButton.styleFrom(backgroundColor: X)` | `ShadButton(backgroundColor: X, ...)` | 自定义色主要按钮 |
| `OutlinedButton.icon(icon, label)` | `ShadButton.outline(leading: icon, child: label)` | 描边按钮 |
| `IconButton(icon, onPressed)` | `ShadButton.ghost(onPressed, child: icon)` | 图标按钮 |

在每个文件顶部添加导入：
```dart
import 'package:cs_ui/cs_ui.dart';
```

---

### Step 4 — 核查 Card 使用

扫描代码中的 `Card` 使用情况：
```
grep -r "Card(" lib/
```

区分两种情况：
1. **自定义 `_XxxCard` 私有类**（内部用 `Container + BoxDecoration`）：无需修改，已是最佳实践
2. **原生 Material `Card(child: ...)` 实例**：替换为 `ShadCard(child: ...)`

ShadCard 参数对应：
```dart
// Before:
Card(color: X, elevation: 4, shape: RoundedRectangleBorder(...), child: Y)
// After:
ShadCard(backgroundColor: X, child: Y)  // elevation/shape 由主题控制
```

---

### Step 5 — 新建 CsAppBar 并替换 AppBar

若 `cs_ui` 尚未包含 `CsAppBar`，需先创建并导出该 Widget。完整代码见 [references/step-details.md](references/step-details.md#step-5csappbar-widget-完整代码)。

**替换各页面 AppBar**：
```dart
// Before:
AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text('...'))
// After:
CsAppBar(title: '...')
```

带 `leading`/`actions` 的 AppBar：
```dart
CsAppBar(
  title: '...',
  leading: ShadButton.ghost(onPressed: () => Navigator.pop(context), child: Icon(...)),
  actions: [...],
)
```

---

### Step 6 — 核查 Chip 使用

扫描：
```
grep -r "Chip(" lib/
```

区分两种情况：
1. **自定义 `_XxxChip` 私有类**（内部用 `Container + BoxDecoration`）：无需修改
2. **原生 Material `Chip(label: ...)` 实例**：替换为 `ShadBadge(child: ...)`

---

### Step 7 — 替换 TabBar → ShadTabs（仅限内容定高场景）

扫描 TabBar 使用：
```
grep -r "TabBar\|TabBarView\|TabController" lib/
```

**ShadTabs 的核心差异**：Material TabBar 把标签和内容分离（TabBar 在 AppBar.bottom，TabBarView 在 body）；ShadTabs 是自包含 widget，每个 `ShadTab` 同时持有标签（`child`）和内容（`content`），整体放在 body。

**改动清单**：

1. 移除 `with SingleTickerProviderStateMixin`（不再需要 vsync）
2. 移除 `TabController` 字段及 init/dispose，改用 `String _selectedTab = '第一个 tab 的 value'`
3. `CsAppBar.bottom` 中的 `TabBar` 整块删除，调整 bottom 高度
4. body 中 `TabBarView` 替换为 `ShadTabs<String>`

```dart
// Before：TabBar 挂在 AppBar.bottom，TabBarView 在 body
class _MyState extends State<MyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) => Scaffold(
    appBar: CsAppBar(
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(controller: _tabController, tabs: [
          Tab(text: 'A'), Tab(text: 'B'), Tab(text: 'C'),
        ]),
      ),
    ),
    body: TabBarView(controller: _tabController, children: [
      WidgetA(), WidgetB(), WidgetC(),
    ]),
  );
}

// After：ShadTabs 自包含，直接放在 body
class _MyState extends State<MyScreen> {
  String _selected = 'A';

  Widget build(BuildContext context) => Scaffold(
    appBar: CsAppBar(title: '...'),   // bottom 不再需要
    body: ShadTabs<String>(
      value: _selected,
      onChanged: (v) => setState(() => _selected = v),
      tabs: [
        ShadTab(value: 'A', child: const Text('A'), content: const WidgetA()),
        ShadTab(value: 'B', child: const Text('B'), content: const WidgetB()),
        ShadTab(value: 'C', child: const Text('C'), content: const WidgetC()),
      ],
    ),
  );
}
```

> **注意**：若 AppBar.bottom 中除 TabBar 外还有其他 Widget（如 SegmentedButton），保留其他 Widget，只删除 TabBar 部分，同时缩减 `preferredSize` 高度。

---

### Step 8 — 图片迁移：统一使用 CsImage

**扫描所有直接图片引用**：

```bash
grep -rn "Image\.asset\|Image\.network\|CachedNetworkImage\|AssetImage\|NetworkImage" lib/
```

过滤掉 `cs_image.dart` 自身，对其余所有命中处执行以下迁移：

**迁移规则**：

| 原写法 | 迁移步骤 |
|--------|---------|
| `Image.asset('assets/images/xxx.png')` | ① 用 `cs-image-manager` 技能注册 configKey ② 替换为 `CsImage(configKey: 'xxx')` |
| `Image.network('https://...')` | ① 注册 configKey ② 设置远程 URL ③ 替换为 `CsImage(configKey: 'xxx')` |
| `CachedNetworkImage(imageUrl: '...')` | 同上 |

**CsImage 完整用法**：

```dart
import 'package:cs_ui/cs_ui.dart';

CsImage(
  configKey: 'home_banner_image',   // 必填，对应配置系统的 key
  description: '首页横幅',           // 建议填写，占位时显示
  width: double.infinity,
  height: 200,
  fit: BoxFit.cover,                 // 可选，默认已是 cover
)
```

> **注意**：新增的每个 configKey 都要通过 `cs-image-manager` 技能在 `default_configs.json` 中注册，否则 `CsImage` 会显示占位图。执行 AI Skill `cs-image-manager` → Step 4「新增图片插槽」完成注册。

---

### Step 10 — 清理 app_theme.dart

移除 Material 组件主题覆盖（由 `CsApp` + shadcn 主题接管），**保留业务色常量**：

```dart
// 删除以下内容：
cardTheme: const CardThemeData(...),
elevatedButtonTheme: ElevatedButtonThemeData(...),

// 保留以下内容：
static const Color primaryOrange = Color(0xFFFF6B35);
static const List<Color> levelColors = [...];
// ... 其他业务色常量
```

---

### Step 11 — 验证

```bash
flutter analyze lib/        # 零 error
flutter pub get             # 依赖解析成功
```

---

## 常见问题

详见 [references/common-issues.md](references/common-issues.md)，涵盖：shadcn_ui 版本冲突、appBuilder 签名变更、CardTheme → CardThemeData、ShadTabs 不适合全屏滚动内容（实测踩坑）。

---

## Related Skills

- **[cs-stack-onboarding](../cs-stack-onboarding/SKILL.md)**: 需要完整接入技术栈（不只是 UI 层）时使用，包含 Riverpod 状态管理、go_router 路由、freezed 数据模型等
- **[cs-image-manager](../cs-image-manager/SKILL.md)**: UI 接入完成后，管理项目图片资源（注册 configKey、设置本地/远程图片）
- **[cs-lottie-manager](../cs-lottie-manager/SKILL.md)**: UI 接入完成后，管理项目 Lottie 动效资源

---

### Step 12 — Emoji → CsImage 替换

emoji 字面量属于「视觉资源」，应统一纳入 `cs-image-manager` 管理，便于后续按主题替换、热更新换图。

详细规则（扫描目标、替换规则、完整示例）见 [references/step-details.md](references/step-details.md#step-12emoji--csimage-替换完整示例)。

**执行步骤**：
1. 正则扫描所有 `lib/` 下 `.dart` 文件，列出所有发现的 emoji 及出现位置
2. 为每个唯一 emoji 生成 `configKey`，格式：`emoji_<描述性名称>`（如 `emoji_party`、`emoji_check`）
3. 在 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json` 中批量注册新插槽（初始无 asset/url，使用占位图）
4. 修改对应 `.dart` 文件，将 emoji 字面量替换为 `CsImage(configKey: 'xxx')`
5. 调用 `cs-image-manager` 将 manifest 同步到 `assets/default_configs.json`

---

## 关键文件清单

| 文件 | 改动说明 |
|------|---------|
| `.cursor/hooks.json` | 注册 afterFileEdit hook |
| `.cursor/hooks/sync-image-manifest.sh` | dart 保存后自动同步 manifest |
| `aiworkspace/sync_image_manifest.py` | 增量扫描 CsImage configKey |
| `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json` | 图片注册表（pages 结构；开发期不入业务仓库） |
| `pubspec.yaml` | 添加 `cs_ui` git 依赖 |
| `pubspec_overrides.yaml` | 本地 path 覆盖（不提交） |
| `lib/main.dart` | MaterialApp → CsApp |
| `lib/utils/app_theme.dart` | 删除 Material 组件主题覆盖 |
| `lib/screens/*.dart` | 按钮/AppBar/TabBar/图片/emoji 替换 |
| `assets/default_configs.json` | 注册所有图片和 emoji configKey（由 cs-image-manager 维护） |
| `cs_ui/lib/src/widgets/cs_app_bar.dart` | 新增 CsAppBar 组件 |
| `cs_ui/lib/cs_ui.dart` | 导出 CsAppBar |
| `cs_ui/pubspec.yaml` | 升级 shadcn_ui 版本约束 |
| `cs_ui/lib/src/widgets/cs_app.dart` | 更新 appBuilder 签名 |
| `cs_ui/lib/src/theme/cs_app_theme.dart` | 切换 activeStyle |
