---
name: cs-plugin-host
description: CS 框架插件主机编排技能。负责 cs/ 框架同步、插件菜单展示、依赖解析、委托插件 subAgent 安装/更新/使用辅助、维护 .cs-plugins.json 锁文件。由 CS框架接入小助手 subAgent 读取并执行。
---

# CS 框架插件主机

CS 框架插件体系的编排核心。所有具体操作委托给各插件 subAgent，主机只负责协调和记账。

---

## 启动时必做：cs/ 框架同步

**每次会话开始，在响应用户请求前，先执行框架同步检查。**

```
检测 ../cs/ 目录是否存在？
  └── 不存在：
        提示：「未检测到 cs/ 框架仓库，cs_repo 类插件将使用 git monorepo 引用。
               建议 clone 到同级目录：git clone https://github.com/bryanpeng-777/cs.git ../cs」
        跳过同步，继续响应用户

  └── 存在（Monorepo 模式，cs/ 是单一 git 仓库）：
        git -C ../cs fetch origin --quiet
        git -C ../cs status --porcelain
          ├── 本地落后远端（behind）→ git -C ../cs pull --ff-only
          │     ├── 成功 → 记录「cs monorepo 已同步，新增 N commit」
          │     └── 失败（有本地修改冲突）→ 警告，跳过，不强制 pull
          └── 已是最新 → 记录「cs monorepo 已是最新」
```

**同步结果输出格式：**
```
🔄 cs/ 框架同步（Monorepo）
  cs（单仓库）  ✅ 已是最新（abc1234）
```
或：
```
🔄 cs/ 框架同步（Monorepo）
  cs（单仓库）  🟡 有更新 → ✅ 已同步（abc1234 → def5678，+3 commits）
               包含更新：cs_core cs_auth cs_ui
```

若已是最新，一行简短输出：`✅ cs/ 框架已是最新，跳过同步`

---

## 模式判断

根据用户输入判断进入哪个工作模式：

| 触发条件 | 模式 |
|---------|------|
| 「接入框架」「安装插件」「接入 xxx」「新项目接入」 | **安装模式** |
| 「更新插件」「升级框架」「有没有更新」 | **更新检测模式** |
| 「同步框架」「更新 cs」「拉取最新框架」 | **框架同步模式**（立即执行上方同步流程） |
| 涉及某个插件的使用问题 / 操作请求 | **使用辅助模式** |
| 「查看已安装」「接入状态」 | **状态查看模式** |

---

## 老项目迁移：.cs-stack.json → .cs-plugins.json

**检测时机**：任何模式启动时，若发现 `.cs-stack.json` 存在但 `.cs-plugins.json` 不存在，立即触发迁移。

**迁移流程（只记账，不重跑安装）**：

