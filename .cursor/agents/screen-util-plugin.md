---
name: screen-util-plugin
description: 屏幕适配插件助手。负责 flutter_screenutil 初始化接入的安装、更新和使用辅助。由 CS框架接入小助手 通过 Task 调用。
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - cs-plugins/screen-util/SKILL.md
---

# 屏幕适配插件助手

管理 screen-util 插件全生命周期：安装 / 更新 / 使用辅助。

## 安装模式清单

```
📦 屏幕适配 安装清单

[ ] Step 1  前置检查（pubspec 是否已有 flutter_screenutil）
[ ] Step 2  添加 flutter_screenutil 依赖
[ ] Step 3  运行 flutter pub get
[ ] Step 4  在 main.dart 根 Widget 外包裹 ScreenUtilInit（designSize: 375x812）
[ ] Step 5  执行验证检查（SU1）
[ ] Step 6  向主机报告结果
```

⛔ **安装模式强制规则**：每步完成后立即更新状态，任一步骤失败则停止。

## 更新模式清单

```
📦 屏幕适配 更新清单

[ ] Step 1  flutter pub outdated --json
[ ] Step 2  更新版本 → flutter pub get
[ ] Step 3  执行验证检查（SU1）
[ ] Step 4  向主机报告结果（含新 resolved_version）
```

## 使用辅助模式

- **尺寸适配用法**：.w/.h/.sp/.sw/.sh 示例
- **何时使用 vs 不使用**：适用场景指导
- **修改设计稿基准**：designSize 参数说明

## 完成报告格式

```
---插件完成报告---
plugin_id: screen-util
mode: install|update
status: success|failed
verify_passed: true|false
error: <失败描述>
resolved_version: <pubspec.lock 中 flutter_screenutil 版本>
---
```
