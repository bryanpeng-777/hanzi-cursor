---
name: cs-framework-onboarding
description: 【已废弃 · 计划 2026-06-30 删除】原后台框架接入技能。逻辑已迁移到 cs-plugins/cs-backend 插件，请通过 cs-plugin-host 安装 cs-backend 插件代替。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：逻辑已完整迁移到 `~/.claude/skills/cs-plugins/cs-backend/SKILL.md`
>
> **新接入方式**：说「接入 cs 框架」→ 选择 cs-backend 插件 → cs-backend-plugin subAgent 执行
>
> **此文件保留供老项目参考，计划于 2026-06-30 删除。**

---

# cs-framework-onboarding

帮助新的 Flutter App 以最小成本接入 cs_framework 后台基础设施，获得配置下发、认证、数据存储、推送通知等能力。全流程 AI 自动完成，用户只需在 Step 1 确认一次业务表方案即可。

## 参考文档

- `references/integration-guide.md` — 完整踩坑记录（schema 暴露、权限授予、FK 指向 auth.users 等）

---

## 框架背景

**技术栈**：
- 后端：Supabase（PostgreSQL + RLS），新加坡节点
- 客户端 SDK：`cs_framework`（Flutter/Dart）
- 管理接口：cs-admin MCP Server（Railway 部署）

**已知固定参数**（直接使用，无需询问用户）：
```
Supabase URL:      https://ljmkxoptnzimpompabsq.supabase.co
Supabase Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqbWt4b3B0bnppbXBvbXBhYnNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzgxMzIsImV4cCI6MjA5MTIxNDEzMn0.CUbc6E49wyt-9WV2978T5kvMsW7CkqUwKn1o_1xBrZw
SDK Git URL:       https://github.com/bryanpeng-777/cs_framework.git
MCP Server:        https://csinfra-production.up.railway.app
```

---

## 总流程

```
Step 0: 扫描 App 代码（自动）
  ↓
Step 1: 输出配置表 + 数据表方案 → 等待用户确认（唯一人工步骤）
  ↓
Step 2: 后台一键建设（全自动 MCP）
  ↓
Step 3: 客户端代码接入（全自动编辑文件）
  ↓
Step 4: 自动化验证（注入测试代码 → flutter run → 监控日志 → 清理）
```

---

## Step 0：扫描 App 代码

**无需询问用户，直接扫描当前工作区。**

读取以下文件：

1. `pubspec.yaml` — 检查是否已有 cs_framework 依赖、已有哪些 assets 声明
2. `lib/main.dart` — 检查是否已有 CsClient.initialize
3. `lib/providers/` 或含 `SharedPreferences` 的文件 — 识别本地存储的用户数据字段
4. `lib/screens/` — 识别硬编码的配置值（数值常量、功能开关、`const` 参数等）

**扫描目标**：
- 找出所有 `static const` / 硬编码魔法数 → 候选应用配置（ConfigManager）
- 找出所有 SharedPreferences 键值 → 候选用户数据（DataManager）
- 判断 App ID（取 `pubspec.yaml` 的 `name` 字段，转为连字符格式）

---

## Step 1：输出方案，等待用户确认

**此步骤必须等待用户确认，不可跳过。**

展示两张表：

### 表 A：建议放后台的应用配置（ConfigManager）

| key | 类型 | 默认值 | 来源文件:行号 | 说明 |
|-----|------|--------|-------------|------|
| `enable_xxx` | bool | false | `game_screen.dart:59` | 功能开关 |
| `quiz_time_limit_seconds` | int | 6 | `hanzi_quiz_screen.dart:46` | 每题限时 |
| ... | ... | ... | ... | ... |

> 规则：全局不变的魔法数（数值阈值、开关、题目数量等）放这里；纯 UI 样式常量（颜色、圆角、动画时长）不放。

### 表 B：建议迁到云端的用户数据（DataManager）

| 表名（建议） | 字段列表 | 来源 | 是否迁移 |
|------------|---------|------|---------|
| `{app_id}_user_progress` | total_stars, streak, passed_levels, mistakes... | `LearningProvider` | 建议迁移 |