```
Step 1  读取 .cs-stack.json → 获取已完成步骤列表（completed_steps）
Step 2  扫描 pubspec.yaml + 关键文件，自动检测已安装的插件：

  检测规则（命令/文件存在即视为已安装）：
  ┌───────────────────────┬──────────────────────────────────────────────────────────────┐
  │ 插件 ID               │ 检测条件（满足任一即认为已安装）                               │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ cs-src-core           │ pubspec 含 cs_core:  OR  grep CsClient.initialize main.dart  │
  │ cs-src-auth           │ pubspec 含 cs_auth:  OR  grep AuthManager.initialize          │
  │ cs-src-push           │ pubspec 含 cs_push:  OR  grep PushManager.initialize          │
  │ cs-src-payment        │ pubspec 含 cs_payment:  OR  grep PaymentManager               │
  │ cs-src-ads            │ pubspec 含 cs_ads:  OR  grep AdManager                        │
  │ cs-src-ui             │ pubspec 含 cs_ui:  OR  grep "CsApp(" lib/                    │
  │ cs-src-auth-ui        │ pubspec 含 cs_auth_ui:  OR  grep CsLoginPage                  │
  │ cs-src-tool-image     │ image_manifest.json 存在（任意位置）                           │
  │ cs-src-tool-lottie    │ lottie_manifest.json 存在（任意位置）                          │
  │ cs-src-tool-video     │ video_manifest.json 存在（任意位置）                           │
  │ cs-riverpod           │ pubspec 含 flutter_riverpod  OR  grep ProviderScope           │
  │ cs-freezed            │ pubspec 含 freezed_annotation  OR  *.freezed.dart 存在        │
  │ cs-go-router          │ pubspec 含 go_router  OR  lib/router/app_router.dart 存在     │
  │ cs-dio                │ pubspec 含 dio:  OR  lib/services/dio_client.dart 存在        │
  │ cs-local-storage      │ pubspec 含 shared_preferences                                 │
  │ cs-logger             │ pubspec 含 logger:  OR  lib/utils/app_logger.dart 存在        │
  │ cs-screen-util        │ pubspec 含 flutter_screenutil                                 │
  ├───────────────────────┼──────────────────────────────────────────────────────────────┤
  │ [旧版兼容检测]         │                                                              │
  │ cs-backend            │ pubspec 含 cs_framework  OR  grep CsClient.initialize         │
  │ cs-ui（旧）           │ pubspec 含 cs_ui:（且不含 cs-src-ui 已检测）                   │
  │ riverpod（旧）        │ pubspec 含 flutter_riverpod（且不含 cs-riverpod 已检测）        │
  │ freezed（旧）         │ pubspec 含 freezed_annotation（同上）                          │
  │ go-router（旧）       │ pubspec 含 go_router（同上）                                   │
  │ dio（旧）             │ pubspec 含 dio:（同上）                                        │
  │ local-storage（旧）   │ pubspec 含 shared_preferences（同上）                          │
  │ logger（旧）          │ pubspec 含 logger:（同上）                                     │
  │ screen-util（旧）     │ pubspec 含 flutter_screenutil（同上）                          │
  │ cs-image（旧）        │ image_manifest.json 存在（同上）                               │
  │ cs-lottie（旧）       │ lottie_manifest.json 存在（同上）                              │
  │ cs-video（旧）        │ video_manifest.json 存在（同上）                               │
  └───────────────────────┴──────────────────────────────────────────────────────────────┘

  ⚠️ 检测到旧版插件 ID 时，在迁移报告中输出提示：
     「检测到旧版插件 {old_id}，建议迁移到 {new_id}（运行「接入框架」按新 ID 重新安装即可）」

Step 3  读取 pubspec.lock，提取各 pubdev 插件的 resolved_version
Step 4  对 cs_repo 类插件：执行 git -C ../cs/{package} rev-parse HEAD 获取 cs_commit
        （若无本地 cs/ 则 cs_commit 填 "unknown"）
Step 5  生成 .cs-plugins.json，installed 中仅写入检测到的已安装插件
Step 6  输出迁移报告：
```

```
🔄 检测到老版锁文件 .cs-stack.json，正在迁移到新格式...

检测到已安装插件（7个）：
  ✅ cs-backend    cs_commit: abc1234
  ✅ cs-ui         cs_commit: abc1234
  ✅ riverpod      resolved_version: 2.5.1
  ✅ freezed       resolved_version: 2.4.3
  ✅ go-router     resolved_version: 14.2.0
  ✅ logger        resolved_version: 2.4.0
  ✅ local-storage resolved_version: 2.3.2

未检测到（未安装或检测失败）：
  ⬜ cs-src-push / cs-src-payment / cs-src-ads / cs-src-auth-ui
  ⬜ cs-freezed / cs-dio / cs-local-storage / cs-screen-util
  ⬜ cs-src-tool-image / cs-src-tool-lottie / cs-src-tool-video

📎 .cs-plugins.json 已生成
   旧文件 .cs-stack.json 已保留（建议在确认新体系正常后手动删除）
```

---

## 安装模式

### Step 1：读取注册表 + 项目现状

```
读取 ~/.claude/skills/cs-plugin-host/REGISTRY.json → 获取所有可用插件
读取 {项目根目录}/.cs-plugins.json → 获取已安装插件列表（不存在则视为全部未安装）
```

### Step 2：展示插件菜单

