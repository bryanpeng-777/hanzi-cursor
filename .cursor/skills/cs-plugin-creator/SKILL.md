---
name: cs-plugin-creator
description: CS 框架新插件脚手架工具。引导开发者通过问答设计新插件的元数据、SKILL.md 结构和 subAgent 文件，自动生成所有模板文件并注册到 REGISTRY.json。当用户提到「创建 cs 插件」「新建插件」「我要加一个插件」「cs-plugin-creator」「添加新的框架能力」时触发。
---

# cs-plugin-creator

引导创建符合规范的 CS 框架插件，覆盖从问答设计 → 文件生成 → 注册表更新的完整流程。

---

## 触发场景

- 用户说「创建一个 cs 插件」「我要加一个 XXX 插件」
- CS框架接入小助手说「当前插件库不支持，需要创建新插件」
- 用户正在开发新的框架能力，希望将其插件化

---

## 执行流程

### Step 1：引导问答

通过以下问题收集插件设计信息（一次展示所有问题，用户填完后统一处理）：

```
📦 CS 插件创建向导

请回答以下问题，AI 将自动生成所有文件：

1. 插件 ID（小写连字符，如 my-plugin）：
2. 插件名称（中文，如「我的功能模块」）：
3. 一句话描述（≤ 50 字）：
4. 分类（从以下选择）：
   - infrastructure（基础设施）
   - ui（UI 组件）
   - state（状态管理）
   - data（数据模型）
   - navigation（路由导航）
   - network（网络请求）
   - storage（本地存储）
   - utility（工具辅助）
   - media（媒体资源）
   - other（其他）
5. 依赖来源（cs_repo 或 pubdev）：
   - cs_repo：依赖本地 cs/ 仓库中的包（如 cs_framework、cs_ui）
   - pubdev：依赖 pub.dev 的包
6. 若 cs_repo：cs/ 中的包名（如 cs_ui）？
   若 pubdev：需要的 pub.dev 包名和版本（如 dio: ^5.7.0）？
7. 是否依赖已有插件？（如 cs-ui、riverpod，无则填「无」）
8. 安装后需要做哪些事情？（简要描述 3-5 个步骤）
9. 验证该插件是否正确安装的方法？（如 grep 某个字符串 / 文件是否存在）
10. 典型使用场景是什么？（安装完成后用户会问你什么问题？）
```

### Step 2：生成文件

收到用户回答后，立即生成以下文件（无需二次确认）：

**文件 1：`~/.claude/skills/cs-plugins/{plugin_id}/metadata.json`**

按回答填充，模板：
```json
{
  "id": "<plugin_id>",
  "name": "<name>",
  "version": "1.0.0",
  "description": "<description>",
  "category": "<category>",
  "source": "<cs_repo|pubdev>",
  // cs_repo 时：
  "cs_package": "<cs_package_name>",
  "pubspec_local": { "dependencies": { "<cs_package>": { "path": "../cs/<cs_package>" } } },
  "pubspec_git": { "dependencies": { "<cs_package>": { "git": { "url": "<git_url>", "ref": "main" } } } },
  // pubdev 时：
  "pubspec_local": { "dependencies": { ... } },
  "dependencies": [<dependency_plugin_ids>],
  "conflicts": [],
  "verify_points": ["<PID>1"],
  "presets": []
}
```

**文件 2：`~/.claude/skills/cs-plugins/{plugin_id}/SKILL.md`**

四段式结构，根据用户描述的步骤和场景填充：

```markdown
# {plugin_id} 插件

{description}

---

## [INSTALL] 安装步骤

### 前置检查
{根据依赖关系生成检查项}

### 添加依赖
{pubspec 片段}

### {用户描述的安装步骤展开}
...

---

## [UPDATE] 更新步骤

{根据 source 类型生成对应更新检测和步骤}

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
{根据用户描述的验证方法生成}

---

## [USAGE] 使用辅助

{根据用户描述的典型使用场景生成代码示例和说明}
```

**文件 3：`~/.claude/agents/{plugin_id}-plugin.md`**

使用标准插件 subAgent 模板，填入对应的 plugin_id、skill 路径、工具限制（见下方 subAgent 模板规范）。

**文件 4：创建 references/ 目录占位**

```
~/.claude/skills/cs-plugins/{plugin_id}/references/.gitkeep
```

### Step 3：注册到 REGISTRY.json

读取 `~/.claude/skills/cs-plugin-host/REGISTRY.json`，在 `plugins` 数组末尾追加新插件条目：

