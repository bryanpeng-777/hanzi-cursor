---
name: cs-stack-onboarding
description: 【已废弃 · 计划 2026-06-30 删除】原 Flutter 全栈接入技能。已拆分为插件体系（cs-plugin-host + 12 个独立插件），请改用「CS框架接入小助手」触发新流程。原触发词「cs-stack-onboarding」「接入全套框架」「一键接入框架」等仍可用，但会被引导至新插件体系。老项目增量更新仍可使用此文件作参考。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：已拆分为 12 个独立插件（cs-backend / cs-ui / riverpod / freezed / go-router / dio / local-storage / logger / screen-util / cs-image / cs-lottie / cs-video），统一由 `cs-plugin-host` 编排。
>
> **新接入流程**：说「接入 cs 框架」→ CS框架接入小助手 → 插件菜单选择 → 按需安装
>
> **此文件保留供老项目增量参考，计划于 2026-06-30 删除。**

---

# cs-stack-onboarding

将任意 Flutter 项目接入完整技术栈，支持从零接入、增量补全、合并后修复三种模式。

## 技术栈范围

| 层 | 库 | 说明 |
|---|---|---|
| 后台框架 | `cs_framework` | Supabase 认证、数据存储、推送、配置下发 |
| UI 组件 | `cs_ui` | shadcn_ui 封装，CsApp / CsAppBar / ShadButton 等 |
| 状态管理 | `flutter_riverpod` + `riverpod_annotation` | Provider 替代方案 |
| 数据模型 | `freezed` + `json_annotation` | 不可变数据类 + JSON 序列化 |
| 路由 | `go_router` | 声明式路由，替代 Navigator |
| 屏幕适配 | `flutter_screenutil` | 按比例缩放尺寸，仅接入不改造；业务开发时按需使用 |
| HTTP 客户端 | `dio` | 第三方/自建后端 HTTP 请求；Supabase 调用仍走 cs_framework |
| 本地偏好存储 | `shared_preferences` | 简单类型用户偏好（主题/语言/开关等）；复杂对象走 cs_framework |
| 敏感数据存储 | `flutter_secure_storage` | API Key / Token / 密码等敏感凭证 |
| 日志 | `logger` | 替代 print，分级输出，Release 自动关闭 |
| 代码生成 | `build_runner` + `freezed` + `riverpod_generator` + `json_serializable` | dev 依赖 |

---

## 三种模式

| 模式 | 触发条件 | 入口 |
|-----|---------|------|
| **全量接入** | 项目从未接入过框架 | Step 0 → Step 1 → Step 2 → Step 3 → Step 4 → Step 5 |
| **增量补全** | 项目已部分接入，需补全缺失项 | Step 0 → Step 1（Gap 报告）→ Step 2（按需）→ Step 3（按需）→ Step 4 → Step 5 |
| **合并后修复** | 基础线合入产品线后，需检测冲突 + 漂移 + 补全 | **Step 0-M** → Step 1（含漂移警告）→ Step 2/3（按需）→ Step 4 → Step 5 |

> 模式由 AI 自动判断：用户提到「合并」「merge」「基础线合入」时进入合并后修复模式；检测到 `.cs-stack.json` 版本锚点则进入增量补全模式；否则进入全量接入模式。

---

## 版本锚点（`.cs-stack.json`）

为支持增量和合并场景，在项目根目录维护一个 `.cs-stack.json` 文件（接入时自动创建/更新）：

```json
{
  "version": "1.0",
  "last_onboarded_at": "2025-04-15",
  "completed_steps": ["2-3", "3-A", "3-B", "3-C", "3-J"],
  "in_progress_step": "3-D",
  "in_progress_step_progress": "已完成 ElevatedButton×7，剩余 AppBar×4 / Card×2",
  "infra_merge_commit": "abc1234",
  "stack_libs": {
    "flutter_riverpod": "^2.5.0",
    "go_router": "^14.0.0",
    "freezed_annotation": "^2.4.0"
  }
}
```

用途：
- **增量补全**：`completed_steps` 告知 Step 0 哪些步骤已完成，仅扫描未完成项
- **中断恢复**：`in_progress_step` 记录上次中断时正在执行的步骤和进度，下次开工直接续点
- **漂移检测**：`stack_libs` 记录上次接入时的版本，与当前 `pubspec.yaml` 对比，发现降级或删除
- **合并溯源**：`infra_merge_commit` 记录上次合入的基础线 commit，便于 `git diff` 精准锁定本次合并范围

**中断恢复逻辑（Step 0 检测）：**

若读取到 `in_progress_step` 字段不为空，在 Gap 报告前先询问用户：

```
⏸️  发现上次中断的步骤：3-D UI 组件改造
   进度：已完成 ElevatedButton×7，剩余 AppBar×4 / Card×2

说「继续」→ 从断点恢复（跳过已完成部分）
说「重来」→ 重新扫描并从头执行该步骤
说「跳过」→ 标记为已完成，继续后续步骤
```

**写入时机：**
- 每个步骤**开始时**：写入 `in_progress_step` + 初始进度描述
- 每个子步骤完成时：更新 `in_progress_step_progress`（如「已完成 ElevatedButton×7」）
- 整个步骤完成时：将 `in_progress_step` 清空，把步骤 ID 追加到 `completed_steps`