```
📦 CS 框架插件菜单

🔧 cs-src-* 源码插件（框架内部模块，需 ../cs/ 或 git monorepo 引用）
  ⬜ cs-src-core      核心基座：CsClient + ConfigManager + DataManager + StorageManager
  ⬜ cs-src-auth      认证逻辑：AuthManager + AuthGuard（依赖 cs-src-core）
  ⬜ cs-src-push      推送通知：PushManager + FCM（依赖 cs-src-core）
  ⬜ cs-src-payment   支付模块：PaymentManager + RevenueCat（依赖 cs-src-core）
  ⬜ cs-src-ads       广告模块：AdManager + AdMob（依赖 cs-src-core）
  ⬜ cs-src-ui        UI 组件：CsApp + 主题 + ShadcnUI（依赖 cs-src-core）
  ⬜ cs-src-auth-ui   登录 UI：CsLoginPage + CsLoginForm（依赖 cs-src-auth + cs-src-ui）

🎨 cs-src-tool-* 工具源码插件（资源管理）
  ⬜ cs-src-tool-image   图片资源管理（image_manifest）
  ⬜ cs-src-tool-lottie  Lottie 动效管理（lottie_manifest）
  ⬜ cs-src-tool-video   视频资源管理（video_manifest）

📦 cs-* pub.dev 包装插件（封装第三方库）
  ⬜ cs-riverpod      状态管理（flutter_riverpod）
  ⬜ cs-freezed       数据模型（freezed + json_annotation）
  ⬜ cs-go-router     声明式路由（go_router）
  ⬜ cs-dio           HTTP 客户端（dio）
  ⬜ cs-local-storage 本地存储（shared_preferences + flutter_secure_storage）
  ⬜ cs-logger        日志系统（logger）
  ⬜ cs-screen-util   屏幕适配（flutter_screenutil）

已安装：{已安装列表，若无则显示「无」}

预设套餐：
  core-only  → cs-src-core
  auth       → cs-src-core + cs-src-auth + cs-src-ui + cs-src-auth-ui
  payment    → cs-src-core + cs-src-payment
  standard   → auth + cs-riverpod + cs-freezed + cs-go-router + cs-dio + cs-local-storage + cs-logger
  full       → standard + cs-src-push + cs-src-payment + cs-src-ads
               + cs-screen-util + cs-src-tool-image + cs-src-tool-lottie + cs-src-tool-video

输入插件 ID（逗号分隔）或套餐名：
```

### Step 3：依赖解析

用户选择后，执行依赖解析：
- 检查所选插件的 `dependencies` 字段，自动补全依赖插件
- 过滤已安装的插件（除非用户说「重新安装」）
- 输出最终安装列表，等待用户确认

```
📋 将安装以下插件（含自动补全的依赖）：
  cs-src-core（cs-src-auth / cs-src-ui 的依赖，自动补全）
  cs-src-auth（cs-src-auth-ui 的依赖，自动补全）
  cs-src-ui（cs-src-auth-ui 的依赖，自动补全）
  cs-src-auth-ui（用户选择）

确认安装？（确认 / 取消）
```

### Step 4：按依赖顺序委托插件 subAgent

用户确认后，按拓扑排序（依赖先于被依赖）委托各插件 subAgent：

- 无依赖关系的插件 → 并行启动（Task，run_in_background: true）
- 有依赖关系的插件 → 等依赖完成后启动

每个插件通过 Task 工具启动对应 subAgent，传入：
```
mode: install
project_path: {当前工作区路径}
cs_dir_exists: {../cs/ 是否存在，true/false}
```

### Step 5：汇总结果 + 写入锁文件

收集所有插件 subAgent 的完成报告，写入 `{项目根目录}/.cs-plugins.json`：

