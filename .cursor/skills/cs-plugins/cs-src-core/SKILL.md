# cs-src-core 插件

CS 框架核心基座接入：Supabase 连接（CsClient）、配置下发（ConfigManager）、业务数据 CRUD（DataManager）、文件存储（StorageManager）。

---

## [INSTALL] 安装步骤

### 前置检查

1. 读取 `pubspec.yaml`，检查是否已有 `cs_core` 依赖
2. 检查 `lib/main.dart` 是否已有 `CsClient.initialize(`
3. 根据 `cs_dir_exists` 参数决定引用方式：
   - `true` → 使用 `path: ../cs/cs_core`
   - `false` → 使用 git monorepo 引用（`url: https://github.com/bryanpeng-777/cs.git path: cs_core ref: main`）
4. 已完整接入 → 跳过安装，进入 VERIFY

### 修改 pubspec.yaml

**本地（monorepo 开发模式）：**
```yaml
dependencies:
  cs_core:
    path: ../cs/cs_core
```

**远程（git monorepo）：**
```yaml
dependencies:
  cs_core:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_core
      ref: main
```

### 修改 lib/main.dart

在 `runApp` 之前添加初始化调用：

```dart
import 'package:cs_core/cs_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CsClient.initialize(
    supabaseUrl: 'https://YOUR_PROJECT.supabase.co',
    supabaseAnonKey: 'YOUR_ANON_KEY',
    appId: 'your-app-id',
    environment: CsEnvironment.dev, // 开发时用 dev，上线改为 prod
  );

  runApp(const MyApp());
}
```

### 可选：创建 assets/default_configs.json

在项目 `assets/` 目录创建离线兜底配置文件：
```json
{
  "_comment": "离线兜底默认配置",
  "_version": "1.0.0"
}
```

并在 `pubspec.yaml` flutter.assets 中声明：
```yaml
flutter:
  assets:
    - assets/default_configs.json
```

---

## [UPDATE] 更新步骤

1. 查看 `cs/cs_core/pubspec.yaml` 中的 `version` 字段
2. 比对当前项目引用的 commit hash（git 模式下）
3. 如使用 path 引用，直接 `flutter pub get` 即可获取最新变更
4. 如使用 git 引用，可更新 `ref` 到最新 commit hash 后运行 `flutter pub get`

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| E1 | `pubspec.yaml` 包含 cs_core 依赖 | grep `cs_core:` |
| E2 | `lib/main.dart` 包含 CsClient.initialize | grep `CsClient.initialize` |
| E3 | flutter pub get 无报错 | 运行 `flutter pub get` 成功 |

---

## [USAGE] 常用 API 示例

### CsClient 初始化
```dart
await CsClient.initialize(
  supabaseUrl: 'https://xxx.supabase.co',
  supabaseAnonKey: 'your-key',
  appId: 'my-app',
  environment: CsEnvironment.prod,
);
```

### ConfigManager 配置读取
```dart
final bannerUrl = await ConfigManager.getString('home_banner_image');
final isEnabled = await ConfigManager.getBool('feature_new_ui') ?? false;
```

### DataManager 数据操作
```dart
// 插入
await DataManager.insert('my_favorites', {'item_id': 'item_001'});

// 查询
final list = await DataManager.select('my_favorites',
  orderBy: 'created_at', ascending: false, limit: 20);

// 删除
await DataManager.delete('my_favorites', match: {'item_id': 'item_001'});
```

### StorageManager 文件上传
```dart
final url = await StorageManager.uploadUserFile(
  file,
  contentType: 'image/png',
);
```

### 常见问题排查

- **Supabase 连接超时**：检查 `supabaseUrl` 是否正确，项目是否已激活
- **ConfigManager 无数据**：确认 Supabase `app_configs` 表中有对应 `app_id` 的记录
- **DataManager RLS 报错**：检查 `business` schema 的 RLS policy 是否正确配置
