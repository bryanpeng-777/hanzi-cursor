# Step 5 详细执行规范：图片资源同步生成

> **门禁**：Step 4 ✅。
>
> **Pre-check（进入本步前必须输出）：**
> ```
> 🔍 Pre-check — 进入 Step 5
>   • {dev_changes_summary}：✅ 已设置 / ❌ 缺失 → 回退补做 Step 3
>   • {test_report}：✅ 已设置 / ❌ 缺失 → 回退补做 Step 4
>   • 编译通过标志：✅ / ❌ → 回退补做 Step 4
>   结论：✅ 门禁通过，开始 Step 5 / ❌ 门禁未通过，先补做 Step 4
> ```

---

## 5-A：读取图片台账

Read `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`：

- **不存在** → 输出提示后 Step 5 标 ✅ 跳过，进入最终汇总：
  ```
  ℹ️ 本项目暂无图片台账，跳过图片生成步骤。
  如需管理图片资源，可由 UI小助手 初始化台账。
  ```
- **存在** → 继续 5-B

---

## 5-B：识别受影响的图片插槽

从 `{dev_changes_summary}` 提取本次修改涉及的页面关键词（从文件名/类名推断，如 `home`、`profile`）。

遍历 `image_manifest.json` 中 `pages.*.images`，筛选满足**任一**条件的图片 key：
1. 所在 page 与关键词模糊匹配（忽略大小写、Screen/Page 后缀）
2. `status` 为 `placeholder`

结果存入 `{affected_images}`。

---

## 5-C：向用户呈现并确认

**`{affected_images}` 为空：**
```
ℹ️ 未发现与本次界面改动直接相关的待更新图片，跳过图片生成步骤。
```
Step 5 标 ✅，进入最终汇总。

**`{affected_images}` 不为空：**
```
🖼️ 检测到 N 张图片可能受本次 UI 改动影响：

  📄 {page_name}
    • {key}：{description}（当前状态：{status}）

是否现在生成/更新这些图片？
  A) 是，立即调用 image-generator-workflow 生成上述图片
  B) 跳过，稍后手动触发
```

- 用户选 **B** 或无回应 → Step 5 标 ✅ 跳过，进入最终汇总
- 用户选 **A** → 继续 5-D

---

## 5-D：调用 image-generator-workflow

Read `~/.claude/agents/image-generator-workflow.md`，通过 **Task**（`subagent_type="generalPurpose"`）启动：

```
你是 image-generator-workflow。请按以下全文执行批量生图流程：

===== image-generator-workflow.md 全文 =====
{image-generator-workflow.md 全文}
============================================

【预选图片】（Step 0 清单中默认勾选，其余默认不勾选）
{affected_images 格式化列表：页面名|key|description|status}

【项目上下文】
项目：{project} | Workspace：{Workspace Path}
manifest：~/.claude/knowledge/ui-assistant/{project}/image_manifest.json
风格文件：~/.claude/knowledge/ui-assistant/{project}/image_style_prompt.md

Step 1 风格确认、Step 2 逐张生图、Step 3 汇总校验完全按规范执行。
不要 commit，完成后输出成功/失败张数汇总。
```

等待返回，提取 `{image_gen_summary}`，Step 5 标 ✅，进入最终汇总。

**GATE PASS 输出（完成后立即输出，进入最终汇总）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 5 完成
产出：
  • 图片生成：{image_gen_summary}（成功 N 张 / 失败 N 张 / 已跳过）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
