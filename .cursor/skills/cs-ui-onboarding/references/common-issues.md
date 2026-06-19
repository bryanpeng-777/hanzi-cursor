# 常见问题

## shadcn_ui 版本冲突

- **现象**：`shadcn_ui >=0.13.0 <0.26.5 is incompatible with flutter_localizations from sdk`
- **解法**：将 `cs_ui/pubspec.yaml` 中的 `shadcn_ui` 约束改为 `'>=0.26.5 <1.0.0'`

---

## ShadApp.custom appBuilder 签名变更

- **版本**：shadcn_ui >=0.26.5 变更了 `appBuilder` 的函数签名
- **变更**：从 `(BuildContext, ThemeData) -> Widget` 改为 `WidgetBuilder`（即 `Widget Function(BuildContext)`）
- **解法**：
  ```dart
  // Before (shadcn_ui <0.26.5):
  appBuilder: (context, materialTheme) { return MaterialApp(theme: materialTheme, ...); }
  // After (shadcn_ui >=0.26.5):
  appBuilder: (context) {
    final materialTheme = Theme.of(context);  // 从 AnimatedTheme 获取
    return MaterialApp(theme: materialTheme, ...);
  }
  ```

---

## CardTheme → CardThemeData

- Flutter 3.27+ 将 `ThemeData.cardTheme` 的类型从 `CardTheme` 改为 `CardThemeData`
- **解法**：将代码中的 `CardTheme(` 改为 `CardThemeData(`

---

## ⚠️ ShadTabs 不适合全屏滚动内容（实测踩坑）

- **现象**：`ShadTabs` 放在 `Scaffold.body` 时，`GridView` / `ListView` 内容区域空白不显示
- **根因**：`ShadTabs` 内部是 `Column`（标题行 + 内容区），内容区不带 `Expanded` 约束，`GridView`/`ListView` 在**无界高度**下渲染失败
- **⛔ 不适用场景**：Tab 内容是 `GridView` / `ListView` 等需撑满全屏的滚动组件
- **✅ 适用场景**：Tab 内容是定高卡片、文本、有限列表（自然定高的内容）
- **替代方案**（全屏滚动）：保留原生 `DefaultTabController` + `TabBar`（放在 `CsAppBar.bottom`）+ `TabBarView`（放在 body），`TabBarView` 会自动撑满剩余空间
