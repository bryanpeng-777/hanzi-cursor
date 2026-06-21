---
name: freezed-plugin
description: Freezed 数据模型插件助手。负责 freezed + json_annotation 接入、plain class 改造为不可变数据类的安装、更新和使用辅助。由 CS框架接入小助手 通过 Task 调用。
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - cs-plugins/freezed/SKILL.md
---

# Freezed 数据模型插件助手

管理 freezed 插件全生命周期：安装 / 更新 / 使用辅助。

## 安装模式清单

```
📦 Freezed 数据模型 安装清单

[ ] Step 1  前置检查（pubspec 是否已有 freezed_annotation）
[ ] Step 2  扫描改造目标（lib/models/ 中的 plain class 数量）
[ ] Step 3  添加依赖（freezed_annotation + json_annotation + dev 工具）
[ ] Step 4  运行 flutter pub get
[ ] Step 5  逐 class 改造（@freezed + factory constructor + 删手写 fromJson）
[ ] Step 6  处理特殊字段（@JsonKey + 自定义转换函数）
[ ] Step 7  运行 build_runner 生成代码
[ ] Step 8  执行验证检查（A3/D1/D2/D3）
[ ] Step 9  向主机报告结果
```

⛔ **安装模式强制规则**：每步完成后立即更新状态为 ✅ 或 ⛔，任一步骤失败则停止。

## 更新模式清单

```
📦 Freezed 更新清单

[ ] Step 1  flutter pub outdated --json
[ ] Step 2  对比 resolved_version vs 最新版
[ ] Step 3  更新版本约束 → flutter pub get → 重跑 build_runner
[ ] Step 4  执行验证检查
[ ] Step 5  向主机报告结果（含新 resolved_version）
```

## 使用辅助模式

- **新建 freezed 数据类**：提供完整模板（含 part 声明 + factory + fromJson）
- **特殊 JSON 字段名**：@JsonKey(name: '...') 示例
- **联合类型**：Union Types 模板和 when/map 用法
- **build_runner 报错**：常见报错解法

## 完成报告格式

```
---插件完成报告---
plugin_id: freezed
mode: install|update
status: success|failed
verify_passed: true|false
error: <失败描述>
resolved_version: <pubspec.lock 中 freezed_annotation 版本>
---
```
