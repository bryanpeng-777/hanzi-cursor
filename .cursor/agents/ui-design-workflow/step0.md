# Step 0 详细执行规范：读取项目背景 + 接收待优化界面

> **Pre-check**：Step 0 是起始步，无前置变量校验。直接开始执行。

## 执行顺序

### 0-A：解析项目名称

从对话上下文 `user_info` 中的 `Workspace Path` 取最后一段，得到 `{project}`（如 `demo`）。

### 0-B：读取 background.md

路径：`~/.claude/knowledge/ceo-assistant/{project}/background.md`

- **文件存在** → 读取全文，存入上下文 `{background}`
- **文件不存在** → **不阻断**（2026-06 优化）：
  1. 尝试 Read `{Workspace Path}/CLAUDE.md`，摘要前 800 字存入 `{background}`，标注 `source=CLAUDE.md_fallback`
  2. 若 CLAUDE.md 也不存在 → `{background}` = 用户消息中的项目描述；输出 ⚠️ 建议后续运行 ceo-assistant 初始化
  3. **继续 Step 0**，不禁止进入 Step 1

### 0-C：接收待优化界面

- 若用户已在本轮消息中提供截图、描述或页面名称 → 存入 `{screen_input}`
- 若未提供 → 询问：

```
📱 请描述需要优化的界面：
- 是哪个页面/功能模块？（如「首页 Banner 区域」「个人中心页」）
- 当前存在什么问题？（如「信息密度太高」「视觉层次不清晰」）
- 有无特定优化方向或参考风格？（可选）
可直接附上截图。
```

等待用户回复，存入 `{screen_input}`。

### 0-D：风格资产检测与冷启动引导

检测路径：`~/.claude/knowledge/ui-assistant/{project}/design_style.md`

**情况 A：文件存在**

输出：`✅ 已检测到风格规范（design_style.md），Step 1 将自动加载。`

直接进入 0-E。

---

**情况 B：文件不存在（新项目冷启动）**

| 模式 | 动作 |
|------|------|
| `autopilot` | 从 `{background}` / CLAUDE.md 推断色板与风格，**直接 Write** `design_style.md`（无需 3 问），创建空 `style_references/` |
| `standard` / `fast_track` | 若 `{background}` 已含 UI 风格段落 → 同样自动推断写入；否则 **一次性** 输出 Q1–Q3（合并为一条消息），用户未答则按 background 默认值写入 |

写入后 **不等待**确认 design_style 草稿；用户可在后续任意时刻要求调整。

**design_style.md 模板：**

```markdown
# {project} 设计风格规范

> 初始化时间：{日期}

## 设计方向
{一句话风格总结}

## 色板
- 背景：{色值}（{色彩名}）
- 主色：{色值}（{色彩名}）
- 强调色：{色值}
- 卡片背景：{色值}，边框：{色值}

## 字体
- 标题：{字重}，letterSpacing：{值}
- 正文：{字重}，行高：{值}

## 布局节奏
- 水平 padding：{值}
- Section 间距：{值}
- 卡片圆角：{值}

## 禁止事项
{用户 Q3 回答整理}

## 记忆点
{项目独特视觉标识，首次初始化可留空待后续补充}
```

**参考图初始化：**

- 若 `{cold_ref_image}` 有值 →
  - 创建 `style_references/` 目录
  - 将图片复制为 `style_references/preview_approved_1.png`
  - 输出：`已将你提供的图片存为首张风格参考图 (preview_approved_1.png)`

- 若 `{cold_ref_image}` 为空 → 询问用户：
  ```
  📸 是否有喜欢的 App 截图或设计参考图？
     有的话发给我，我将作为第一张参考图存入风格库。
     没有可直接跳过，后续每次确认设计方案时会自动积累。
  ```
  - 用户提供图片 → 复制为 `style_references/preview_approved_1.png`
  - 用户跳过 → 创建空 `style_references/` 目录

写入完成后输出：
```
✅ 风格规范 + 参考图库已初始化，进入 Step 1
```

---

### 0-E：门禁校验

background.md 已读 + 界面描述已接收 + 风格资产已就绪 → Step 0 标 ✅，进入 Step 1。

**GATE PASS 输出（完成后立即输出，然后停止）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 0 完成
产出：
  • {background}：已读取（{字数} 字）
  • {screen_input}：「{界面描述前30字}…」
  • 风格规范：{已加载 / 已初始化（新建）}
  • 参考图库：{N 张参考图 / 空库}
下一步：Step 1（同回合连续执行；生成方案后不等待确认）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
