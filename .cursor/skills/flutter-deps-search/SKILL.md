---
name: flutter-deps-search
description: 在 Flutter 项目的三方依赖库源码中搜索符号、类名、方法名、关键词。给定一个 Flutter 项目路径和搜索词，自动解析 pubspec.lock 定位所有依赖包（hosted/git/sdk/path，支持 FVM 多版本），并在包源码中并发全文搜索，按包分组展示结果（文件路径 + 行号 + 行内容）。支持正则模式。当用户说「查三方库里有没有 XXX」「在依赖里搜 XXX」「flutter 三方库搜索」「依赖库符号查询」「flutter-deps-search」「这个符号在哪个三方库」时触发。即使用户只说「帮我搜一下依赖里有没有 XXX」且上下文是 Flutter 项目，也应主动使用此技能。
---

# Flutter Deps Search

在 Flutter 项目的三方依赖库源码中搜索符号/关键词，复现 grass哥的 VS Code 插件 `flutter-deps-search` 的核心能力，以纯命令行方式运行，无需打开 VS Code。

## 前提

- 目标 Flutter 项目的根目录存在 `pubspec.lock`
- 已运行过 `flutter pub get`（依赖已缓存到本地 pub-cache）
- Python 环境需安装 `pyyaml`：`pip install pyyaml`

## 脚本位置

```
~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py
```

## 使用方式

### 基本搜索

```bash
python3 ~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py \
  "<关键词>" \
  --project <Flutter项目根目录>
```

### 常用参数

| 参数 | 说明 |
|------|------|
| `<关键词>` | 必填，至少 2 个字符 |
| `--project / -p` | Flutter 项目根目录，默认当前目录 |
| `--regex / -r` | 将关键词作为正则表达式 |
| `--all-files / -a` | 搜索所有文件类型（默认只搜 `.dart`） |
| `--limit / -l` | 结果上限，默认 500 |
| `--json` | 以 JSON 格式输出（方便 AI 进一步处理） |

### 示例

```bash
# 搜索 "CampNetworkService" 这个符号
python3 ~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py \
  "CampNetworkService" \
  --project ~/work_tree_bugfix/flutter_module

# 搜索方法名（正则，匹配 sendRequest 开头的方法）
python3 ~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py \
  "sendRequest\w+" --regex \
  --project ~/work_tree_bugfix/flutter_module

# 在所有文件（含 .yaml .json）中搜索
python3 ~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py \
  "pub.dev" --all-files \
  --project ~/work_tree_bugfix/flutter_module
```

## 输出格式

```
搜索 'XXX' — 共 N 条结果，涉及 M 个包

📦 package_name 1.2.3  (K 条)
    lib/src/foo.dart:42
      class XXXImpl extends ...
    lib/src/bar.dart:17
      void doXXX() { ...

📦 another_package 0.9.0  (2 条)
    ...
```

## 支持的包类型

| 来源 | 说明 |
|------|------|
| `hosted` | pub.dev / 腾讯镜像，自动匹配 mirror 子目录 |
| `git` | 支持单包仓库和 monorepo 子包（通过 `path` 字段） |
| `sdk` | Flutter SDK 内置包（flutter、flutter_test、sky_engine 等） |
| `path` | 本地路径依赖（相对/绝对路径均支持） |

## pub-cache 路径检测顺序

1. `~/.fvm/versions/*/` 下各 FVM 版本的 `.pub-cache`
2. `~/fvm/versions/*/` 下各 FVM 版本的 `.pub-cache`
3. 标准路径 `~/.pub-cache/`

## 当被 AI 调用时

AI 使用此技能的标准流程：

1. 确认 Flutter 项目路径（默认用当前 workspace 的 `flutter_module/` 目录）
2. 运行脚本，捕获输出
3. 解析结果，按包分组展示，并给出定位建议
4. 如果结果过多（>50 条），引导用户细化关键词或加 `--regex` 过滤

```bash
python3 ~/.claude/skills/flutter-deps-search/scripts/flutter_deps_search.py \
  "<用户关键词>" \
  --project /Users/bryanpeng/work_tree_bugfix/flutter_module \
  --limit 100
```
