# Riverpod 状态改造规则

本文件供 `cs-stack-onboarding` Step 3-B 使用。

使用**代码生成方式**（riverpod_annotation + riverpod_generator），这是 Riverpod 2.x 的推荐写法，
需配合 `build_runner` 生成 `.g.dart` 文件。

---

## 依赖说明

```yaml
dependencies:
  flutter_riverpod: ^2.5.0      # 运行时核心
  riverpod_annotation: ^2.4.0   # @riverpod 注解（运行时依赖，不是 dev）

dev_dependencies:
  riverpod_generator: ^2.4.0    # 从注解生成 provider 代码
  build_runner: ^2.4.0          # 执行代码生成
```

> `riverpod_annotation` 是运行时依赖（放 dependencies），`riverpod_generator` 才是 dev 依赖。

---

## Step 3-B-1：ProviderScope 注入

在 `main.dart` 中用 `ProviderScope` 包裹根 Widget：

```dart
// Before
void main() {
  runApp(const MyApp());
}

// After
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

---

## Step 3-B-2：目录结构

```
lib/
  models/              # @freezed 数据类（含 fromJson）
    user.dart
    user.freezed.dart  # build_runner 生成
    user.g.dart        # build_runner 生成
  providers/           # @riverpod 注解 provider
    users_provider.dart
    users_provider.g.dart   # build_runner 生成
    settings_provider.dart
    settings_provider.g.dart
```

每个 provider 文件必须有：
```dart
part 'xxx_provider.g.dart';  // 对应生成文件名
```

---

## Step 3-B-3：@riverpod 注解 Provider 类型选择

### 类型 1：只读计算值 / 单次异步加载（函数式）

```dart
// lib/providers/users_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../network/dio_client.dart';

part 'users_provider.g.dart';

// 同步计算值
@riverpod
String greeting(GreetingRef ref) {
  final user = ref.watch(currentUserProvider);
  return 'Hello, ${user.name}!';
}

// 异步数据（网络请求）— 自动成为 AsyncNotifierProvider
@riverpod
Future<List<User>> users(UsersRef ref) async {
  final response = await ref.read(dioClientProvider).get('/users');
  return (response.data as List)
      .map((json) => User.fromJson(json as Map<String, dynamic>))
      .toList();
}

// 带参数的异步（family）
@riverpod
Future<User> user(UserRef ref, String userId) async {
  final response = await ref.read(dioClientProvider).get('/users/$userId');
  return User.fromJson(response.data as Map<String, dynamic>);
}
```

使用：
```dart
// users: AsyncValue<List<User>>
final usersAsync = ref.watch(usersProvider);

// user('123'): AsyncValue<User>
final userAsync = ref.watch(userProvider('123'));
```

---

### 类型 2：可变同步状态（Notifier）

```dart
// lib/providers/counter_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_provider.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;           // 初始值

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}
```

生成：`counterProvider`（类型 `NotifierProvider<Counter, int>`）

使用：
```dart
final count = ref.watch(counterProvider);
ref.read(counterProvider.notifier).increment();
```

---

### 类型 3：可变异步状态（AsyncNotifier）

适用于需要**加载 + 修改**的场景（如列表的增删改查）：

```dart
// lib/providers/posts_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/post.dart';
import '../network/dio_client.dart';

part 'posts_provider.g.dart';

@riverpod
class PostsNotifier extends _$PostsNotifier {
  @override
  Future<List<Post>> build() => _fetch();

