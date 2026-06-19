# CLAUDE.md 技术栈规范模板

在 Step 4 验证通过后，自动在项目根目录生成或更新 `CLAUDE.md`（若已存在则追加 `## 技术栈规范` 章节，不覆盖已有内容）。

这份规范让 AI 在该项目中新增任何功能时，**自动遵守框架约定，不会用错库**。

---

## 写入规则

### 基本判断

- 若 `CLAUDE.md` **不存在** → 直接创建，内容为下方模板
- 若 `CLAUDE.md` **已存在且无** `## 技术栈规范` 章节 → 追加章节，**同时执行「过时内容扫描与更新」（见下方）**
- 若 `CLAUDE.md` **已存在且有** `## 技术栈规范` 章节 → 用最新模板替换该章节，**同时执行「过时内容扫描与更新」**
- 若项目未接入某个库（如未接入 `dio`），则对应章节不写入
- 若项目根目录已有 `AGENTS.md` 而无 `CLAUDE.md` → 写入 `AGENTS.md`

### 过时内容扫描与更新（必须执行）

> **追加技术栈规范章节 ≠ CLAUDE.md 更新完成。**
> CLAUDE.md 的其他章节如果描述了旧技术栈（如 Provider / ChangeNotifier），AI 读文件时会先读到旧信息，规范章节被旧内容覆盖，等于无效。
> 因此，**追加章节后必须扫描全文，更新所有与新技术栈矛盾的描述**。

扫描目标（按优先级）：

| 扫描目标 | 典型旧内容 | 应更新为 |
|---------|-----------|---------|
| `## 状态管理` 章节 | 「使用 Provider（ChangeNotifier）模式」、`context.watch<XProvider>()` 等 | Riverpod 说明 + 新 API 示例 |
| `## 依赖说明` 表格 | `provider: ^x.x.x` 条目 | 移除 provider，补充 flutter_riverpod / freezed_annotation / go_router 等新依赖 |
| `## 项目结构` 目录树 | `providers/` 下只有旧 ChangeNotifier 文件 | 更新为实际文件列表（含 .g.dart 生成文件）；`models/` 补充 LearningState / .freezed.dart 等 |
| `## 数据模型` 章节 | 含 mutable 字段（`bool isLearned;`，无 const） | 更新为 `@freezed` 不可变类说明 |
| 任意位置出现的旧 API | `provider.totalStars`、`context.read<XProvider>()` 等 | 更新为 `ref.watch(xProvider).totalStars`、`ref.read(xProvider.notifier).method()` |

**扫描执行方式：**

1. 读取 CLAUDE.md 全文
2. 逐段检查是否含上表中的「典型旧内容」关键词：`ChangeNotifier`、`context.watch<`、`context.read<`、`provider:` 依赖、`extends ChangeNotifier`
3. 发现则**精准替换该段**（不删整个章节，只改有矛盾的部分）
4. 完成后验证：全文搜索 `ChangeNotifier`、`extends Provider`、`provider:` 依赖，确认为零

⚠️ 已知踩坑（2026-04-18）：
- 现象：追加了 `## 技术栈规范` 章节，但文件前 390 行的 `## 状态管理`、`## 依赖说明`、`## 项目结构` 仍描述旧 Provider 模式，包括 `provider: ^6.1.2` 依赖和 `context.watch<LearningProvider>()` 的 API 示例
- 根因：claudemd-template.md 的写入规则只说「追加章节」，没有要求扫描和清理矛盾内容；执行时以为追加章节等于完成
- 修正：写入规则增加「过时内容扫描与更新」步骤，并在追加章节后必须执行全文扫描

---

> 写入/更新完成后告知用户：「✅ 框架规范已写入 CLAUDE.md，并已清理旧技术栈描述，后续 AI 在此项目开发新功能时会自动遵守这套约定」

## 模板内容（根据项目实际接入的库按需裁剪）

````markdown
## 技术栈规范

本项目已接入 cs_framework 完整技术栈，所有新增功能必须遵守以下规范。

### 路由（go_router）
- ✅ 跳转用 `context.go()` / `context.push()` / `context.pop()`
- ❌ 禁止使用 `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed`
- 所有路由定义集中在 `lib/router/app_router.dart`

**新增路由标准写法：**
```dart
// lib/router/app_router.dart
GoRoute(
  path: '/feature',
  name: 'feature',
  builder: (context, state) => const FeaturePage(),
),
// 跳转
context.go('/feature');
context.push('/feature');
```

### 状态管理（Riverpod）
- ✅ 新建状态用 `@riverpod` 注解 + `build_runner` 生成，放在 `lib/providers/`
- ✅ Widget 继承 `ConsumerWidget` 或 `ConsumerStatefulWidget`
- ❌ 禁止使用 `StatefulWidget` + `setState` 管理业务状态
- ❌ 禁止使用 Provider、GetX、BLoC 等其他状态管理库

**新建 Provider 标准写法：**
```dart
// lib/providers/feature_provider.dart
part 'feature_provider.g.dart';

@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  FeatureState build() => const FeatureState.initial();

  Future<void> loadData() async {
    state = await AsyncValue.guard(() => ref.read(dataManagerProvider).fetchXxx());
  }
}

// Widget 消费
class FeaturePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureNotifierProvider);
    return state.when(data: (d) => Text(d.name), loading: () => ..., error: (e, _) => ...);
  }
}
```

