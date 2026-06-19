# Dio 接入与 HTTP 迁移规则

本文件供 `cs-stack-onboarding` Step 2-4（Dio 接入）和 Step 3-G（http 包迁移）使用。

---

## 分工原则

```
请求目标是 Supabase（supabase.co URL / Supabase 表 / Auth / Storage / Realtime）？
  ├── 是 → cs_framework DataManager / ConfigManager（不用 Dio）
  └── 否 → DioClient（第三方 API / 自建后端）
```

**Supabase Storage** 统一走 Supabase SDK，不用 Dio。

---

## Step 接入-1：安装 Dio

在 `pubspec.yaml` 的 `dependencies` 中添加：

```yaml
dio: ^5.7.0
```

执行 `flutter pub get`。

---

## Step 接入-2：创建 DioClient

新建 `lib/network/dio_client.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/app_logger.dart';

part 'dio_client.g.dart';

class DioClient {
  late final Dio _dio;

  DioClient({String baseUrl = '', Map<String, dynamic>? headers}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _AuthInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? params}) =>
      _dio.get<T>(path, queryParameters: params);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  Future<Response> download(String url, String savePath,
      {ProgressCallback? onReceiveProgress}) =>
      _dio.download(url, savePath, onReceiveProgress: onReceiveProgress);
}

// ── Interceptors ──────────────────────────────────────────

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    appLogger.d('[Dio] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    appLogger.d('[Dio] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    appLogger.e('[Dio] Error: ${err.message}', error: err);
    handler.next(err);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 在此注入非 Supabase 接口所需的 token（如自建后端的 JWT）
    // 若已接入 flutter_secure_storage，可从构造注入的 SecureStorageManager 读取：
    // final token = await secureStorageManager.getCustomApiToken();
    // if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    switch (statusCode) {
      case 401:
        appLogger.w('[Dio] 401 Unauthorized — token 可能已过期');
        break;
      case 429:
        appLogger.w('[Dio] 429 Too Many Requests — 触发限流');
        break;
    }
    handler.next(err);
  }
}

// ── Riverpod Provider（@riverpod 注解 + keepAlive 全局单例）─────

@Riverpod(keepAlive: true)
DioClient dioClient(DioClientRef ref) {
  return DioClient(
    baseUrl: 'https://your-api.example.com', // 替换为实际 baseUrl
  );
}
```

---

## Step 接入-3：确认 baseUrl

询问用户项目的非 Supabase 后端 baseUrl（如没有则留空，后续按需填写）：

```
DioClient 已创建。请提供非 Supabase 接口的 baseUrl（如 https://api.example.com），
若暂时没有可先留空，后续在 dioClientProvider 中填写。
```

---

## Step 3-G：http 包迁移

### 扫描目标

扫描所有 `.dart` 文件中的 `http` 包用法：

```bash
# 识别 http 包导入
rg -n "package:http/http\.dart" lib/

# 识别具体调用
rg -n "http\.(get|post|put|delete|patch)" lib/
```

### 分类判断规则

对每处 `http.*` 调用，检查其 URL：

| URL 特征 | 分类 | 迁移目标 |
|---------|-----|---------|
| 含 `supabase.co` | Supabase 直连 | `DataManager` |
| 含 Supabase 表名路径（如 `/rest/v1/users`） | Supabase REST | `DataManager` |
| 含 `/auth/v1/` | Supabase Auth | Supabase Auth SDK |
| 其他 URL | 第三方/自建 | `DioClient` |

### 迁移示例

#### http → DataManager（Supabase 调用）

```dart
// Before
import 'package:http/http.dart' as http;

final response = await http.get(
  Uri.parse('https://xxx.supabase.co/rest/v1/users'),
  headers: {'apikey': '...', 'Authorization': 'Bearer ...'},
);
final data = jsonDecode(response.body);

// After（使用 cs_framework DataManager）
// DataManager 底层复用 cs_framework 的 Supabase client，自动处理 Auth
final data = await DataManager.shared.read(table: 'users');
```

#### http → DioClient（第三方/自建 API）

```dart
// Before
import 'package:http/http.dart' as http;

final response = await http.post(
  Uri.parse('https://api.openai.com/v1/chat/completions'),
  headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
  body: jsonEncode({'model': 'gpt-4', 'messages': [...]}),
);

// After（使用 DioClient）
final dio = ref.read(dioClientProvider);
final response = await dio.post(
  '/chat/completions',
  data: {'model': 'gpt-4', 'messages': [...]},
);
// 注：apiKey 等敏感信息通过 _AuthInterceptor 统一注入，无需每次传
```

#### http.MultipartRequest → Dio（文件上传，非 Supabase Storage）

```dart
// Before
final request = http.MultipartRequest('POST', Uri.parse(url));
request.files.add(await http.MultipartFile.fromPath('file', filePath));
final response = await request.send();

// After（Dio 支持原生 FormData）
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath),
});
final response = await ref.read(dioClientProvider).post('/upload', data: formData);
```

### 清理 http 包

全部迁移完成后：

1. 检查是否还有 `import 'package:http/http.dart'` 残留
2. 无残留则从 `pubspec.yaml` 中删除 `http:` 依赖
3. 执行 `flutter pub get` 确认无错

---

## 常见踩坑

### DioException 类型判断

```dart
try {
  final response = await dio.get('/api/data');
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    // 连接超时
  } else if (e.type == DioExceptionType.receiveTimeout) {
    // 接收超时
  } else if (e.response != null) {
    // 服务器返回了错误状态码
    final statusCode = e.response!.statusCode;
  }
}
```

### 不要用 Dio 调用 Supabase

Supabase SDK 内部已做了认证、重试、Realtime 等处理，绕过 SDK 直接用 Dio 调用 Supabase 会丢失这些能力，且 Auth token 需要手动管理。

### baseUrl 动态配置

若需要从 cs_framework ConfigManager 读取 baseUrl（支持远程动态配置）：

```dart
@Riverpod(keepAlive: true)
DioClient dioClient(DioClientRef ref) {
  final baseUrl = ConfigManager.shared.getString('api_base_url') 
      ?? 'https://your-api.example.com';
  return DioClient(baseUrl: baseUrl);
}
```