> 规则：跨设备需要同步的用户进度、收藏、偏好设置放这里；纯本地的临时状态不放。

```
以上是我的接入方案建议，请确认或修改：
- 说「确认」直接执行
- 说「去掉 XXX」可删除某条配置
- 说「表 B 不要」可跳过用户数据云同步
- 说「修改 YYY 的默认值为 ZZZ」可调整
```

**用户确认后立即进入 Step 2，不再询问其他问题。**

---

## Step 2：后台一键建设（全自动）

按以下顺序执行，每步完成后继续下一步，不需要用户确认：

### 2-A. 注册 App（cs-admin MCP）

```
register_app(app_id: '<app_id>')
```

### 2-B. 暴露 business schema（Supabase MCP apply_migration）

**先检查是否已暴露**，避免重复执行：

```sql
-- 检查：查询 business schema 下是否有表可见
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'business';
```

若未暴露，执行：

```sql
ALTER ROLE authenticator SET pgrst.db_schemas TO 'public,business,graphql_public';
NOTIFY pgrst, 'reload config';
```

### 2-C. 授权 business schema（Supabase MCP apply_migration）

**先检查是否已授权**：

```sql
SELECT has_schema_privilege('authenticated', 'business', 'USAGE') AS has_usage;
```

若返回 `false`，执行：

```sql
GRANT USAGE ON SCHEMA business TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA business TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA business GRANT ALL ON TABLES TO anon, authenticated;
```

### 2-D. 创建业务表（Supabase MCP apply_migration，每张表一次调用）

按 Step 1 表 B 确认的方案建表。**关键规范**：

- FK 必须指向 `auth.users(id)`，**不得引用 `business.users(id)`**（AuthManager 目前无法自动同步 business.users，会导致 FK 约束报错）
- 开启 RLS
- 创建 user 隔离 policy：`FOR ALL USING (auth.uid() = user_id)`
- 创建 service_role 全访问 policy

模板：
```sql
CREATE TABLE IF NOT EXISTS business.{app_id}_{entity} (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- 业务字段...
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_{app_id}_user UNIQUE (user_id)
);
ALTER TABLE business.{app_id}_{entity} ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_own_{app_id}_{entity}" ON business.{app_id}_{entity}
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "service_role_{app_id}_{entity}" ON business.{app_id}_{entity}
  FOR ALL USING (auth.role() = 'service_role');
```

### 2-E. 刷新 schema cache

```sql
NOTIFY pgrst, 'reload schema';
```

### 2-F. 写入初始 app_configs（cs-admin MCP）

将表 A 所有配置写入 dev 环境：

```
update_config(app_id, config_key, config_type, value, environment: 'dev')
```

可并行执行多条。

---

## Step 3：客户端代码接入（全自动编辑文件）

### 3-A. pubspec.yaml

添加 cs_framework 依赖：
```yaml
cs_framework:
  git:
    url: https://github.com/bryanpeng-777/cs_framework.git
    ref: main
```

在 flutter assets 中添加：
```yaml
- assets/default_configs.json
```

### 3-B. assets/default_configs.json

用表 A 的 key/defaultValue 生成离线兜底配置：
```json
{
  "_comment": "离线兜底配置，网络不可用时生效",
  "<key1>": <default_value1>,
  "<key2>": <default_value2>
}
```

### 3-C. lib/main.dart

在 `WidgetsFlutterBinding.ensureInitialized()` 之后添加初始化：
```dart
import 'package:flutter/foundation.dart';
import 'package:cs_framework/cs_framework.dart';

await CsClient.initialize(
  supabaseUrl: 'https://ljmkxoptnzimpompabsq.supabase.co',
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  appId: '<app_id>',
  environment: kReleaseMode ? CsEnvironment.prod : CsEnvironment.dev,
  enablePushNotifications: false,
);
```

---

### ⚠️ 关键设计决策：登录页守卫条件（接入后必须明确选择）

`CsClient.initialize()` 完成后，Supabase 会自动恢复本地 session（包括匿名 session）。
在配置 GoRouter `redirect` 时，**守卫条件的选择决定了用户看不看到登录页**。

