# 宝宝识字 App - 知识库

## 项目概述

面向 3-6 岁学前儿童的 Flutter 识字应用，支持 iOS / Android / Web 多端运行。
通过卡片、游戏、积分等儿童友好的交互方式，帮助孩子认识常用汉字。

- **GitHub**: https://github.com/bryanpeng-777/hanzi-cursor
- **本地路径**: `/Users/pengchao/cursorBiz/hanzi-cursor`
- **Flutter SDK**: ^3.6.2 | **Dart SDK**: ^3.6.2

---

## 大仓可用积木

本 App 目前独立运行，如需引入后端/云同步能力，可复用大仓中的基础模块：

| 积木 | 本地路径 | 提供能力 |
|------|---------|---------|
| cs_framework | `../cs_framework` | 认证、配置下发、用户数据存储、推送通知 |
| cs_ui | `../cs_ui` | shadcn_ui 统一主题（4 套配色方案） |

**本地接入方式**（不修改 pubspec.yaml，使用 override）：
```yaml
# hanzi-cursor/pubspec_overrides.yaml（已加入 .gitignore，不会提交）
dependency_overrides:
  cs_framework:
    path: ../cs_framework
  cs_ui:
    path: ../cs_ui
```

**发布引用方式**（pubspec.yaml 中）：
```yaml
cs_framework:
  git:
    url: https://github.com/bryanpeng-777/cs_framework.git
    ref: main
```

---

## 项目结构

```
lib/
├── main.dart                          # App 入口 + SplashScreen（2秒启动页）
├── data/
│   ├── hanzi_data.dart                # 所有汉字数据（68个，10关卡）
│   └── pinyin_data.dart               # 拼音声母/韵母数据
├── models/
│   ├── hanzi_model.dart               # HanziCharacter + LearningProgress（@freezed）
│   ├── hanzi_model.freezed.dart       # build_runner 生成
│   ├── hanzi_model.g.dart             # build_runner 生成
│   ├── learning_state.dart            # LearningState（@freezed，含计算属性）
│   └── learning_state.freezed.dart    # build_runner 生成
├── providers/
│   ├── learning_provider.dart         # LearningNotifier（@riverpod keepAlive），管理全局学习进度
│   ├── learning_provider.g.dart       # build_runner 生成
│   ├── game_config_provider.dart      # GameConfigProvider（@riverpod keepAlive），从 ConfigManager 加载游戏配置
│   └── game_config_provider.g.dart    # build_runner 生成
├── screens/
│   ├── home_screen.dart               # 首页（进度卡 + 每日一字 + 功能入口）
│   ├── learn_screen.dart              # 识字 Hub（学习/测验/错题重练 三入口）
│   ├── hanzi_learn_grid_screen.dart   # 识字学习网格（按关卡筛选，动态适配关卡数）
│   ├── hanzi_detail_screen.dart       # 汉字详情（大字 + 笔画 + 例词 + 收藏）
│   ├── hanzi_quiz_level_screen.dart   # 识字测验选关（10关，渐进解锁）
│   ├── hanzi_quiz_screen.dart         # 识字测验（拼音+含义→选汉字，6秒限时）
│   ├── game_screen.dart               # 游戏大厅（选择游戏模式）
│   ├── match_game_screen.dart         # 图字配对游戏
│   ├── listen_game_screen.dart        # 听音选字游戏（8题）
│   ├── vocabulary_screen.dart         # 生字本（已学 + 收藏 双标签）
│   ├── pinyin_screen.dart             # 拼音 Hub（学习/测验/错题重练 三入口）
│   ├── pinyin_learn_screen.dart       # 拼音学习
│   └── pinyin_exercise_screen.dart    # 拼音测验 + 错题重练
├── utils/
│   └── app_theme.dart                 # 全局主题（颜色、字体、组件样式）
└── widgets/
    ├── star_reward_widget.dart         # 星星奖励弹窗（学会汉字后触发）
    └── stroke_animation_widget.dart    # 米字格笔画动画组件
```

---

## 数据模型

### HanziCharacter（`lib/models/hanzi_model.dart`）

`HanziCharacter` 为 `@freezed` 生成类，核心字段包括：

- `character` / `pinyin` / `meaning` / `strokeCount` / `exampleWords` / `level`
- `iconHint`：配图语义短文案（**禁止** Unicode 表情），供 `CsImage(description: …)` 与无障碍说明使用；实际图由 `hanzi_icon_${character}` 等 `configKey` 指向 `default_configs.json`