  Future<List<Post>> _fetch() async {
    final response = await ref.read(dioClientProvider).get('/posts');
    return (response.data as List)
        .map((json) => Post.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> addPost(Post post) async {
    await ref.read(dioClientProvider).post('/posts', data: post.toJson());
    ref.invalidateSelf();   // 触发重新加载
  }

  Future<void> deletePost(String id) async {
    await ref.read(dioClientProvider).delete('/posts/$id');
    // 乐观更新：不等重新请求，直接从本地列表移除
    state = AsyncData(
      state.requireValue.where((p) => p.id != id).toList(),
    );
  }
}
```

生成：`postsNotifierProvider`

使用：
```dart
final postsAsync = ref.watch(postsNotifierProvider);
postsAsync.when(
  data: (posts) => ListView.builder(...),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
ref.read(postsNotifierProvider.notifier).refresh();
```

---

### 类型 4：全局单例服务（keepAlive）

```dart
// lib/providers/dio_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/dio_client.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)   // 不随 Widget 销毁
DioClient dioClient(DioClientRef ref) {
  return DioClient(baseUrl: 'https://api.example.com');
}
```

> 普通 `@riverpod` 在没有 Widget 监听时会自动 dispose；`keepAlive: true` 保持存活。

---

## Step 3-B-4：与 freezed + json_serializable 完整集成

### Model 层（freezed 负责）

```dart
// lib/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';  // freezed 生成：copyWith / == / hashCode / toString
part 'user.g.dart';        // json_serializable 生成：fromJson / toJson

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default(false) bool isAdmin,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### Provider 层（riverpod_annotation 负责）

```dart
// lib/providers/user_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import '../network/dio_client.dart';

part 'user_provider.g.dart';

// 读取单个用户（带参数）
@riverpod
Future<User> user(UserRef ref, String userId) async {
  final response = await ref.read(dioClientProvider).get('/users/$userId');
  return User.fromJson(response.data as Map<String, dynamic>);
}

// 可变用户状态（支持更新）
@riverpod
class CurrentUser extends _$CurrentUser {
  @override
  Future<User?> build() async {
    // 从 cs_framework 读取当前登录用户 ID
    final userId = CsClient.currentUserId;
    if (userId == null) return null;
    final response = await ref.read(dioClientProvider).get('/users/$userId');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // freezed copyWith：只改需要改的字段，其他保持不变
  Future<void> updateName(String name) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = current.copyWith(name: name); // freezed 自动生成的 copyWith
    state = AsyncData(updated);                   // 乐观更新 UI

    await ref.read(dioClientProvider).put(
      '/users/${current.id}',
      data: updated.toJson(),                     // json_serializable 自动生成的 toJson
    );
  }
}
```

### Widget 层（ConsumerWidget）

```dart
// lib/screens/profile_screen.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Text('未登录');
        return Column(children: [
          Text(user.name),
          Text(user.avatarUrl ?? '无头像'),
          if (user.isAdmin) const Chip(label: Text('管理员')),
          ElevatedButton(
            onPressed: () =>
                ref.read(currentUserProvider.notifier).updateName('新名字'),
            child: const Text('改名'),
          ),
        ]);
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

---

## Step 3-B-5：状态归属判断（改造前必读）

**改造不是只改类名。改造的目标是：所有业务状态必须由 Provider 管理，Widget 内部的 `setState` 调用只允许用于纯本地 UI 状态。**

### 两类状态的区分标准

| 类别 | 定义 | 处理方式 | 典型示例 |
|---|---|---|---|
| **本地 UI 状态**（可保留 setState） | 不跨组件、不含业务数据、不通过网络/DB产生 | 保留在 Widget / State | `TextEditingController`、`FocusNode`、`AnimationController`、Tab 当前 index、底部 Sheet 展开收起 |
| **业务状态**（必须 Provider 化） | 涉及网络请求、数据库操作、Stream/Realtime、跨 Widget 共享、loading/error 等 | 提升为 `@riverpod Notifier` | `_loading`、`_favorites`、`_queryResult`、`_statusMessage`、`_recentChanges`、Realtime 流监听结果 |

### 常见业务状态 → Provider 映射

| 业务状态字段 | Provider 类型 | 说明 |
|---|---|---|
| `List<T> _items` + `bool _loading` + 网络加载 | `AsyncNotifier<List<T>>` | `AsyncValue` 自动处理三态 |
| `bool _loading` + `String? _statusMessage` + 操作结果 | `Notifier<XState>` + `@freezed XState` | 操作类，用 freezed 打包状态 |
| Stream 监听结果（Realtime / onChange） | `Notifier` 内部 `ref.onDispose` | `build()` 中订阅，`ref.onDispose` 取消 |
| 环境/配置等全局单例 | `StateProvider<T>` 或 `@Riverpod(keepAlive: true)` | 跨屏幕共享 |

### 改造完成标准（缺一不可）

```
✅ 所有 StatefulWidget → ConsumerStatefulWidget（或 ConsumerWidget）
✅ 所有业务状态字段从 State 移入 Provider（零 _loading、零 _favorites 等业务变量）
✅ 所有业务逻辑 setState(() {...}) 调用消灭（不含纯 UI setState）
✅ Stream/Realtime 监听从 initState 移入 Provider.build() + ref.onDispose
✅ flutter analyze 零 error
```

---

## Step 3-B-5：Widget 改造规则

### StatelessWidget → ConsumerWidget（需要读取 provider）

```dart
// Before
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('Hello');
}

// After
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('Count: $count');
  }
}
```

### StatefulWidget → ConsumerWidget（业务状态已全部 Provider 化）

当所有 `setState` 都是业务状态时，可以进一步简化为无 State 的 ConsumerWidget：

```dart
// Before
class DataScreen extends ConsumerStatefulWidget { ... }
class _DataScreenState extends ConsumerState<DataScreen> {
  List<Item> _items = [];
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await fetchItems();
    setState(() => _loading = false);
  }
  // ...
}

