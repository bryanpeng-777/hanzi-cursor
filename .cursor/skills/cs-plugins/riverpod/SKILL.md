# riverpod 插件

Riverpod 状态管理接入：替代业务逻辑中的 setState，所有业务状态提升为 Provider。

**详细改造规则见** `references/transform-riverpod.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 flutter_riverpod 依赖
2. 扫描统计改造目标：
   - `extends StatefulWidget` 数量
   - `setState(` 调用数量（区分业务逻辑 vs 纯 UI 控制器）
   - `ChangeNotifier` / `Provider` 旧包残留
3. 检查 main.dart 是否已有 `ProviderScope(`

### 添加依赖

在 `pubspec.yaml` 添加：
```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.4.0
dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

运行 `flutter pub get`

### 包裹 ProviderScope

在 `main.dart` 的 `runApp` 调用处包裹 ProviderScope：
```dart
runApp(const ProviderScope(child: MyApp()));
```

### 代码改造（读取 references/transform-riverpod.md 执行）

改造标准（仅转换类名不等于完成）：
- 业务状态字段（`_loading`、`_items`、Stream 订阅结果等）必须全部移入 Provider
- `initState` 中的网络请求/Stream 订阅必须迁移到 `Provider.build()` + `ref.onDispose`
- `StatefulWidget → ConsumerStatefulWidget` 只是前提，不是终点
- 只有 `TextEditingController`、`AnimationController`、Tab index 等纯 UI 控制器可保留本地 setState
- `ConfigManager.get*()` 等后端配置值也属于业务状态，必须提取到独立 Provider

### 运行代码生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 验证

执行 VERIFY 段落全部检查点

---

## [UPDATE] 更新步骤

### 版本对比

```bash
flutter pub outdated --json  # 查看 flutter_riverpod 最新版本
```

列出 CHANGELOG 中的 Breaking Change（riverpod 大版本间有 API 变更）。

### 更新操作

修改 pubspec.yaml 版本号 → `flutter pub get` → 处理 API 变更 → 重跑 build_runner

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| A3 | dev_dependencies 完整 | 读取 pubspec.yaml dev_dependencies | build_runner / riverpod_generator 均存在 |
| B1 | ProviderScope 已包裹 | `grep -n "ProviderScope(" lib/main.dart` | 有输出 |
| B2 | 业务逻辑 setState 清零 | `grep -rn "setState(" lib/` + AI 审查上下文 | 仅 UI 控制器使用 |
| B3 | 无剩余业务型 StatefulWidget | `grep -rn "extends StatefulWidget" lib/` | 零残余或仅纯动画类 |
| B4 | 代码生成文件已生成 | `ls lib/**/*.g.dart` | 存在 .g.dart 文件 |

> B2 判断规则：`setState` 内修改 List/Map/bool _loading/String _message/Stream 结果 = 未迁移；仅修改 _tabIndex/_controller 等 = 合法保留

---

## [USAGE] 使用辅助

### 新建一个 Provider

```dart
// lib/providers/xxx_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'xxx_provider.g.dart';

@riverpod
class XxxNotifier extends _$XxxNotifier {
  @override
  XxxState build() {
    return const XxxState();
  }

  void doSomething() {
    state = state.copyWith(...);
  }
}
```

重跑代码生成：`flutter pub run build_runner build --delete-conflicting-outputs`

### 在 Widget 中使用 Provider

```dart
// ConsumerWidget（无本地状态）
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(xxxNotifierProvider);
    return Text(state.value);
  }
}

// ConsumerStatefulWidget（有本地 UI 状态）
class MyWidget extends ConsumerStatefulWidget { ... }
class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xxxNotifierProvider);
    // ref.read(xxxNotifierProvider.notifier).doSomething();
  }
}
```

### 异步 Provider（网络请求）

```dart
@riverpod
Future<List<Item>> fetchItems(FetchItemsRef ref) async {
  final items = await DataManager.select('items');
  return items.map((e) => Item.fromJson(e)).toList();
}

// Widget 中使用
final asyncItems = ref.watch(fetchItemsProvider);
return asyncItems.when(
  data: (items) => ListView(...),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => Text('错误：$e'),
);
```

### build_runner 常见问题

- 冲突报错 → 加 `--delete-conflicting-outputs`
- 文件未生成 → 检查 `part 'xxx.g.dart'` 声明是否存在
- 找不到 Provider → 确认文件顶部有 `part 'xxx.g.dart'`，且已运行 build_runner
