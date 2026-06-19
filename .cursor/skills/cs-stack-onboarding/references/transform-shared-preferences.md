# shared_preferences 接入与本地存储改造规则

本文件供 `cs-stack-onboarding` Step 2-5（shared_preferences 接入）和 Step 3-H（本地存储改造）使用。

---

## 分工原则

```
需要本地持久化的数据？
  ├── 简单类型（bool / int / String / double）
  │     └── 业务语义属于「用户偏好设置」（主题、语言、开关、上次选中项等）？
  │           ├── 是 → shared_preferences（PreferencesManager）
  │           └── 否 → cs_framework DataManager / Hive
  └── 复杂对象 / 列表 / 嵌套结构
        └── → cs_framework DataManager / Hive（不用 shared_preferences）
```

### 典型 shared_preferences 场景

| 数据 | 类型 | 说明 |
|-----|-----|-----|
| 深色模式开关 | `bool` | 用户偏好 |
| 语言/地区设置 | `String` | 用户偏好 |
| 通知开关 | `bool` | 用户偏好 |
| 引导页是否已看 | `bool` | 简单状态标记 |
| 上次选中的 Tab | `int` | 简单状态 |
| 用户自定义字体大小 | `double` | 用户偏好 |
| 非 Supabase 接口的 Token | `String` | 简单凭证（敏感数据建议用 flutter_secure_storage） |

### 不适用 shared_preferences 的场景

| 数据 | 应使用 |
|-----|------|
| 用户 Profile 对象（含多个字段） | cs_framework DataManager |
| 商品列表缓存 / API 响应缓存 | cs_framework DataManager / Hive |
| Supabase 认证 Session | cs_framework（自动管理） |
| 图片/文件路径列表 | cs_framework DataManager |

---

## Step 接入-1：安装依赖

在 `pubspec.yaml` 的 `dependencies` 中添加：

```yaml
shared_preferences: ^2.3.0
```

执行 `flutter pub get`。

---

## Step 接入-2：创建 PreferencesManager

新建 `lib/storage/preferences_manager.dart`，提供类型安全的读写封装：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences_manager.g.dart';

class PreferencesManager {
  final SharedPreferences _prefs;

  PreferencesManager(this._prefs);

  // ── Keys ──────────────────────────────────────────────

  static const _keyThemeMode = 'theme_mode';       // 0=system, 1=light, 2=dark
  static const _keyLanguage = 'language';
  static const _keyNotificationEnabled = 'notification_enabled';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyLastSelectedTab = 'last_selected_tab';
  // 根据项目实际需求继续添加

  // ── Theme ─────────────────────────────────────────────

  int get themeMode => _prefs.getInt(_keyThemeMode) ?? 0;
  Future<void> setThemeMode(int mode) => _prefs.setInt(_keyThemeMode, mode);

  // ── Language ──────────────────────────────────────────

  String? get language => _prefs.getString(_keyLanguage);
  Future<void> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  // ── Notification ──────────────────────────────────────

  bool get notificationEnabled => _prefs.getBool(_keyNotificationEnabled) ?? true;
  Future<void> setNotificationEnabled(bool enabled) =>
      _prefs.setBool(_keyNotificationEnabled, enabled);

  // ── Onboarding ────────────────────────────────────────

  bool get onboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_keyOnboardingDone, true);

  // ── Tab ───────────────────────────────────────────────

  int get lastSelectedTab => _prefs.getInt(_keyLastSelectedTab) ?? 0;
  Future<void> setLastSelectedTab(int index) =>
      _prefs.setInt(_keyLastSelectedTab, index);

  // ── Generic（兜底，直接操作原始 key）─────────────────

  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  String? getString(String key) => _prefs.getString(key);
  double? getDouble(String key) => _prefs.getDouble(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}

// ── Riverpod Provider（通过 main.dart override 注入）─────