// After：_items 和 _loading 全部交给 Provider，Widget 无状态
class DataScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsNotifierProvider);
    return itemsAsync.when(
      data: (items) => ListView.builder(...),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### StatefulWidget → ConsumerStatefulWidget（有合理本地 UI 状态 + provider）

**只有当存在合理本地 UI 状态（TextEditingController 等）时，才保留 ConsumerStatefulWidget。**

```dart
// After：只保留 Controller（纯本地 UI 状态），业务状态全部 Provider 化
class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});
  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  // ✅ 合理本地 UI 状态：TextEditingController 不归 Provider 管
  final _controller = TextEditingController();

  // ❌ 禁止：这类字段必须移到 Provider
  // bool _loading = false;
  // String? _statusMessage;
  // List<Item> _items = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 业务状态从 Provider 读取
    final actionState = ref.watch(formActionNotifierProvider);
    return Column(children: [
      TextField(controller: _controller),
      if (actionState.loading) const CircularProgressIndicator(),
      ElevatedButton(
        onPressed: actionState.loading
            ? null
            : () => ref
                .read(formActionNotifierProvider.notifier)
                .submit(_controller.text),
        child: const Text('提交'),
      ),
    ]);
  }
}
```

---

## Step 3-B-6：运行代码生成

本技能中，3-B（Riverpod）与 3-C（freezed）共享一次统一代码生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

执行建议：
- 若 3-B 和 3-C 都会做：两者改造完成后再统一运行一次，避免重复生成和冲突
- 若只做 3-B：改造完成后运行一次即可

开发期如需边改边看结果，可临时使用 watch 模式（保存即自动生成）：

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## Step 3-B-7：改造完整性核查（Step 4 之前必须执行）

**改造后、运行 build_runner 之前，必须做全量核查。不核查视为改造未完成。**

### 核查步骤

**1. 统计残余 setState**

```bash
# 统计所有 setState 调用
grep -rn "setState(" lib/ --include="*.dart"
```

对每条 setState 判断：

| setState 内容 | 归类 | 处理 |
|---|---|---|
| `setState(() => _loading = true/false)` | ❌ 业务状态 | 必须移入 Provider |
| `setState(() => _items = list)` | ❌ 业务状态 | 必须移入 Provider |
| `setState(() => _statusMessage = '...')` | ❌ 业务状态 | 必须移入 Provider |
| `setState(() => _currentIndex = i)` | ✅ Tab 切换（纯 UI） | 允许保留 |
| `setState(() {})` 仅触发重建（无业务数据赋值） | ⚠️ 灰色地带 | 分析是否可替代；若依赖单例（如 AuthManager）触发重建，注明原因后允许保留 |

**2. 统计残余本地业务状态字段**

```bash
# 检测 State 类内有无业务字段（_loading / _items / _result 等）
grep -n "bool _loading\|List _\|String? _\|_recentChanges\|_queryResult\|_statusMessage" lib/**/*.dart
```

发现任意业务字段 → 必须 Provider 化后才能进入 Step 4。

**3. 统计残余 initState 业务逻辑**

```bash
grep -n "initState" lib/**/*.dart
```

`initState` 内只允许存在：`super.initState()` 和控制器初始化。
发现网络请求、数据加载、Stream 订阅 → 必须迁移到 Provider.build() + ref.onDispose。

**4. 核查结果输出格式**

```
🔍 Riverpod 改造核查报告：
  setState 总计：N 处
    ✅ 合理本地 UI（Tab index / Controller 等）：X 处
    ❌ 待消灭业务状态：Y 处 → [列出文件名:行号]
  业务状态字段残余：N 处 → [列出字段名]
  initState 业务逻辑残余：N 处 → [列出文件名]

结论：[通过 / 未通过，需继续改造]
```

**未通过时：回到 Step 3-B 继续改造对应文件，直到核查结果为「通过」再进入 Step 4。**

---

## Step 3-B-8：旧版 Provider 包迁移对照表

| 旧 `provider` 包 | Riverpod 代码生成等价 |
|----------------|-------------------|
| `ChangeNotifier` + `ChangeNotifierProvider` | `@riverpod class XNotifier extends _$XNotifier` |
| `Provider<T>` | `@Riverpod(keepAlive: true) T x(XRef ref)` |
| `FutureProvider<T>` | `@riverpod Future<T> x(XRef ref) async` |
| `StreamProvider<T>` | `@riverpod Stream<T> x(XRef ref)` |
| `context.watch<T>()` | `ref.watch(xProvider)` |
| `context.read<T>()` | `ref.read(xProvider)` |

---

## 常见踩坑

### ref.watch vs ref.read
- `ref.watch`：build 方法中使用，值变化时 Widget 自动重建
- `ref.read`：onPressed 等事件回调中使用，只取一次当前值
- **错误**：在 build 中用 `ref.read`（不响应变化）
- **错误**：在 onPressed 中用 `ref.watch`（产生不必要订阅）

### initState 中不能用 ref.watch
```dart
@override
void initState() {
  super.initState();
  // 正确：用 Future.microtask 延后执行
  Future.microtask(() => ref.read(postsNotifierProvider.notifier).refresh());
}
```

### part 文件名必须与源文件名一致
```dart
// 文件名：users_provider.dart
part 'users_provider.g.dart';  // ✅ 正确
part 'user_provider.g.dart';   // ❌ 错误，名字不一致会导致生成失败
```

### AsyncValue 操作

```dart
final async = ref.watch(usersProvider);

// 安全取值（null if loading/error）
final users = async.valueOrNull;

// 强制取值（loading/error 时抛异常，慎用）
final users = async.requireValue;

// 局部刷新（不整体 loading，保留旧数据）
ref.invalidate(usersProvider);

// Notifier 内部刷新自身
ref.invalidateSelf();
```