```json
{
  "schema": "cs-plugin-v3",
  "installed": {
    "cs-src-core": {
      "plugin_version": "2.0.0",
      "installed_at": "YYYY-MM-DD",
      "config": {},
      "cs_commit": "<git rev-parse HEAD of cs monorepo>",
      "cs_package_path": "cs_core",
      "verify_passed": true
    },
    "cs-src-auth": {
      "plugin_version": "2.0.0",
      "installed_at": "YYYY-MM-DD",
      "config": {},
      "cs_commit": "<git rev-parse HEAD of cs monorepo>",
      "cs_package_path": "cs_auth",
      "verify_passed": true
    },
    "cs-riverpod": {
      "plugin_version": "1.1.0",
      "installed_at": "YYYY-MM-DD",
      "resolved_version": "<pubspec.lock 中的版本>",
      "verify_passed": true
    }
  },
  "exceptions": {}
}
```

输出安装汇总：
```
✅ 安装完成（4/4 成功）
  ✅ cs-src-core   核心基座接入完成
  ✅ cs-src-auth   认证模块接入完成
  ✅ cs-riverpod   状态管理接入完成
  ✅ cs-go-router  路由接入完成

📎 .cs-plugins.json 已更新
```

---

## 更新检测模式

### Step 1：读取已安装插件

读取 `{项目根目录}/.cs-plugins.json`，获取已安装插件列表及记录信息。

### Step 2：三维并行检测

对每个已安装插件同时检测三个维度：

**维度 1：插件定义更新（所有插件）**
```
REGISTRY.json 中 version vs .cs-plugins.json 中 plugin_version
不一致 → 插件安装逻辑有更新
```

**维度 2：框架代码更新（cs_repo 类插件，Monorepo 模式）**
```
从 .cs-plugins.json 中读取插件的 cs_package_path（如 cs_core / cs_auth 等）

若 ../cs/ 存在（本地 Monorepo 模式）：
  git -C ../cs log --oneline {cs_commit}..HEAD -- {cs_package_path}/
  有输出 → {cs_package_path} 有新 commit

若不存在（使用 git: 引用远程 Monorepo）：
  git ls-remote {git_url} HEAD → 对比存储的 cs_commit
  有差异 → 建议更新（无法精确判断是否影响当前包）
```

**维度 3：pub.dev 包版本更新（pubdev 类插件）**
```
flutter pub outdated --json
解析输出，找到各插件关联包的 latest 版本
与 resolved_version 对比
```

### Step 3：展示更新结果

```
📦 插件更新检测结果

  cs-src-core    🟡 框架代码：cs monorepo（cs_core/）有 3 个新 commit
  cs-src-auth    ✅ 已是最新
  cs-riverpod    🟡 包版本：flutter_riverpod 2.5.1 → 2.6.0
  cs-go-router   ✅ 已是最新
  cs-logger      🟡 插件定义：v1.0.0 → v1.1.0（修复踩坑记录）

选择要更新的插件（输入 ID 逗号分隔 或 "全部"）：
```

### Step 4：委托插件 subAgent 更新

传入 `mode: update`，流程同安装模式 Step 4～5。

---

## 使用辅助模式

识别用户请求涉及哪个插件（关键词匹配已安装插件列表），委托对应插件 subAgent：

| 关键词 | 对应插件 |
|--------|---------|
| CsClient / ConfigManager / DataManager / StorageManager / Supabase | cs-src-core |
| AuthManager / AuthGuard / 登录逻辑 / 认证 | cs-src-auth |
| PushManager / FCM / 推送 / 通知 | cs-src-push |
| PaymentManager / RevenueCat / 支付 / 内购 | cs-src-payment |
| AdManager / AdMob / 广告 / Banner / Interstitial / Rewarded | cs-src-ads |
| ShadButton / CsApp / CsAppBar / 主题 / cs_ui | cs-src-ui |
| CsLoginPage / CsLoginForm / 登录UI / 登录页面 | cs-src-auth-ui |
| CsImage / 图片 / image_manifest | cs-src-tool-image |
| CsLottie / 动画 / lottie_manifest | cs-src-tool-lottie |
| CsVideo / 视频 / video_manifest | cs-src-tool-video |
| Provider / riverpod / setState / build_runner | cs-riverpod |
| freezed / 数据类 / fromJson / toJson | cs-freezed |
| 路由 / 跳转 / go_router / Navigator | cs-go-router |
| 请求 / API / dio / 拦截器 | cs-dio |
| SharedPreferences / secure / 存储 | cs-local-storage |
| print / log / logger / appLogger | cs-logger |
| 屏幕适配 / ScreenUtil / sp / w / h | cs-screen-util |

