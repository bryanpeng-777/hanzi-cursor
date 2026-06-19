# Step 0-M：合并后扫描（仅合并后修复模式）

> 当用户提到「合并了基础线」「基础线合入了」「merge完了」「infra合入」时，在 Step 0 之前先执行此步骤。

## 0-M-1 冲突文件检测

```bash
# 检查未解决冲突（<<<<<<< 标记）
git diff --name-only --diff-filter=U

# 查看本次合并带来的所有变更文件
git diff ORIG_HEAD..HEAD --name-only
```

若 `ORIG_HEAD` 不存在（非 merge commit），引导用户提供基础线的 branch 名或 commit hash：
```
git diff <infra-branch-or-commit>..HEAD --name-only
```

## 0-M-2 冲突解决指引

对检测到的冲突文件，按以下策略逐文件引导解决：

| 文件 | 解决策略 |
|-----|---------|
| `pubspec.yaml` | 取两侧依赖**并集**；版本冲突取**较高版本**；产品侧独有依赖全部保留 |
| `main.dart` | 保留产品侧业务逻辑；采纳基础线初始化顺序：`CsClient.initialize` → `PreferencesManager` → `ProviderScope` → `ScreenUtilInit` |
| `lib/router/app_router.dart` | 以产品侧路由为主（含业务页面）；从基础线合入新增路由和守卫逻辑 |
| `lib/network/dio_client.dart` | 以基础线版本为准（纯框架文件）；产品侧自定义 interceptor 追加 |
| `lib/storage/preferences_manager.dart` | 以基础线版本为准；产品侧新增的 key 常量追加 |
| `lib/storage/secure_storage_manager.dart` | 以基础线版本为准；产品侧新增的 key 常量追加 |
| `lib/utils/app_logger.dart` | 以基础线版本为准 |
| `lib/features/` 业务页面 | 以**产品侧为准**；检查导入路径是否因基础线重构而失效 |
| `analysis_options.yaml` | 取两侧规则**并集** |
| `.cs-stack.json` | 以基础线版本为准，合并后更新 `infra_merge_commit` 字段 |

> 每解决一个冲突文件，立即执行 `git add <file>` 标记为已解决，最后统一 `git commit`。

## 0-M-3 版本漂移检测

对比 `.cs-stack.json` 中记录的 `stack_libs` 版本与当前 `pubspec.yaml`：

- **版本升级**：检查是否有已知 breaking change（见下表），有则在报告中标注 `⚠️ 有 Breaking Change`，并在 Gap 报告中附上迁移指引
- **版本降级**：🔴 高危，询问是否恢复到较高版本
- **依赖缺失**（基础线有但产品线 pubspec 没有）：纳入 Step 1 Gap 报告补装

**常见库 Breaking Change 速查表：**

| 库 | 版本范围 | 关键变化 | 迁移动作 |
|----|---------|---------|---------|
| `go_router` | v13 → v14 | `GoRoute` 的 `redirect` 参数签名变化 | 检查 `app_router.dart` 中所有 `redirect:` 回调 |
| `go_router` | v14 → v15 | `ShellRoute` 构造参数调整 | 检查是否使用 `ShellRoute`，有则按新签名修改 |
| `flutter_riverpod` | v1 → v2 | `StateNotifier` 废弃，改用 `@riverpod` 注解 | 扫描 `extends StateNotifier`，逐个迁移 |
| `flutter_riverpod` | v2.4 → v2.5 | `AsyncValue` 新增 `requireValue`，`when` 参数无变化 | 无强制迁移，可选改写 |
| `freezed` | v1 → v2 | `@freezed` 工厂方法必须加 `const`；`when`/`map` 参数名变化 | 运行 build_runner，根据编译报错逐一修复 |
| `freezed_annotation` | v2.3 → v2.4 | `@Default` 对 `DateTime` 类型支持改变 | 检查用了 `@Default` 的 DateTime 字段 |
| `dio` | v4 → v5 | `BaseOptions`、`Interceptor` 接口变化 | 更新 `dio_client.dart` 的 interceptor 签名 |
| `shared_preferences` | v2.2 → v2.3 | 新增 `SharedPreferencesAsync` API | 无破坏性变化，现有代码兼容 |
| `flutter_screenutil` | v5.8 → v5.9 | `SizeExtension` 默认行为微调 | 视觉检查，无强制迁移 |