**AuthManager 提供两个不同语义的属性：**

| 属性 | 含义 | 包含匿名用户？ |
|---|---|---|
| `AuthManager.isLoggedIn` | 有 session（匿名或邮箱） | ✅ 包含 |
| `AuthManager.isEmailUser` | 绑定邮箱的正式用户 | ❌ 不含 |

**产品意图 → 选择守卫条件：**

| 产品需求 | 守卫条件 | 效果 |
|---|---|---|
| 「跳过后永久记住，不再显示登录页」（大多数内容 App） | `AuthManager.isLoggedIn` | 匿名 session 跨冷启动保留，用户只跳过一次 |
| 「每次冷启动都显示登录页，但邮箱用户自动登录」（Demo / 强登录 App） | `AuthManager.isEmailUser` | 匿名用户每次冷启动都见登录页 |

**使用 `isEmailUser` 时，main() 中还需要一行清除残留匿名 session：**
```dart
// 邮箱用户保留 session，匿名用户冷启动清除（确保见到登录页）
if (AuthManager.isLoggedIn && AuthManager.isAnonymous) {
  await AuthManager.signOut();
}
```

**GoRouter redirect 模板（根据上表选择 isLoggedIn 或 isEmailUser）：**
```dart
redirect: (context, state) {
  final isLoginRoute = state.matchedLocation == '/';

  // 根据产品需求选一个：
  final isAuthenticated = AuthManager.isLoggedIn;  // 方案A：记住匿名
  // final isAuthenticated = AuthManager.isEmailUser; // 方案B：每次见登录页

  if (!isAuthenticated && !isLoginRoute) return '/';
  if (isAuthenticated && isLoginRoute) return '/home';
  return null;
},
```

> **注意**：不能不加思考直接用 `isLoggedIn`。用错会导致「用户点过跳过之后永远不再看到登录页」的隐性 Bug，且 flutter analyze 不会报错，只有运行时才能发现。

### 3-D. 修改 Screen/Provider 读取配置和同步用户数据

- 将表 A 中每个 key 对应的硬编码值替换为 `ConfigManager.getInt/getBool/getString` 异步读取
- 将表 B 中的 Provider `loadProgress`/`saveProgress` 改为优先从云端读，双写本地+云端
- 迁移策略：云端有数据用云端；云端空但本地有数据则一次性上传

### 3-E. 运行 flutter pub get

```bash
flutter pub get
```

---

## Step 4：自动化验证

**全程 AI 自动完成，不需要用户操作。**

### 4-A. 后台验证（Supabase MCP，秒级）

| 检查项 | SQL | 期望 |
|--------|-----|------|
| app_configs 已写入 | `SELECT COUNT(*) FROM app_configs WHERE app_id='<id>'` | > 0 |
| 业务表已存在 | `SELECT table_name FROM information_schema.tables WHERE table_schema='business' AND table_name LIKE '<app_id>%'` | 返回表名 |
| schema 权限正常 | `SELECT has_schema_privilege('authenticated','business','USAGE')` | true |

### 4-B. 客户端验证（注入测试代码 → flutter run → 监控日志 → 清理）

**Step 4-B-1：注入临时验证函数**

在 `main.dart` 的 `CsClient.initialize()` 之后注入（用特殊注释标记，方便后续删除）：

```dart
// [CS_VALIDATE_BEGIN]
await _csFrameworkValidate();
// [CS_VALIDATE_END]
```

在文件末尾添加：

```dart
// [CS_VALIDATE_FN_BEGIN]
Future<void> _csFrameworkValidate() async {
  try {
    // 1. 验证 ConfigManager 读取
    final cfgVal = await ConfigManager.getInt('cs_validate_ping');
    debugPrint('[CS_VALIDATE] ConfigManager: ${cfgVal == 42 ? "OK" : "NO_DATA(可接受)"}');

    // 2. 验证 DataManager 写入+读取
    final userId = CsClient.supabase.auth.currentUser?.id;
    if (userId != null) {
      await DataManager.upsert(
        'cs_validate',
        {'user_id': userId, 'ping': 'ok'},
        onConflict: 'user_id',
      );
      final row = await DataManager.selectOne('cs_validate');
      debugPrint('[CS_VALIDATE] DataManager write: OK');
      debugPrint('[CS_VALIDATE] DataManager read: ${row != null ? "OK" : "FAIL"}');
    } else {
      debugPrint('[CS_VALIDATE] DataManager: SKIP (no user yet)');
    }
    debugPrint('[CS_VALIDATE] ALL_DONE');
  } catch (e) {
    debugPrint('[CS_VALIDATE] ERROR: $e');
  }
}
// [CS_VALIDATE_FN_END]
```