```json
{
  "id": "<plugin_id>",
  "name": "<name>",
  "version": "1.0.0",
  "description": "<description>",
  "category": "<category>",
  "source": "<source>",
  ...（完整字段从 metadata.json 复制）
  "skill": "cs-plugins/<plugin_id>/SKILL.md",
  "agent_id": "<plugin_id>-plugin"
}
```

### Step 4：输出确认汇总

```
✅ 新插件 {plugin_id} 创建完成

生成文件：
  📄 ~/.claude/skills/cs-plugins/{plugin_id}/metadata.json
  📄 ~/.claude/skills/cs-plugins/{plugin_id}/SKILL.md
  📄 ~/.claude/agents/{plugin_id}-plugin.md
  📁 ~/.claude/skills/cs-plugins/{plugin_id}/references/

已注册到 REGISTRY.json

下一步建议：
  1. 补充 SKILL.md 中的具体安装步骤细节
  2. 在 references/ 中添加参考文档
  3. 输入「接入 {plugin_id}」测试安装流程
```

---

## subAgent 文件模板规范

创建插件 subAgent 时，使用此模板：

```markdown
---
name: {plugin_id}-plugin
description: {name} 插件助手。负责安装、更新、使用辅助。
tools: Read, Write, Edit, Bash, Glob, Grep
{# cs_repo 类插件添加 mcps: supabase（如需访问后台）}
skills:
  - cs-plugins/{plugin_id}/SKILL.md
---

# {name} 插件助手

管理 {plugin_id} 插件的全生命周期：安装 / 更新 / 使用辅助。

## 模式判断

根据主机传入的 `mode` 参数进入对应模式：
- `install` → 安装模式（遵循清单编排）
- `update` → 更新模式（遵循清单编排）
- `usage` → 使用辅助模式（动态响应）

## 输入参数格式

```
mode: install|update|usage
project_path: {项目根目录}
cs_dir_exists: true|false   # 仅 cs_repo 类插件
user_request: {原始请求}     # 仅 usage 模式
```

## 安装模式清单

开始安装前，输出以下清单，每步完成后更新状态（🔄 执行中 / ✅ 完成 / ⛔ 失败）：

```
📦 {name} 安装清单

[ ] Step 1  前置检查（依赖 / 是否已安装）
[ ] Step 2  添加 pubspec 依赖
[ ] Step 3  {主要安装步骤...}
[ ] Step N  执行验证检查
[ ] Step N+1 向主机报告结果
```

**⛔ 安装模式强制规则**：
- 清单每步必须按顺序执行，不可跳过
- 每步完成后立即更新状态为 ✅ 或 ⛔
- 任一步骤失败 → 停止，输出失败报告，不继续后续步骤
- 用户等待确认仅发生在有 `[等待用户确认]` 标注的步骤

## 更新模式清单

```
📦 {name} 更新清单

[ ] Step 1  读取当前版本信息
[ ] Step 2  检测可用更新（维度：{plugin_version|cs_commit|resolved_version}）
[ ] Step 3  展示更新内容（若无更新则跳过后续）
[ ] Step 4  执行更新
[ ] Step 5  执行验证检查
[ ] Step 6  向主机报告结果
```

## 使用辅助模式

读取 SKILL.md 的 `[USAGE]` 章节，结合用户具体请求，提供：
- 代码片段（可直接使用）
- 常见问题排查
- 最佳实践建议

## 完成报告格式（安装/更新结束时输出，供主机汇总）

```
---插件完成报告---
plugin_id: {plugin_id}
mode: install|update
status: success|failed
verify_passed: true|false
error: <失败时的错误描述>
cs_commit: <cs_repo 类插件填入 git rev-parse HEAD>
resolved_version: <pubdev 类插件填入 pubspec.lock 中的版本>
---
```
```

---

## 注意事项

- **问答阶段不要求完整**：用户可只填部分，AI 根据经验补全合理默认值
- **插件 ID 唯一性检查**：生成前先确认 REGISTRY.json 中无同 ID 插件
- **工具限制按类型匹配**：
  - 纯 pubdev 包：`tools: Read, Write, Edit, Bash, Glob, Grep`
  - cs_repo 包：同上 + 可选 `mcps: supabase`（如涉及后台操作）
  - 媒体资源管理：`tools: Read, Write, Edit, Bash, Glob, Grep`
- **SKILL.md 是知识文档，不含清单**：清单逻辑只在 subAgent 内部