### LearningProgress（`lib/models/hanzi_model.dart`）

```dart
class LearningProgress {
  final String character;  // 对应汉字
  bool isLearned;          // 是否已学会
  bool isFavorite;         // 是否已收藏
  int stars;               // 获得的星星数
  DateTime? lastStudied;   // 最后学习时间
}
```

---

## 状态管理

使用 **Riverpod（@riverpod 注解 + build_runner 代码生成）** 模式。

### Provider 列表

| Provider | 类型 | 说明 |
|----------|------|------|
| `learningNotifierProvider` | `Notifier<LearningState>`（keepAlive） | 全局学习进度状态 |
| `gameConfigProvider` | `AsyncNotifier<GameConfigState>`（keepAlive） | 游戏配置（从 ConfigManager 加载） |

### 学习状态 API（LearningState）

```dart
// 读取（在 Widget 中用 ref.watch）
final state = ref.watch(learningNotifierProvider);
state.totalStars          // 总星星数
state.learnedCount        // 已学汉字数
state.totalCount          // 全部汉字数
state.overallProgress     // 学习进度 0.0~1.0
state.learnedCharacters   // 已学汉字列表
state.favoriteCharacters  // 收藏汉字列表
state.getProgress(char)   // 获取某字的学习进度
state.isLearned(char)     // 是否已学
state.isFavorite(char)    // 是否已收藏
state.pinyinMistakes      // 拼音错题集 Set<String>
state.hanziQuizMistakes   // 汉字测验错题集 Set<String>
state.isHanziLevelUnlocked(level)   // 关卡是否已解锁
state.isHanziLevelPassed(level)     // 关卡是否已通关
state.getHanziQuizBestScore(level)  // 某关卡历史最高分

// 写入（在回调中用 ref.read）
final notifier = ref.read(learningNotifierProvider.notifier);
await notifier.markAsLearned(char, starsEarned: 3)
await notifier.addStars(char, count)
await notifier.toggleFavorite(char)
await notifier.addPinyinMistake(initial)
await notifier.removePinyinMistake(initial)
await notifier.clearPinyinMistakes()
await notifier.addHanziMistake(char)
await notifier.removeHanziMistake(char)
await notifier.markHanziLevelPassed(level, scorePercent)
```

### 持久化

学习进度由 `LearningNotifier` 双写到本地（SharedPreferences）和云端（Supabase DataManager）：

| SharedPreferences Key | 类型 | 内容 |
|----------------------|------|------|
| `learning_progress` | JSON | `Map<String, LearningProgress>` |
| `total_stars` | int | 总星星数 |
| `current_streak` | int | 连续学习天数（UI 暂未展示） |
| `pinyin_mistakes` | 逗号字符串 | 拼音错题集 |
| `hanzi_quiz_mistakes` | 逗号字符串 | 汉字测验错题集 |
| `hanzi_quiz_passed_levels` | 逗号字符串 | 已通关关卡 |
| `hanzi_quiz_best_scores` | JSON | 各关卡历史最高分 |

> ❌ 禁止在业务代码中直接调用 `SharedPreferences.getInstance()`，持久化逻辑已全部封装在 `LearningNotifier` 内。

---

## 汉字数据（`lib/data/hanzi_data.dart`）

当前共 **68 个汉字**，分 10 关卡：

| 关卡 | 主题 | 汉字示例 | 数量 |
|------|------|------|------|
| Level 1 | 数字&基础 | 一二三人口手目日月山 | 10 |
| Level 2 | 大小&五行 | 大小火水木土 | 6 |
| Level 3 | 天地&日常 | 天地心书鱼花 | 6 |
| Level 4 | 动物 | 猫狗鸟虫马牛羊兔 | 8 |
| Level 5 | 颜色 | 红黄蓝绿白黑 | 6 |
| Level 6 | 食物 | 饭米面包果菜 | 6 |
| Level 7 | 身体 | 头耳鼻足发眼 | 6 |
| Level 8 | 家庭 | 爸妈哥姐弟妹 | 6 |
| Level 9 | 方位 | 上下左右前后 | 6 |
| Level 10 | 自然 | 风雨雪云雷电 | 6 |

### 新增汉字

在 `allHanzi` 列表中追加一个 `HanziCharacter`：

```dart
HanziCharacter(
  character: '风',
  pinyin: 'fēng',
  meaning: '风',
  iconHint: '「风」识字配图：风',
  strokeCount: '4画',
  exampleWords: ['风筝', '台风', '风景'],
  level: 2,
),
```

