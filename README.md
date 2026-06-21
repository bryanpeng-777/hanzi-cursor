# 宝宝识字

面向 3-6 岁学前儿童的 Flutter 识字应用，通过拼音学习、汉字卡片、测验、游戏和星星奖励，帮助孩子在轻量互动中认识常用汉字。

线上预览：[https://bryanpeng-777.github.io/hanzi-cursor/](https://bryanpeng-777.github.io/hanzi-cursor/)

## 功能概览

- 拼音学习：覆盖 23 个声母和 24 个韵母，包含例字、助记口诀、拼读示例和测验。
- 汉字学习：内置 66 个常用汉字，分为 10 个关卡，支持按关卡浏览和汉字详情页。
- 识字测验：按关卡进行 4 选 1 测验，支持错题集和关卡通关记录。
- 趣味游戏：包含图字配对、听音选字、涂鸦填色；拼字游戏通过远程配置开关控制。
- 学习进度：使用 Riverpod 管理本地状态，学习记录、收藏、星星和错题会持久化。
- 登录与游客模式：基于 `cs_auth` 提供登录页，也支持跳过登录进入游客模式。

## 技术栈

- Flutter / Dart
- Riverpod + `riverpod_generator`
- Freezed + `json_serializable`
- `go_router`
- `cs_ui` / `cs_core` / `cs_auth`
- `flutter_screenutil`
- `flutter_animate`
- `google_fonts`
- `flutter_tts`

## 项目结构

```text
lib/
├── constants/      # Figma/D2C 布局和静态资源映射常量
├── data/           # 汉字、拼音、涂鸦模板等静态数据
├── design/         # 识字 App 视觉规范和复用组件
├── dev/            # 开发调试 playground
├── models/         # Freezed 数据模型
├── providers/      # Riverpod 状态管理
├── router/         # go_router 路由与登录守卫
├── screens/        # 业务页面
├── utils/          # 主题、横屏、日志、语音、图片导出工具
└── widgets/        # 通用 Widget
```

## 路由与页面

应用启动后进入 2 秒 Splash，再根据登录状态进入登录页或主页。主页固定横屏设计，底部包含 4 个一级 Tab：

- 拼音：拼音学习、拼音测验、错题重练。
- 识字：汉字学习、识字测验、汉字错题重练。
- 游戏：图字配对、听音选字、涂鸦填色、拼字游戏占位。
- 生字本：已学汉字和收藏汉字。

主要路由集中在 `lib/router/app_router.dart`，新增页面应优先通过 `go_router` 注册。

## 数据与资源

- 汉字数据：`lib/data/hanzi_data.dart`
- 拼音数据：`lib/data/pinyin_data.dart`
- 默认配置：`assets/default_configs.json`
- 图片资源：`assets/images/`、`assets/figma_d2c/`、`assets/figma_ui/`

业务图片通过 `CsImage(configKey: ...)` 读取配置，避免在页面中写死资源路径。

## 本地开发

安装依赖：

```bash
flutter pub get
```

运行 Web：

```bash
flutter run -d chrome
```

运行测试：

```bash
flutter test
```

静态分析：

```bash
flutter analyze
```

构建 Web：

```bash
flutter build web --release --base-href /hanzi-cursor/
```

本地预览构建产物：

```bash
python3 -m http.server 8091 --directory build/web
```

## 代码生成

修改 `@riverpod`、`@freezed` 或 JSON 序列化相关文件后，需要重新生成代码：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 部署

仓库通过 GitHub Actions 部署 Flutter Web 到 GitHub Pages：

- workflow：`.github/workflows/deploy-web.yml`
- 触发条件：推送到 `main` 分支，或手动 `workflow_dispatch`
- 构建命令：`flutter build web --release --base-href /hanzi-cursor/`
- 发布分支：`gh-pages`

推送前建议检查：

```bash
git status
git ls-files pubspec_overrides.yaml
rg -A4 "source:" pubspec.lock | rg "path"
```

`pubspec_overrides.yaml` 仅用于本地 path override，不能提交。

## 开发约定

- 路由跳转使用 `context.go()` / `context.push()` / `context.pop()`。
- 全局状态使用 Riverpod，业务状态不要直接散落到 Widget 中。
- 资源图片优先通过 `CsImage` 和 `default_configs.json` 管理。
- 日志使用项目封装的 logger，不使用 `print()`。
- 新增页面或状态后补充对应测试，至少保证 `flutter analyze` 和 `flutter test` 通过。