/// 必须在 main.dart 中通过 override 注入，确保 SharedPreferences 异步初始化完成
@Riverpod(keepAlive: true)
PreferencesManager preferencesManager(PreferencesManagerRef ref) {
  throw UnimplementedError('preferencesManagerProvider must be overridden in main.dart');
}
```

---

## Step 接入-3：main.dart 初始化

在 `main()` 中异步初始化 SharedPreferences，并通过 Riverpod `overrides` 注入：

```dart
// main.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'storage/preferences_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 其他初始化（cs_framework 等）...

  final prefs = await SharedPreferences.getInstance();
  final prefsManager = PreferencesManager(prefs);

  runApp(
    ProviderScope(
      overrides: [
        preferencesManagerProvider.overrideWithValue(prefsManager),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## Step 3-H：本地存储改造

### 扫描目标

扫描以下模式，判断是否符合「简单类型 + 用户偏好」双条件：

| 扫描模式 | 说明 |
|---------|-----|
| `SharedPreferences.getInstance()` 散落在各处 | 已有用法但未封装，需集中到 PreferencesManager |
| `StatefulWidget` 中的 `bool`/`int`/`String` 字段，值在 initState 中赋默认值且语义明显是设置项 | 应持久化到 shared_preferences |
| `setState(() { _isDark = !_isDark; })` 且该变量语义是主题/语言等偏好 | 应迁移到 PreferencesManager + Riverpod |
| 手写本地 JSON 文件读写（简单 key-value 结构） | 若值为简单类型，迁移到 shared_preferences |

### 判断双条件

对每个候选数据，同时满足以下两条才迁移到 shared_preferences：

1. **类型条件**：`bool` / `int` / `String` / `double`（单值，非列表/对象）
2. **语义条件**：属于用户偏好/设置类（主题、语言、通知开关、引导页状态、上次记录的简单选项等）

不满足任意一条 → 保留原存储方式或迁移到 cs_framework DataManager。

### 迁移示例

#### 散落的 SharedPreferences 调用 → PreferencesManager

```dart
// Before（散落在各 Widget 中）
final prefs = await SharedPreferences.getInstance();
final isDark = prefs.getBool('dark_mode') ?? false;
await prefs.setBool('dark_mode', true);

// After（统一通过 PreferencesManager）
final prefsManager = ref.read(preferencesManagerProvider);
final isDark = prefsManager.themeMode == 2;
await prefsManager.setThemeMode(2);
```

#### StatefulWidget 中的偏好变量 → Riverpod + PreferencesManager

```dart
// Before
class SettingsScreen extends StatefulWidget { ... }
class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  void _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', value);
    setState(() { _notificationsEnabled = value; });
  }

  @override
  Widget build(BuildContext context) {
    return Switch(value: _notificationsEnabled, onChanged: _toggle);
  }
}

// After（PreferencesManager + @riverpod Notifier）
// 1. 在 providers/ 中定义持久化 Notifier
@riverpod
class NotificationEnabled extends _$NotificationEnabled {
  @override
  bool build() => ref.read(preferencesManagerProvider).notificationEnabled;

  Future<void> toggle(bool value) async {
    state = value;
    await ref.read(preferencesManagerProvider).setNotificationEnabled(value);
  }
}

// 2. Widget 变为 ConsumerWidget
class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationEnabledProvider);
    return Switch(
      value: enabled,
      onChanged: (value) =>
          ref.read(notificationEnabledProvider.notifier).toggle(value),
    );
  }
}
```

#### 不改造的反例（复杂对象，应走 cs_framework）

```dart
// 不改造：这是复杂对象，即使有人用 jsonEncode 存到 SharedPreferences，也应迁移到 DataManager
final prefs = await SharedPreferences.getInstance();
final userJson = prefs.getString('user_profile');  // ← 复杂对象伪装成 String
// → 应迁移到 cs_framework DataManager，不属于 shared_preferences 范畴
```

---

## 改造后注意事项

- **Key 统一管理**：所有 key 常量集中在 `PreferencesManager` 中定义，禁止在业务代码中写死字符串 key
- **异步写，同步读**：`PreferencesManager` 的 getter 均同步（从内存缓存读），setter 返回 `Future<void>`
- **敏感数据**：Token、密码等敏感信息不应放 shared_preferences（未加密），应使用 `flutter_secure_storage`
- **clear() 谨慎使用**：`clear()` 会清空所有 key，退出登录时只清用户相关 key，不要全清