辅助函数：
- `getHanziByLevel(int level)` — 按关卡筛选
- `findHanzi(String character)` — 按汉字查找，不存在返回 null

---

## 主题设计（`lib/utils/app_theme.dart`）

### 颜色系统

```dart
AppTheme.primaryOrange   // #FF6B35 - 主色（橙色）
AppTheme.primaryYellow   // #FFD23F - 辅色（黄色）
AppTheme.primaryGreen    // #4CAF50 - 成功/Level1
AppTheme.primaryBlue     // #2196F3 - 信息/Level2
AppTheme.primaryPink     // #E91E8C - 强调/Level3
AppTheme.backgroundPeach // #FFF3E0 - 页面背景（暖白）
AppTheme.levelColors     // [绿, 蓝, 橙] 对应三个关卡
```

### 字体

使用 **Google Fonts - Noto Sans SC**，通过 `google_fonts` 包在运行时加载。
解决 Flutter Web 中文乱码的关键：`web/index.html` 中预加载了 CDN 字体。

```html
<!-- web/index.html 中的字体预加载 -->
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC..." rel="stylesheet">
```

### 关卡颜色

```dart
AppColors.getLevelColor(level)  // level 1=绿 2=蓝 3=橙
```

---

## 图片资源（CsImage）与批量生图

- **运行时**：`CsImage(configKey: …)` 由 `assets/default_configs.json` 提供 `url` / `asset` 兜底；业务代码不写死资源路径。
- **开发期台账**：`~/.claude/knowledge/ui-assistant/hanzi/image_manifest.json`（与 Cursor `sync_image_manifest.py` hook 增量同步 `configKey`）。
- **凡「生成 / 替换位图」**（配图、图标、占位图、`assets/images` 下文件、`default_configs` 的 `asset` 等）：**必须**先读取并遵循 `~/.claude/skills/image-generator/SKILL.md`（Step 0 选图 → Step 1 统一风格 → Step 2 逐张 GenerateImage + PIL 定尺寸与压缩 → Step 3 回写 manifest + `default_configs.json`）。大仓内对应 Cursor 规则：`.cursor/rules/image-generator.mdc`。
- **提交前**：若修改了配图与配置，在 `hanzi-cursor` 根目录执行 `python3 scripts/sync_image_manifest_to_defaults.py --check`（不通则 `--apply`）以满足 pre-commit 对「台账 ↔ default_configs」一致性的校验。

---

## 页面导航

App 采用底部 Tab 导航，4 个一级页面：

```
HomeScreen（底部 Tab 容器）
├── Tab 0: PinyinScreen        → 拼音 Hub
│          ├── PinyinLearnScreen         → 拼音学习
│          └── PinyinExerciseScreen      → 声母测验 + 错题重练
├── Tab 1: LearnScreen         → 识字 Hub
│          ├── HanziLearnGridScreen      → 识字学习网格
│          ├── HanziQuizLevelScreen      → 测验选关（10关渐进解锁）
│          │    └── HanziQuizScreen       → 测验（拼音+含义→选汉字）
│          └── HanziQuizScreen(mistake)  → 错题重练
├── Tab 2: GameScreen          → 游戏大厅
│          ├── MatchGameScreen           → 图字配对
│          └── ListenGameScreen          → 听音选字
└── Tab 3: VocabularyScreen    → 生字本
```

### 从子页面跳转到指定 Tab

```dart
// 在子 Widget 中跳转到特定 Tab
final homeState = context.findAncestorStateOfType<_HomeScreenState>();
homeState?._onTap(tabIndex);  // 0=拼音 1=识字 2=游戏 3=生字本
```

---

## 功能说明

### 每日一字（首页）

根据当天日期自动选字，每天不同：

```dart
final todayChar = allHanzi[DateTime.now().day % allHanzi.length];
```

展示内容：汉字大字、拼音、含义、`CsImage` 情境配图、笔画数、前2个例词。

### 识字 Tab（三入口 Hub）

`learn_screen.dart` 为入口 Hub，包含三个功能卡片：

**识字学习**（`hanzi_learn_grid_screen.dart`）：
- 横向滚动的关卡选择器，动态适配关卡数量（无需硬编码）
- 网格展示当前关卡汉字，已学显示绿色角标（对号图标）
- 点击进入 `HanziDetailScreen`

