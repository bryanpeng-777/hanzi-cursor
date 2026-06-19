---
name: camp-ai-publisher
description: 将本地技能（Skill）发布到团队 camp-ai 商店的全流程自动化技能。用户只需提供要发布的技能名称列表，技能自动完成：版本检查升级、文件名安全扫描与修复、依赖排序、metadata 生成、格式校验、提交审核，并在每步失败时提供可操作的修复建议。当用户说「发布技能」「上传技能到商店」「把技能发布到 camp-ai」「camp-ai-publisher」「提交到团队技能库」「发布到 camp-skills」，或提供一个/多个技能名称并希望让团队同学通过 camp-ai 安装时触发。即使用户只说「帮我发布这个技能」且上下文是 camp-ai 商店，也应主动使用此技能。
---

# Camp-AI Publisher

将本地技能上传到团队 camp-ai 商店（`git.woa.com/koh_social/camp-skills`）。**不修改任何技能内容文件**，仅新增 `metadata.json`（商店索引描述文件），以及在文件名含特殊字符时提示用户确认重命名（工蜂平台硬限制）。

---

## 前置知识

- **商店地址**：`https://git.woa.com/koh_social/camp-skills`（branch: `camp-ai-cli`）
- **发布命令**：`camp-ai dev init` → `camp-ai dev check` → `camp-ai dev submit`
- **技能路径约定**：`~/.claude/skills/<name>/` 或 `~/.claude/skills/camp/<name>/`
- **工蜂文件名限制**：只允许字母、数字、`_`、`-`、`.`，含中文/特殊字符的文件名会导致上传失败

---

## 执行流程

```
用户输入技能列表
  │
  ├─ Step 0：解析输入 & 定位路径
  ├─ Step 1：版本检查（camp-ai >= 0.12.0）
  ├─ Step 2：依赖排序（被依赖的先发布）
  └─ Step 3：逐个发布
       ├─ 3a. 文件名安全扫描 & 自动修复
       ├─ 3b. camp-ai dev init（生成/更新 metadata.json）
       ├─ 3c. camp-ai dev check（格式校验）
       └─ 3d. camp-ai dev submit（提交审核）
```

---

## Step 0：解析输入 & 定位路径

用户可能以以下方式指定技能：

| 输入示例 | 解析方式 |
|---------|---------|
| `datong-report` | 搜索 `~/.claude/skills/datong-report/` 和 `~/.claude/skills/camp/datong-report/` |
| `camp/camp-datong-tracking` | 直接映射到 `~/.claude/skills/camp/camp-datong-tracking/` |
| 绝对路径 | 直接使用 |

**搜索顺序**（找到即停止）：
1. `~/.claude/skills/<name>/`
2. `~/.claude/skills/camp/<name>/`
3. `~/.claude/skills/` 递归搜索（深度 3）

找不到时，输出候选列表供用户确认，**不要猜测**。

---

## Step 1：版本检查

```bash
camp-ai --version
```

- 版本 `< 0.12.0` → 运行 `camp-ai update`，等待完成后继续
- 版本 `>= 0.12.0` → 直接继续

---

## Step 2：依赖排序

检查每个技能的 `SKILL.md` 中是否引用了其他待发布技能的路径（搜索 `~/.claude/skills/<other-name>/` 字样）。

被引用的技能排在前面发布。若存在循环依赖，报错并请用户确认手动顺序。

> 📖 技能间依赖常见写法：`从 datong-report 读取 references/xxx.md`、`路径为 ~/.claude/skills/datong-report/`

---

## Step 3：逐个发布

对每个技能**按序**执行以下子步骤：

### 3a. 文件名安全扫描 & 自动修复

工蜂平台要求：文件名只能包含字母、数字、`_`、`-`、`.`。

```bash
# 扫描技能目录下所有违规文件名
find <skill_path> -name "*[^a-zA-Z0-9_./-]*" -not -path "*/.git/*"
```

对每个违规文件：
1. 展示原文件名和建议的新文件名（将中文/特殊字符替换为拼音或语义英文）
2. **等待用户确认**后执行重命名
3. 若 SKILL.md 中有引用该文件，同步更新引用路径

**常见违规模式**：

| 违规字符 | 示例 | 建议替换 |
|---------|------|---------|
| 中文冒号 `：` | `附：说明.md` | `guide.md` 或 `appendix-notes.md` |
| 中文括号 `（）` | `使用说明（v2）.md` | `usage-v2.md` |
| 空格 | `my skill.md` | `my-skill.md` |
| 中文字符 | `使用说明.md` | `usage-guide.md` |

### 3b. 生成 / 更新 metadata.json

```bash
cd <skill_path> && camp-ai dev init .
```

- 若 `metadata.json` 已存在 → `camp-ai dev init` 会自动跳过或提示更新，根据提示操作
- 生成完成后展示 `name`、`shortDescription`、`version` 供用户确认，若不满意可手动编辑后继续

### 3c. 格式校验

```bash
cd <skill_path> && camp-ai dev check .
```

- 校验通过（有评分输出）→ 继续
- 有 `❌` 错误 → **停止**，展示错误，等待用户修复后重试
- 有 `💡` 建议 → 展示给用户，询问「是否继续提交（建议不影响发布）？」

### 3d. 提交审核

```bash
cd <skill_path> && camp-ai dev submit .
```

**成功**：输出 `🎉 提交成功！<name> v<version> 已提交审核`，继续下一个技能。

**失败处理**：

| 错误信息 | 原因 | 自动处理 |
|---------|------|---------|
| `file name can contain only letters...` | 仍有违规文件名（Step 3a 未完全处理） | 重新执行 3a，修复后重试 |
| `HTTP 401` / `HTTP 403` | 认证失败 | 提示运行 `camp-ai init --login` |
| `网络连接` / `timeout` | 网络问题 | 等待 5 秒后自动重试，最多 3 次 |
| `无进行中的审核` + 失败 | 其他提交错误 | 展示完整错误，建议查看日志 `~/.camp-ai/.logs/` |

---

## 完成后输出

```
📦 发布汇总
  ✅ datong-report v1.0.0        → 已提交审核
  ✅ camp-datong-tracking v1.0.0 → 已提交审核

⏳ 审核状态
  待管理员在 https://git.woa.com/koh_social/camp-skills 的 MR 中审核通过后正式发布。

📥 同学安装方式：
  camp-ai store install datong-report
  camp-ai store install camp-datong-tracking
```

---

## 注意事项

- **顺序**：依赖技能必须先于被依赖技能提交（Step 2 自动处理）
- **文件名修复**：重命名前务必确认，涉及 SKILL.md 引用的需同步更新
- **已提交过的技能**：重复提交会创建新版本 MR，`metadata.json` 中的 `version` 应先手动递增
- **check 评分**：92/100 以上可直接提交，分数仅供参考不阻断发布
- **日志路径**：`~/.camp-ai/.logs/camp-ai-<日期>.log`，提交失败时首先查看此文件定位根因
