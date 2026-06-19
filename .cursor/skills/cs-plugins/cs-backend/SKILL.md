# cs-backend 插件

Supabase 后台基础设施接入：认证（AuthManager）、配置下发（ConfigManager）、数据存储（DataManager）、推送通知。

**完整踩坑记录见** `references/integration-guide.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 读取 `pubspec.yaml`，检查是否已有 `cs_framework` 依赖
2. 检查 `lib/main.dart` 是否已有 `CsClient.initialize(`
3. 根据主机传入的 `cs_dir_exists` 参数决定引用方式：
   - `true` → 使用 `path: ../cs/cs_framework`
   - `false` → 使用 `git: url: https://github.com/bryanpeng-777/cs_framework.git ref: main`
4. 已完整接入（pubspec + CsClient.initialize 都存在）→ 跳过安装，进入 VERIFY

### 扫描 App 代码

读取以下文件，识别接入配置：
- `pubspec.yaml` → 获取 `name` 字段作为 `app_id`（转连字符格式）
- `lib/main.dart` → 检查 CsClient 初始化状态
- `lib/screens/` 或含 `static const` 的文件 → 候选应用配置（ConfigManager）
- 含 `SharedPreferences` 的文件 → 候选用户数据（DataManager）

### 方案确认（唯一等待用户的步骤）

展示两张表让用户确认：

**表 A：建议放后台的应用配置（ConfigManager）**
| key | 类型 | 默认值 | 来源 | 说明 |
|-----|------|--------|------|------|
| 从代码扫描中提取... |

**表 B：建议迁到云端的用户数据（DataManager）**
| 表名 | 字段列表 | 来源 | 是否迁移 |
|------|---------|------|---------|
| 从 SharedPreferences 扫描中提取... |

用户确认后立即执行，不再询问其他问题。

### 后台建设（全自动，需 Supabase MCP）

按顺序执行（每步先检查是否已存在，避免重复）：

1. **注册 App**：`register_app(app_id)`
2. **暴露 business schema**：
   ```sql
   ALTER ROLE authenticator SET pgrst.db_schemas TO 'public,business,graphql_public';
   NOTIFY pgrst, 'reload config';
   ```
3. **授权 business schema**：
   ```sql
   GRANT USAGE ON SCHEMA business TO anon, authenticated;
   GRANT ALL ON ALL TABLES IN SCHEMA business TO anon, authenticated;
   ALTER DEFAULT PRIVILEGES IN SCHEMA business GRANT ALL ON TABLES TO anon, authenticated;
   ```
4. **创建业务表**（按表 B 方案）：FK 必须指向 `auth.users(id)`，开启 RLS，创建 user_own + service_role 两个 policy
5. **刷新 schema cache**：`NOTIFY pgrst, 'reload schema'`
6. **写入初始配置**（按表 A 方案）：`update_config(app_id, key, type, value, environment: 'dev')`

### 客户端代码接入

**pubspec.yaml**：按前置检查确定的引用方式添加 cs_framework 依赖，并在 flutter.assets 添加 `assets/default_configs.json`

**assets/default_configs.json**：用表 A 的 key/defaultValue 生成离线兜底配置

**lib/main.dart**：在 `WidgetsFlutterBinding.ensureInitialized()` 后添加：
```dart
import 'package:flutter/foundation.dart';
import 'package:cs_framework/cs_framework.dart';

await CsClient.initialize(
  supabaseUrl: 'https://ljmkxoptnzimpompabsq.supabase.co',
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqbWt4b3B0bnppbXBvbXBhYnNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzgxMzIsImV4cCI6MjA5MTIxNDEzMn0.CUbc6E49wyt-9WV2978T5kvMsW7CkqUwKn1o_1xBrZw',
  appId: '<app_id>',
  environment: kReleaseMode ? CsEnvironment.prod : CsEnvironment.dev,
  urlScheme: 'mountain<app_id>',
  enablePushNotifications: false,
);
```

**登录守卫选择**（GoRouter redirect，必须明确选择）：
- `AuthManager.isLoggedIn` → 记住匿名登录，用户只需跳过一次
- `AuthManager.isEmailUser` → 每次冷启动显示登录页（邮箱用户自动登录）

若使用 `isEmailUser`，main() 中还需清除残留匿名 session：
```dart
if (AuthManager.isLoggedIn && AuthManager.isAnonymous) {
  await AuthManager.signOut();
}
```

**URL Scheme 配置**（命名规则：`mountain` + appId 小写去特殊字符）：
- iOS `Info.plist`：添加 `CFBundleURLTypes` 条目
- Android `AndroidManifest.xml`：添加 `intent-filter` with scheme

**修改 Provider/Screen**：将硬编码配置值替换为 `ConfigManager.getInt/getBool/getString` 异步读取，SharedPreferences 进度数据改为双写本地+云端

**运行**：`flutter pub get`

---

## [UPDATE] 更新步骤

### 版本对比

1. 读取 `.cs-plugins.json` 中的 `cs_commit`
2. 若本地有 cs/：`git -C ../cs/cs_framework log --oneline {cs_commit}..HEAD`
3. 若无本地 cs/：`git ls-remote <git_url> HEAD` 对比存储的 commit
4. 输出新 commit 列表，识别是否有 Breaking Change（查看 CHANGELOG.md 或 commit message）

### 迁移步骤

- 对照 cs_framework CHANGELOG 处理 API 变更
- 更新 `flutter pub get`

### 验证

执行 VERIFY 段落的所有检查点

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令/方法 | 期望 |
|----|--------|----------|------|
| A2 | cs_framework path 路径规范 | `grep "cs_framework:" pubspec.yaml` | 含 `path: ../cs/cs_framework`（若为本地引用） |
| E1 | CsClient 已初始化 | `grep -n "CsClient.initialize" lib/main.dart` | 有输出 |
| E2 | urlScheme 参数已配置 | `grep "urlScheme:" lib/main.dart` | 有输出 |
| E3 | iOS URL Scheme 已配置 | 读取 `ios/Runner/Info.plist` | 含 `mountain` 前缀 CFBundleURLSchemes |
| E4 | Android URL Scheme 已配置 | 读取 `android/.../AndroidManifest.xml` | 含 `mountain` 前缀 android:scheme |
| F1 | 登录页面文件存在 | `ls lib/**/login*.dart lib/**/auth*.dart` | 存在登录相关文件 |
| F2 | 使用 cs_ui 登录组件 | `grep -rn "CsLoginPage\|CsLoginForm" lib/` | 有输出（不接受自写登录表单） |
| F3 | 登录路由已注册 | 读取 `lib/router/app_router.dart` | 含登录路由（`/login` 或 loginPage） |

后台验证（需 Supabase MCP）：
- `app_configs` 已写入：`SELECT COUNT(*) FROM app_configs WHERE app_id='<id>'` > 0
- 业务表已存在：`SELECT table_name FROM information_schema.tables WHERE table_schema='business'`
- schema 权限正常：`SELECT has_schema_privilege('authenticated','business','USAGE')` = true

---

## [USAGE] 使用辅助

### 新增配置项

用户说「新增一个配置 xxx」：
1. 调用 cs-admin MCP：`update_config(app_id, 'xxx', type, default_value, environment: 'dev')`
2. 在 `assets/default_configs.json` 追加兜底值
3. 在代码中使用：`await ConfigManager.getXxx('xxx')`

### 新增业务表

用户说「新建一张表存 xxx」：
1. 设计表结构（id UUID / user_id UUID FK auth.users / 业务字段 / updated_at）
2. 执行 SQL 建表（开启 RLS + 两个 policy）
3. 刷新 schema cache
4. 在代码中通过 DataManager 访问

### DataManager 常用操作

```dart
// 查询
final rows = await DataManager.select('table_name');
final row = await DataManager.selectOne('table_name', filters: {'user_id': userId});

// 写入（upsert）
await DataManager.upsert('table_name', {'user_id': userId, 'field': value}, onConflict: 'user_id');

// 删除
await DataManager.delete('table_name', filters: {'id': id});
```

### ConfigManager 常用操作

```dart
final value = await ConfigManager.getInt('key_name');
final flag = await ConfigManager.getBool('feature_flag');
final text = await ConfigManager.getString('display_text');
```

### 认证相关

```dart
// 检查登录状态
AuthManager.isLoggedIn      // 有 session（含匿名）
AuthManager.isEmailUser     // 绑定邮箱的正式用户
AuthManager.isAnonymous     // 纯匿名用户

// 退出登录
await AuthManager.signOut();
```

### 常见报错速查

| 错误码 | 原因 | 解决 |
|--------|------|------|
| `PGRST106: Invalid schema: business` | business schema 未暴露 | 执行 INSTALL 的后台建设 Step 2 |
| `PGRST205: schema cache` | schema 暴露后未刷新缓存 | `NOTIFY pgrst, 'reload schema'` |
| `42501: permission denied for schema business` | 无 USAGE 权限 | 执行 INSTALL 的后台建设 Step 3 |
| `23503: FK constraint violates business.users` | FK 引用错误 | 改为 `REFERENCES auth.users(id)` |
| `default_configs.json 404` | assets 未声明 | pubspec.yaml 添加 assets 条目 |