**处理流程：**
1. 检测到版本升级时，查上表是否命中
2. 命中 → 在 Gap 报告中展示具体迁移动作，并扫描项目中受影响的代码文件数量
3. 未命中已知表 → 提示「建议查阅该库的 CHANGELOG.md 确认是否有 breaking change」，附上库的 pub.dev 链接

## 0-M-4 CLAUDE.md 规范过期检测

合并后框架规范可能已变化（新增禁止项、库版本升级导致 API 改变），需检测 `CLAUDE.md` 是否过期：

1. 检查项目根目录是否有 `CLAUDE.md` / `AGENTS.md`
2. 若有，查找 `## 技术栈规范` 章节，对比以下关键点是否与当前接入状态一致：
   - 库版本号（如 `go_router: ^14.0.0` → 已升级到 `^15.0.0`）
   - 是否覆盖了当前已接入的所有库章节（如新接入了 `flutter_secure_storage` 但规范里没有）
3. 若检测到不一致，纳入 Step 0-M 报告的「📋 CLAUDE.md 过期」区块，合并后修复完成后自动触发 Step 5-1 重新生成

> 合并后修复模式执行完 Step 4 后，**无论 CLAUDE.md 是否过期都强制执行 Step 5-1**，确保规范始终与当前接入状态同步。

## 0-M-5 接入漂移检测（关键）

接入漂移是指：**产品线代码意外覆盖或回退了框架的接入状态**。逐项检测：

| 检测项 | 预期状态 | 漂移表现 |
|-------|---------|---------|
| `main.dart` | 含 `CsClient.initialize()` + `ProviderScope` + `ScreenUtilInit` | 任一初始化被删除或顺序错乱 |
| `pubspec.yaml` | 含所有框架依赖且版本无降级 | 依赖被删除或降级 |
| `lib/router/app_router.dart` | 被 `MaterialApp.router(routerConfig: appRouter)` 引用 | 文件被删除或引用被改回 `MaterialApp` |
| `lib/network/dio_client.dart` | 文件存在且含三个 interceptor | 文件被删除或 interceptor 缺失 |
| `lib/storage/preferences_manager.dart` | 文件存在 | 文件被删除 |
| `lib/storage/secure_storage_manager.dart` | 文件存在 | 文件被删除 |
| `lib/utils/app_logger.dart` | 文件存在 | 文件被删除 |
| `analysis_options.yaml` | 含 `avoid_print: true` | 规则被移除 |
| `CLAUDE.md` / `AGENTS.md` | 含 `## 技术栈规范` 章节且版本号与当前一致 | 章节缺失或版本号过期 |
| `.cursor/hooks.json` | 含三个 manifest sync hook | 文件缺失或 hook 被移除 |
| `aiworkspace/sync_*.py` | 三个 Python 脚本均存在 | 任一脚本被删除 |

## 0-M 输出报告格式

```
🔀 合并后扫描报告
────────────────────────────────
⚠️  冲突文件（N 个，需逐一解决）：
  pubspec.yaml / main.dart / lib/router/app_router.dart

📦 版本变更（M 项）：
  go_router: ^14.0.0 → ^15.0.0  ✅ 升级（⚠️ 有 Breaking Change，见 0-M-3）
  flutter_riverpod: ^2.6.0 → ^2.5.0  🔴 降级（建议恢复）

🔍 接入漂移（K 项）：
  🔴 main.dart：ScreenUtilInit 初始化丢失
  🟡 analysis_options.yaml：avoid_print 规则被移除
  🟡 CLAUDE.md：go_router 版本号过期（^14.0.0 → ^15.0.0）

📋 接入 Gap（继续使用 Step 1 展示详情）

说「解决冲突」→ 逐文件解决冲突
说「跳过冲突」→ 跳到漂移修复
说「确认」→ 一次性全部处理
```
