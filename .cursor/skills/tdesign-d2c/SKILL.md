---
name: tdesign-d2c
description: 使用 Figma API 获取任意 Figma 设计稿上下文并进行处理，并转换为可维护的代码。内置 TDesign 相关映射逻辑，也可以扩展 references 的增加业务组件或其他信息辅助提升代码采纳率。
---

# Prerequisites

在进入下面的主流程之前，**必须先阅读并执行 `PREFLIGHT_CHECK.md`**，
只有在 `PREFLIGHT_CHECK.md` 中的所有前置项都通过后，才能进入下方的 §1。

---

# 1. 通过 Figma 链接，获取 Figma 的上下文，并组织成注入组件信息的 HTML 和快照

- Prompt 中的 Figma 文件链接，记为 `${figma-link}`

- 执行 `npx tsx scripts/get-figma-context.ts ${figma-token} ${figma-link} ${model}`

# 2. 获取组件结构

- 执行 `npx tsx scripts/analyze-components.ts ${figma-id}`，分析 `_design-context/${figma-id}` 中的 HTML，以获取组件信息。

- 输出文件为`_design-context/${figma-id}/component-info.json`。

# 3. 优化组件信息

## 3.1 组件信息获取

- 必读：`references/components`（业务组件）
- 选读：仅当 `package.json` 的 `dependencies` 含 TDesign 相关依赖时读取 `references/tdesign`（TDesign 组件），否则后续 §4、§5 一并跳过。

## 3.2 组件映射规则

- §2 生成的 `component-info.json` 中，每个节点的 `componentName` 字段初始为通用占位值。
- 结合 §3.1 加载到的 references 与 §1 产出的 `_design-context/${figma-id}/screenShot.png`，尽可能将所有 `componentName` 替换为对应的真实组件名，优先采用业务组件，其次再考虑 TDesign 组件（若适用）；无合适映射则保留原占位名。

- 对于涉及 `Table` 组件的部分，由于设计稿内部节点复杂且存在通过列方式组合的可能性，请分析其内部组件的结构和 screenshot 的结果，重新组织为 `data` 属性和其他 `props` 信息，并重写 `component-info.json` 相关部分的内容。

<!-- 如果不依赖 TDesign，可以直接将步骤 4、5 和相关 script 移除 -->

# 4. 查询组件文档

- 在生成代码之前，查询项目中使用的组件的 API 文档。
- 不要编造任何 API，并且始终检查 TypeScript 错误。

- 框架包括：`react` / `vue-next` / `miniprogram` / `uniapp`/ `vue` / `mobile-react`/ `mobile-vue`

> [用法] `npx tsx scripts/query-docs.ts <框架> <组件>`
> 例如：npx tsx query-docs.ts react button,link

- 根据你自己的知识生成组件代码。如果遇到任何类型错误，请参考文档。

- 不要实现 TDesign 未提供的任何API。
- 不要主动使用未在 `component-info.json` 的 Props 中提及的涉及边框、斑马纹等的属性，以及与渲染截图存在差异的属性。

# 5. 查询 TDesign 图标参考

- 当 `component-info.json` 中某个组件存在 `src` 字段时，通常表示该字段为图标资源链接。
- 在导入图标前，必须通过 `componentName` 调用图标查询工具，检查 TDesign 图标库中是否存在可替代图标，以优先使用组件库实现，减少本地图片依赖。

> [用法] `npx tsx scripts/query-icon.ts <关键词>`
> 例如：`npx tsx scripts/query-icon.ts chevron-down,task-setting`

- 若查询结果中存在匹配的图标，使用图标组件替代 `src` 引用，否则继续使用 `src` 中的图片资源进行渲染。

# 6. 生成代码

## 6.1 生成基本代码结构

根据 `_design-context` 中的内容生成相应的工程代码，然后将生成的代码保存在合适的文件中，并导入该文件以执行。

## 6.2 框架特殊处理规则

### 6.2.1 小程序（MiniProgram）

- **顶部导航栏胶囊区域**：设计稿中顶部导航栏右侧的胶囊操作区域统一不处理，由小程序框架自动渲染。生成代码时应忽略该区域，仅实现导航栏左侧和中间部分的内容（如返回按钮、标题、搜索框等）。

- **Swiper 轮播组件**：小程序框架中，如需实现轮播功能且需要自定义轮播项内容，应使用**原生小程序 `swiper` + `swiper-item`** 组件，而非 TDesign 的 `t-swiper` 组件。TDesign 的 `t-swiper` 在小程序中通过 `list` 属性传入数据，支持图片内容轮播，不支持 `t-swiper-item` 子组件写法。

## 6.3 实现样式

**保持布局参考 `_design-context/${figma-id}` 中的原始 HTML 布局**，组件之间的间距和布局应与原始 HTML 布局对应。

- 默认使用相对布局（flex / grid）实现整体结构，仅在元素坐标无法用父节点的排列规则表达时才使用 `position: absolute`。
- 外层容器的宽度需与 Figma 根节点一致，整体高度不应超过 Figma 根节点的高度，避免下半部分元素出现累计纵向偏移。
- 文本节点必须显式设置 `line-height`、`font-size` 与 `figma.html` 保持一致，不要依赖浏览器默认行高。
- 容器之间的垂直间距按 `figma.html` 中相邻节点的 `top` 差值计算，并在上下两端至少有一侧通过 `margin` 或 `gap` 精确设置，不要让 `padding` 和 `line-height` 同时贡献间距。
- 检查项目是否已使用 `tailwindcss` 或已安装 `tailwindcss`。
- 如果使用 `tailwindcss`，则使用 `tailwindcss` 类从分离的各层实现每个节点的样式。
- 如果不使用 `tailwindcss`，则使用 `css` 类从分离的各层实现每个节点的样式。
- 如果默认使用 `sass` 或 `less`，则使用 `sass` 或 `less` 类从分离的各层实现每个节点的样式。

# 7. 询问用户是否需要使用该技能检查结果

生成代码后，询问用户是否基于生成结果，尝试进行二次优化。
**问题1 — 检查结果**（标题："检查结果"）：
是否检查生成结果，并基于对比结果尝试进行效果二次优化？选项：是 / 否

- 如果用户选择 "是"，则使用 `RESULT_CHECK.md` 检查结果。
- 如果用户选择 "否"，则进入步骤 8。

# 8. 删除设计上下文文件并收集反馈

完成所有步骤并验证结果后，清理临时上下文文件，并先收集用户反馈。

## 8.1 清理上下文文件

清理本次转换的临时上下文文件 `_design-context/${figma-id}`。

## 8.2 收集用户反馈

向用户询问本次转换的满意度和改进建议，包括：

- **评分**：请用户对本次转换结果打分（1-5 分），含义如下：
  - 1 分：生成结果基本不可用
  - 2 分：需要大量修改
  - 3 分：一般，需要部分修改
  - 4 分：只需少量调整
  - 5 分：几乎无需修改

收集到用户评分后，通过 `@tdesign/d2c-utils` 提供的 `reportFeedback` 方法将反馈上报：

```bash
npx tsx -e "import { reportFeedback } from '@tdesign/d2c-utils'; reportFeedback('${figmaUrl}', { score: '${score}' });"
```

**注意事项**：

- 不要使用 tail 命令查看 `_design-context/${figma-id}` 目录下的任何 HTML 文件或 component-info JSON 文件。
- 如果任何脚本需要第三方库，请将其添加到 `package.json` 的 devDependencies 中。
- 仅在实现最终确认并被接受后才删除上下文文件。
