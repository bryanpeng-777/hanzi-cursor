---
name: app-dev-workflow
description: 应用开发全流程技能（开发 → 提交 → 推送 → 监控 CI → 构建成功才算结束）。当用户说「应用开发」「App 开发」「开发应用」「做 App 功能」「改 App」「实现这个功能并部署」「开发完 push 部署」「应用开发任务」时触发；用户只需提供具体开发内容，本技能自动把代码修改、git 提交、push 触发 GitHub Actions、监控构建直到成功纳入标准流程。即使用户只说「应用开发：XXX」或「帮我开发 XXX 并上线」，也应主动使用此技能。不要与纯「部署」「只 push」混淆——那些用 flutter-github-deploy；不要与纯「修 bug 不部署」混淆——那些用 dev-assistant 或 bugfix。
disable-model-invocation: false
---

# 应用开发全流程（App Dev Workflow）

用户说「**应用开发**」并提供具体需求时，按本技能执行**完整闭环**：理解需求 → 写代码 → 本地验证 → 提交 → 推送 → 监控 CI → **构建成功才能结束**。

> **与 dev-assistant 的分工**：dev-assistant 负责日常写代码/修 bug，默认不主动 commit。本技能是「带部署门禁的应用开发」专用流程，自动包含提交与部署；任务未部署成功不算完成。

---

## Step 0：确认任务（清单 + 用户确认）

从用户消息提取开发内容，输出简短清单：

```markdown
## 应用开发任务清单
- **项目**：{从 Workspace Path 推断，如 hanzi-cursor}
- **需求**：{用户描述的核心改动}
- **预期**：{改什么、解决什么问题}
- **部署目标**：GitHub Pages（Flutter Web）/ 仅提交不部署 / 其他
- **流程**：开发 → 本地验证 → commit → push → 监控 CI 至成功
```

若用户**未说明是否部署**，默认：**改完即 push 并等待 CI 成功**（与本次对话惯例一致）。

若需求含糊（缺页面、缺行为、缺验收标准），先追问 1～2 个关键问题，**不要**带着模糊需求直接改代码。

用户确认或已给出足够细节后，进入 Step 1。

---

## Step 1：项目上下文加载

**项目检测**：从 `user_info` 的 `Workspace Path` 取最后一段为 `{project}`。

按顺序读取（存在则读，不存在跳过）：

| 文档 | 路径 |
|------|------|
| 项目知识库 | `{workspace}/CLAUDE.md` |
| 技术栈规范 | `~/.claude/knowledge/dev-assistant/{project}/rule.md` |
| 公共能力 | `~/.claude/knowledge/dev-assistant/{project}/project_capabilities.json` |

遵守项目规范（Riverpod、go_router、CsImage、禁止 print 等）。跨包修改时分别在各 git 仓库内 commit。

---

## Step 2：开发实现

1. 定位相关代码（SemanticSearch / Grep / Read）
2. **最小改动**完成需求，匹配现有风格
3. 若改了 `@riverpod` / `@freezed` 注解，运行：
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. 图片资源类改动走 `image-generator-workflow`，不在此技能内绕过

开发过程中不向用户反复确认细枝末节；有阻塞性歧义再询问。

---

## Step 3：本地验证

在 `{project}` 根目录至少执行：

```bash
flutter analyze
```

若改动涉及 Web 构建或 CI 曾因编译失败，额外执行：

```bash
flutter build web --release --base-href /{repo-name}/
```

（`{repo-name}` 从 `git remote` 或 `CLAUDE.md` 获取，如 `hanzi-cursor` 对应 `--base-href /hanzi-cursor/`）

**analyze 或 build 失败**：在本步骤内修复，不得进入 Step 4。

---

## Step 4：提交

用户在本技能流程下已隐含授权 commit + push（与全局「仅用户要求才 commit」规则在本技能内让位）。

```bash
git status
git diff
git log -3 --oneline
```

编写中文 commit message（动词开头，如 `fix:` / `feat:` / `refactor:`），然后：

```bash
git add <相关文件>
git commit -m "$(cat <<'EOF'
<简洁中文描述，说明做了什么>
EOF
)"
```

跨包改动：每个有改动的仓库分别 commit。

---

## Step 5：推送与部署预检

**完整预检与推送逻辑**遵循 `~/.claude/skills/flutter-github-deploy/SKILL.md` 的 Step 1～2，至少包括：

1. `pubspec_overrides.yaml` 未被 git 追踪
2. `pubspec.lock` 无 `source: path` 污染
3. git 依赖包（cs_ui、cs_framework 等）无未推送 commit
4. 本地分支与 remote 同步（必要时 `git pull --rebase` 后再 push）

```bash
git push origin main
```

推送后告知：已 push，GitHub Actions 已触发。

---

## Step 6：监控 CI（完成门禁 — 不可跳过）

**任务在此步骤成功之前不得标记为完成。**

```bash
gh run list --limit 3
gh run watch <run_id> --exit-status
```

- **成功**：进入 Step 7
- **失败**：读取 `gh run view <run_id> --log-failed`，修复后重新 commit + push，再次 watch（最多 **5 轮**，与 flutter-github-deploy 一致）
- **超过 5 轮仍失败**：停止并说明阻塞点，请用户介入

---

## Step 7：收尾汇报

构建成功后输出：

```markdown
## 应用开发完成

| 项目 | 内容 |
|------|------|
| 改动摘要 | … |
| Commit | `<hash>` — `<message>` |
| CI | ✅ 成功（`<duration>`） |
| 线上地址 | https://<owner>.github.io/<repo>/ （若适用） |

请在浏览器验证：{用户关心的页面或功能}
```

---

## 触发示例

| 用户说法 | 行为 |
|---------|------|
| 「应用开发：拼音测验横屏布局优化，说明和拼音放一行」 | 走全流程含部署 |
| 「应用开发，首页加一个入口，改完部署」 | 走全流程含部署 |
| 「应用开发：只改本地逻辑，先别 push」 | Step 0 清单中部署目标改为「仅提交不部署」，跳过 Step 5～6 |
| 「帮我 push 部署一下」 | 用 **flutter-github-deploy**，不用本技能 |
| 「修个 bug，不用部署」 | 用 **dev-assistant** / **bugfix** |

---

## 注意事项

- **完成定义**：默认 = CI 构建成功 + 已 push；不是「代码改完」
- **不要提前结束**：不得在 push 后未 watch CI 的情况下说「任务完成」
- **hanzi-cursor 部署**：workflow 为 `.github/workflows/deploy-web.yml`，触发分支 `main`
- **用户紧急例外**：用户明确说「不要 push / 不要等 CI」时，在 Step 0 记录并在 Step 4 后停止
