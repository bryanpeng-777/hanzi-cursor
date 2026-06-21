---
name: screenshot-to-flutter
description: 将 UI 截图、设计稿、Figma 导出图或界面录屏帧转换为可运行的 Flutter Widget 代码。借鉴 screenshot-to-code 的分阶段流程（视觉分析→布局规划→代码生成→静态校验→迭代修正）。当用户说「截图转 Flutter」「图片转代码」「screenshot to flutter」「设计稿还原」「UI 截图实现」「mockup to dart」「界面截图写 Widget」或要把设计图/截图变成 Flutter 界面时，必须使用本技能。即使未提及 Flutter，只要目标是「把图片变成 App 界面代码」且项目是 Flutter，也应触发。
---

# Screenshot to Flutter

将 UI 视觉输入（截图 / 设计稿 / Figma 导出 / 录屏帧）还原为 **可编译、可预览** 的 Flutter 代码。

> 方法论参考开源项目 [screenshot-to-code](https://github.com/abi/screenshot-to-code)：先精确复刻视觉，再生成代码；支持多图、设计系统约束、增量修改。本技能将其 **Web 栈** 映射为 **Flutter + 项目技术栈**。

## 分工

| 环节 | 执行者 |
|------|--------|
| 项目栈检测、目录规范、`flutter analyze` | `scripts/` |
| 视觉解读、Widget 树设计、代码编写、迭代修正 | AI |

---

## Step 0：输入收集与模式判定

### 0-A 确认输入

向用户确认或从对话中提取：

| 字段 | 说明 |
|------|------|
| **视觉输入** | 一张或多张图片路径；若有录屏，取关键帧 |
| **目标** | 新建页面 / 替换现有页面 / 局部改版 |
| **输出路径** | 如 `lib/screens/foo_screen.dart`；未指定则询问 |
| **附加说明** | 交互、文案修正、是否横屏等 |

**缺图则停止**，请用户提供截图或路径。

### 0-B 检测项目 Profile

```bash
python3 ~/.claude/skills/screenshot-to-flutter/scripts/detect_project_profile.py <项目根目录>
```

根据输出选择 stack 策略，详见 [references/project-profiles.md](references/project-profiles.md)。

### 0-C 判定生成模式（对标 screenshot-to-code `plan.py`）

| 模式 | 条件 | 策略 |
|------|------|------|
| **create** | 新建 Widget / 新文件 | 完整生成 |
| **update** | 已有目标 `.dart` 且用户要改 UI | 仅 `edit_file` 局部替换，禁止整文件重写 |
| **update-targeted** | 用户指定「只改某个按钮/卡片/区域」 | 定位该 Widget 子树，最小 diff |

### 0-D 加载设计系统（可选）

若项目有设计规范文件，**必须先 Read** 并在后续 prompt 中注入 `<design_system>` 块（对标 `design_system.py`）：

- 通用：`lib/design/*_design_spec.dart`、`lib/utils/app_theme.dart`
- hanzi-cursor：`lib/design/hanzi_design_spec.dart`、`lib/design/hanzi_shared_widgets.dart`

设计系统与截图冲突时，**以设计系统为准**（颜色 token、间距、共享组件）。

---

## Step 1：视觉分析（Replication Analysis）

对照截图输出结构化分析（不写代码），模板见 [references/prompt-templates.md](references/prompt-templates.md#step-1-视觉分析输出)。

必须提取：

1. **画布**：尺寸感（手机竖屏 / 横屏 / 平板）、安全区、是否含设备边框（移动端截图应忽略边框，只还原 UI）
2. **布局树**：Row/Column/Stack/Grid 层级、对齐、间距比例
3. **样式 token**：背景色、主色、圆角、阴影、字号层级（尽量映射到项目 DesignSpec）
4. **文案**：截图中的 **精确文字**（后续代码必须一致）
5. **资产清单**：图标/插画/头像 → 标记为 `extractable`（可用占位或 CsImage）或 `generate`（需走 image-generator-workflow）

多图时按 screenshot-to-code 规则组织：

- 不同页面 → 独立 route / 文件，必要时加导航
- 同 App 不同 Tab → 用 Tab/IndexedStack 串联
- 无关联 → 分节展示「Screenshot 1 / 2 / 3」便于对照

---

## Step 2：实现规划（Build Plan）

输出简短规划后再写代码：

```
## Widget 树
[层级大纲]

## 复用组件
[HanziSurfaceCard / ShadButton / CsAppBar 等]

## 资产策略
| 元素 | 策略 | configKey / 占位 |
|------|------|------------------|

## 文件变更
- 新建/修改：path
- 路由（若需要）：go_router path
```

**Stack 约束**：Read [references/flutter-stack.md](references/flutter-stack.md) 中与当前 profile 匹配的章节，严格遵守。

---

## Step 3：代码生成

### 3-A Create 模式

1. 创建或更新目标 `.dart` 文件
2. 优先复用项目已有 **共享 Widget**（如 `HanziLandscapeScaffold`、`HanziSurfaceCard`）
3. 图片使用 `CsImage(configKey: …)` 或 `Image.asset`，**禁止**硬编码网络 URL（除非用户明确要求）
4. 需新配图时：列出 `configKey` + description，提示用户走 **image-generator-workflow**，本步先用 `Container` + 色块占位并在注释标明

### 3-B Update 模式

对标 screenshot-to-code 的 `edit_file` 策略：

- 用 **精确字符串替换**，不重写整个文件
- 保留 import、状态管理、业务逻辑
- 若用户给出选中元素描述（类似 preview 里选中 DOM），按 tag/文案/Key 定位 Widget 子树，只改该 subtree

### 3-C 代码质量要求

- `ConsumerWidget` / `ConsumerStatefulWidget`（若项目用 Riverpod）
- 屏幕适配：有 `flutter_screenutil` 则用 `.w` / `.h` / `.sp`
- 路由：有 `go_router` 则用 `context.push` / `context.go`
- UI 组件：有 `cs_ui` 则用 `ShadButton`、`CsAppBar`、`CsImage` 等，禁止 Material 原生按钮/AppBar（见 flutter-stack.md）
- 中文排版：有 `google_fonts` 则用 `GoogleFonts.notoSansSc()`

完整 prompt 话术模板：[references/prompt-templates.md](references/prompt-templates.md)

---

## Step 4：验证（Visual & Static Check）

对标 screenshot-to-code 的 `screenshot_preview`——在 Flutter 侧做静态与可选预览校验：

```bash
# 1. 静态分析（必须）
bash ~/.claude/skills/screenshot-to-flutter/scripts/validate_output.sh <项目根> [目标dart相对路径]

# 2. 可选：Web 预览（用户需要看效果时）
cd <项目根> && flutter run -d chrome --target=<入口或测试页>
```

检查清单：

- [ ] `flutter analyze` 无 error
- [ ] 布局层级与 Step 1 分析一致
- [ ] 文案与截图一致
- [ ] 颜色/圆角/间距与 DesignSpec 或截图接近
- [ ] 无 `print`、无 `Navigator.push`（若项目规范禁止）

若发现明显偏差（重叠、间距错误、颜色不对），回到 Step 3-B 做 **targeted update**，而非整页重写。

---

## Step 5：交付摘要

用 1～2 句话说明：

- 生成了什么 Widget / 文件
- 哪些资产仍是占位、需后续 image-generator-workflow
- 如何预览（路由 path 或 Tab 入口）

---

## 与其他技能的关系

| 场景 | 路由 |
|------|------|
| 需要批量生成/替换位图 | **image-generator-workflow**（本技能只写 `CsImage(configKey)` 占位） |
| 完整界面改版 + Figma + 测试闭环 | **ui-design-workflow** |
| 纯 Web 截图转 HTML/React | 直接用 [screenshot-to-code](https://github.com/abi/screenshot-to-code) 或 **frontend-design** |
| 代码写完要编译/部署 | **dev-assistant** / **app-dev-workflow** |

---

## 注意事项

- 本技能 **不** 启动 screenshot-to-code 的 Python 后端；在 Cursor 内用多模态能力 + 上述流程完成
- 追求 **视觉还原度**，但业务状态（Provider、路由参数）需与用户确认，不要臆造复杂逻辑
- 录屏输入：先抽 3～5 关键帧当多图处理，交互说明写入 Step 2 规划
