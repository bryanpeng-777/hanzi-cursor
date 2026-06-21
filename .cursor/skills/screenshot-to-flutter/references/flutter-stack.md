# Flutter Stack 策略

对标 screenshot-to-code 的 `system_prompt.py` 中「Stack-specific instructions」，按项目已接入的依赖选择写法。

检测命令：

```bash
python3 ~/.claude/skills/screenshot-to-flutter/scripts/detect_project_profile.py <项目根>
```

---

## cs_ui + Riverpod + go_router（推荐 / hanzi-cursor 默认）

**适用**：`pubspec.yaml` 含 `cs_ui`、`flutter_riverpod`、`go_router`

### 组件映射

| 截图元素 | Flutter 实现 |
|----------|--------------|
| 顶栏 | `CsAppBar` |
| 主按钮 / 次按钮 | `ShadButton` |
| 卡片容器 | 项目共享卡（如 `HanziSurfaceCard`）或 `ShadCard` |
| 底部导航 | 项目 `HanziBottomNavBar` 或自定义 |
| 配图 | `CsImage(configKey: '…')` |
| Tab 切换 | `ShadTabs` 或 `IndexedStack` + 底部栏 |

### 禁止

- `ElevatedButton` / `TextButton` / `OutlinedButton` → 用 `ShadButton`
- `AppBar` → 用 `CsAppBar`
- `Navigator.push` / `pop` → 用 `context.push` / `context.pop`
- 业务状态 `setState` → 用 `@riverpod` Provider（除非纯本地 UI 动画）

### 屏幕适配

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 间距、字号
EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h)
TextStyle(fontSize: 14.sp)
```

设计尺寸与 `ScreenUtilInit` 的 `designSize` 对齐（hanzi-cursor 横屏见 `HanziDesignSpec.canvasWidth/Height`）。

### 字体

```dart
import 'package:google_fonts/google_fonts.dart';

GoogleFonts.notoSansSc(fontSize: 16.sp, fontWeight: FontWeight.w600)
```

或复用 DesignSpec 中的 `hubTitleStyle` 等 getter。

---

## Material 纯 Flutter（无 cs_ui）

**适用**：未接入 cs_ui 的 Flutter 项目

- 可用 `Material 3`：`Theme.of(context).colorScheme`
- 仍建议抽 `DesignSpec` 常量，避免魔法数字散落
- 路由可用 `Navigator` 或 `go_router`（以项目现状为准）

---

## 资产策略（对标 screenshot-to-code Image Manipulation）

| 情况 | 做法 |
|------|------|
| 截图中有明确图标/插画，项目已有 configKey | `CsImage(configKey: 'existing_key')` |
| 需要新图 | 注释占位 + 列出建议 configKey；用户确认后走 image-generator-workflow |
| 简单几何/色块 | 用 `Container` + `BoxDecoration`，不要为整页截图 `generate_images` |
| 头像/照片类 | 圆形 `ClipOval` + 占位色；或 `CsImage` |

**禁止**：把整张截图当作一张 `Image.asset` 贴上去当 UI（screenshot-to-code 同样禁止 embed 整页截图）。

---

## Targeted Element Edits

用户说「只改标题颜色」「把这个按钮变大」时：

1. 在现有 `.dart` 中按 **Widget 类型 + 文案 + Key** 定位 subtree
2. 只修改该 subtree 的 decoration / padding / style
3. 不动无关的 Provider、路由、其他卡片

这与 screenshot-to-code 中「selected element outerHTML 定位」同理——运行时 DOM 与源码可能不完全一致，靠语义定位。
