# go-router 插件

go_router 声明式路由接入：替代 Navigator.push/pop，统一管理路由配置。

**详细改造规则见** `references/transform-go-router.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 go_router 依赖
2. 扫描统计：`Navigator.push` / `Navigator.pop` / `Navigator.pushNamed` 数量
3. 检查是否已有 `lib/router/app_router.dart`

### 添加依赖

```yaml
dependencies:
  go_router: ^14.0.0
```

运行 `flutter pub get`

### 代码改造（读取 references/transform-go-router.md 执行）

1. 新建 `lib/router/app_router.dart`，声明所有路由
2. 修改 `main.dart`：`MaterialApp` → `MaterialApp.router(routerConfig: appRouter)`
3. 全局替换 `Navigator.push/pop/pushNamed` → `context.go/push/pop`

核心模板：
```dart
// lib/router/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoginRoute = state.matchedLocation == '/';
    final isAuthenticated = AuthManager.isLoggedIn;
    if (!isAuthenticated && !isLoginRoute) return '/';
    if (isAuthenticated && isLoginRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],
);
```

⚠️ **已知踩坑**：`showModalBottomSheet` 内用 `Navigator.pop(ctx)` 关闭弹窗，应改为 `ctx.pop()`

### 验证

执行 VERIFY 段落全部检查点

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查 go_router 最新版
```

注意 go_router 版本间 Breaking Change（API 参数变化）。

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| C1 | app_router.dart 已创建 | `ls lib/router/app_router.dart` | 文件存在 |
| C2 | MaterialApp 已迁移 | `grep -n "MaterialApp.router(" lib/main.dart` | 有输出 |
| C3 | Navigator 调用清零 | `grep -rn "Navigator\." lib/` | 零 push/pop/pushNamed |

---

## [USAGE] 使用辅助

### 新增一个路由

在 `app_router.dart` 的 routes 列表追加：
```dart
GoRoute(
  path: '/detail/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return DetailPage(id: id);
  },
),
```

### 路由跳转方式

```dart
context.go('/home')              // 替换当前路由（无返回）
context.push('/detail/123')      // 推入新路由（有返回）
context.pop()                    // 返回上一页
context.go('/home', extra: data) // 传递对象参数
```

### 传参方式

```dart
// Path 参数：/detail/:id
final id = state.pathParameters['id'];

// Query 参数：/search?q=flutter
final query = state.uri.queryParameters['q'];

// Extra 参数（对象，不序列化到 URL）
final data = state.extra as MyData;
```

### 配置登录守卫

```dart
redirect: (context, state) {
  final publicRoutes = ['/', '/onboarding'];
  final isPublic = publicRoutes.contains(state.matchedLocation);
  if (!AuthManager.isLoggedIn && !isPublic) return '/';
  return null;
},
```

### BottomSheet 内关闭弹窗

```dart
// ❌ 错误（会触发 cs-stack-checker C3 检查）
Navigator.pop(ctx);

// ✅ 正确
ctx.pop();
```