传入 `mode: usage` + 用户原始请求。

若涉及多个插件，顺序委托（先完成一个再委托下一个）。

若插件未安装，提示：「{插件名} 尚未安装，是否先安装？」

---

## 状态查看模式

读取 `.cs-plugins.json`，格式化输出已安装插件列表：

```
📋 {项目名} 已安装插件

  ✅ cs-src-core      v2.0.0  安装于 2026-04-30  验证通过
  ✅ cs-src-auth      v2.0.0  安装于 2026-04-30  验证通过
  ✅ cs-riverpod      v1.1.0  安装于 2026-04-30  验证通过
  ✅ cs-go-router     v1.0.0  安装于 2026-04-30  验证通过

未安装：cs-src-ui / cs-src-auth-ui / cs-src-push / cs-src-payment / cs-src-ads
        cs-freezed / cs-dio / cs-local-storage / cs-logger / cs-screen-util
        cs-src-tool-image / cs-src-tool-lottie / cs-src-tool-video
```

---

## 全局验收（所有插件安装完成后）

当安装了 3 个及以上插件，或用户明确要求全量验收时，在所有插件 subAgent 完成报告汇总后，额外执行以下全局检查：

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| I1 | flutter analyze 无 error | `flutter analyze lib/` | 零 error（warning 可忽略） |
| I2 | .cs-plugins.json 已完整 | 读取 .cs-plugins.json | 所有已安装插件均有记录 + verify_passed: true |
| I3 | iOS 编译通过 | `flutter build ios --no-codesign` | 退出码 0 |
| I4 | Android 编译通过 | `flutter build apk --debug` | 退出码 0 |

> I3/I4 仅在涉及 cs-backend（修改 Info.plist / AndroidManifest.xml）时执行，纯 pubdev 插件无需编译验收。

输出：
```
🔍 全局验收
  I1 flutter analyze  ✅ 零 error
  I2 锁文件完整       ✅ 7个插件均已记录
  I3 iOS 编译         ✅ 通过
  I4 Android 编译     ✅ 通过
```

---

## Step K：写入 dev-assistant 项目规范文档

**触发时机**：安装模式（Step 5 汇总后）和更新模式（Step 4 更新完成后）均执行，单插件安装同样执行。

### 执行流程

**1. 提取 `{project}`**

从当前项目路径的最后一段提取项目名：
```
project_path = {当前工作区路径}
project = project_path.split('/')[-1]   # 如 "demo"
```

**2. 读取已安装插件**

读取 `{project_path}/.cs-plugins.json`，获取 `installed` 字段中所有插件 ID。

**3. 按插件映射生成规范条目**

根据已安装插件，从以下映射表选取对应条目：

