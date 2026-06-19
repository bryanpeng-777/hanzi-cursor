---
name: cs-stack-checker
description: 【已废弃 · 计划 2026-06-30 删除】原 cs 框架接入完整性检查者。其 26 项检验已分散到各插件 subAgent 的 VERIFY 步骤，全局验收（I1/I4/I5）移至 cs-plugin-host。新项目请使用插件体系，不再需要单独调用此技能。
---

> ⚠️ **DEPRECATED（废弃声明）**
>
> **废弃时间**：2026-04-30
> **计划删除**：2026-06-30
>
> **迁移方向**：
> - 26 项检验已分散到各插件的 `[VERIFY]` 章节（B→riverpod、C→go-router、D→freezed、E/F→cs-backend、G→cs-ui、H→logger/local-storage、A/I→主机层）
> - 全局验收（flutter analyze / iOS/Android 编译）移至 `cs-plugin-host/SKILL.md` 的「全局验收」章节
> - 老项目打回+补修循环由各插件 subAgent 自行处理
>
> **此文件仅供老项目参考，请勿在新流程中调用。**

---

# cs-stack-checker

cs 框架接入完整性检查者。对 cs-stack-onboarding 的输出结果做系统化验证，发现问题打回重做，并推动 cs-stack-onboarding 技能持续进化。

## 工作流程

```
cs-stack-onboarding Step 5 完成
    ↓ 自动触发（或用户主动触发）
[轮次 N，最多 3 轮]
    ↓
执行全量检查（A~I 共 26 项）
    ↓
有失败项？
  → 是：输出打回报告（含每项失败原因 + 期望值 vs 实际值）
         → 调用 cs-stack-onboarding 补修（只修失败项）
         → 补修完成后：触发「技能反思」—— 更新 cs-stack-onboarding SKILL.md
         → 回到检查（轮次+1）
  → 否：输出「✅ 全量通过报告」，结束
3 轮后仍有失败项 → 输出「⚠️ 需要人工干预」报告，列出所有未通过项
```

---

## 检查项全览（A~I，共 26 项）

### A. 依赖层（pubspec.yaml）

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| A1 | 必要依赖全部声明 | cs_framework / cs_ui / flutter_riverpod / riverpod_annotation / freezed_annotation / json_annotation / go_router / flutter_screenutil / dio / shared_preferences / flutter_secure_storage / logger 均在 dependencies | 解析 pubspec.yaml |
| A2 | cs_framework/cs_ui path 路径规范 | `path: ../cs/cs_framework` 和 `path: ../cs/cs_ui`（若用 path 引用） | 解析 pubspec.yaml |
| A3 | dev_dependencies 完整 | build_runner / freezed / riverpod_generator / json_serializable 均存在 | 解析 pubspec.yaml |
| A4 | 已无 http 残余依赖 | pubspec.yaml 中无 `http:` | grep pubspec.yaml |

---

### B. Riverpod 状态管理

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| B1 | ProviderScope 已包裹 | main.dart 中存在 `ProviderScope(` | grep main.dart |
| B2 | 业务逻辑 setState 清零 | `setState(` 仅剩 TextEditingController / AnimationController / FocusNode 等纯 UI 控制器使用；业务数据字段的 setState 为零 | grep -rn "setState(" lib/ + AI 审查上下文 |
| B3 | 无剩余业务型 StatefulWidget | `extends StatefulWidget` 零残余（或剩余均为纯 UI 动画类） | grep -rn "extends StatefulWidget" lib/ |
| B4 | 代码生成文件已生成 | lib/ 下存在 .g.dart 文件（riverpod provider 的生成产物） | glob lib/**/*.g.dart |

> **B2 判断规则**：`setState` 内部修改的是 `List`、`Map`、`bool _loading`、`String _message`、Stream 订阅结果等业务字段时，判定为「未迁移」；仅修改 `_tabIndex`、`_controller` 等 UI 状态时，视为合法保留。

---

### C. go_router 路由

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| C1 | app_router.dart 已创建 | `lib/router/app_router.dart` 文件存在 | 文件检查 |
| C2 | MaterialApp 已迁移 | main.dart 中存在 `MaterialApp.router(` | grep main.dart |
| C3 | Navigator 调用清零 | `Navigator.push` / `Navigator.pop` / `Navigator.pushNamed` 零残余 | grep -rn "Navigator\." lib/ |

---

### D. freezed 数据模型

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| D1 | 业务模型已 freezed 化 | lib/models/ 下无未加 @freezed 的 plain class（含多个 final 字段的） | 读 lib/models/ + AI 审查 |
| D2 | 无多余 @JsonSerializable | 无叠加 `@JsonSerializable()` 注解（freezed 已内置） | grep -rn "@JsonSerializable" lib/ |
| D3 | freezed 生成文件已存在 | lib/ 下存在 .freezed.dart 文件 | glob lib/**/*.freezed.dart |

