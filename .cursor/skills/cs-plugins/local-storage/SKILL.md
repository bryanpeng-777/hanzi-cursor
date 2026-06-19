# local-storage 插件

本地存储接入：shared_preferences（用户偏好设置）+ flutter_secure_storage（敏感凭证）。

**详细规则见** `references/transform-shared-preferences.md` 和 `references/transform-secure-storage.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有相关依赖
2. 扫描散落的 `SharedPreferences.getInstance()` 调用数量
3. 扫描疑似硬编码敏感数据（含 `api_key` / `token` / `secret` / `sk-` / `AIza` 的变量或字符串）

### 添加依赖

```yaml
dependencies:
  shared_preferences: ^2.3.0
  flutter_secure_storage: ^9.2.0
```

运行 `flutter pub get`

### 初始化 PreferencesManager

新建 `lib/services/preferences_manager.dart`，封装 SharedPreferences 单例，避免散落的 `SharedPreferences.getInstance()` 调用（详见 references/transform-shared-preferences.md）。

配合 Riverpod 时，声明 Provider：
```dart
@riverpod
PreferencesManager preferencesManager(PreferencesManagerRef ref) => PreferencesManager();
```

改造散落调用：`SharedPreferences.getInstance()` → `ref.read(preferencesManagerProvider)`

### 初始化 SecureStorageManager

新建 `lib/services/secure_storage_manager.dart`，封装 flutter_secure_storage（详见 references/transform-secure-storage.md）。

将硬编码 API Key / Token 迁移到 SecureStorage 读取。

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查最新版
```

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| H2 | 无硬编码敏感数据 | `grep -rn "api_key\|sk-\|AIza\|password" lib/` | 零硬编码值 |
| H3 | 无散落 SharedPreferences 直接调用 | `grep -rn "SharedPreferences.getInstance" lib/` | 零残余 |

---

## [USAGE] 使用辅助

### SharedPreferences 常用操作（通过 PreferencesManager）

```dart
// 读取
final theme = ref.read(preferencesManagerProvider).getString('theme');
final isFirstLaunch = ref.read(preferencesManagerProvider).getBool('first_launch') ?? true;

// 写入
await ref.read(preferencesManagerProvider).setString('theme', 'dark');
await ref.read(preferencesManagerProvider).setBool('first_launch', false);
```

### SecureStorage 常用操作

```dart
// 存储敏感数据（API Token / 密码等）
await SecureStorageManager.write('api_token', token);

// 读取
final token = await SecureStorageManager.read('api_token');

// 删除
await SecureStorageManager.delete('api_token');
```

### 判断哪些数据该用 SharedPreferences vs SecureStorage

| 数据类型 | 存储方式 |
|---------|---------|
| 主题/语言/开关等用户偏好 | SharedPreferences（PreferencesManager） |
| 上次选择的 Tab、布局设置 | SharedPreferences |
| API Token / 密码 / 私钥 | flutter_secure_storage（SecureStorageManager） |
| 用户进度/收藏等跨设备数据 | DataManager（cs_framework，云同步） |

### 新增一个偏好设置键

1. 在 `PreferencesManager` 中添加对应的 getter/setter
2. 使用 `const String _keyXxx = 'xxx'` 定义键名常量，避免拼写错误