---

## 核心流程

```
Step 0:   扫描项目 → 检测已安装的库 + 统计各类改造目标数量
  ↓ 合并后修复模式时，先执行 Step 0-M
Step 0-M: 合并后扫描 → 冲突检测 + 版本漂移 + 接入完整性复查
Step 1:   Gap 报告 → 展示待安装库 + 待改造项（含漂移警告），等待用户确认
Step 2:   库安装 → 按需安装缺失的库（已装则跳过）；cs_ui 接入时自动执行 2-4 Cursor hooks 初始化
Step 3:   代码改造 → 逐类自动改造（可按类跳过）
Step 4:   构建验证 → flutter pub get / build_runner / flutter analyze
Step 5:   收尾 → 5-1 写入 CLAUDE.md 框架规范 + 5-2 更新 .cs-stack.json 版本锚点
```

---

## Step 0-M：合并后扫描（仅合并后修复模式）

> **读取 `references/merge-mode.md` 并按其规则执行。**

包含 5 个子步骤：冲突文件检测（0-M-1）→ 冲突解决指引（0-M-2）→ 版本漂移检测（0-M-3，含 Breaking Change 速查表）→ CLAUDE.md 过期检测（0-M-4）→ 接入漂移检测（0-M-5）。

> 合并后修复模式执行完 Step 4 后，**无论 CLAUDE.md 是否过期都强制执行 Step 5-1**。

---

## Step 0：项目扫描

读取目标项目的 `pubspec.yaml`（路径由当前工作区自动检测），并检查 `.cs-stack.json` 版本锚点：

```
检测以下库是否在 dependencies / dev_dependencies 中：
  dependencies: cs_framework / cs_ui / go_router / flutter_riverpod / freezed_annotation / json_annotation / flutter_screenutil / dio / shared_preferences / flutter_secure_storage / logger
  dev:          build_runner / freezed / riverpod_generator / json_serializable
```

**版本锚点增量优化**：若 `.cs-stack.json` 存在，读取 `completed_steps` 字段，对已完成步骤**跳过扫描**（直接标记为「已完成」），仅对未完成步骤执行扫描统计。

同时检测：
- `http` 包是否存在（`import 'package:http/http.dart'` 或 pubspec.yaml 中有 `http:` 依赖），有则纳入 Step 3-G 迁移范围
- 散落的 `SharedPreferences.getInstance()` 调用数量，纳入 Step 3-H 改造范围
- 代码中硬编码的疑似敏感字符串（含 `api_key` / `token` / `secret` / `password` 的变量名或字符串值如 `sk-` / `AIza`），纳入 Step 3-I 迁移范围
- `print(` / `debugPrint(` / `developer.log(` 调用数量，纳入 Step 3-J 迁移范围

**同时检测 Android 原生构建配置版本**（避免 Step 4-2 编译失败）：

| 检测文件 | 检测项 | 获取当前要求 |
|---------|--------|------------|
| `android/gradle/wrapper/gradle-wrapper.properties` | `distributionUrl` 中的 Gradle 版本 | 运行 `flutter doctor` 查看推荐版本 |
| `android/settings.gradle` | `com.android.application` 版本（AGP） | Flutter 最低要求可从 `flutter doctor` 获取 |
| `android/settings.gradle` | `org.jetbrains.kotlin.android` 版本 | 需 ≥ 所有 Flutter 插件依赖的 Kotlin stdlib 版本 |

若发现版本过旧，在 Step 1 Gap 报告中列出 ⚠️，并在 Step 4-2 之前自动修复。

同时扫描 `lib/` 目录下所有 `.dart` 文件，统计改造目标数量：

| 扫描项 | 统计内容 |
|-------|---------|
| `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed` | 路由调用数量 |
| `MaterialApp(` / `routes:` / `onGenerateRoute:` | 路由配置数量 |
| `extends StatefulWidget` / `setState(` | 状态管理目标数量 |
| `lib/models/` 下有多个 `final` 字段的 plain class | 模型改造数量 |
| `Image.asset(` / `Image.network(` / `CachedNetworkImage(` | 图片写死用法数量 |
| `ElevatedButton(` / `TextButton(` / `AppBar(` / `Card(` / `Chip(` / `TabBar(` | UI 组件残余数量 |
| Unicode 表情符号（含 U+2600–U+27BF、U+1F000–U+1FAFF 等）在 `lib/**/*.dart` 中的字面量 | 含 Text/字符串/数据字段/注释在内的总处数 |

---

## Step 1：Gap 报告 + 改造预览（等待用户确认）

输出格式：

