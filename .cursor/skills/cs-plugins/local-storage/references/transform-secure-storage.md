# flutter_secure_storage 接入与敏感数据改造规则

本文件供 `cs-stack-onboarding` Step 2-6（secure storage 接入）和 Step 3-I（敏感数据迁移）使用。

---

## 分工原则

三种本地存储的边界：

```
本地持久化数据
  ├── 敏感数据（API Key / Token / 密码 / 私钥等）
  │     └── → flutter_secure_storage（SecureStorageManager）
  ├── 简单类型 + 用户偏好（主题 / 语言 / 开关）
  │     └── → shared_preferences（PreferencesManager）
  └── 复杂对象 / 业务数据 / 缓存
        └── → cs_framework DataManager / Hive
```

### 典型 flutter_secure_storage 场景

| 数据 | 说明 |
|-----|-----|
| 第三方 API Key（OpenAI、地图、支付等） | 敏感凭证 |
| 非 Supabase 后端的 JWT / Access Token | 敏感凭证 |
| OAuth Refresh Token | 敏感凭证 |
| 用户密码（如需本地保存） | 敏感数据 |
| 加密密钥 / 私钥 | 敏感数据 |
| 设备绑定凭证 | 敏感数据 |

### 不适用场景

| 数据 | 原因 | 应使用 |
|-----|-----|------|
| Supabase Auth Session | cs_framework 自动管理，已安全存储 | cs_framework |
| 非敏感用户设置 | 无需加密 | shared_preferences |
| 大量结构化数据 | secure storage 不适合大数据量 | cs_framework DataManager |

---

## Step 接入-1：安装依赖

在 `pubspec.yaml` 的 `dependencies` 中添加：

```yaml
flutter_secure_storage: ^9.2.0
```

**iOS 额外配置**：在 `ios/Runner/Info.plist` 中确认 Keychain Sharing 未被禁用（默认不需要额外配置）。

**Android 额外配置**：`android/app/build.gradle` 中确认 `minSdkVersion >= 18`（flutter_secure_storage 最低要求）：

```groovy
defaultConfig {
    minSdkVersion 18
}
```

执行 `flutter pub get`。

---

## Step 接入-2：创建 SecureStorageManager

新建 `lib/storage/secure_storage_manager.dart`：

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_manager.g.dart';

class SecureStorageManager {
  final FlutterSecureStorage _storage;

  SecureStorageManager()
      : _storage = const FlutterSecureStorage(
          // iOS：使用 Keychain，App 卸载后数据默认保留
          // Android：使用 EncryptedSharedPreferences（API 23+）
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ── Keys ──────────────────────────────────────────────

  static const _keyOpenAiApiKey = 'openai_api_key';
  static const _keyCustomApiToken = 'custom_api_token';
  static const _keyRefreshToken = 'refresh_token';
  // 根据项目实际需求继续添加

  // ── OpenAI / 第三方 API Key ────────────────────────────

  Future<String?> getOpenAiApiKey() => _storage.read(key: _keyOpenAiApiKey);
  Future<void> setOpenAiApiKey(String key) =>
      _storage.write(key: _keyOpenAiApiKey, value: key);
  Future<void> deleteOpenAiApiKey() => _storage.delete(key: _keyOpenAiApiKey);

  // ── 自建后端 Token ─────────────────────────────────────

  Future<String?> getCustomApiToken() => _storage.read(key: _keyCustomApiToken);
  Future<void> setCustomApiToken(String token) =>
      _storage.write(key: _keyCustomApiToken, value: token);
  Future<void> deleteCustomApiToken() => _storage.delete(key: _keyCustomApiToken);

  // ── Refresh Token ──────────────────────────────────────

  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);
  Future<void> deleteRefreshToken() => _storage.delete(key: _keyRefreshToken);

  // ── Generic（兜底）────────────────────────────────────

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);

  /// 退出登录时清除所有用户相关凭证（不影响设备级凭证）
  Future<void> clearUserCredentials() async {
    await _storage.delete(key: _keyCustomApiToken);
    await _storage.delete(key: _keyRefreshToken);
    // 注意：_keyOpenAiApiKey 通常是设备/应用级配置，退出登录不清除
  }

  /// 完全清空（慎用，仅用于调试/重置场景）
  Future<void> clearAll() => _storage.deleteAll();
}

// ── Riverpod Provider ──────────────────────────────────

@Riverpod(keepAlive: true)
SecureStorageManager secureStorageManager(SecureStorageManagerRef ref) {
  return SecureStorageManager();
}
```

> **注意**：`SecureStorageManager` 无需异步初始化，可直接在 `Provider` 中同步创建，无需 `overrides`。

---

## Step 接入-3：接入 DioClient 的 AuthInterceptor（可选）

如果项目使用 Dio 调用自建后端，更新 `lib/network/dio_client.dart` 中的 `_AuthInterceptor`，从 SecureStorageManager 读取 Token：

```dart
// 在 DioClient 中注入 SecureStorageManager
class DioClient {
  final SecureStorageManager _secureStorage;

