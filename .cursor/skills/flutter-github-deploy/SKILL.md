---
name: flutter-github-deploy
description: Flutter Web 项目推送并部署到 GitHub Pages 的全自动闭环技能。自动执行预检（pubspec.lock 依赖来源、依赖包未推送 commit、仓库可见性）、修复常见问题、推送代码、监控 GitHub Actions 流水线，发现失败则分析日志并修复后重试，直到部署成功（Ralph Loop 模式）。当用户提到「部署到 GitHub Pages」、「推送并部署」、「deploy Flutter web」、「push 到 git 直到部署成功」、「flutter-github-deploy」，或在 Flutter 项目完成开发后希望把最新代码发布到线上时触发。即使用户只说「帮我部署一下」或「推上去」且上下文是 Flutter 项目，也应主动使用此技能。
---

# Flutter GitHub Deploy

将 Flutter Web 项目推送到 GitHub 并触发 GitHub Actions 部署到 GitHub Pages，形成「预检 → 修复 → 推送 → 监控 → 失败则修复重推」的自动化闭环。

---

## 核心流程

```
预检 → 修复已知问题 → 推送依赖包 → 推送主项目
    → 监控 CI → 成功则结束
                ↓ 失败
            分析日志 → 修复 → 重推 → 再监控（最多 5 次）
```

---

## Step 1：预检

在推送任何代码前，先做以下全套检查，避免 CI 必然失败的问题。

### 1.1 检查主项目 git 状态

```bash
git status
git log --oneline origin/main..HEAD   # 查看未推送的 commit 数量
git remote -v                          # 确认 remote 地址
```

### 1.2 检查 pubspec_overrides.yaml

`pubspec_overrides.yaml` 是本地开发专用文件，绝不能推送到 CI。

```bash
# 检查是否被 git 追踪（已追踪则必须 rm --cached）
git ls-files pubspec_overrides.yaml

# 检查是否在 .gitignore
grep "pubspec_overrides" .gitignore
```

**如果被追踪**：`git rm --cached pubspec_overrides.yaml`

### 1.3 检查 pubspec.lock 的依赖来源

pubspec.lock 中如果有 `source: path` 的依赖（来自本地 overrides），CI 无法解析，必须修复。

```bash
grep -A4 "source:" pubspec.lock | grep -B2 "path"
```

**如果发现 path 依赖**：
1. 临时移走 `pubspec_overrides.yaml`（`mv pubspec_overrides.yaml pubspec_overrides.yaml.bak`）
2. 执行 `flutter pub get` 重新生成 lock（此时使用 pubspec.yaml 中的 git/pub 依赖）
3. 恢复 `mv pubspec_overrides.yaml.bak pubspec_overrides.yaml`
4. 提交修复后的 pubspec.lock

### 1.4 检查 git 依赖包是否有未推送的 commit

pubspec.yaml 中通过 `git:` 引用的包（如 cs_ui、cs_framework），如果本地有未推送的 commit，CI 拉到的是旧版本，可能导致版本冲突。

对每个 git 依赖包：
```bash
# 从 pubspec.yaml 提取所有 git 依赖的路径（相对路径）
grep -B2 "git:" pubspec.yaml

# 进入各依赖包目录检查
cd <dep_path> && git log --oneline origin/main..HEAD
```

**如果有未推送 commit**：先推送依赖包 `git push origin main`，再继续。

### 1.5 检查 git 依赖仓库的可见性

私有仓库 CI 无法匿名 clone，会报 `fatal: could not read Username`。

```bash
gh repo view <owner>/<repo> --json visibility -q .visibility
```

**如果是 PRIVATE 且用于 CI 的公开项目**：
- 方案 A（推荐）：改为 Public — `gh repo edit <owner>/<repo> --visibility public --accept-visibility-change-consequences`
- 方案 B：在 workflow 中加 PAT 认证（需用户手动创建 secret）

> 询问用户选择哪种方案，再执行。

---

## Step 2：提交并推送

完成所有预检修复后：

```bash
# 如果有修复产生的改动（如 pubspec.lock），先提交
git add pubspec.lock
git commit -m "fix: 修复 pubspec.lock，改为 git 依赖（CI 修复）"

# 推送主项目
git push origin main
```

推送成功后告知用户「已推送 N 个 commit，GitHub Actions 已触发」。

---

## Step 3：监控 CI（Ralph Loop 开始）

### 3.1 获取最新 run ID

```bash
sleep 5 && gh run list --limit 3 --repo <owner>/<repo>
```

### 3.2 监控 run 直到结束

```bash
gh run watch <run_id> --repo <owner>/<repo>
```

等待 workflow 完成（通常 2-5 分钟）。

### 3.3 结果处理

**成功（✓）**：进入 Step 4 完成收尾。

**失败（✗）**：进入 Step 3.4 分析日志。

### 3.4 失败诊断

```bash
gh run view <run_id> --log-failed --repo <owner>/<repo>
```

根据错误日志判断根因并修复（常见问题见下方「常见失败类型」），然后：

```bash
git add <修复的文件>
git commit -m "fix: <修复描述>"
git push origin main
```

重新回到 Step 3.1，最多循环 **5 次**。

---

## 常见失败类型及修复方法

| 错误信息 | 根因 | 修复方法 |
|---------|------|---------|
| `fatal: could not read Username` | git 依赖仓库是私有的 | 改为 Public，或加 PAT secret |
| `Because XXX depends on intl ^0.19.0` | git 依赖包未推送新版本 commit | 先推送依赖包（含版本升级 commit） |
| `source: path` in pubspec.lock | pubspec_overrides.yaml 混入了 lock | 移走 overrides，重新 `flutter pub get` |
| `flutter pub get` 版本解析失败 | 依赖版本冲突 | 检查 pubspec.yaml 约束，升级或固定版本 |
| `Build web` 步骤失败 | Dart/Flutter 编译错误 | 本地先 `flutter build web` 确认可编译 |
| `Publish to gh-pages` 失败 | GITHUB_TOKEN 权限不足 | 在 workflow 中加 `permissions: contents: write` |
| workflow 文件语法错误 | YAML 格式问题 | 检查缩进和字段名 |

---

## Step 4：完成

部署成功后：

1. 获取 GitHub Pages 访问地址：
   ```bash
   gh repo view <owner>/<repo> --json url -q .url
   # Pages 地址通常为 https://<owner>.github.io/<repo>/
   ```

2. 告知用户部署结果和访问地址。

3. 如果本次修复了 workflow 或配置问题，建议用户将经验记入知识库（调用 `knowledge-collector` 技能）。

---

## 注意事项

- **pubspec_overrides.yaml 永远不提交**：它是本地开发专用，应在 `.gitignore` 中，且确认未被 `git ls-files` 追踪
- **依赖包要先于主项目推送**：git 依赖 CI 用的是远端 commit，本地超前的 commit 必须先推
- **本地先验证可编译**：如果有大量改动，建议先本地 `flutter build web` 确认无编译错误，再推送
- **最大重试 5 次**：超过 5 次仍失败，停止并告知用户需要人工介入
