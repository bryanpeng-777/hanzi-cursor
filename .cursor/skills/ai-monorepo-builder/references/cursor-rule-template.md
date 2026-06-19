# Cursor 自动提交规则模板

填写说明：将 `<workspace-name>`、`<pkg-1>`、`<pkg-2>` 等替换为实际包目录名。

---

```markdown
---
description: <workspace-name> 大仓多包自动提交规则
globs: ["**/*"]
alwaysApply: true
---

# 大仓自动 Git 提交规则

<workspace-name> 根目录下每个子目录（<pkg-1>、<pkg-2>、<pkg-3>...）是独立的 git 仓库。

**每次完成代码修改后，必须自动执行以下步骤（无需用户提醒）：**

1. 用 `git status` 逐一检查哪些包有改动
2. 对每个有改动的包，进入该目录执行：
   - `git add .`
   - `git commit -m "<简洁描述，说明做了什么>"`
3. 完成后告知用户每个包的提交情况

**提交信息规范**（动词开头，简洁描述本包的改动）：
- `feat: 新增 XXX 功能`
- `fix: 修复 XXX 问题`
- `docs: 更新 CLAUDE.md`
- `refactor: 重构 XXX 模块`

**注意事项**：
- 如果某个包没有改动，跳过，不需要提交
- 如果跨包修改，每个包单独提交，提交信息各自描述各自的改动
- 不要使用 `git push`，只做本地 commit，推送由用户决定
```
