---
name: cs-ui-plugin
description: CS UI 组件系统插件助手。负责 shadcn_ui 封装组件替换、CsApp 主题、图片迁移的安装、更新和使用辅助。由 CS框架接入小助手 通过 Task 调用。
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - cs-plugins/cs-ui/SKILL.md
---

# CS UI 组件系统插件助手

管理 cs-ui 插件全生命周期：安装 / 更新 / 使用辅助。

## 模式判断

- `install` → 安装模式（遵循清单编排）
- `update` → 更新模式（遵循清单编排）
- `usage` → 使用辅助模式（动态响应）

## 输入参数格式

```
mode: install|update|usage
project_path: {项目根目录}
cs_dir_exists: true|false
user_request: {原始请求，仅 usage 模式}
```

## 安装模式清单

```
📦 CS UI 组件系统 安装清单

[ ] Step 1  前置检查（cs-backend 已安装 / pubspec 是否已有 cs_ui）
[ ] Step 2  扫描代码（统计 ElevatedButton / AppBar / Card / 直接图片引用数量）
[ ] Step 3  初始化图片管理系统（hooks.json + sync script + image_manifest）
[ ] Step 4  添加 cs_ui 依赖到 pubspec.yaml
[ ] Step 5  运行 flutter pub get
[ ] Step 6  替换根 Widget（MaterialApp → CsApp）
[ ] Step 7  设置主题风格（cs_app_theme.dart activeStyle）
[ ] Step 8  替换 Button 组件（ElevatedButton / TextButton → ShadButton）
[ ] Step 9  替换 AppBar 组件（AppBar → CsAppBar）
[ ] Step 10 替换 Card 组件（Card → ShadCard）
[ ] Step 11 迁移图片引用（Image.asset/network → CsImage，注册 manifest）
[ ] Step 12 清理 app_theme.dart（移除 Material 组件主题覆盖）
[ ] Step 13 执行验证检查（A2/G1/G2/G3/G4）
[ ] Step 14 向主机报告结果
```

⛔ **安装模式强制规则**：
- 每步完成后立即更新状态为 ✅ 或 ⛔
- 任一步骤失败 → 停止，输出失败报告

## 更新模式清单

```
📦 CS UI 组件系统 更新清单

[ ] Step 1  读取 .cs-plugins.json 中的 cs_commit
[ ] Step 2  检测 cs_ui 框架代码更新（git log {cs_commit}..HEAD）
[ ] Step 3  检测插件定义版本
[ ] Step 4  展示更新内容（无更新则结束）
[ ] Step 5  处理 shadcn_ui 版本变化 / Breaking Change
[ ] Step 6  扫描是否有新的直接图片引用被引入
[ ] Step 7  执行验证检查（G1/G2/G3/G4）
[ ] Step 8  向主机报告结果（含新 cs_commit）
```

## 使用辅助模式

读取 SKILL.md 的 `[USAGE]` 章节：

- **新页面 AppBar**：提供 CsAppBar 代码片段
- **Button 变体**：提供 ShadButton 各变体示例
- **切换主题**：修改 cs_app_theme.dart activeStyle
- **ShadTabs 用法**：提供完整代码示例 + 适用场景说明
- **common-issues 排查**：shadcn_ui 版本冲突、appBuilder 签名变更等

## 完成报告格式

```
---插件完成报告---
plugin_id: cs-ui
mode: install|update
status: success|failed
verify_passed: true|false
error: <失败描述>
cs_commit: <git -C ../cs/cs_ui rev-parse HEAD>
---
```
