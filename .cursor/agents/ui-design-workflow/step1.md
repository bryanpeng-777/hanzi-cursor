# Step 1 详细执行规范：生成设计方案（规格文档 + 预览图）

> **门禁**：Step 1 必须 ✅。
>
> **Pre-check（进入本步前必须输出）：**
> ```
> 🔍 Pre-check — 进入 Step 1
>   • {background}：✅ 已设置 / ❌ 缺失 → 回退补做 Step 0
>   • {screen_input}：✅ 已设置 / ❌ 缺失 → 回退补做 Step 0
>   结论：✅ 门禁通过，开始 Step 1 / ❌ 门禁未通过，先补做 Step 0
> ```

## 1-A：Gemini 模型切换确认（硬门禁 · 生成设计图前必做）

Step 1 的设计方案 + 预览图由**当前主会话**直接生成（不拉起子 Agent / Task）。预览图依赖 `GenerateImage`，**推荐在 Gemini 模型下执行**以获得更稳定的出图质量。

⛔ **在收到用户确认前，禁止执行下方 1-B。**

### 1-A-1：输出提醒（每次即将执行 1-B 前必须输出）

```
🎨 Step 1 — 生成设计方案 + 预览图

本步将在当前对话中直接生成七维设计规格与预览图（使用 GenerateImage）。

请你先在 Cursor 中切换模型：
  1. 打开当前对话的模型选择器
  2. 切换为 Gemini 系列（推荐 gemini-3-flash；若不可用可选你本地可用的 Gemini 变体）

切换完成后请回复：
  • 「模型已切换」或「开始生成」→ 我将继续生成设计方案 + 预览图
  • 若暂不切模型，回复「跳过」→ 用当前模型继续（不推荐，预览质量可能不稳定）
```

然后 **停止**，等待用户回复。

### 1-A-2：用户回复分支

| 用户回复 | 动作 |
|----------|------|
| 「模型已切换」「开始生成」「开始」 | 设置 `{gemini_model_confirmed}=true`，进入 **1-B** |
| 「跳过」 | 输出「⚠️ 已记录：未切换 Gemini，预览质量不保证」，设置 `{gemini_model_confirmed}=skipped`，进入 **1-B** |
| 其他（如修改意见、无关内容） | 若尚未生成过方案 → 重申 1-A-1 提醒；若已在 1-D 迭代 → 按 1-D 修改意见分支处理 |

> **迭代重生成**：用户于 1-D 提出修改意见后返回 1-B 前，须**再次输出 1-A-1 简短版**（可合并为一句：「将重新生成预览图，请确认模型仍为 Gemini（或回复「跳过」），回复「开始生成」」），收到确认后再执行 1-B。

---

## 1-B：在当前会话生成设计方案 + 预览图

**前置**：`{gemini_model_confirmed}` 为 `true` 或 `skipped`。

> 若本轮为首次生成，`{prev_design_spec}` 和 `{user_feedback}` 为空。
> 若本轮为迭代修改，将上一版 `{design_spec}` 赋给 `{prev_design_spec}`，用户修改意见赋给 `{user_feedback}`。

**在当前会话按以下步骤严格执行（禁止拉起子 Agent / Task）：**

1. **Read** `~/.claude/skills/frontend-design/SKILL.md`，加载其中的 Design-Only 模式规范。

2. **尝试 Read** `~/.claude/knowledge/ui-assistant/{project}/design_style.md`
   - 若文件存在：将内容完整读取，存为 `{style_guide}`；后续生成的设计规格必须与其保持一致（色板、字体、布局节奏、禁止事项均遵守）
   - 若文件不存在：`{style_guide}` = 空，自由发挥

3. **扫描** `~/.claude/knowledge/ui-assistant/{project}/style_references/` 目录
   - 若目录存在且非空：列出所有文件名，取文件名按字母序最大的一张，完整路径存为 `{ref_image_path}`
   - 若目录不存在或为空：`{ref_image_path}` = 空

4. **生成七维设计规格文档**（包含：设计方向、色彩、字体、动效基调、空间 & 布局、视觉细节、记忆点），结合：
   - 项目背景：`{background}`
   - 待优化界面：`{screen_input}`
   - 项目名：`{project}`
   - 风格约束（若存在）：`{style_guide}`（必须严格遵守其中的色板、字体、布局节奏、禁止事项）
   - 若为迭代修改：在上一版草稿 `{prev_design_spec}` 基础上按 `{user_feedback}` 调整

5. **合成 preview_prompt**：
   `"{项目风格摘要}，{设计方向}，{色彩方案}，{布局描述}，高保真 App 界面截图风格，{待优化界面类型}，精致细节，{记忆点}"`

6. **调用 GenerateImage**（正文须出现「请用 GenerateImage 生成以下预览图」）：
   - description：preview_prompt（完整内容）
   - filename：`{project}_ui_preview.png`
   - reference_image_paths：若 `{ref_image_path}` 非空，则传入 `[{ref_image_path}]`；若为空则不传此参数

7. 将七维规格文档全文存入 `{design_spec}`，确认预览图文件名 `{project}_ui_preview.png`，进入 **1-C**。

若无 GenerateImage 工具 → 声明「无法生成预览图」，询问用户是否仅凭文字规格继续。

---

## 1-C：展示并等待确认

```
✅ 设计方案已生成

[设计规格文档全文]

[预览图（若已生成）]

---
满意后说「确认」进入下一步（将向你索取 Figma 链接）。
如需调整，请告知修改意见（如「主色改为暖橙」），我将重新生成方案。
```

- 用户说**「确认」** → 执行风格沉淀（见下方），再输出 GATE PASS，进入 Step 2
- 用户提出**修改意见** → 将当前 `{design_spec}` 存为 `{prev_design_spec}`，将用户意见存为 `{user_feedback}`，回到 **1-A**（简短提醒切换模型）→ 确认后 **1-B** 重新执行，循环直到用户确认

**风格沉淀（用户确认后、GATE PASS 之前执行）：**

```
1. 将本次 {design_spec}（七维规格文档）覆盖写入：
   ~/.claude/knowledge/ui-assistant/{project}/design_style.md
   （保留文件头注释，更新"来源"为当次日期和方案名）

2. 统计 style_references/ 目录下已有文件数量 N（从 0 开始），
   将 {project}_ui_preview.png 复制为：
   ~/.claude/knowledge/ui-assistant/{project}/style_references/preview_approved_{N+1}.png
   输出：「已沉淀风格规范 + 存入参考图 preview_approved_{N+1}.png」
```

**GATE PASS 输出（用户确认后立即输出，然后停止）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 1 完成
产出：
  • {design_spec}：七维规格文档已生成（设计方向：{设计方向一句话}）
  • 预览图：{project}_ui_preview.png（已生成 / 无 GenerateImage 工具已跳过）
  • 用户确认：✅ 已收到「确认」
下一步：Step 2（说「继续」开始，或直接提供 Figma 链接）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