  DioClient({required SecureStorageManager secureStorage, String baseUrl = ''})
      : _secureStorage = secureStorage {
    // ...
    _dio.interceptors.add(_AuthInterceptor(_secureStorage));
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageManager _secureStorage;
  _AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getCustomApiToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// Riverpod Provider 更新（使用 @riverpod 注解）
@Riverpod(keepAlive: true)
DioClient dioClient(DioClientRef ref) {
  final secureStorage = ref.read(secureStorageManagerProvider);
  return DioClient(secureStorage: secureStorage, baseUrl: 'https://your-api.example.com');
}
```

---

## Step 3-I：敏感数据迁移

### 扫描目标

| 扫描模式 | 风险等级 | 改造动作 |
|---------|---------|---------|
| 代码中硬编码的 API Key 字符串（如 `'sk-...'`、`'AIza...'`） | 🔴 高危 | 移出代码，改从 SecureStorageManager 读取 |
| `SharedPreferences` 中存储含 `token` / `key` / `password` / `secret` 的 key | 🔴 高危 | 迁移到 SecureStorageManager |
| 明文写入本地文件的敏感字段 | 🟠 中危 | 迁移到 SecureStorageManager |
| 环境变量 / `.env` 文件中的 key 被直接打包进 App | 🟠 中危 | 改为运行时从 SecureStorageManager 或远端配置读取 |

### 硬编码 API Key 迁移

```dart
// Before（高危：key 直接暴露在代码中，会泄露到 Git）
const openAiApiKey = 'sk-xxxxxxxxxxxxxxxx';
final response = await dio.post('/chat', options: Options(
  headers: {'Authorization': 'Bearer $openAiApiKey'},
));

// After（运行时从 SecureStorage 读取）
final key = await ref.read(secureStorageManagerProvider).getOpenAiApiKey();
if (key == null) {
  // 引导用户在设置页输入并保存 API Key
  return;
}
final response = await ref.read(dioClientProvider).post('/chat');
// Token 注入由 _AuthInterceptor 统一处理
```

**首次设置 API Key 的 UI 流程**（设置页示例）：

```dart
// 设置页：用户输入后保存到 SecureStorage
ElevatedButton(
  onPressed: () async {
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) {
      await ref.read(secureStorageManagerProvider).setOpenAiApiKey(key);
      // 提示保存成功
    }
  },
  child: const Text('保存 API Key'),
)
```

### SharedPreferences 敏感 key 迁移

```dart
// Before（不安全：SharedPreferences 未加密）
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', token);
final token = prefs.getString('auth_token');

// After
final storage = ref.read(secureStorageManagerProvider);
await storage.setCustomApiToken(token);
final token = await storage.getCustomApiToken();
```

### 退出登录时清理凭证

```dart
// 退出登录时
Future<void> logout() async {
  // 清除 Supabase session（cs_framework 处理）
  await CsClient.signOut();

  // 清除本地敏感凭证
  await ref.read(secureStorageManagerProvider).clearUserCredentials();

  // 清除用户偏好（可选）
  // ref.read(preferencesManagerProvider).clear();

  // 跳转登录页
  context.go('/login');
}
```

---

## 常见踩坑

### Android 卸载后数据残留
- `EncryptedSharedPreferences` 在 Android 上 App 卸载后数据会被清除（与 iOS Keychain 不同）
- 如需跨安装保留（如设备绑定凭证），需配合服务端逻辑

### iOS 模拟器 Keychain 问题
- 部分 iOS 模拟器版本 Keychain 访问可能报错
- 解法：在模拟器的 `Device > Erase All Content and Settings` 后重试，或在真机测试

### 不要在 `const` 中使用
- `FlutterSecureStorage` 的读取是异步的，不能用于 `const` 初始化或 `initState` 的同步部分
- 需要在 `initState` 中用 `Future.microtask`，或直接在 `ConsumerWidget.build` 中通过 `@riverpod` 异步 provider 读取

### @riverpod 异步读取示例

```dart
@riverpod
Future<String?> apiKey(ApiKeyRef ref) async {
  return ref.read(secureStorageManagerProvider).getOpenAiApiKey();
}

// Widget 中
final apiKeyAsync = ref.watch(apiKeyProvider);
return apiKeyAsync.when(
  data: (key) => key != null ? const Text('已配置') : const Text('未配置'),
  loading: () => const CircularProgressIndicator(),
  error: (_, __) => const Text('读取失败'),
);
```
