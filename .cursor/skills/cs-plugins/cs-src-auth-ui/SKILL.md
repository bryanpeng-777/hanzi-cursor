# cs-src-auth-ui 插件

CS 框架登录 UI 组件：CsLoginPage（完整登录页）+ CsLoginForm（可嵌入表单积木）+ 密码找回/重置流程。

**依赖**：cs-src-auth + cs-src-ui（必须先安装）

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-src-auth 和 cs-src-ui 已安装
2. 检查 `pubspec.yaml` 是否已有 `cs_auth_ui:` 依赖

### 修改 pubspec.yaml

**本地模式：**
```yaml
dependencies:
  cs_auth_ui:
    path: ../cs/cs_auth_ui
```

**远程模式：**
```yaml
dependencies:
  cs_auth_ui:
    git:
      url: https://github.com/bryanpeng-777/cs.git
      path: cs_auth_ui
      ref: main
```

### 在路由中注册登录页

```dart
import 'package:cs_auth_ui/cs_auth_ui.dart';

GoRouter(
  redirect: (context, state) {
    final needsLogin = !AuthManager.isLoggedIn && state.uri.path != '/login';
    return needsLogin ? '/login' : null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, state) => CsLoginPage(
        onLoginSuccess: () => context.go('/home'),
        onSkip: () => context.go('/home'),        // 匿名登录后跳转
        redirectPath: state.uri.queryParameters['redirect'],
      ),
    ),
  ],
)
```

---

## [UPDATE] 更新步骤

`flutter pub get` 获取最新版本。

---

## [VERIFY] 验证要点

| ID | 检查项 | 通过条件 |
|----|--------|---------|
| G4 | `pubspec.yaml` 包含 cs_auth_ui 依赖 | grep `cs_auth_ui:` |
| G5 | 路由中有 CsLoginPage | grep `CsLoginPage` |

---

## [USAGE] 常用 API 示例

### 完整登录页（推荐）
```dart
CsLoginPage(
  logo: Image.asset('assets/logo.png', height: 80),
  title: '欢迎来到 MyApp',
  subtitle: '登录后享受完整功能',
  showSkipButton: true,            // 显示「跳过先逛逛」
  onLoginSuccess: () => context.go('/home'),
  onSkip: () => context.go('/home'),
)
```

### 嵌入式登录表单
```dart
// 嵌入 BottomSheet 或 Dialog
CsLoginForm(
  mode: CsLoginFormMode.login,     // login | register | linkEmail
  onSuccess: () {
    Navigator.pop(context);
    showSuccessToast('登录成功');
  },
)
```

### 忘记密码页
```dart
GoRoute(
  path: '/forgot-password',
  builder: (_, __) => CsForgotPasswordPage(
    onEmailSent: (email) => context.go('/verify-otp?email=$email'),
  ),
)
```

### 常见问题排查

- **「跳过」报错**：检查 Supabase 项目是否已激活、网络是否正常
- **OTP 无效**：确认 Supabase Authentication → Email 发信配置
- **登录页样式异常**：确认 CsApp（来自 cs-src-ui）已在最顶层包裹