**识字测验**（`hanzi_quiz_level_screen.dart` + `hanzi_quiz_screen.dart`）：
- 关卡选择界面：10关列表，展示解锁状态和历史最高分
- 未解锁关卡点击弹 SnackBar 提示「请先通过第X关测验」
- 题型：显示拼音（大字）+ 含义文字，4选1正确汉字
- 每题限时 6 秒，答错进错题集，≥70% 正确率通关并解锁下一关

**错题重练**：错题集有内容时激活，进入 `HanziQuizScreen(mistakeMode: true)`

### 汉字详情

- 弹跳入场动画（`flutter_animate`）
- 米字格 + 笔画动画（`StrokeAnimationWidget`）
- 收藏按钮（`CsImage`：`img_icon_favorite_on` / `img_icon_favorite_off`）
- "我学会了" 按钮 → 触发 `markAsLearned` → 弹出星星奖励

### 游戏系统

**图字配对**（`match_game_screen.dart`）：
- 从当前关卡随机抽 5 对汉字
- 左列情境配图（`CsImage`），右列汉字，点击配对
- 正确高亮绿色，完成后显示结算

**听音选字**（`listen_game_screen.dart`）：
- 8 题，显示拼音，4 选 1
- 每题答对 +1 星星
- 完成后显示正确率

### 积分系统

| 动作 | 获得星星 |
|------|---------|
| 标记学会（默认） | +1 |
| 游戏答对 | +1 |
| 详情页学会 | +3 |

---

## 开发命令

```bash
# 安装依赖
flutter pub get

# 运行（Web）
flutter run -d chrome

# 运行（iOS 模拟器）
flutter run -d ios

# 构建 Web（release）
flutter build web --release

# 本地预览构建产物（端口 8091）
python3 -m http.server 8091 --directory build/web

# 部署到 GitHub Pages（自动触发 GitHub Actions）
# 线上地址：https://bryanpeng-777.github.io/hanzi-cursor/
git push origin main
```

### CI/部署注意事项

推送前必须确认，否则 GitHub Actions 必然失败：

1. **pubspec.lock 不能含 path 依赖**：本地 `pubspec_overrides.yaml` 使用 path 依赖后如果执行了 `flutter pub get`，lock 会被污染。推送前检查：
   ```bash
   grep -A4 "source:" pubspec.lock | grep "path"  # 有输出 = 需要修复
   ```
   修复：临时移走 overrides → `flutter pub get` → 恢复 → 提交新 lock

2. **依赖包先于主项目推送**：`cs_ui` / `cs_framework` 若有未推送 commit，CI 拉到旧版本可能版本冲突。推送前检查：
   ```bash
   cd ../cs_ui && git log --oneline origin/main..HEAD
   cd ../cs_framework && git log --oneline origin/main..HEAD
   ```

3. **依赖仓库需为 Public**：`cs_framework` 和 `cs_ui` 已设为 Public，CI 可匿名 clone。

---

## 依赖说明

| 包 | 版本 | 用途 |
|----|------|------|
| `cs_framework` | path: ../cs/cs_framework | 认证、配置下发、数据存储、推送 |
| `cs_ui` | path: ../cs/cs_ui | shadcn_ui 统一主题，CsApp / CsAppBar / ShadButton 等 |
| `flutter_riverpod` | ^2.5.0 | 状态管理核心 |
| `riverpod_annotation` | ^2.4.0 | @riverpod 注解 |
| `freezed_annotation` | ^2.4.0 | @freezed 不可变数据类注解 |
| `json_annotation` | ^4.9.0 | JSON 序列化注解 |
| `go_router` | ^14.0.0 | 声明式路由 |
| `flutter_screenutil` | ^5.9.0 | 屏幕适配（.w / .h / .sp） |
| `dio` | ^5.7.0 | 第三方 HTTP 客户端 |
| `shared_preferences` | ^2.3.3 | 用户偏好本地存储 |
| `flutter_secure_storage` | ^9.2.0 | 敏感凭证存储（Token / API Key） |
| `logger` | ^2.4.0 | 分级日志（替代 print） |
| `flutter_animate` | ^4.5.2 | 动画效果（fadeIn/scale/slideX 等） |
| `google_fonts` | ^6.2.1 | Noto Sans SC 中文字体 |
| `audioplayers` | ^6.1.0 | 音频播放（预留，暂未使用） |
| `lottie` | ^3.1.3 | Lottie 动画（预留，暂未使用） |
| `flutter_tts` | ^4.2.5 | 文字转语音 |

---

## 已知问题 & 注意事项

