# go_router 路由改造规则

本文件供 `cs-stack-onboarding` Step 3-A 使用。

---

## 改造目标

将项目中所有命令式路由（Navigator API + MaterialApp routes）替换为声明式路由（GoRouter）。

---

## Step 3-A-1：创建路由配置文件

在 `lib/router/app_router.dart` 创建 GoRouter 配置。

根据 Step 0 扫描到的路由调用，自动提取页面列表，生成以下模板：

```dart
import 'package:go_router/go_router.dart';
// import 所有页面文件

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // AI 根据扫描结果自动填充其他路由
  ],
);
```

**路由命名规范**：
- 路径全小写，单词用 `-` 分隔（如 `/user-profile`）
- 带参数路由：`/detail/:id`，页面中用 `state.pathParameters['id']` 获取

---

## Step 3-A-2：改造 MaterialApp

| 改造前 | 改造后 |
|-------|-------|
| `MaterialApp(routes: {...})` | `MaterialApp.router(routerConfig: appRouter)` |
| `MaterialApp(onGenerateRoute: ...)` | `MaterialApp.router(routerConfig: appRouter)` |
| `MaterialApp(home: HomeScreen())` | `MaterialApp.router(routerConfig: appRouter)`（initialLocation: '/' 指向 HomeScreen） |

示例：

```dart
// Before
MaterialApp(
  routes: {
    '/': (context) => const HomeScreen(),
    '/detail': (context) => const DetailScreen(),
  },
)

// After
MaterialApp.router(
  routerConfig: appRouter,
)
```

---

## Step 3-A-3：替换 Navigator 调用

### 页面跳转

| 改造前 | 改造后 | 说明 |
|-------|-------|-----|
| `Navigator.push(context, MaterialPageRoute(builder: (_) => XScreen()))` | `context.push('/x')` | 保留回退栈 |
| `Navigator.pushNamed(context, '/x')` | `context.push('/x')` | 保留回退栈，避免误改成替换式跳转 |
| `Navigator.pushNamed(context, '/x', arguments: data)` | `context.push('/x', extra: data)` | 带参数且保留回退栈 |
| `Navigator.pushReplacement(context, MaterialPageRoute(...))` | `context.go('/x')` | 替换当前页 |
| `Navigator.pushReplacementNamed(context, '/x')` | `context.go('/x')` | 替换当前页 |
| `Navigator.pushAndRemoveUntil(context, ..., (_) => false)` | `context.go('/x')` | 清空栈后跳转 |
| `Navigator.pop(context)` | `context.pop()` | 返回上一页 |
| `Navigator.pop(context, result)` | `context.pop(result)` | 返回并带返回值 |
| `Navigator.canPop(context)` | `context.canPop()` | 检查是否可返回 |

### 接收路由参数

```dart
// Before（arguments 方式）
final data = ModalRoute.of(context)!.settings.arguments as MyData;

// After（GoRouter extra 方式）
// 在 GoRoute 的 builder 中：
builder: (context, state) {
  final data = state.extra as MyData;
  return DetailScreen(data: data);
}
```

### 命名参数（path parameters）

```dart
// 路由定义
GoRoute(path: '/user/:id', builder: (context, state) {
  final id = state.pathParameters['id']!;
  return UserScreen(id: id);
})

// 跳转
context.go('/user/123');
```

---

## Step 3-A-4：处理嵌套路由

原有 `Navigator` 嵌套（如底部导航栏的多个子路由）：

```dart
// After：使用 StatefulShellRoute
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      ScaffoldWithNavBar(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ]),
  ],
)
```

---

## Step 3-A-5：导入检查

确保所有使用了 `context.go / context.push / context.pop` 的文件顶部有：

```dart
import 'package:go_router/go_router.dart';
```

同时 `main.dart` 或路由使用处导入：

```dart
import 'router/app_router.dart';
```

---

## 常见踩坑

### context.go 在 initState 中不可用
- **原因**：initState 执行时 widget 尚未完全挂载，GoRouter context 不可用
- **解法**：改用 `WidgetsBinding.instance.addPostFrameCallback((_) { context.go('/x'); })`

### WillPopScope 替代
- GoRouter 中 `WillPopScope` 改为 `PopScope`（Flutter 3.16+）：
  ```dart
  PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) { ... },
    child: ...,
  )
  ```
