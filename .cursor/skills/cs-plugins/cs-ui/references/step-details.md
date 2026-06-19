# Step 详细实现

## Step 5：CsAppBar Widget 完整代码

若 `cs_ui` 尚未包含 `CsAppBar`，在 `cs_ui/lib/src/widgets/cs_app_bar.dart` 创建：

```dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CsAppBar({
    super.key, this.title, this.leading, this.actions,
    this.backgroundColor = Colors.transparent, this.elevation = 0,
    this.centerTitle = false, this.bottom, this.titleTextStyle,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color backgroundColor;
  final double elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final TextStyle? titleTextStyle;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    final defaultTitleStyle = TextStyle(
      fontWeight: FontWeight.bold, fontSize: 18,
      color: shadTheme.colorScheme.foreground,
    );
    return AppBar(
      backgroundColor: backgroundColor, elevation: elevation,
      centerTitle: centerTitle, leading: leading, actions: actions,
      bottom: bottom,
      title: title != null
          ? Text(title!, style: titleTextStyle ?? defaultTitleStyle)
          : null,
    );
  }
}
```

在 `cs_ui/lib/cs_ui.dart` 导出：
```dart
export 'src/widgets/cs_app_bar.dart';
```

---

## Step 7：ShadTabs 完整改造示例

Material TabBar 和 ShadTabs 的完整 Before → After：

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

## Step 12：Emoji → CsImage 替换完整示例

### 扫描目标

正则匹配所有 `.dart` 文件中的 emoji Unicode 字面量，覆盖以下范围：
- 表情符号：U+1F000–U+1FFFF（😊 🎉 🔥 等）
- 符号与标点：U+2600–U+27BF（☀️ ✅ ⚠️ 等）
- 杂项符号：U+2300–U+23FF（⏰ ⌛ 等）

### 扫描 + 替换规则

| 场景 | 改造前 | 改造后 |
|-----|-------|-------|
| Text 中单独使用 emoji | `Text('🎉')` | `CsImage(configKey: 'emoji_party', width: 20, height: 20)` |
| Text 中 emoji 与文字混排 | `Text('🎉 恭喜完成！')` | `Row(children: [CsImage(...), const Text(' 恭喜完成！')])` |
| 字符串变量中的 emoji | `final label = '✅ 完成'` | 拆分为 `CsImage` + 文字，或保留纯文本（AI 根据语义判断） |
| Icon + emoji 混用 | 含 emoji 的 Icon label | emoji 部分抽出替换为 `CsImage` |

> **不改造的情形**：注释中的 emoji、print/log 中的 emoji、测试文件中的 emoji。

### 替换完整示例

```dart
// Before
Column(children: [
  Text('🎉 任务完成！'),
  Text('⚠️ 请注意以下事项'),
  Text('✅ 已验证'),
])

// After
Column(children: [
  Row(children: [
    CsImage(configKey: 'emoji_party', width: 20, height: 20),
    const Text(' 任务完成！'),
  ]),
  Row(children: [
    CsImage(configKey: 'emoji_warning', width: 20, height: 20),
    const Text(' 请注意以下事项'),
  ]),
  Row(children: [
    CsImage(configKey: 'emoji_check', width: 20, height: 20),
    const Text(' 已验证'),
  ]),
])
```
