# Step 3 详细执行规范：调用 dev-assistant 实现设计方案

> **门禁**：Step 2 ✅（`{d2c_intermediate}`、`{d2c_image_map}` 已就绪）。
>
> **Pre-check（进入本步前必须输出）：**
> ```
> 🔍 Pre-check — 进入 Step 3
>   • {d2c_html}：✅ 已设置（{行数} 行）/ ❌ 缺失 → 回退补做 Step 2
>   • {d2c_intermediate}：✅ 已设置（{行数} 行）/ ❌ 缺失 → 回退补做 Step 2
>   • {d2c_image_map}：✅ 已设置（{K} 个节点）/ ❌ 缺失 → 回退补做 Step 2
>   结论：✅ 门禁通过，开始 Step 3 / ❌ 门禁未通过，先补做 Step 2
> ```
>
> **子步骤顺序（强制）**：3-Pre-Capabilities → 3-Pre-A → 3-Pre-B → 3-Pre-C（默认 auto）→ dev-assistant → **连续 Step 4**

---

## 3-Pre-Capabilities：读取/生成项目公共能力列表

检查：`~/.claude/knowledge/dev-assistant/{project}/project_capabilities.json`

**存在** → Read 读取，存入 `{project_capabilities}`，跳至 3-Pre-A。

**不存在** → 执行以下扫描（依次）：

1. Read `{cs_ui_path}/lib/cs_ui.dart`（路径从 `{Workspace Path}/../cs/cs_ui` 推断或从 pubspec_overrides.yaml 解析），提取所有 export 的 Widget 名称
2. 逐一 Read 每个 Widget 源文件，提取构造函数参数和文档注释示例
3. Read `~/.claude/knowledge/dev-assistant/{project}/rule.md`，提取 `replaces` 和 `banned_patterns`
4. Read `{Workspace Path}/CLAUDE.md`，提取技术栈表
5. Read `{cs_ui_path}/lib/src/theme/cs_app_theme.dart`，提取 `activeStyle` 及对应主题 Token

合成 JSON（schema 见下），Write 到 `~/.claude/knowledge/dev-assistant/{project}/project_capabilities.json`，Read 存入 `{project_capabilities}`。

**project_capabilities.json schema：**
```json
{
  "project": "", "generated_at": "",
  "design_tokens": { "active_theme": "", "background_color": "", "border_radius": "", "button_height": "" },
  "capabilities": {
    "ui_components": { "description": "", "entries": [
      { "name": "", "import": "", "required_params": [], "optional_params": [], "example": "", "replaces": [], "notes": "" }
    ]},
    "auth": { "description": "", "entries": [] },
    "state_management": { "description": "", "entries": [] },
    "routing": { "description": "", "config_path": "", "entries": [] },
    "data": { "description": "", "entries": [] },
    "logging": { "description": "", "entries": [] },
    "http": { "description": "", "entries": [] },
    "storage": { "description": "", "entries": [] }
  },
  "global_banned_patterns": [{ "banned": "", "use_instead": "" }]
}
```

**Update 触发词**：用户说「更新组件列表」→ 强制重新扫描覆盖（保留人工 `notes`）。

---

## 3-Pre-A：预读图片台账

Read `~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`：
- 存在 → 提取 `pages.*.images` 所有插槽，存入 `{existing_image_slots}`（`configKey | description | status`）
- 不存在 → 创建空结构 `{"pages": {}}` 写入，继续

---

## 3-Pre-B：将 Figma 图片接入项目 assets + 注册台账

遍历 `{d2c_image_map}` 中 `type != "decoration"` 的条目：

**① 创建目录**
```bash
mkdir -p {Workspace Path}/assets/figma_d2c
```

**② 拷贝并语义重命名**
```bash
cp {src_path} {Workspace Path}/assets/figma_d2c/{configKey}.{ext}
```
文件不存在时跳过并记录警告，不阻断流程。

**③ 注册 pubspec.yaml**（若 `assets/figma_d2c/` 未包含则添加）

**④ 注册 image_manifest.json**（`pages.figma_d2c.images` 下，status = `"provided"`，已存在且 provided 则跳过）

**⑤ 更新 default_configs.json**
```json
"xxx_image": { "url": null, "asset": "assets/figma_d2c/xxx_image.png" }
```

**⑥ 生成 {figma_image_slots}**（供 dev-assistant 使用）
```
configKey | dest_asset_path | description | type
```

---

## 3-Pre-C：生成翻译映射决策表（默认 auto 确认）

扫描 `{d2c_intermediate}`，对照 `{project_capabilities}`，输出四维映射表。

`global_banned_patterns` 命中时标注 `❌ 已替换`。

| 条件 | 动作 |
|------|------|
| 映射表 **无 ❌**、无非 capabilities 组件 | `{translation_map_confirmed}=auto`，**同回合**调度 dev-assistant |
| 含 ❌ 或未知组件 | **仅此情况暂停**，等人确认或给修改意见 |

存入 `{translation_map}`。

---

## dev-assistant 调度

Read `~/.claude/agents/dev-assistant.md`，通过 **Task**（`subagent_type="generalPurpose"`）启动，传入 prompt：

```
你是 dev-assistant（程序员小助手）。

===== dev-assistant.md 全文 =====
{dev-assistant.md 全文}
=================================

【任务】将 tdesign-d2c 中间代码翻译为项目 Flutter/Dart 实现，修改界面代码实现设计改进。

【翻译映射决策表（用户已确认，必须严格遵守）】
{translation_map 全文}

【设计方案】{design_spec 全文}

【中间代码 intermediate.tsx】
{d2c_intermediate 全文}

【Figma 原始布局 figma.html（像素校准）】
{d2c_html 全文}

【组件结构 component-info.json】
{d2c_components 全文}

【界面描述】{screen_input}

【项目上下文】
项目：{project} | Workspace Path：{Workspace Path}
背景摘要：{background 前300字}

【project_capabilities.json】
{project_capabilities 全文}

【Figma 图片映射表（已接入 assets，直接引用 configKey）】
{figma_image_slots}

【存量图片插槽台账】
{existing_image_slots}
manifest 路径：~/.claude/knowledge/ui-assistant/{project}/image_manifest.json
default_configs 路径：{Workspace Path}/assets/default_configs.json

【执行要求】
1. 定位需修改的 UI 文件（code-locator 或搜索）
2. 以 intermediate.tsx 为翻译依据，figma.html 做像素校准
3. 图片位必须用 CsImage，禁止用字符/Emoji/纯色块替代
   - 优先用 Figma 映射表 configKey → 存量台账语义匹配 → 新建 placeholder
   - CsImage(configKey:'xxx', description:'...', width:..., height:..., fit:BoxFit.cover)
   - 禁止 Image.asset / Image.network / CachedNetworkImage
4. 代码改完后不 commit，输出变更文件列表、改动摘要、CsImage configKey 清单（configKey|来源|所在页面）
```

等待返回，提取 `{dev_changes_summary}`，Step 3 标 ✅，输出 GATE PASS。

**GATE PASS 输出（完成后立即输出，然后停止）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 3 完成
产出：
  • {project_capabilities}：已就绪（{M} 个组件，{N} 条禁用规则）
  • {translation_map}：{translation_map_confirmed}（{K} 条映射）
  • {dev_changes_summary}：已修改 {N} 个文件
下一步：Step 4（同回合连续执行）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