1. **中文字体**：Flutter Web 默认不加载中文字体，必须通过 `google_fonts` 包 + `web/index.html` CDN 双保险，否则显示乱码方块
2. **竖屏锁定**：`main.dart` 中设置了 `portraitUp/portraitDown`，横屏无支持
3. **音频未接入**：`audioplayers` 已作为依赖引入但尚未实现读音功能
4. **Lottie 动画**：`lottie` 已引入但尚未有 `.json` 动画资产
5. **assets 目录**：`pubspec.yaml` 声明了 `assets/images/` 和 `assets/audio/`，但目录内为空，需提前创建否则 build 可能报错

---

## 扩展计划（待开发）

- [ ] 汉字读音（接入 `audioplayers`，录制/TTS 读音）
- [ ] 笔顺动画（接入真实笔顺数据，逐笔动态展示）
- [ ] 更多游戏模式（组词游戏、默写游戏）
- [ ] 家长控制面板（学习报告、时间限制）
- [ ] 汉字库扩展（目前 68 字 10 关，可继续追加 level 11+）
- [ ] 连续打卡奖励（`currentStreak` 已有字段，UI 待接入）
- [ ] 多人对战模式

---

## 技术栈规范

本项目已接入 cs_framework 完整技术栈，所有新增功能必须遵守以下规范。

### 路由（go_router）
- 跳转用 `context.go()` / `context.push()` / `context.pop()`
- ❌ 禁止使用 `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed`
- 所有路由定义集中在 `lib/router/app_router.dart`

### 状态管理（Riverpod）
- 新建状态用 `@riverpod` 注解 + `build_runner` 生成，放在 `lib/providers/`
- Widget 继承 `ConsumerWidget` 或 `ConsumerStatefulWidget`
- ❌ 禁止使用 `StatefulWidget` + `setState` 管理业务状态
- ❌ 禁止使用 Provider、GetX、BLoC 等其他状态管理库

### 数据模型（freezed + json_annotation）
- `lib/models/` 下的数据类用 `@freezed` 注解，由 `build_runner` 生成
- JSON 反序列化用 `factory X.fromJson(json) => _$XFromJson(json)`
- ❌ 禁止手写 `copyWith` / `==` / `hashCode` / `toString`
- ❌ 禁止在 `@freezed` 类上叠加 `@JsonSerializable()`

### 代码生成（build_runner）
- 修改 `@riverpod` / `@freezed` / `@JsonSerializable` 注解后必须运行：
  `flutter pub run build_runner build --delete-conflicting-outputs`

### 状态访问
- 全局学习状态：`ref.watch(learningNotifierProvider)` → `LearningState`
- 操作方法：`ref.read(learningNotifierProvider.notifier).markAsLearned(...)`
- 状态定义：`lib/models/learning_state.dart`（@freezed）
- Notifier 定义：`lib/providers/learning_provider.dart`（@riverpod keepAlive）

### UI 组件（cs_ui / shadcn_ui）
- 按钮用 `ShadButton`，顶栏用 `CsAppBar`，应用根用 `CsApp`
- ❌ 禁止使用 `ElevatedButton` / `TextButton` / `AppBar`

### 本地存储分层

| 数据类型 | 使用方式 |
|---------|---------|
| 学习进度（复杂对象） | `ref.read(learningNotifierProvider.notifier)` → 自动双写 SharedPreferences + DataManager |
| 简单用户偏好（bool/int/String） | `SharedPreferences`（通过 cs_framework PreferencesManager） |
| 敏感凭证（Token / API Key） | `flutter_secure_storage`（通过 cs_framework SecureStorageManager） |
| 业务数据（云端） | `cs_framework DataManager` |

- ❌ 禁止在业务代码中直接调用 `SharedPreferences.getInstance()`
- ❌ 禁止将 Token / API Key 硬编码在代码中

### HTTP 请求

- 调用 Supabase 表 / Auth / Storage → `cs_framework DataManager`
- 调用第三方 / 自建后端 → `DioClient`（通过 cs_framework）
- ❌ 禁止使用 `http` 包，禁止直接 `Dio()`

### 日志

- 使用 `appLogger.d()` / `.i()` / `.w()` / `.e()`
- ❌ 禁止使用 `print()` / `debugPrint()` / `developer.log()`

### 后端配置（ConfigManager）

- 从 ConfigManager 加载的配置值（开关、数字参数等）必须放入 `@Riverpod(keepAlive: true)` Provider
- ❌ 禁止将 ConfigManager 加载结果通过 `setState` 存储在 Widget State 中
- 参考：`lib/providers/game_config_provider.dart`（spellGameEnabled / matchGameWordCount 等）
