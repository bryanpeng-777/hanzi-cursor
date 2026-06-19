# freezed + json_annotation 模型改造规则

本文件供 `cs-stack-onboarding` Step 3-C 使用。

---

## 依赖说明

```yaml
dependencies:
  freezed_annotation: ^2.4.0   # @freezed / @Default 等注解（运行时依赖）
  json_annotation: ^4.9.0      # @JsonKey / @JsonEnum 等注解（运行时依赖）

dev_dependencies:
  freezed: ^2.4.0              # 从 @freezed 注解生成代码
  json_serializable: ^6.7.0   # 从 fromJson 工厂生成序列化代码
  build_runner: ^2.4.0        # 执行代码生成
```

> **注意**：`@JsonSerializable()` 注解**不需要**也**不能**加在 `@freezed` 类上。
> freezed 检测到 `fromJson` 工厂方法时，会自动在内部处理 JSON 序列化，无需手动标注。

---

## 改造目标

将 `lib/models/` 下的 plain Dart 数据类替换为 `@freezed` 注解的不可变数据类，
自动获得 `copyWith` / `==` / `hashCode` / `toString` / `fromJson` / `toJson`。

---

## 扫描目标识别规则

以下特征的 class 属于「应改造的 plain 数据类」：

1. 位于 `lib/models/`、`lib/data/`、`lib/entities/` 等目录
2. 有 2 个以上 `final` 字段
3. 有手写 `copyWith` / `==` / `hashCode`
4. 有手写 `fromJson` / `toJson`

**不改造**的情况：
- 有复杂初始化逻辑（构造时执行计算）
- Mixin 或 abstract class
- `extends` 非 Object 的 class（freezed 不支持继承）
- 含不可序列化字段（如 `Function`、`Stream`）

---

## Step 3-C-1：基础改造模板

每个 `@freezed` 文件固定结构：

```dart
// lib/models/user.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart'; // 使用 @JsonKey / @JsonEnum / @Default 时必须导入

part 'user.freezed.dart'; // freezed 生成：copyWith / == / hashCode / toString
part 'user.g.dart';       // json_serializable 生成：fromJson / toJson

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required int age,
    String? email,
  }) = _User;

  // 有 fromJson → build_runner 自动生成 toJson
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

**改造要点**：
- 删除手写 `copyWith`（freezed 自动生成，支持深拷贝嵌套对象）
- 删除手写 `==` 和 `hashCode`（freezed 基于所有字段自动生成）
- 删除手写 `fromJson` / `toJson` 实现，只保留 `factory User.fromJson` 声明（引用生成代码）
- **不加** `@JsonSerializable()`，freezed 内部已处理

---

## Step 3-C-2：@JsonKey 字段注解

需要自定义 JSON 行为时，在字段上使用 `@JsonKey`（需导入 `json_annotation`）：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'user_id') required String userId,         // JSON key 为 user_id
    @JsonKey(name: 'created_at') required DateTime createdAt, // 下划线命名 → 驼峰命名
    @JsonKey(includeIfNull: false) String? avatar,            // null 时不输出此字段
    @JsonKey(name: 'is_admin', defaultValue: false) required bool isAdmin,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}
```

---

## Step 3-C-3：@Default 默认值