---

### E. cs_framework 后台接入

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| E1 | CsClient 已初始化 | main.dart 中存在 `CsClient.initialize(` | grep main.dart |
| E2 | urlScheme 参数已配置 | `CsClient.initialize(` 调用中含 `urlScheme:` 参数 | 读 main.dart |
| E3 | iOS URL Scheme 已配置 | Info.plist 中存在 `mountain` 前缀的 CFBundleURLSchemes | 读 ios/Runner/Info.plist |
| E4 | Android URL Scheme 已配置 | AndroidManifest.xml 中存在 `mountain` 前缀的 `android:scheme` | 读 android/.../AndroidManifest.xml |

---

### F. 登录模块

| ID | 检查项 | 验收标准 | 命令/方法 |
|----|--------|---------|-----------|
| F1 | 登录页面文件存在 | lib/ 下存在 login 相关 .dart 文件 | glob lib/**/login*.dart / glob lib/**/auth*.dart |
| F2 | 使用了 cs_ui 登录组件 | 代码中存在 `CsLoginPage` 或 `CsLoginForm`（不是自写表单） | grep -rn "CsLoginPage\|CsLoginForm" lib/ |
| F3 | 登录路由已注册 | app_router.dart 中含登录路由（`/login` 或 loginPage 相关路由） | 读 lib/router/app_router.dart |

---

### G. UI 组件替换

| ID | 检查项 | 验收标准 | 豁免规则 | 命令 |
|----|--------|---------|---------|------|
| G1 | ElevatedButton/TextButton/OutlinedButton 清零 | 零残余 | 若无对应 ShadButton 变体时可保留，须在检查报告中注明 | grep -rn "ElevatedButton\|TextButton\|OutlinedButton" lib/ |
| G2 | AppBar 清零 | 零 `AppBar(` 残余 | 无豁免 | grep -rn "AppBar(" lib/ |
| G3 | Card 清零 | 零 `Card(` 残余 | 无豁免 | grep -rn "Card(" lib/ |
| G4 | 图片写死用法清零 | 零 `Image.asset(` / `Image.network(` / `CachedNetworkImage(` | 无豁免 | grep -rn "Image\.asset\|Image\.network\|CachedNetworkImage" lib/ |

---

### H. 日志 & 安全

| ID | 检查项 | 验收标准 | 命令 |
|----|--------|---------|------|
| H1 | print/debugPrint 清零 | lib/ 下零 `print(` / `debugPrint(` | grep -rn "print\|debugPrint" lib/ |
| H2 | 无硬编码敏感数据 | 无包含 `api_key` / `token` / `secret` / `sk-` / `AIza` 的变量名或字符串值 | grep -rn "api_key\|sk-\|AIza" lib/ |
| H3 | 无散落 SharedPreferences 直接调用 | 零 `SharedPreferences.getInstance()` | grep -rn "SharedPreferences.getInstance" lib/ |

---

### I. 构建 & 规范文件

| ID | 检查项 | 验收标准 | 命令 |
|----|--------|---------|------|
| I1 | flutter analyze 无 error | `flutter analyze` 退出码为 0，零 error（warning 可保留） | flutter analyze |
| I2 | CLAUDE.md 含技术栈规范 | CLAUDE.md 中存在「技术栈规范」章节，且无旧 ChangeNotifier/provider 描述 | 读 CLAUDE.md |
| I3 | .cs-stack.json 完整 | 文件存在且 `completed_steps` 包含本次执行的所有步骤 | 读 .cs-stack.json |
| I4 | iOS 原生编译通过 | `flutter build ios --no-codesign` 退出码为 0 | flutter build ios --no-codesign |
| I5 | Android 原生编译通过 | `flutter build apk --debug` 退出码为 0 | flutter build apk --debug |

> **I4/I5 说明**：`flutter analyze` 只验证 Dart 层，不涉及原生构建配置（Gradle/AGP/Kotlin）。Gradle 版本过旧、Kotlin 与插件不兼容等问题，只有实际编译才能发现。若项目不支持某平台（纯 Web 等），对应项可豁免并注明原因。

---

## 检查执行顺序

按以下顺序执行，前序类别若有失败项先打回，视情况可并行执行同类别内各项：

```
A（依赖） → E（后台接入）→ B（Riverpod）→ C（路由）→ D（模型）→ F（登录）
→ G（UI）→ H（日志安全）→ I（构建规范）
```

> 若 A 类未通过，停止检查，直接打回，依赖不完整会导致后续所有检查无效。
> 若 I1（flutter analyze）有 error，I2/I3 仍继续检查，不阻塞。