### 数据模型（freezed + json_annotation）
- ✅ `lib/models/` 下的数据类用 `@freezed` 注解，由 `build_runner` 生成
- ✅ JSON 反序列化用 `factory X.fromJson(json) => _$XFromJson(json)`
- ❌ 禁止手写 `copyWith` / `==` / `hashCode` / `toString`
- ❌ 禁止在 `@freezed` 类上叠加 `@JsonSerializable()`

**新建 Model 标准写法：**
```dart
// lib/models/feature_model.dart
part 'feature_model.freezed.dart';
part 'feature_model.g.dart';

@freezed
class FeatureModel with _$FeatureModel {
  const factory FeatureModel({
    required String id,
    required String name,
    @Default(false) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _FeatureModel;

  factory FeatureModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureModelFromJson(json);
}
```

### 代码生成（build_runner）
- 修改 `@riverpod` / `@freezed` / `@JsonSerializable` 注解后必须运行：
  `flutter pub run build_runner build --delete-conflicting-outputs`

### 本地存储分层
| 数据类型 | 使用方式 |
|---------|---------|
| 用户偏好（bool/int/String） | `ref.read(preferencesManagerProvider)` |
| 敏感凭证（Token / API Key） | `ref.read(secureStorageManagerProvider)` |
| 业务数据 / 复杂对象 | `cs_framework DataManager` |
- ❌ 禁止直接调用 `SharedPreferences.getInstance()`
- ❌ 禁止把 Token / Key 硬编码在代码中

**存储标准写法：**
```dart
// 用户偏好
final prefs = ref.read(preferencesManagerProvider);
await prefs.setThemeMode(ThemeMode.dark);
final theme = prefs.getThemeMode();

// 敏感凭证
final secure = ref.read(secureStorageManagerProvider);
await secure.saveApiKey(apiKey);
final key = await secure.getApiKey();
```

### HTTP 请求
- ✅ 调用 Supabase 表/Auth/Storage → `cs_framework DataManager`
- ✅ 调用第三方/自建后端 → `ref.read(dioClientProvider)`
- ❌ 禁止使用 `http` 包，禁止直接 `new Dio()`

**HTTP 标准写法：**
```dart
// 第三方接口
final dio = ref.read(dioClientProvider);
final resp = await dio.get('/api/feature');

// Supabase 数据
final dm = ref.read(dataManagerProvider);
final rows = await dm.fetchAll('feature_table');
```

### 日志
- ✅ 使用 `appLogger.d()` / `.i()` / `.w()` / `.e()`
- ❌ 禁止使用 `print()` / `debugPrint()` / `developer.log()`

**日志标准写法：**
```dart
appLogger.d('加载功能数据');                              // 调试
appLogger.i('用户登录成功: $userId');                     // 关键事件
appLogger.w('配置缺失，使用默认值');                       // 警告
appLogger.e('请求失败', error: e, stackTrace: st);        // 错误
```

### UI 组件（cs_ui / shadcn_ui）
- ✅ 按钮用 `ShadButton`，卡片用 `ShadCard`，顶栏用 `CsAppBar`
- ❌ 禁止使用 `ElevatedButton` / `TextButton` / `OutlinedButton` / `AppBar` / `Card`

### 图片 / 动画 / 视频
- ✅ 图片用 `CsImage`，动画用 `CsLottie`，视频用 `CsVideo`
- ❌ 禁止使用 `Image.asset` / `Image.network` / `Lottie.asset` / `Lottie.network` 写死路径

### 屏幕适配（flutter_screenutil）
- 已完成初始化，业务开发时按需使用 `.w` / `.h` / `.sp` / `.r` 扩展方法

### 开发流程（TDD 强制）

**每次新增功能或修 bug 前，Plan 阶段必须完成测试用例设计，再写代码：**

1. 读取 `test_manifest.md` 了解现有测试覆盖情况
2. 在计划中列出新增/变更的测试用例（输入条件 / 操作步骤 / 预期结果）
3. 区分「自动化」vs「手动」验证方式，自动化用例需指明所属 scenario 文件
4. 等用户确认测试用例设计后，再进入 Agent 模式写代码

**AI 行为约束：**
- 收到开发任务 → 先读 `test_manifest.md` → 提出测试用例设计 → 用户确认后再动代码
- 代码完成后 → 将新用例追加到 `test_manifest.md`（状态：`已实现`）
- 上线前 → 说「测试管理」触发 cs-test-manager 跑全量用例并确认手动用例

**test_manifest.md 用例状态说明：**

| 状态 | 含义 |
|---|---|
| `计划中` | TDD 阶段设计好、测试代码尚未编写 |
| `已实现` | 测试代码已就绪，每次跑应通过 |
| `skip` | 暂时跳过，需注明原因 |

> 「通不通过」由每次运行实时输出决定，不持久化到文件，避免状态过期误导。

**test_manifest.md 位置：** 项目根目录（与 `pubspec.yaml` 同级）
````
