# 项目 Profile

`detect_project_profile.py` 输出 `profile` 字段后，按此表选取策略。

| profile | 检测条件 | 设计系统文件 | 共享组件 |
|---------|----------|--------------|----------|
| `hanzi-cursor` | 目录名含 hanzi 或存在 `hanzi_design_spec.dart` | `lib/design/hanzi_design_spec.dart` | `lib/design/hanzi_shared_widgets.dart` |
| `cs-flutter` | 有 `cs_ui` 依赖 | `lib/utils/app_theme.dart` 或项目 design/ | cs_ui 组件 |
| `flutter-material` | 仅 Flutter，无 cs_ui | 可选 `app_theme.dart` | Material 组件 |

---

## hanzi-cursor 专属

- **横屏**：812×375，Scaffold 优先 `HanziLandscapeScaffold`
- **Hub 页**：标题区 + 卡片网格，卡片用 `HanziSurfaceCard` + 强调色阴影
- **路由**：新预览页可挂 `go_router`，测试入口参考 `home_screen.dart` 中 Codia 对比按钮模式
- **图片**：`CsImage` + `assets/default_configs.json`；新 key 需台账，见 image-generator-workflow

Read 顺序：

1. `lib/design/hanzi_design_spec.dart`
2. `lib/design/hanzi_shared_widgets.dart`
3. 目标 screen 邻近文件的写法（保持一致）

---

## 未知项目

1. 扫描 `lib/design/`、`lib/theme/`、`lib/utils/app_theme.dart`
2. 读 `pubspec.yaml` 依赖
3. 读一个同类 screen 作风格样本
4. 在 Step 2 规划中声明假设，必要时询问用户