使用 `@Default` 时同样需要导入 `json_annotation`（`@Default` 来自 `freezed_annotation`，但确保两者都导入以防隐式依赖问题）：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class Settings with _$Settings {
  const factory Settings({
    @Default(false) bool isDarkMode,       // JSON 中无此字段时使用默认值
    @Default('zh') String language,
    @Default([]) List<String> favorites,   // 空列表默认值
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
}
```

---

## Step 3-C-4：枚举序列化

```dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value') // 序列化时使用 value 字段值
enum UserRole {
  admin('admin'),
  user('user'),
  guest('guest');

  const UserRole(this.value);
  final String value;
}

// 在 @freezed 类中使用
@freezed
class User with _$User {
  const factory User({
    required String id,
    @Default(UserRole.user) UserRole role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## Step 3-C-5：纯状态类（不需要 JSON）

只需要 `copyWith` / `==` / `hashCode`，不需要序列化时，不加 `fromJson` 工厂，不需要 `part 'xxx.g.dart'`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
// 无需导入 json_annotation

part 'app_state.freezed.dart'; // 只需这一个 part

@freezed
class AppState with _$AppState {
  const factory AppState({
    @Default(false) bool isLoading,
    @Default([]) List<String> items,
    String? errorMessage,
  }) = _AppState;
  // 不添加 fromJson，无需 part 'app_state.g.dart'
}
```

---

## Step 3-C-6：在 @freezed 类中添加自定义方法 / getter

`@freezed` 类默认不允许在类体内定义方法。需要先声明一个**私有构造函数**才能添加：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  // 必须先声明这个私有构造，才能在下方添加方法 / getter
  const User._();

  const factory User({
    required String id,
    required String firstName,
    required String lastName,
    String? email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // 自定义 getter（基于字段计算）
  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
  bool get hasEmail => email != null;
}
```

> 如果没有 `const User._()` 私有构造，添加方法会报编译错误。

---

## Step 3-C-7：嵌套对象

嵌套的子对象也需要是 `@freezed` 类（或至少有 `fromJson`）：

```dart
@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required User user,            // User 是 @freezed 类，有 fromJson/toJson
    required List<Product> items,  // Product 同理
    @Default(OrderStatus.pending) OrderStatus status,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
```

---

## Step 3-C-8：Union Types（多态变体）

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

// 不需要 JSON 的 union（无 fromJson）
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.error(String message) = Failure<T>;
  const factory Result.loading() = Loading<T>;
}

// 使用
result.when(
  success: (data) => Text('$data'),
  error: (message) => Text(message),
  loading: () => const CircularProgressIndicator(),
);

// 或部分匹配
result.maybeWhen(
  error: (msg) => showError(msg),
  orElse: () {},
);
```

> 仅在原项目有类似手写 sealed class 时才建议改造，普通数据类不需要。

---

## Step 3-C-9：运行代码生成

所有 `@freezed` 类改造完成后运行：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

成功标志：
- 生成 `xxx.freezed.dart`（含 `copyWith` / `==` / `hashCode` / `toString`）
- 生成 `xxx.g.dart`（含 `_$XxxFromJson` / `_$XxxToJson`，仅有 `fromJson` 工厂时才生成）
- `flutter analyze` 无 error

常见错误处理：

| 错误 | 原因 | 解法 |
|-----|-----|-----|
| `Part file not found` | 忘记 `part` 指令 | 补充 `part 'xxx.freezed.dart'` |
| `The class doesn't have a constructor named '_'` | 添加自定义方法时忘记私有构造 | 补充 `const Xxx._();` |
| `Type '_$Xxx' is not a subtype` | 生成文件与类定义不匹配 | 删除旧生成文件后重新运行 |
| `Conflicting outputs` | 旧生成文件冲突 | 加 `--delete-conflicting-outputs` |
| `@JsonSerializable` on freezed class | 不应在 freezed 类上加此注解 | 删除 `@JsonSerializable()`，保留 `fromJson` 工厂即可 |

---

## 生成文件目录结构

```
lib/
  models/
    user.dart              # 源文件（手动维护）
    user.freezed.dart      # 自动生成，勿手动编辑
    user.g.dart            # 自动生成，勿手动编辑（有 fromJson 时才生成）
    app_state.dart         # 纯状态类（无 fromJson）
    app_state.freezed.dart # 自动生成
    # 无 app_state.g.dart
```

> 建议将生成文件提交到 Git（不加入 `.gitignore`），方便 CI/CD 直接构建无需额外运行 `build_runner`。
