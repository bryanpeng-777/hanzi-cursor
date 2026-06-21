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
>
> ⛔ **禁止**：提醒/要求切换 Gemini 或任何特定模型；禁止本步完成后停下来等用户「确认」。

---

## 1-A：在当前会话生成设计方案 + 预览图

设计方案 + 预览图由**当前主会话**直接生成（不拉起子 Agent / Task），**用当前可用模型 + GenerateImage 即可**。

> 若本轮为首次生成，`{prev_design_spec}` 和 `{user_feedback}` 为空。
> 若用户在同轮消息中附带修改意见，将上一版 `{design_spec}` 赋给 `{prev_design_spec}`，意见赋给 `{user_feedback}`。

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

7. 将七维规格文档全文存入 `{design_spec}`，设 `{design_confirmed}=auto`，进入 **1-B**。

若无 GenerateImage 工具 → 声明「无法生成预览图」，仍用 `{design_spec}` 继续，不阻断。

---

## 1-B：展示、风格沉淀、连续进入 Step 2

输出设计方案摘要 + 预览图（若有），**不等待用户确认**，立即执行风格沉淀：

```
1. 将本次 {design_spec} 覆盖写入：
   ~/.claude/knowledge/ui-assistant/{project}/design_style.md

2. 若已生成预览图：复制为 style_references/preview_approved_{N+1}.png
```

**GATE PASS 后（非 Harness）立即进入 Step 2**，不在步间等待「继续」。

**GATE PASS 输出：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 1 完成
产出：
  • {design_spec}：七维规格文档已生成（设计方向：{设计方向一句话}）
  • 预览图：{project}_ui_preview.png（已生成 / 已跳过）
  • {design_confirmed}：auto
下一步：Step 2（同回合连续执行；缺 Figma 链接时在 2-A 索取）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> 用户若对方案不满，可在后续任意时刻提出修改意见 → 将当前 `{design_spec}` 存为 `{prev_design_spec}`，回 **1-A** 重生成；**不**作为本步默认门禁。
