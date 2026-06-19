# freezed 插件

Freezed 数据模型接入：将 plain class 改造为不可变数据类，自动生成 copyWith / fromJson / toJson。

**详细改造规则见** `references/transform-freezed.md`

---

## [INSTALL] 安装步骤

### 前置检查

1. 检查 pubspec.yaml 是否已有 freezed_annotation 依赖
2. 扫描 `lib/models/` 下有多个 final 字段的 plain class 数量
3. 扫描已有手写 fromJson 的 class 数量

### 添加依赖

```yaml
dependencies:
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
dev_dependencies:
  freezed: ^2.4.0
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
```

运行 `flutter pub get`

### 代码改造（读取 references/transform-freezed.md 执行）

核心规则：
- plain class → `@freezed` 注解 + factory constructor
- **禁止**叠加 `@JsonSerializable()`（freezed 已内置）
- 已有手写 fromJson → 删除，改用 `@JsonKey` 处理特殊字段

```dart
// Before:
class User {
  final String id;
  final String name;
  User({required this.id, required this.name});
  factory User.fromJson(Map<String, dynamic> json) => User(id: json['id'], name: json['name']);
}

// After:
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({required String id, required String name}) = _User;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 运行代码生成

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## [UPDATE] 更新步骤

```bash
flutter pub outdated --json  # 检查 freezed_annotation / json_annotation 最新版
```

更新版本号 → `flutter pub get` → 重跑 build_runner

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| A3 | dev_dependencies 完整 | 读取 pubspec.yaml dev_dependencies | build_runner / freezed / json_serializable 均存在 |
| D1 | 业务模型已 freezed 化 | 读 lib/models/ + AI 审查 | 无未加 @freezed 的多字段 plain class |
| D2 | 无多余 @JsonSerializable | `grep -rn "@JsonSerializable" lib/` | 零残余（freezed 已内置） |
| D3 | freezed 生成文件已存在 | `ls lib/**/*.freezed.dart` | 存在 .freezed.dart 文件 |

---

## [USAGE] 使用辅助

### 新建一个 freezed 数据类

```dart
// lib/models/item.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    String? description,  // nullable 字段
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}
```

重跑代码生成后使用：

```dart
final item = Item(id: '1', title: '任务');
final updated = item.copyWith(isCompleted: true);  // 不可变更新
final json = item.toJson();
final fromJson = Item.fromJson(json);
```

### 处理特殊 JSON 字段名

```dart
@freezed
class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    @JsonKey(name: 'user_id') required String userId,  // snake_case → camelCase
    @JsonKey(fromJson: _dateFromJson) required DateTime createdAt,
  }) = _ApiResponse;
}
DateTime _dateFromJson(String s) => DateTime.parse(s);
```

### 联合类型（Union Types）

```dart
@freezed
class AsyncState<T> with _$AsyncState<T> {
  const factory AsyncState.loading() = _Loading;
  const factory AsyncState.data(T value) = _Data;
  const factory AsyncState.error(String message) = _Error;
}

// 使用 when/map 处理
state.when(
  loading: () => const CircularProgressIndicator(),
  data: (value) => Text(value.toString()),
  error: (msg) => Text(msg),
);
```