| 插件 ID | 规范段落标题 | 规范内容 |
|---------|------------|---------|
| cs-src-core | 后台框架 | 使用 cs_core：CsClient / ConfigManager / DataManager / StorageManager。所有 Supabase 操作统一走框架，禁止直接调用 Supabase SDK |
| cs-src-ui | UI 组件 | 使用 cs_ui：CsApp / ShadButton / ShadCard / ShadBadge / CsAppBar。禁止使用 Material 原生组件：ElevatedButton / TextButton / OutlinedButton / AppBar / Card / Chip |
| cs-src-auth | 认证 | 使用 AuthManager / AuthGuard。禁止直接调用 Supabase Auth API |
| cs-src-auth-ui | 登录 UI | 使用 CsLoginPage / CsLoginForm，禁止自行实现登录页面 |
| cs-riverpod | 状态管理 | 使用 flutter_riverpod。所有 Widget 必须继承 ConsumerWidget 或 ConsumerStatefulWidget。禁止在业务逻辑中使用 setState（只有 TextEditingController / AnimationController / Tab index 等纯 UI 控制器可保留 setState） |
| cs-go-router | 路由 | 使用 go_router（lib/router/app_router.dart）。统一用 context.go / context.push / context.pop。禁止 Navigator.push / Navigator.pop / Navigator.pushNamed |
| cs-freezed | 数据模型 | 使用 freezed。新业务数据类必须用 @freezed + factory + fromJson/toJson。新增 @freezed 注解后必须运行 `flutter pub run build_runner build --delete-conflicting-outputs` |
| cs-logger | 日志 | 使用 AppLogger（lib/utils/app_logger.dart）。全项目禁止 print / debugPrint |
| cs-dio | HTTP | 第三方接口统一走 DioClient（lib/services/dio_client.dart）。Supabase 操作走 cs_core，不走 DioClient |
| cs-local-storage | 本地存储 | 普通偏好设置用 shared_preferences；Token / Key 等敏感凭证必须用 flutter_secure_storage |
| cs-screen-util | 屏幕适配 | 使用 flutter_screenutil。尺寸单位使用 .w（宽度）/ .h（高度）/ .sp（字号） |
| cs-src-tool-image | 图片资源 | 使用 CsImage(configKey: '...')。禁止 Image.asset / Image.network / CachedNetworkImage 直接写死路径 |
| cs-src-tool-lottie | Lottie 动效 | 使用 CsLottie(configKey: '...')。禁止直接使用 Lottie.asset / Lottie.network |
| cs-src-tool-video | 视频资源 | 使用 CsVideo(configKey: '...')。禁止直接写死视频路径 |

**4. 创建目录并写入文件**

```bash
mkdir -p ~/.claude/knowledge/dev-assistant/{project}
```

写入 `~/.claude/knowledge/dev-assistant/{project}/rule.md`，格式如下：

```markdown
# {project} CS框架开发规范

> 由 cs-plugin-host 自动生成，最后更新：{YYYY-MM-DD}
> 已安装插件：{plugin_id_list 逗号分隔}

---

## 技术栈规范

### 后台框架
（若已安装 cs-src-core）
使用 cs_core：CsClient / ConfigManager / DataManager / StorageManager。
所有 Supabase 操作统一走框架，禁止直接调用 Supabase SDK。

### UI 组件
（若已安装 cs-src-ui）
使用 cs_ui：CsApp / ShadButton / ShadCard / ShadBadge / CsAppBar。
禁止使用 Material 原生组件：ElevatedButton / TextButton / OutlinedButton / AppBar / Card / Chip。

...（只包含已安装插件对应的段落）

---

## 代码生成

新增 @freezed 或 @riverpod 注解后必须运行：
`flutter pub run build_runner build --delete-conflicting-outputs`
（仅在已安装 cs-freezed 或 cs-riverpod 时包含此段）
```

> 若文件已存在则**覆盖**（不追加），确保规范与当前已安装插件状态保持同步。

**5. 提交到 knowledge 仓库**

```bash
cd ~/.claude/knowledge \
  && git add dev-assistant/{project}/ \
  && git commit -m "knowledge(dev): 更新 {project} CS框架规范文档（{plugin_count}个插件）" \
  && git push origin main
```

若 `~/.claude/knowledge` 不是 git 仓库或 push 失败，跳过 push，只做本地写入，在输出中提示。

**6. 输出结果**

```
📋 dev-assistant 规范文档已更新
   路径：~/.claude/knowledge/dev-assistant/{project}/rule.md
   覆盖插件规范：{plugin_count} 个
   dev-assistant 下次开发时将自动读取此文档
```

---

## 注意事项

- **主机不做具体操作**：所有文件修改、命令执行均由插件 subAgent 完成，主机只协调
- **cs/ 同步优先**：安装/更新 cs_repo 类插件前，确保 cs/ 是最新的
- **依赖不可跳过**：安装有依赖的插件时，必须先安装其依赖，不允许用户跳过
- **锁文件是权威**：`.cs-plugins.json` 是已安装状态的唯一来源，不依赖 pubspec.yaml 推断
- **老版迁移**：检测到 `.cs-stack.json` 时，自动迁移，不重复安装
- **Step K 始终执行**：无论安装了几个插件，Step K 都执行；更新单个插件后同样更新规范文档，保证知识库与锁文件同步