---

## 打回报告格式

发现失败项时，输出以下格式的打回报告：

```
🔴 框架接入检查失败（第 N 轮，共 M 项未通过）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ B2 业务逻辑 setState 未清零
   期望：业务状态字段全部移入 Provider，setState 仅用于纯 UI 控制器
   实际：lib/features/home/home_page.dart:42 发现 setState 修改 _items（业务列表）
   文件：lib/features/home/home_page.dart

❌ F2 未使用 cs_ui 登录组件
   期望：使用 CsLoginPage 或 CsLoginForm
   实际：lib/features/auth/login_page.dart 自写了登录表单（TextField + ElevatedButton）
   文件：lib/features/auth/login_page.dart

❌ G2 AppBar 未清零
   期望：零 AppBar( 残余
   实际：发现 3 处（home_page.dart:15, detail_page.dart:8, settings_page.dart:22）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
→ 正在调用 cs-stack-onboarding 补修上述 3 项...
```

---

## 调用 cs-stack-onboarding 补修

打回后，触发 cs-stack-onboarding 仅修复失败项：

1. 明确告知本轮失败的具体步骤 ID（如 3-B、3-D、登录模块）
2. cs-stack-onboarding 按步骤 ID 精准补修，不重跑已通过的步骤
3. 补修完成后，执行「技能反思」（见下方）
4. 反思完成后，重新运行本检查（轮次+1）

---

## 技能反思（每次补修后强制执行）

补修完成后，必须执行以下反思流程，将此次踩坑写入 cs-stack-onboarding 的 SKILL.md：

### 反思步骤

1. **分析根因**：此次被打回的项，cs-stack-onboarding 为什么没有做到位？
   - 是判断逻辑不完整？（如 B2：只改了类名没迁移业务字段）
   - 是步骤说明不够清晰？（如 F2：没有强制要求用 CsLoginPage）
   - 是验收标准缺失？（如 G2：没有核查 AppBar）

2. **定位写入位置**：找到 cs-stack-onboarding SKILL.md 中对应步骤的「改造标准」或「注意事项」

3. **写入踩坑内容**：在对应位置追加「⚠️ 已知踩坑」说明，格式如下：

```markdown
⚠️ 已知踩坑（YYYY-MM-DD）：
- 现象：仅将 StatefulWidget 改为 ConsumerStatefulWidget，未将业务字段移入 Provider
- 根因：改造时只关注类继承，未逐字段审查 setState 的使用
- 修正：改造完成后必须逐行扫描 setState 调用，确认修改的变量是否为业务字段
```

4. **路径**：`/Users/bryanpeng/.claude/skills/cs-stack-onboarding/SKILL.md`（直接编辑该文件）

> 反思的目标不是惩罚，而是让 cs-stack-onboarding 在下次执行时「想起」这个坑，从而做到第一次就对。

---

## 通过报告格式

全部 26 项通过时，输出：

```
✅ 框架接入检查全量通过（第 N 轮）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A. 依赖层        ✅ A1 A2 A3 A4
B. Riverpod     ✅ B1 B2 B3 B4
C. go_router    ✅ C1 C2 C3
D. freezed      ✅ D1 D2 D3
E. 后台接入     ✅ E1 E2 E3 E4
F. 登录模块     ✅ F1 F2 F3
G. UI 组件      ✅ G1 G2 G3 G4
H. 日志安全     ✅ H1 H2 H3
I. 构建规范     ✅ I1 I2 I3

🎉 框架接入已完整，项目已达到 cs-stack 接入标准！
```

---

## 3 轮后未通过报告

```
⚠️ 已达到最大重试轮次（3轮），以下项目需要人工干预：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ [列出所有未通过项及原因]

建议：
1. 人工检查上述文件，确认是否有框架不支持的特殊场景
2. 若确实无法自动改造，在 .cs-stack.json 的 exceptions 字段中记录豁免原因
3. 完成人工处理后，可重新运行 cs-stack-checker 验证
```

---

## 注意事项

- **检查范围**：仅扫描 `lib/` 目录，不扫描 `test/` 和 `build/`
- **G 类豁免**：若某个 Material 组件在 cs_ui 中确无对应替换（如 `Chip` 用于特殊标签场景），可在报告中标注「豁免」并说明原因，不计入失败
- **B2 判断**：需结合代码上下文 AI 审查，不能仅靠 grep 计数，需判断 setState 修改的是否为业务字段
- **并行检查**：同一类别内的各项可并行执行以提升效率；跨类别按顺序执行
- **轮次计数**：每次「检查→打回→补修→反思」算一轮，通过后的轮次不再计数
