# 卡通风 (Cartoon) — 主题规范

## 设计理念
活泼、圆润、色彩鲜明。参考 Animal Crossing、游戏 UI、儿童友好设计。
适合社交类、游戏类、娱乐类 App。

---

## 颜色系统

| Token | 值 | 说明 |
|---|---|---|
| background | `#FFF9F0` | 暖奶油背景 |
| foreground | `#09090B` | 主文字 |
| card | `#FFFFFF` | 卡片背景 |
| primary | `#E11D48` (rose 系) | 主色，珊瑚粉红 |
| primaryForeground | `#FFF1F2` | 主色上文字 |
| secondary | `#F4F4F5` | 次要色 |
| secondaryForeground | `#18181B` | 次要色文字 |
| muted | `#F4F4F5` | 低调背景 |
| mutedForeground | `#71717A` | 次要文字 |
| border | `#E4E4E7` | 边框 |
| ring | `#E11D48` | focus 环 |

ColorScheme 名称：`rose`（使用 `ShadRoseColorScheme.light(background: Color(0xFFFFF9F0))`）

---

## 圆角系统

| 用途 | 值 |
|---|---|
| 全局默认圆角 | `20px` |
| BorderRadius 代码 | `BorderRadius.circular(20)` |

---

## 间距规范

| 名称 | 值 | 用途 |
|---|---|---|
| xs | 6px | 图标间距 |
| sm | 12px | 列表项间距 |
| md | 20px | 卡片内边距、页面水平边距 |
| lg | 28px | 区块间距 |
| xl | 40px | 页面顶部间距 |

> 卡通风间距比清新简约整体偏大约 25%，呼吸感更足。

---

## 字体规范

| 属性 | 值 |
|---|---|
| 字体族 | 系统默认，可选 Nunito（需 google_fonts）|
| 基础字号 | 15px（比 fresh-minimal 偏大） |
| 标题字号 | 20px / 26px |
| 字重 | Regular 400 / SemiBold 600 / Bold 800 |
| 行距 | 1.5 |

---

## 阴影规范

| 层级 | 值 |
|---|---|
| card | `BoxShadow(color: Color(0xFFE11D48).withValues(alpha: 0.12), blurRadius: 0, offset: Offset(4, 4))` |
| button | 偏移实色阴影，体现卡通厚重感 |

---

## 组件规范

### Button
```dart
primaryButtonTheme: const ShadButtonTheme(height: 48),
secondaryButtonTheme: const ShadButtonTheme(height: 48),
outlineButtonTheme: const ShadButtonTheme(height: 48),
```
按钮更高（48px），体现活泼感。

### 其他组件
- `NavigationBar`：背景用 `colorScheme.surface`，选中色鲜艳
- `AppBar`：可用主色背景（`colorScheme.primary`）营造活泼感
- `Card`：圆角 20px，彩色偏移阴影
- `Chip / Badge`：大圆角，鲜明颜色

---

## ShadThemeData 代码片段

```dart
// lib/src/theme/cartoon_theme.dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CartoonTheme {
  const CartoonTheme._();

  static ShadThemeData get themeData => ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadRoseColorScheme.light(
          background: Color(0xFFFFF9F0),
        ),
        radius: BorderRadius.circular(20),
        primaryButtonTheme: const ShadButtonTheme(height: 48),
        secondaryButtonTheme: const ShadButtonTheme(height: 48),
        outlineButtonTheme: const ShadButtonTheme(height: 48),
      );

  static ShadThemeData get darkThemeData => ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadRoseColorScheme.dark(),
        radius: BorderRadius.circular(20),
        primaryButtonTheme: const ShadButtonTheme(height: 48),
        secondaryButtonTheme: const ShadButtonTheme(height: 48),
        outlineButtonTheme: const ShadButtonTheme(height: 48),
      );
}
```

---

## CsAppTheme.activeStyle 切换值

```dart
static const CsThemeStyle activeStyle = CsThemeStyle.cartoon;
```
