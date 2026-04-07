# 宝宝识字 App - 知识库

## 项目概述

面向 3-6 岁学前儿童的 Flutter 识字应用，支持 iOS / Android / Web 多端运行。
通过卡片、游戏、积分等儿童友好的交互方式，帮助孩子认识常用汉字。

- **GitHub**: https://github.com/bryanpeng-777/hanzi-cursor
- **本地路径**: `/Users/bryanpeng/work3/cursorAGIProject/hanzi`
- **Flutter SDK**: ^3.6.2 | **Dart SDK**: ^3.6.2

---

## 项目结构

```
lib/
├── main.dart                        # App 入口 + SplashScreen（2秒启动页）
├── data/
│   └── hanzi_data.dart              # 所有汉字数据（22个，3关卡）
├── models/
│   └── hanzi_model.dart             # 数据模型定义
├── providers/
│   └── learning_provider.dart       # 全局状态管理（Provider）
├── screens/
│   ├── home_screen.dart             # 首页（进度卡 + 每日一字 + 功能入口）
│   ├── learn_screen.dart            # 识字列表（按关卡筛选的网格）
│   ├── hanzi_detail_screen.dart     # 汉字详情（大字 + 笔画 + 例词 + 收藏）
│   ├── game_screen.dart             # 游戏大厅（选择游戏模式）
│   ├── match_game_screen.dart       # 图字配对游戏
│   ├── listen_game_screen.dart      # 听音选字游戏（8题）
│   └── vocabulary_screen.dart       # 生字本（已学 + 收藏 双标签）
├── utils/
│   └── app_theme.dart               # 全局主题（颜色、字体、组件样式）
└── widgets/
    ├── star_reward_widget.dart       # 星星奖励弹窗（学会汉字后触发）
    └── stroke_animation_widget.dart  # 米字格笔画动画组件
```

---

## 数据模型

### HanziCharacter（`lib/models/hanzi_model.dart`）

```dart
class HanziCharacter {
  final String character;      // 汉字本体，如 '一'
  final String pinyin;         // 拼音，如 'yī'
  final String meaning;        // 含义，如 '数字1'
  final String emoji;          // 配图 emoji，如 '☝️'
  final String strokeCount;    // 笔画数，如 '1画'
  final List<String> exampleWords; // 例词，如 ['一个', '第一', '一起']
  final int level;             // 关卡：1=初级 2=中级 3=高级
}
```

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

使用 **Provider（ChangeNotifier）** 模式，全局单例 `LearningProvider`。

### 关键 API

```dart
// 读取
provider.totalStars          // 总星星数
provider.learnedCount        // 已学汉字数
provider.totalCount          // 全部汉字数（22）
provider.overallProgress     // 学习进度 0.0~1.0
provider.learnedCharacters   // 已学汉字列表
provider.favoriteCharacters  // 收藏汉字列表
provider.getProgress(char)   // 获取某字的学习进度
provider.isLearned(char)     // 是否已学
provider.isFavorite(char)    // 是否已收藏

// 写入（自动持久化到 SharedPreferences）
provider.markAsLearned(char, starsEarned: 3)  // 标记已学，+星星
provider.addStars(char, count)                 // 增加星星
provider.toggleFavorite(char)                  // 收藏/取消收藏
```

### 持久化

SharedPreferences 存储两个 key：
- `learning_progress`：JSON 格式的 `Map<String, LearningProgress>`
- `total_stars`：int，总星星数
- `current_streak`：int，连续学习天数（暂未在 UI 展示）

---

## 汉字数据（`lib/data/hanzi_data.dart`）

当前共 **22 个汉字**，分 3 关卡：

| 关卡 | 汉字 | 数量 |
|------|------|------|
| Level 1（初级） | 一、二、三、人、口、手、目、日、月、山 | 10 |
| Level 2（中级） | 大、小、火、水、木、土 | 6 |
| Level 3（高级） | 天、地、心、书、鱼、花 | 6 |

### 新增汉字

在 `allHanzi` 列表中追加一个 `HanziCharacter`：

```dart
HanziCharacter(
  character: '风',
  pinyin: 'fēng',
  meaning: '风',
  emoji: '💨',
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

## 页面导航

App 采用底部 Tab 导航，4 个一级页面：

```
HomeScreen（底部 Tab 容器）
├── Tab 0: _HomePage        → 首页
├── Tab 1: LearnScreen       → 识字列表
├── Tab 2: GameScreen        → 游戏大厅
└── Tab 3: VocabularyScreen  → 生字本

LearnScreen → HanziDetailScreen（Push 跳转）
GameScreen  → MatchGameScreen / ListenGameScreen（Push 跳转）
```

### 从首页跳转到子 Tab

```dart
// 在子 Widget 中跳转到特定 Tab
final homeState = context.findAncestorStateOfType<_HomeScreenState>();
homeState?._onTap(tabIndex);  // 0=首页 1=识字 2=游戏 3=生字本
```

---

## 功能说明

### 每日一字（首页）

根据当天日期自动选字，每天不同：

```dart
final todayChar = allHanzi[DateTime.now().day % allHanzi.length];
```

展示内容：汉字大字、拼音、含义、emoji、笔画数、前2个例词。

### 识字卡片

- 按关卡（全部/1/2/3）筛选，网格展示
- 已学汉字显示绿色角标 ✅
- 点击进入 `HanziDetailScreen`

### 汉字详情

- 弹跳入场动画（`flutter_animate`）
- 米字格 + 笔画动画（`StrokeAnimationWidget`）
- 收藏按钮（❤️）
- "我学会了" 按钮 → 触发 `markAsLearned` → 弹出星星奖励

### 游戏系统

**图字配对**（`match_game_screen.dart`）：
- 从当前关卡随机抽 5 对汉字
- 左列 emoji，右列汉字，点击配对
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
```

---

## 依赖说明

| 包 | 版本 | 用途 |
|----|------|------|
| `provider` | ^6.1.2 | 状态管理 |
| `shared_preferences` | ^2.3.3 | 本地持久化 |
| `flutter_animate` | ^4.5.2 | 动画效果（fadeIn/scale/slideX 等）|
| `google_fonts` | ^6.2.1 | Noto Sans SC 中文字体 |
| `audioplayers` | ^6.1.0 | 音频播放（暂未使用，预留） |
| `lottie` | ^3.3.1 | Lottie 动画（暂未使用，预留） |

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
- [ ] 汉字库扩展（目前 22 字，目标 100+）
- [ ] 连续打卡奖励（`currentStreak` 已有字段，UI 待接入）
- [ ] 多人对战模式