同时，在 Supabase 后台建一张临时验证表（apply_migration）：

```sql
CREATE TABLE IF NOT EXISTS business.cs_validate (
  id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ping    TEXT DEFAULT 'ok',
  CONSTRAINT uq_cs_validate_user UNIQUE (user_id)
);
ALTER TABLE business.cs_validate ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_own_cs_validate" ON business.cs_validate
  FOR ALL USING (auth.uid() = user_id);
```

同时写入一条 cs-admin 配置用于 ConfigManager 验证：

```
update_config(app_id, 'cs_validate_ping', 'custom', 42, environment: 'dev')
```

**Step 4-B-2：后台启动 flutter run，监控日志**

```bash
flutter run -d chrome --web-port <空闲端口> 2>&1
```

等待以下关键日志（超时 90 秒）：

| 日志关键词 | 含义 |
|-----------|------|
| `Supabase init completed` | Supabase 连接正常 |
| `[AuthManager] 匿名登录成功` | 认证正常 |
| `[ConfigManager] 全量同步完成，共 N 条配置` | 配置下发正常 |
| `[CS_VALIDATE] DataManager read: OK` | 用户数据读写正常 |
| `[CS_VALIDATE] ALL_DONE` | 全部验证完成 |
| `[CS_VALIDATE] ERROR:` | 验证失败，需诊断 |

**Step 4-B-3：输出验证报告**

```
验证结果（<app_id>）：
✅ Supabase 连接正常
✅ 匿名认证成功（userId: xxx）
✅ ConfigManager 同步 N 条配置
✅ DataManager 写入正常
✅ DataManager 读取正常

接入完成！
```

若有失败项，根据日志自动诊断（参考 references/integration-guide.md 的踩坑记录），修复后重新验证。

**Step 4-B-4：清理**

验证通过后：
1. 杀掉 flutter run 进程
2. 删除 main.dart 中 `[CS_VALIDATE_BEGIN]...[CS_VALIDATE_END]` 和 `[CS_VALIDATE_FN_BEGIN]...[CS_VALIDATE_FN_END]` 之间的代码
3. 删除 Supabase 中的 `cs_validate_ping` 配置（cs-admin MCP delete_config）
4. 删除 `business.cs_validate` 表（Supabase MCP execute_sql `DROP TABLE IF EXISTS business.cs_validate`）

---

## 已知踩坑（快速参考）

完整踩坑详情见 `references/integration-guide.md`，高频问题速查：

| 错误码 | 原因 | 解决方案 |
|--------|------|---------|
| `PGRST106: Invalid schema: business` | business schema 未暴露给 PostgREST | Step 2-B |
| `PGRST205: schema cache` | schema 暴露后未刷新缓存 | `NOTIFY pgrst, 'reload schema'` |
| `42501: permission denied for schema business` | anon/authenticated 无 USAGE 权限 | Step 2-C |
| `23503: FK constraint violates business.users` | 表 FK 错误地引用了 business.users | 改为 `REFERENCES auth.users(id)` |
| `default_configs.json 404` | assets 未声明 | pubspec.yaml 添加 assets 条目 |

---

## 后续管理（接入完成后随时可让 AI 做）

- **新增/修改配置**：`update_config(app_id, key, value)`
- **开关功能**：`toggle_feature_flag(app_id, key)`
- **查看配置历史**：`view_audit_log(app_id)`
- **回滚配置**：`rollback_config(app_id, key, version)`
- **发布到 prod**：`promote_to_prod(app_id)`
