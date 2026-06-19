# screen-util 插件

flutter_screenutil 屏幕适配接入：按比例缩放尺寸，仅初始化，业务代码按需使用。

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 flutter_screenutil 依赖
2. 检查 main.dart 是否已有 ScreenUtilInit 初始化

### 添加依赖

```yaml
dependencies:
  flutter_screenutil: ^5.9.0
```

运行 `flutter pub get`

### 初始化 ScreenUtilInit

在 `main.dart` 的根 Widget（通常是 MaterialApp / CsApp 外层）包裹 ScreenUtilInit：

```dart
ScreenUtilInit(
  designSize: const Size(375, 812),  // 设计稿尺寸（按实际设计稿调整）
  minTextAdapt: true,
  splitScreenMode: true,
  builder: (context, child) {
    return CsApp(
      title: 'My App',
      home: child,
    );
  },
  child: const HomePage(),
)
```

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查 flutter_screenutil 最新版
```

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| SU1 | ScreenUtilInit 已初始化 | `grep -n "ScreenUtilInit" lib/main.dart` | 有输出 |

---

## [USAGE] 使用辅助

### 尺寸适配用法

```dart
// 宽度/高度适配
Container(width: 100.w, height: 50.h)

// 字号适配
Text('标题', style: TextStyle(fontSize: 16.sp))

// 屏幕宽高百分比
Container(width: 0.8.sw, height: 0.3.sh)  // 80% 宽，30% 高
```

### 何时使用 vs 不使用

- **使用**：需要在不同屏幕尺寸保持视觉比例的固定尺寸元素（卡片、图标、间距）
- **不使用**：`Expanded`、`Flexible`、`MediaQuery` 等已经自适应的布局

### 修改设计稿基准尺寸

在 `ScreenUtilInit` 的 `designSize` 参数中修改，改完后热重启生效。