```
📦 待安装（N 项）：  freezed_annotation / json_annotation / riverpod_annotation / build_runner ...
📦 待接入（仅初始化，不改造代码）：flutter_screenutil / dio
⚠️  发现旧 http 包：需迁移至 DataManager 或 DioClient（见 3-G）
⚠️  cs_framework / cs_ui 使用非标准 path: 路径（应为 ../cs/cs_framework）：见 2-1
  3-H 本地存储：发现 N 处散落 SharedPreferences 调用 / M 处可持久化的偏好变量
  🔴 发现疑似敏感数据：N 处硬编码 key/token / M 处 SharedPreferences 存储敏感字段（见 3-I）
  3-J print 替换：发现 print×N / debugPrint×M / developer.log×K（共 X 处，将替换为 appLogger）
✅ 已安装（M 项）：  cs_framework / cs_ui / go_router / flutter_riverpod

🔧 待改造（按类展示）：
  3-A go_router：  发现 12 处 Navigator.push，3 处 routes: {}
  3-B Riverpod：   发现 8 个 StatefulWidget，15 处 setState
  3-C freezed：    发现 lib/models/ 下 5 个 plain class，3 个有手写 fromJson
  3-D UI 组件：    ElevatedButton×7 / AppBar×4 / Card×2 / Chip×1（共 14 处）
  3-E 图片/动画：  Image.asset×5 / Image.network×2 / Lottie×1
  3-F 无 Emoji：   发现 23 处 Unicode 表情字面量（须清零，见 3-F）
  3-K 可测试性：   main/test_helpers 初始化重复×1 / 关键 Widget 缺 Key×8

🚨 接入漂移（仅合并后修复模式显示）：
  🔴 main.dart：ScreenUtilInit 初始化丢失 → 需修复（见 Step 2）
  🟡 analysis_options.yaml：avoid_print 规则被移除 → 需修复（见 Step 3-J）

说「确认」开始全部执行
说「跳过 3-C」可跳过某个改造步骤
说「只做 3-A」可只执行某步
说「只修漂移」可只修复接入漂移项（跳过新增改造）
```

---

## Step 2：库安装（按增量检测结果执行）

### 2-1 cs_framework 完成度检测

| 情形 | 标志 | 处理 |
|-----|-----|-----|
| 完全未接入 | pubspec.yaml 无 `cs_framework` | 读取并完整执行 `cs-framework-onboarding` 技能 |
| 已装但未初始化 | pubspec 有依赖，但 `main.dart` 无 `CsClient.initialize()` | 只执行 cs-framework-onboarding 的客户端 Step（跳过后台建表） |
| 已完成 | pubspec 有依赖 + `CsClient.initialize()` 已在 main.dart | 跳过，仅做数据访问规范扫描 |

**依赖声明规范（新产品项目）**：

cs 大仓和产品项目在同一父目录下（标准工作区结构）：

```
<工作目录>/
├── cs/                  ← cs 大仓（cs_framework / cs_ui / cs_infra）
├── product_a/           ← 产品项目（与 cs 同级）
└── product_b/
```

基于此结构，依赖声明采用**双层方案**：

**本地开发（path:）**：在 `pubspec.yaml` 使用 `path:` 引用，路径固定为 `../cs/cs_framework`，团队所有人路径一致，cs_framework 代码变更立即生效：

```yaml
dependencies:
  cs_framework:
    path: ../cs/cs_framework
  cs_ui:
    path: ../cs/cs_ui
```

**CI / 远程构建（git:）**：在 `pubspec_overrides.yaml`（加入 `.gitignore`）覆盖为 `git:` URL，或 CI 环境同级 clone cs 仓库使 `path:` 写法同样生效。

**接入时路径验证**：在 Step 0 扫描时，检查 `../cs/cs_framework` 是否存在：
- 存在 → 使用 `path:` 写法
- 不存在 → 直接使用 `git:` URL 写法，提示建议 clone cs 仓库到同级目录

若扫描到已使用 `path:` 但路径不是 `../cs/cs_framework`，在 Step 1 标记 ⚠️ 建议对齐标准路径。

### 2-2 cs_ui 完成度检测（逐组件独立）

**不整体判断，而是对每类组件独立检测**——只要某类有残余，该类就纳入 Step 3-D 改造；参见 Step 3-D 详细表格。

### 2-3 其他库安装

检测到缺失时，直接编辑 `pubspec.yaml`：

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.4.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  go_router: ^14.0.0
  flutter_screenutil: ^5.9.0
  dio: ^5.7.0
  shared_preferences: ^2.3.0
  flutter_secure_storage: ^9.2.0
  logger: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  riverpod_generator: ^2.4.0
  json_serializable: ^6.7.0
```

安装完成后执行 `flutter pub get`。

各库的初始化详情（ScreenUtilInit / Dio / shared_preferences / flutter_secure_storage / logger）见原有 Step 2 对应小节，此处省略重复内容。初始化时需读取对应的 `references/transform-*.md`。

### 2-3b URL Scheme 自动配置（cs_framework 接入时自动执行）

当检测到 `CsClient.initialize()` 被写入或已存在时，自动配置用于密码重置深链接的 URL Scheme：

**命名规则**：`mountain` + `appId`（全小写，去除特殊字符），例如：
- `appId = "demo"` → `mountaindemo`
- `appId = "my-app"` → `mountainmyapp`

**Step 2-3b-1：`CsClient.initialize()` 加入 urlScheme 参数**

```dart
await CsClient.initialize(
  supabaseUrl: ...,
  supabaseAnonKey: ...,
  appId: 'your-app',
  urlScheme: 'mountainyourapp',  // ← 新增
);
```

**Step 2-3b-2：iOS 配置（`ios/Runner/Info.plist`）**

在 `Info.plist` 中找到（或新建）`CFBundleURLTypes` 节点，加入：

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>mountainyourapp</string>
    </array>
  </dict>
</array>
```

