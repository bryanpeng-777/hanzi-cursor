# cs-src-auth 插件

CS 框架认证模块接入：AuthManager（匿名/邮箱登录、账号升级、密码重置）+ AuthGuard 路由守卫。

**依赖**：cs-src-core（必须先安装）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-src-core 已安装（`pubspec.yaml` 中有 `cs_core:` 依赖）
2. 检查 `pubspec.yaml` 是否已有 `cs_auth:` 依赖
3. 已完整接入 → 跳过安装，进入 VERIFY

### 修改 pubspec.yaml

**本地（monorepo 开发模式）：**
```yaml
dependencies:
  cs_auth:
    path: ../cs/cs_auth
```

**远程（git monorepo）：**
```yaml
dependencies:
  cs_auth:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_auth
      ref: main
```

### 初始化

在 `CsClient.initialize()` 之后调用：

```dart
import 'package:cs_auth/cs_auth.dart';

// 在 main.dart 中
await CsClient.initialize(...);
await AuthManager.initialize(); // 恢复已有 session，不自动创建匿名账号
```

---

## [UPDATE] 更新步骤

1. 查看 `cs/cs_auth/pubspec.yaml` version 字段
2. path 引用模式下 `flutter pub get` 即可获取最新

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| E4 | `pubspec.yaml` 包含 cs_auth 依赖 | grep `cs_auth:` |
| E5 | 代码中调用 `AuthManager.initialize()` | grep `AuthManager.initialize` |

---

## [USAGE] 常用 API 示例

### 匿名登录（跳过登录）
```dart
final response = await AuthManager.signInAnonymously();
print('匿名用户 ID: ${response.user?.id}');
```

### 邮箱注册
```dart
final response = await AuthManager.signUpWithEmail(email, password);
// 注册后会发送确认邮件（6位 OTP 验证码）
final otpResponse = await AuthManager.verifyEmailOtp(email, otpCode);
```

### 邮箱登录
```dart
final response = await AuthManager.signInWithEmail(email, password);
```

### 匿名账号升级（保留历史数据）
```dart
await AuthManager.linkWithEmail(email, password);
```

### 当前用户状态
```dart
final isLoggedIn = AuthManager.isLoggedIn;     // 含匿名
final isAnonymous = AuthManager.isAnonymous;
final isEmailUser = AuthManager.isEmailUser;   // 邮箱账号
final userId = AuthManager.currentUserId;
```

### AuthGuard 路由守卫（go_router）
```dart
GoRouter(
  redirect: AuthGuard.requireAnySession, // 未登录跳 /login
  routes: [...],
)

// 某个路由只允许邮箱用户访问
GoRoute(
  path: '/profile',
  redirect: AuthGuard.requireEmailUser,
)
```

### 常见问题排查

- **匿名登录失败**：检查 Supabase dashboard → Authentication → Settings → Anonymous sign-ins 是否开启
- **OTP 无效**：确认 Supabase dashboard → Authentication → Email 模板已配置
