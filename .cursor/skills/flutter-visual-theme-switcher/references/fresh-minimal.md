# 清新简约 (Fresh Minimal) — 主题规范

## 设计理念
干净、轻盈、留白充足。参考 Material 3、iOS Human Interface Guidelines。
适合工具类、效率类、内容阅读类 App。

---

## 颜色系统

| Token | 值 | 说明 |
|---|---|---|
| background | `#FAFAFA` | 主背景，浅灰白 |
| foreground | `#09090B` | 主文字 |
| card | `#FFFFFF` | 卡片背景 |
| primary | `#1D4ED8` (slate 系) | 主色调，冷蓝 |
| primaryForeground | `#F8FAFC` | 主色上的文字 |
| secondary | `#F1F5F9` | 次要色，浅蓝灰 |
| secondaryForeground | `#0F172A` | 次要色上文字 |
| muted | `#F1F5F9` | 低调背景 |
| mutedForeground | `#64748B` | 次要文字 |
| border | `#E2E8F0` | 边框 |
| ring | `#1D4ED8` | focus 环颜色 |

ColorScheme 名称：`slate`（使用 `ShadSlateColorScheme.light(background: Color(0xFFFAFAFA))`）

---

## 圆角系统

| 用途 | 值 |
|---|---|
| 全局默认圆角 | `8px` |
| BorderRadius 代码 | `BorderRadius.circular(8)` |

---

## 间距规范

| 名称 | 值 | 用途 |
|---|---|---|
| xs | 4px | 图标间距、徽章 |
| sm | 8px | 列表项间距 |
| md | 16px | 卡片内边距、页面水平边距 |
| lg | 24px | 区块间距 |
| xl | 32px | 页面顶部间距 |

---

## 字体规范

| 属性 | 值 |
|---|---|
| 字体族 | 系统默认 (SF Pro / Roboto) |
| 基础字号 | 14px |
| 标题字号 | 18px / 22px |
| 字重 | Regular 400 / Medium 500 / Bold 700 |
| 行距 | 1.4 |

---

## 阴影规范

| 层级 | 值 |
|---|---|
| card | `BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: Offset(0, 2))` |
| modal | `BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: Offset(0, 4))` |

---

## 组件规范

### Button
```dart
primaryButtonTheme: const ShadButtonTheme(height: 40),
secondaryButtonTheme: const ShadButtonTheme(height: 40),
outlineButtonTheme: const ShadButtonTheme(height: 40),
```

### 其他组件
- `NavigationBar`：背景用 `colorScheme.surface`，选中用 `colorScheme.primary`
- `AppBar`：透明背景或 `colorScheme.surface`，文字 `colorScheme.onSurface`
- `Card`：圆角 8px，轻阴影
- `TextField / ShadInput`：边框 `colorScheme.outline`，圆角 8px

---

## ShadThemeData 代码片段

```dart
// lib/src/theme/fresh_minimal_theme.dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FreshMinimalTheme {
  const FreshMinimalTheme._();

  static ShadThemeData get themeData => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(
          background: Color(0xFFFAFAFA),
        ),
        radius: BorderRadius.circular(8),
        primaryButtonTheme: const ShadButtonTheme(height: 40),
        secondaryButtonTheme: const ShadButtonTheme(height: 40),
        outlineButtonTheme: const ShadButtonTheme(height: 40),
      );

  static ShadThemeData get darkThemeData => ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
        radius: BorderRadius.circular(8),
        primaryButtonTheme: const ShadButtonTheme(height: 40),
        secondaryButtonTheme: const ShadButtonTheme(height: 40),
        outlineButtonTheme: const ShadButtonTheme(height: 40),
      );
}
```

---

## CsAppTheme.activeStyle 切换值

```dart
static const CsThemeStyle activeStyle = CsThemeStyle.freshMinimal;
```
