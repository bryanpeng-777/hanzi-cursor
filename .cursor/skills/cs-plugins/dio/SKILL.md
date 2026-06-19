# dio 插件

Dio HTTP 客户端接入：替代 http 包，提供拦截器、统一错误处理、文件上传下载。

**详细改造规则见** `references/transform-dio.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 dio 依赖
2. 扫描 `http` 包使用情况（需迁移）：`grep -rn "import 'package:http" lib/`
3. 统计散落的 `http.get` / `http.post` 调用数量

### 添加依赖

```yaml
dependencies:
  dio: ^5.7.0
```

运行 `flutter pub get`

### 初始化 DioClient（读取 references/transform-dio.md 的 Step 3-G 执行）

新建 `lib/services/dio_client.dart`：
```dart
import 'package:dio/dio.dart';

class DioClient {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ))..interceptors.addAll([
    LogInterceptor(requestBody: true, responseBody: true),
    _ErrorInterceptor(),
  ]);

  static Future<Response> get(String url, {Map<String, dynamic>? queryParams}) =>
      _dio.get(url, queryParameters: queryParams);

  static Future<Response> post(String url, {dynamic data}) =>
      _dio.post(url, data: data);
}
```

### 迁移 http 包调用

- Supabase URL → 改用 `DataManager`（cs_framework 已处理）
- 其他 URL → 改用 `DioClient`
- 完成后删除 pubspec.yaml 中的 `http:` 依赖

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查 dio 最新版
```

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| N1 | 无 http 包残余依赖 | `grep "http:" pubspec.yaml` | 零残余 |
| N2 | dio_client.dart 已创建 | `ls lib/services/dio_client.dart` | 文件存在 |

---

## [USAGE] 使用辅助

### 发起 GET 请求

```dart
final response = await DioClient.get(
  'https://api.example.com/items',
  queryParams: {'page': 1, 'limit': 20},
);
final items = (response.data['data'] as List).map((e) => Item.fromJson(e)).toList();
```

### 发起 POST 请求

```dart
final response = await DioClient.post(
  'https://api.example.com/items',
  data: {'title': '新任务', 'completed': false},
);
```

### 添加 Auth Token 拦截器

```dart
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = SecureStorageManager.read('api_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}
```

### 统一错误处理

```dart
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message = switch (err.type) {
      DioExceptionType.connectionTimeout => '连接超时',
      DioExceptionType.receiveTimeout => '响应超时',
      DioExceptionType.badResponse => '服务器错误 ${err.response?.statusCode}',
      _ => '网络错误',
    };
    appLogger.e('DioClient error: $message', error: err);
    handler.next(err);
  }
}
```

### 文件上传

```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(filePath, filename: 'upload.jpg'),
});
await DioClient._dio.post('/upload', data: formData);
```