已存在 `CFBundleURLTypes` 时，在 `array` 内追加新 `<dict>` 节点，不覆盖已有配置。

**Step 2-3b-3：Android 配置（`android/app/src/main/AndroidManifest.xml`）**

在主 Activity 的 `<intent-filter>` 内加入（或新建一个独立的 `<intent-filter>`）：

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="mountainyourapp" />
</intent-filter>
```

**Step 2-3b-4：验证**

配置完成后输出：

```
✅ URL Scheme 配置完成
   Scheme：mountainyourapp
   iOS：Info.plist ✓
   Android：AndroidManifest.xml ✓
   CsClient.initialize(urlScheme: 'mountainyourapp') ✓

⚠️  上线前检查清单（密码重置邮件相关）：
   □ Supabase Dashboard → Authentication → Email Templates：确认「Reset Password」邮件模板中的 Redirect URL 包含 mountainyourapp://reset-password
   □ Dashboard → Authentication → URL Configuration → Redirect URLs：添加 mountainyourapp://reset-password
   □ 生产环境邮件：Authentication → SMTP Settings 配置第三方 SMTP（Supabase 自带每小时限 4 封）
```

**跳过条件**：
- 若 `Info.plist` / `AndroidManifest.xml` 不存在（纯 Dart 项目 / 单元测试场景），则跳过对应平台配置，仅更新 `CsClient.initialize()`
- 若目标 scheme 已在平台配置中存在，则跳过对应平台步骤

⚠️ 已知踩坑（2026-04-16）：
- 现象：增量补全模式下，Step 2-3b 的 iOS/Android 原生配置常被跳过；`CsClient.initialize(urlScheme:)` 已写入代码，但 Info.plist 和 AndroidManifest.xml 中没有对应 Scheme，导致密码重置深链接无法唤起 App
- 根因：增量模式重点检查已完成步骤的漂移，但 Step 2-3b 是新增能力（框架首次引入 urlScheme），既往 completed_steps 中没有记录，导致被漏掉
- 修正：每次增量扫描时，无论 completed_steps 是否包含 Step 2，都必须额外检查 E3/E4（原生 URL Scheme 配置），将其作为独立的必验项，不依赖 completed_steps 记录

### 2-4 Cursor hooks 初始化（cs_ui 接入时自动执行）

> **读取 `references/cursor-hooks-setup.md` 并按其规则执行。**

在 cs_ui 已安装且 `.cursor/hooks.json` 缺少 manifest sync hook 时，自动创建 hooks.json、shell 脚本、Python 脚本和空 manifest 文件。Cursor hooks 无需任何安装命令，文件存在即生效。

---

## Step 3：代码改造

### 推荐执行顺序

```
3-I（敏感数据）→ 3-J（print替换）→ 3-C（freezed 模型）→ 3-B（Riverpod 状态）
→ 3-A（go_router 路由）→ 3-G（http迁移）→ 3-H（本地存储）
→ 3-D（UI组件）→ 3-E（图片/动画）→ 3-F（Emoji）→ 3-K（可测试性）
```

理由：3-I 最高优先级（安全）→ 3-J 无依赖先消噪 → 3-C 先于 3-B（模型先于状态）→ 3-B 先于 3-A（Provider 先于路由）→ 3-D/E/F 纯 UI 层 → 3-K 最后执行（依赖其他改造完成后的最终代码结构）。

### `build_runner` 统一执行

3-B（Riverpod）和 3-C（freezed）改造期间不逐一运行 build_runner，两者都完成后在 Step 4 统一运行一次。

### 3-A go_router 路由改造

**读取 `references/transform-go-router.md` 并按其规则执行。**

核心：新建 `lib/router/app_router.dart` → `MaterialApp.router(routerConfig: appRouter)` → `Navigator.push/pop` → `context.go/push/pop`

⚠️ 已知踩坑（2026-04-16）：
- 现象：`showModalBottomSheet` 内用 `Navigator.pop(ctx)` 关闭弹窗，被 C3 检查判为残余
- 根因：改造时只关注页面导航的 Navigator 调用，遗漏了 BottomSheet 内的关闭回调
- 修正：BottomSheet 内关闭弹窗应使用 `ctx.pop()`（go_router extension），行为完全等价，且满足 C3 零 Navigator 的要求；3-A 改造完成后的核查命令需覆盖所有 `Navigator.pop` 用法，不仅限于页面导航

### 3-B Riverpod 状态改造

**读取 `references/transform-riverpod.md` 并按其规则执行。**

核心：`ProviderScope` 包裹 → 所有业务状态提升为 `@riverpod Notifier` → Widget 内业务逻辑 `setState` 清零

**⚠️ 改造标准（转换类名不等于完成）：**
- 业务状态字段（`_loading`、`_items`、`_statusMessage`、Stream 监听结果等）必须全部移入 Provider
- `initState` 中的网络请求/Stream 订阅必须迁移到 `Provider.build()` + `ref.onDispose`
- `StatefulWidget → ConsumerStatefulWidget` 只是前提，不是终点
- 只有 `TextEditingController`、`AnimationController`、Tab index 等纯 UI 控制器可保留本地 setState
- 改造完成后必须执行 Step 3-B-7 核查，核查通过才能进入 Step 4

⚠️ 已知踩坑（2026-04-18）：
- 现象：改造完 ChangeNotifier → Riverpod 后，cs-stack-checker 仍发现 3-5 个屏幕用 `setState` 存储从 `ConfigManager.getXxx()` 异步加载的配置（如 `_spellGameEnabled`、`_wordCount`、`_timeLimit`）
- 根因：改造时只关注「业务数据状态（列表/用户数据）」，忽视了「后端配置值的本地缓存」同样属于需要 Provider 管理的业务状态
- 修正：3-B 改造阶段必须额外扫描所有 `ConfigManager.get*()` / `RemoteConfig` 调用——只要其结果被赋给局部 State 字段并通过 setState 更新，就必须提取到独立的 `@Riverpod(keepAlive: true) class XxxConfig extends _$XxxConfig` Provider 中；建议将同类型配置合并到一个 `GameConfigProvider` 或 `AppConfigProvider`

### 3-C freezed + json_annotation 模型改造

**读取 `references/transform-freezed.md` 并按其规则执行。**

核心：plain class → `@freezed` 注解 + factory constructor；禁止叠加 `@JsonSerializable()`

### 3-D UI 组件改造（逐组件独立）

| 扫描目标 | 改造动作 |
|---------|---------|
| `ElevatedButton` / `TextButton` / `OutlinedButton` | → `ShadButton` |
| `AppBar(` | → `CsAppBar` |
| `Card(` | → `ShadCard` |
| `Chip(` | → `ShadBadge`（仅 Material Chip） |
| `TabBar(` / `TabBarView` | → `ShadTabs`（仅内容定高场景） |

### 3-E 图片/动画/视频改造

调用 `cs-image-manager` / `cs-lottie-manager` / `cs-video-manager` 技能扫描并替换写死用法。

### 3-F 禁止 Emoji：一律 `CsImage` + 配置键（强制）

> **验收：`lib/` 下任意 `.dart` 源码中不得出现 Unicode 表情符号字面量**（含 `Text('…')`、拼接标题、数据常量、注释里的示例字符）。  
> 「装饰含义」用 **纯中文/英文 `description`** 写在 `CsImage(description: …)` 与数据字段（如 `iconHint`）中，**禁止**用 emoji 代替语义。

**必须执行：**

1. **全量扫描**：对 `lib/**/*.dart` 扫描常见 emoji 区段（含 ⭐、🔥、📚 及 U+1F300+ 等）；`flutter analyze` 不能替代此步。
2. **UI 装饰**：原 `Text('🔥')` 等 → `CsImage(configKey: '…', description: '…')`；`default_configs.json` 为每个 `configKey` 增加占位条目（`url`/`asset` 均可为 null）。
3. **数据层**：模型字段禁止命名为 `emoji`、禁止存储 Unicode 表情；使用 `iconHint`（或 `illustrationLabel`）存**无表情的短文案**（如 `「雨」识字配图：天气现象`），与 `hanzi_icon_雨` 等 `configKey` 一一对应。
4. **拼音例图**：`PinyinItem` 等使用 `iconHint` + `pinyin_icon_${symbol}`，与汉字数据同等规则。
5. **登记**：新建或更新 `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`（可调用 `cs-image-manager` / `cs-image` 从 `default_configs.json` 导入插槽），便于后续批量换正式图。

**可选**：若仓库内仍有 `cs-ui-onboarding` 的专项扫描清单，可作为补充，**不得**仅以「触发另一技能」代替上述 1–5 步。

⚠️ 已知踩坑（2026-04-19）：
- 现象：仅把界面上的 `Text(emoji)` 换成 `CsImage`，`lib/data/*.dart` 与模型字段仍保留 emoji 字符串，用户要求「项目里不能有 emoji」未满足。
- 根因：把「Emoji 改造」理解成仅 UI 装饰层，遗漏数据常量与 `⭐` 等杂项符号。
- 修正：3-F 明确为「源码零表情」+ 数据字段改名 + manifest 登记。

### 3-G http 包 → Dio / DataManager 迁移

**读取 `references/transform-dio.md` 中的「Step 3-G」部分并执行。**

Supabase URL → `DataManager`；其他 URL → `DioClient`；完成后删除 `http:` 依赖。

### 3-H 本地存储改造 → shared_preferences

**读取 `references/transform-shared-preferences.md` 中的「Step 3-H」部分并执行。**

散落 `SharedPreferences.getInstance()` → `ref.read(preferencesManagerProvider)`。

### 3-I 敏感数据 → SecureStorageManager 迁移

**读取 `references/transform-secure-storage.md` 中的「Step 3-I」部分并执行。**

硬编码 API Key / Token → 从 `SecureStorageManager` 读取。优先级最高（🔴 高危）。

### 3-J print → appLogger 替换

**读取 `references/transform-logger.md` 中的「Step 3-J」部分并执行。**

覆盖 `print` / `debugPrint` / `developer.log`，按语义判断日志级别。

### 3-K 可测试性改造

扫描项目是否满足自动化测试的基本条件，执行以下改造：

**3-K-1 初始化逻辑抽取**

检查 `main()` 与 `integration_test/test_helpers/` 下是否存在重复的初始化参数（如 `CsClient.initialize()` 参数各写一份）：
- 发现重复 → 新建 `lib/app_initializer.dart`，将初始化逻辑集中在 `initializeApp({bool clearAnonymousSession})` 函数中
- `main.dart` 改为调用 `await initializeApp(clearAnonymousSession: true)`
- `test_helpers/test_app.dart` 改为调用 `await initializeApp(clearAnonymousSession: false)`（测试由 setUp/ensureLoggedOut 手动控制登录态）
- 已有 `app_initializer.dart` 且无重复 → 跳过

**3-K-2 关键 Widget 加 Key**

扫描以下 Widget，若缺少 `Key` 则补充语义化 `Key`：
- 底部导航 Tab 项（按文字标签命名，如 `Key('bottom_nav_首页')`）
- 环境切换按钮（如 `Key('env_badge_dev')`、`Key('env_badge_prod')`）
- 核心操作按钮（如添加、删除、提交等，命名如 `Key('add_favorite_button')`）
- 登录/注册表单的 submit 按钮（如 `Key('login_submit_button')`）

**验收标准：**
- `lib/app_initializer.dart` 存在，`main.dart` 和 `test_helpers` 均调用它
- 核心交互 Widget 有语义化 Key，测试可通过 `find.byKey` 定位

---

## Step 4：构建验证

### 4-1 Dart 层验证

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

- 无 error → 通过
- 有 warning → 展示列表，询问用户是否修复
- 有 error → 自动修复后重新验证（最多重试 3 次）

### 4-2 原生层编译验证（Dart 层通过后必须执行）

```bash
flutter build ios --no-codesign
flutter build apk --debug
```

- 两个平台均编译成功 → 通过
- 任一失败 → 分析错误原因，修复后重试
- 若项目不支持某平台（纯 Web 项目等），可跳过对应平台并注明原因

**常见原生编译失败原因及修复：**

| 错误特征 | 根因 | 修复方法 |
|---------|------|---------|
| `AGP version X is lower than Flutter's minimum` | settings.gradle 的 AGP 版本过旧 | 升级 AGP 到 Flutter 当前最低要求（见 flutter doctor） |
| `Gradle version X will soon be dropped` / build fail | gradle-wrapper.properties 版本过旧 | 升级 Gradle 到 8.7+ |
| `Kotlin metadata version X.X.X but compiler can read up to Y.Y` | Kotlin 插件版本低于某依赖包的 stdlib 版本 | 升级 Kotlin 插件至 settings.gradle 中依赖包要求的版本 |
| iOS `CocoaPods recommended version` | Pod 版本低 | `sudo gem install cocoapods` 更新 |

⚠️ 已知踩坑（2026-04-18）：
- 现象：Step 4 跑完 `flutter analyze` 零 error 后判定「构建验证通过」，直接进入 Step 5；但实际 Android 编译失败（Gradle 8.3 / AGP 8.1.0 / Kotlin 1.8.22 版本过旧），iOS 编译成功
- 根因：Step 4 只定义了 Dart 层的三条命令（pub get / build_runner / analyze），这三条完全不涉及原生 Android/iOS 构建；`flutter analyze` 不读取 `.gradle` 文件，Gradle/AGP/Kotlin 版本过旧在 Dart 层是透明的
- 修正：Step 4 拆分为「4-1 Dart 层」和「4-2 原生层」两个阶段，两者均通过才算完成；原生层编译失败是阻塞性问题，不得跳过进入 Step 5

**每个改造步骤完成后，额外执行以下收尾核查（不可跳过）：**

| 改造步骤 | 核查命令 | 验收标准 |
|---|---|---|
| 3-B Riverpod | `grep -rn "setState(" lib/` | 业务逻辑 setState 清零（详见 3-B-7 核查规则） |
| 3-A go_router | `grep -rn "Navigator\." lib/` | 零 Navigator.push/pop/pushNamed |
| 3-J print 替换 | `grep -rn "print\|debugPrint" lib/` | 零 print / debugPrint |
| 3-D UI 组件 | `grep -rn "ElevatedButton\|AppBar(" lib/` | 零残余 Material 原生组件 |
| 3-K 可测试性 | `ls lib/app_initializer.dart` | app_initializer.dart 存在，main.dart 和 test_helpers 均调用 initializeApp() |

发现残余 → 回到对应步骤继续改造，不得以「留着以后再改」为由跳过。

---

## Step 5：写入项目规范 + 更新版本锚点

### 5-1 写入 CLAUDE.md / AGENTS.md

> **读取 `references/claudemd-template.md` 并按其写入规则和模板执行。**

根据项目实际接入的库按需裁剪模板，写入或更新 `CLAUDE.md` 的 `## 技术栈规范` 章节。

**⚠️ 执行 5-1 的完整流程（两步缺一不可）：**

**第一步：写入/更新技术栈规范章节**

按 `claudemd-template.md` 的「基本判断」规则执行（创建 / 追加 / 替换）。

**第二步：过时内容扫描与清理（不可省略）**

按 `claudemd-template.md` 的「过时内容扫描与更新」规则，扫描全文并修正矛盾描述：
- `## 状态管理` 章节含旧 ChangeNotifier/Provider → 更新为 Riverpod
- `## 依赖说明` 含 `provider:` 依赖条目 → 移除并补充新依赖
- `## 项目结构` 的 providers/models 目录 → 更新为实际文件
- 任意 `context.read<XProvider>()` / `context.watch<XProvider>()` API 示例 → 更新为 ref.watch/read
- 扫描完毕后全文搜索 `ChangeNotifier`、`extends Provider`、`provider:` 依赖，确认为零

⚠️ 已知踩坑（2026-04-18）：
- 现象：只执行了第一步（追加规范章节），跳过了第二步（扫描旧内容）；文件前半部分的旧 Provider 描述和 `provider: ^6.1.2` 依赖全部保留，直到用户主动检查才发现
- 根因：5-1 的描述只说「写入技术栈规范章节」，没有明确要求扫描清理；追加章节后产生了"完成感"
- 修正：明确两步流程，第二步与第一步同等必须；5-1 执行完毕的验收标准是「全文无 ChangeNotifier / provider 包 / 旧 API」，而非仅「规范章节存在」

### 5-2 更新版本锚点（`.cs-stack.json`）

在 Step 4 验证通过后，自动写回 `.cs-stack.json`：

```json
{
  "version": "1.0",
  "last_onboarded_at": "<今日日期 YYYY-MM-DD>",
  "completed_steps": ["<累加历史 + 本次执行的所有步骤>"],
  "infra_merge_commit": "<git rev-parse HEAD，仅合并后修复模式填写>",
  "stack_libs": { "<从当前 pubspec.yaml 读取所有框架库版本>" }
}
```

规则：
- `completed_steps` 为**累加**，不覆盖历史记录
- `in_progress_step` 在步骤完成时清空为 `null`，中断时保留
- `stack_libs` 从当前 `pubspec.yaml` 全量刷新

### 5-3 初始化项目管理文件（project_info & launch_checklist & test_manifest）

> ⚠️ **5-3 与 5-1、5-2 同等必须，不是可选收尾。** 5-3 的两个子任务必须逐一执行文件检查，不得以「onboarding 已完成」为由跳过。

**5-3-1 项目台账初始化（project_tracker.md）**

**先执行文件检查**，再决定行为：

检查项目的 `aiworkspace/` 目录下是否存在 `project_tracker.md`：

- **不存在** → 读取并执行 `cs-project-manager` 技能的 Step 2（初始化台账），询问用户 App 名称和启用的能力（支付/广告/推送/认证），根据选择自动生成对应任务清单，完成后提示：
  ```
  ✅ 已初始化项目台账：
    - aiworkspace/project_tracker.md（含项目信息 + 任务台账）
  后续说「项目小助手」随时查看进度和更新任务状态。
  ```
- **已存在** → 跳过，不覆盖。

⚠️ 已知踩坑（2026-04-18）：
- 现象：5-3-1 和 5-3-2 均未执行，直至用户主动询问才发现
- 根因：5-3 用「检查 → 若不存在则执行另一个技能」的间接结构描述，在长流程末尾被当作"可选检查"跳过；加之 5-3-1 需要停下来询问用户（能力选择），打断了"全自动收尾"的节奏
- 修正：在 5-3 节首加强制提示，明确与 5-1/5-2 同等级；Step 5 完成检查点也必须包含「5-3 是否执行」的自检

**5-3-2 test_manifest.md（测试台账）**

检查项目根目录下是否存在 `test_manifest.md`：

- **不存在** → 读取并执行 `cs-test-manager` 技能的 Step 2（初始化），优先用扫描模式从 `integration_test/` 自动生成，若 `integration_test/` 不存在则写入空模板。完成后提示：
  ```
  ✅ 已初始化测试台账：
    - test_manifest.md（测试用例清单）
  后续说「测试管理」可查看、新增用例或跑全量测试。
  开发新功能时，Plan 阶段会自动读取此文件并提出测试用例设计。
  ```
- **已存在** → 跳过，不覆盖。

> 🚨 **Step 5 完成 → 立即执行 Step 6，禁止在此输出「框架接入完成」等总结性文字。** 总结必须等 Step 6 全部通过后才能输出。
>
> **Step 5 自检清单（完成 5-2 后，输出任何内容前必须逐项确认）：**
> - [ ] 5-1 CLAUDE.md 技术栈规范已写入？
> - [ ] 5-2 .cs-stack.json 已写入？
> - [ ] 5-3-1 project_tracker.md 已检查（存在则跳过，不存在则已初始化）？
> - [ ] 5-3-2 test_manifest.md 已检查（存在则跳过，不存在则已初始化）？
> - [ ] Step 6 cs-stack-checker 已开始执行？
>
> 以上任一为「否」→ 立刻补执行对应步骤，禁止输出总结。

---

## Step 6：自动触发接入检查者（Step 5 完成后强制执行）

Step 5 全部完成后，**立即自动读取并执行 `cs-stack-checker` 技能**，无需用户触发：

```
读取 /Users/pengchao/.claude/skills/cs-stack-checker/SKILL.md
按检查者的流程执行全量检查（最多 3 轮）
```

> 这一步不可跳过。cs-stack-checker 负责验证本次接入是否彻底，发现问题会打回此技能补修，并推动此技能通过反思持续进化。

**⚠️ 强制检查点（Step 5 结束时必须对自己提问）：**

> 「我是否已经读取并开始执行 cs-stack-checker？」
> 如果答案是否，则不论当前输出了多少总结文字，都必须立刻读取并执行。
> 生成总结 ≠ 任务结束。Step 6 是 onboarding 的最后一步，不是可选收尾。

⚠️ 已知踩坑（2026-04-16）：
- 现象：增量模式只做了旧文件清理和 auth 组件替换，认为「没有跑完完整流程」就跳过了 Step 5 和 Step 6
- 根因：Step 6 的触发条件写成「Step 5 完成后」，增量模式下 Step 5 常被视为可选项，导致检查从未执行
- 修正：触发规则改为「本次会话有任何实质性改动就必须执行」；同时明确：增量模式的最后一步永远是 Step 5 → Step 6，不得省略

⚠️ 已知踩坑（2026-04-18）：
- 现象：Step 5 正常完成后，输出了「框架接入完成！」的大段总结，Step 6 被遗漏，直到用户主动提问才补执行
- 根因：连续执行 7 个步骤后，Step 5 的完成感触发了「任务结束」的输出冲动；总结文字本身是对「任务完成」的信号强化，使 Step 6 的触发被覆盖。Step 6 在 SKILL.md 末尾，触发声明未在执行路径上形成阻断
- 修正：在 Step 5 完成节点增加「强制检查点」——输出总结前必须先问自己「Step 6 是否已执行」；技能文档在 Step 5 节末尾也需要加一行醒目提示，不只在 Step 6 节首说明

---

## 注意事项

- **确认不可跳过**：Step 1 的改造预览必须等用户确认后才开始执行
- **每步完成后汇报**：执行完一个子步骤后，汇报「已完成 3-A，共改动 N 个文件」再继续
- **cs-framework-onboarding 委托时**：需完整读取该技能的 SKILL.md 并按其流程执行，不得简化
- **ShadTabs 踩坑**：Tab 内容是 GridView/ListView 时不适用，应保留原生 TabBar
- **build_runner 冲突**：改造后若 build_runner 报冲突，加 `--delete-conflicting-outputs` 参数

### 双线并行开发

> **读取 `references/dual-track-guide.md` 了解最佳实践。**

核心：基础线只改框架文件，产品线只在 `lib/features/` 开发业务；合入后立即运行合并后修复模式。

## 引用文件索引

| 文件 | 内容 | 何时读取 |
|-----|------|---------|
| `references/merge-mode.md` | Step 0-M 完整流程（冲突解决/版本漂移/接入漂移/Breaking Change 表） | 合并后修复模式 |
| `references/claudemd-template.md` | CLAUDE.md 技术栈规范模板 + 写入规则 | Step 5-1 |
| `references/cursor-hooks-setup.md` | Cursor hooks 初始化详细步骤 | Step 2-4（cs_ui 接入时） |
| `cs-project-manager/SKILL.md` | 项目台账管理技能（项目信息 + 任务进度追踪，说「项目小助手」触发） | Step 5-3-1 |
| `cs-test-manager/SKILL.md` | 测试用例台账管理技能 | Step 5-3-2 |
| `references/dual-track-guide.md` | 双线并行开发最佳实践 | 按需参考 |
| `references/transform-go-router.md` | go_router 改造规则 | Step 3-A |
| `references/transform-riverpod.md` | Riverpod 改造规则 | Step 3-B |
| `references/transform-freezed.md` | freezed 改造规则 | Step 3-C |
| `references/transform-dio.md` | Dio 接入 + http 迁移规则 | Step 2 / Step 3-G |
| `references/transform-shared-preferences.md` | shared_preferences 接入 + 改造规则 | Step 2 / Step 3-H |
| `references/transform-secure-storage.md` | secure_storage 接入 + 迁移规则 | Step 2 / Step 3-I |
| `references/transform-logger.md` | logger 接入 + print 替换规则 | Step 2 / Step 3-J |

---

## Related Skills

- **[cs-stack-checker](../cs-stack-checker/SKILL.md)**: 接入完成后自动验证（AI 自动触发），检查 Riverpod 迁移、路由改造、UI 替换是否彻底
- **[cs-ui-onboarding](../cs-ui-onboarding/SKILL.md)**: 只做 UI 层接入（shadcn 组件替换）时使用，比全量接入更轻量
- **[production-risk-checker](../production-risk-checker/SKILL.md)**: 接入完成、上线前做现网风险扫描
