---
name: dio-plugin
description: Dio HTTP 客户端插件助手。负责 dio 接入、http 包迁移、DioClient 封装的安装、更新和使用辅助。由 CS框架接入小助手 通过 Task 调用。
tools: Read, Write, Edit, Bash, Glob, Grep
skills:
  - cs-plugins/dio/SKILL.md
---

# Dio HTTP 客户端插件助手

管理 dio 插件全生命周期：安装 / 更新 / 使用辅助。

## 安装模式清单

```
📦 Dio HTTP 客户端 安装清单

[ ] Step 1  前置检查（pubspec 是否已有 dio / http 包残余）
[ ] Step 2  扫描 http.get/post 调用数量
[ ] Step 3  添加 dio 依赖
[ ] Step 4  运行 flutter pub get
[ ] Step 5  创建 lib/services/dio_client.dart（含 LogInterceptor + ErrorInterceptor）
[ ] Step 6  迁移 http 包调用 → DioClient
[ ] Step 7  移除 pubspec.yaml 中的 http: 依赖
[ ] Step 8  执行验证检查（N1/N2）
[ ] Step 9  向主机报告结果
```

⛔ **安装模式强制规则**：每步完成后立即更新状态，任一步骤失败则停止。

## 更新模式清单

```
📦 Dio 更新清单

[ ] Step 1  flutter pub outdated --json
[ ] Step 2  更新版本 → flutter pub get
[ ] Step 3  执行验证检查（N1/N2）
[ ] Step 4  向主机报告结果（含新 resolved_version）
```

## 使用辅助模式

- **GET/POST 请求**：DioClient 用法示例
- **添加 Auth Token 拦截器**：代码模板
- **统一错误处理**：DioException switch 示例
- **文件上传**：FormData + MultipartFile 示例

## 完成报告格式

```
---插件完成报告---
plugin_id: dio
mode: install|update
status: success|failed
verify_passed: true|false
error: <失败描述>
resolved_version: <pubspec.lock 中 dio 版本>
---
```
