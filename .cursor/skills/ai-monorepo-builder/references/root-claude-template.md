# 根目录 CLAUDE.md 模板

填写说明：将 `<workspace>`、`<main-app>`、`<module-*>` 等占位符替换为实际值。

---

```markdown
# <工作区名称> 大仓

以 <主项目名> 为核心，配合多个可复用基础模块积木的 AI 友好型开发工作区。每个包是独立 git repo，根目录只是本地容器。

---

## 包索引

| 包 | 路径 | 职责 | 详细文档 |
|----|------|------|---------|
| <主项目名> | `<main-app>/` | <主项目一句话描述> | [<main-app>/CLAUDE.md](<main-app>/CLAUDE.md) |
| <模块A> | `<module-a>/` | <模块A一句话描述> | [<module-a>/CLAUDE.md](<module-a>/CLAUDE.md) |
| <模块B> | `<module-b>/` | <模块B一句话描述> | [<module-b>/CLAUDE.md](<module-b>/CLAUDE.md) |

---

## 开发路由

**AI 接到开发任务时，根据任务描述自动路由到对应包：**

| 任务描述 | 路由到 |
|---------|--------|
| <模块A 负责的功能描述> | `<module-a>/` |
| <模块B 负责的功能描述> | `<module-b>/` |
| <主项目核心功能描述> | `<main-app>/` |
| 新建 App（复用已有积木） | 新建目录，`pubspec.yaml` 用 Git URL 引用积木 |

---

## 包间关系

```
<module-a>  ←── 对外：Git URL 引用（可单独发布）
<module-b>  ←── 对外：Git URL 引用（可单独发布）
      ↑               ↑
<main-app>（发布用 Git URL，本地开发用 pubspec_overrides.yaml）
```

---

## 跨包本地开发

本地开发时，用 `pubspec_overrides.yaml` 切换到本地路径（该文件已加入 `.gitignore`，永不提交）：

```yaml
# <main-app>/pubspec_overrides.yaml（本地专用，不提交 git）
dependency_overrides:
  <module-a>:
    path: ../<module-a>
  <module-b>:
    path: ../<module-b>
```

发布/推送时，`pubspec.yaml` 里的 Git URL 引用保持不变，不受影响。

---

## 新增包到大仓

1. 在工作区根目录下 `git clone` 或 `mkdir + git init` 新目录
2. 在本文件「包索引」和「开发路由」表中追加该包条目
3. 检查新包的 `.gitignore`，确保包含 `pubspec_overrides.yaml`（Flutter 包）
4. 为新包创建 `CLAUDE.md`（若无）

无需其他注册步骤。

---

## AI 行为规范

- **每次完成代码修改后**：自动对每个被修改的包执行 `git add . && git commit`（详见 `.cursor/rules/auto-commit.mdc`）
- **跨包修改时**：每个包单独提交，提交信息各自描述自己的改动
- **新建包时**：顺手更新本文件的包索引和开发路由表
```
