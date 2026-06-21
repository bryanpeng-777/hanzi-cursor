# Prompt 模板

借鉴 [screenshot-to-code/backend/prompts/create/image.py](https://github.com/abi/screenshot-to-code/blob/main/backend/prompts/create/image.py) 的结构，适配 Flutter。

---

## Step 1 视觉分析输出

```markdown
# 视觉分析报告

## 画布
- 方向：横屏 / 竖屏
- 估计逻辑尺寸：宽 × 高
- 是否含设备边框：是/否（若是，忽略边框）

## 布局树
- Root: …
  - Header: …
  - Body: …
  - Footer: …

## 样式 Token
| 用途 | 色值/描述 | 建议映射 |
|------|-----------|----------|
| 页面背景 | #… | HanziDesignSpec.surfaceWarm |
| 主色 | #… | … |

## 文案（精确）
- 标题：「…」
- 按钮：「…」

## 资产清单
| 元素 | 类型 | 策略 |
|------|------|------|
| 左侧插画 | 图标 | CsImage 占位 hanzi_icon_xxx |
```

---

## Step 3 生成用 System 块（内化执行，不必输出给用户）

```
你是 Flutter UI 还原专家。根据截图生成可编译 Dart 代码。

## 复制要求（Replication）
- 页面视觉应与截图尽可能一致
- 使用截图中的精确文案
- 布局用 Row/Column/Stack/Flex 表达，间距用数值或 DesignSpec
- 不要贴整页截图当背景图
- 图片元素用 CsImage 占位或项目已有组件

## 设计系统
{design_system_block — 从 hanzi_design_spec 等读取}

## 选中栈
{flutter-stack.md 中对应 profile 的约束}

## 多图
{按 SKILL Step 1 多图规则}

## 附加说明
{用户 text_prompt}
```

---

## Design System Block 格式

对标 `design_system.py`：

```markdown
## 设计系统

若与设计系统冲突，以设计系统为准。

<design_system>
{粘贴 DesignSpec 常量名、共享 Widget 列表、禁止项}
</design_system>
```

---

## Update 模式 User 块

```
在文件 {path} 中更新 UI，使其更接近截图/用户描述。

要求：
- 仅用 search_replace 式局部修改
- 保留现有 import、Provider、路由
- 定位：{用户描述的 Widget / 文案 / Key}
- 变更：{具体修改}

Selected stack: {profile}
```
