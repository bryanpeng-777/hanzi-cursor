# Step 2 详细执行规范：Figma 链接 → tdesign-d2c 转换 → 生成中间代码

> **门禁**：Step 1 ✅（快速通道下 Step 0/1 ⏭️ 跳过，直接从 2-B 开始）。
>
> **Pre-check（进入本步前必须输出）：**
> ```
> 🔍 Pre-check — 进入 Step 2
>   • {design_spec}：✅ 已设置 / ❌ 缺失（快速通道下允许为空）
>   结论：✅ 门禁通过 / ❌ 门禁未通过，先补做 Step 1
> ```

## 2-A：索取 Figma 链接（快速通道下跳过）

```
🔗 请提供该设计对应的 Figma 链接（格式：
https://www.figma.com/design/XXXX/...?node-id=X-X&...）
```

将链接存入 `{figma_link}`，提取 `node-id` 参数存为 `{figma_node_id}`。

## 2-B：确保 tdesign-d2c 依赖就绪

```bash
ls /Users/bryanpeng/.claude/skills/tdesign-d2c/node_modules/@tdesign/d2c-utils 2>/dev/null | head -1
```

若不存在：
```bash
cd /Users/bryanpeng/.claude/skills/tdesign-d2c && npm install 2>&1 | tail -3
```

## 2-C：获取 Figma 上下文

> Figma Token：从环境变量 `FIGMA_ACCESS_TOKEN` 读取，勿写入仓库。

```bash
cd /Users/bryanpeng/.claude/skills/tdesign-d2c && \
  npx tsx scripts/get-figma-context.ts \
    "$FIGMA_ACCESS_TOKEN" \
    "{figma_link}" \
    "claude-sonnet-4-5" 2>&1
```

输出目录：`/Users/bryanpeng/.claude/skills/tdesign-d2c/_design-context/{figma_node_id}/`

## 2-D：分析组件结构

```bash
cd /Users/bryanpeng/.claude/skills/tdesign-d2c && \
  npx tsx scripts/analyze-components.ts {figma_node_id} 2>&1
```

## 2-E：读取产物

Read 以下两个文件，存入上下文：
- `figma.html` → `{d2c_html}`
- `component-info.json` → `{d2c_components}`

路径：`/Users/bryanpeng/.claude/skills/tdesign-d2c/_design-context/{figma_node_id}/`

**任一文件读取失败 → 禁止进入 Step 3（无降级路径）。**

## 2-F：生成中间代码（intermediate.tsx）

基于 `{d2c_html}` 和 `{d2c_components}`，遵循 tdesign-d2c §6 规则生成 React HTML/CSS 中间代码：

**生成规则：**
- 原生 HTML 标签 + CSS（不引用任何组件库）
- 严格参照 `figma.html` 中每个节点的坐标、尺寸、色值、字号
- 默认 flex/grid 相对布局，仅浮层/角标允许 `position: absolute`
- 文本节点必须显式设置 `line-height`、`font-size`
- 组件边界用注释标注，名称来自 `component-info.json`

**文件头：**
```tsx
// 由 tdesign-d2c 从 Figma 自动生成，作为 Flutter 实现的中间参考
// node-id: {figma_node_id} | 框架: React（最终由 dev-assistant 翻译为 Flutter）
import React from 'react';
```

Write 保存到：
`/Users/bryanpeng/.claude/skills/tdesign-d2c/_design-context/{figma_node_id}/intermediate.tsx`

Read 读回，存为 `{d2c_intermediate}`。

## 2-G：生成图片映射表（image_map.json）

扫描 `{d2c_html}` 中所有 `background:url(...)` 或 `<img src=...>` 节点，生成映射条目：

| 字段 | 说明 |
|------|------|
| `configKey` | 基于 `data-name`/周围文本/父节点推断语义名，snake_case；≤40px 以 `_icon` 结尾，否则 `_image` |
| `type` | `icon`（≤40px）/ `image_slot`（>40px）/ `decoration`（≤3px 分割线等） |
| `src_file` | UUID + 扩展名 |
| `src_path` | `/Users/bryanpeng/assets/{figma_node_id}/{src_file}` |
| `width`/`height` | 从节点 `style` 解析 |
| `description` | 中文无障碍描述 |

`decoration` 类型跳过；同一 `configKey` 去重保留第一条。

Write 到 `image_map.json`（同目录），Read 存为 `{d2c_image_map}`。

## 2-H：清理临时文件

```bash
rm -rf /Users/bryanpeng/.claude/skills/tdesign-d2c/_design-context/{figma_node_id}
```

## 汇报格式

```
✅ tdesign-d2c 转换完成
- figma.html：{行数} 行，{N} 个定位节点
- component-info.json：识别出 {M} 个组件
- intermediate.tsx：{行数} 行 React 中间代码
- image_map.json：{K} 个图片节点（icon: X，image_slot: Y，decoration: Z）
- Figma 原始资源：/Users/bryanpeng/assets/{figma_node_id}/（共 N 个文件）
```

Step 2 标 ✅，输出 GATE PASS，进入 Step 3。

**GATE PASS 输出（完成后立即输出，然后停止）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 2 完成
产出：
  • {d2c_html}：{行数} 行，{N} 个定位节点
  • {d2c_intermediate}：{行数} 行 React 中间代码
  • {d2c_image_map}：{K} 个图片节点（icon: X，image_slot: Y）
  • Figma 资源：/Users/bryanpeng/assets/{figma_node_id}/（共 N 个文件）
下一步：Step 3（同回合连续执行）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
