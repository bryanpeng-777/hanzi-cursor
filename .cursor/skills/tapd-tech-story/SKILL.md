---
name: tapd-tech-story
description: 新建或修改 TAPD 技术需求单，自动使用规范的五段式描述模板（背景、需求内容、平台、测试内容、开关测试）。当用户提到"新建技术需求"、"创建 TAPD 单"、"建需求"或需要修改现有技术需求格式时触发。
---

# TAPD 技术需求模板

## 描述格式模板

新建或修改技术需求的 `description` 字段必须严格使用以下五段式 HTML 结构：

```html
<p>1、背景：</p>
<p>{背景描述，说明当前现状和存在的问题}</p>
<ul><li>{问题点1}</li><li>{问题点2}</li></ul>

<p>2、需求内容：</p>
<p>{需求目标和方案描述}</p>
<ul><li>{具体方案点1}</li><li>{具体方案点2}</li></ul>

<p>3、平台（如：单端【安卓 or iOS】、双端、创作者中台、纯后台）：</p>
<p>{填写具体平台，如：双端（iOS + 安卓）、单端【iOS】、纯后台 等}</p>

<p>4、测试内容（提供路径和图片）：</p>
<ul><li>{验收标准1}</li><li>{验收标准2}</li></ul>

<p>5、包含开关测试（开关预期表现）：</p>
<p>{如有开关填写开关名称和预期表现，如无则填"无"}</p>
```

## 脚本分工

> **脚本处理**：生成规范的五段式 HTML description（`scripts/create_story.py`）
> **AI 处理**：信息收集（若用户未提供完整五段）、调用 TAPD MCP 创建/更新需求单

```bash
# 交互式生成 HTML
python3 scripts/create_story.py

# 命令行模式（已有信息时）
python3 scripts/create_story.py \
  --bg "背景描述" --content "需求内容" --platform "双端（iOS + 安卓）" \
  --test "验收标准1,验收标准2" --switch "无"

# 输出 JSON 格式（直接作为 description 参数）
python3 scripts/create_story.py ... --json
```

---

## 操作流程

### 新建技术需求

1. 向用户收集五段内容（若已有信息则直接推断填写）
2. 调用 `create_story_or_task`，`entity_type` 为 `stories`，`description` 使用上述模板
3. 返回新建的需求链接

### 修改现有技术需求格式

1. 调用 `get_stories_or_tasks` 获取当前 `description`（fields 带上 `description`）
2. 将原内容映射到五段模板：
   - 背景/问题 → 第1段
   - 目标/方案 → 第2段
   - 平台信息 → 第3段（若无，询问用户或根据上下文推断）
   - 验收标准 → 第4段
   - 开关信息 → 第5段（若无，填"无"）
3. 调用 `update_story_or_task` 更新 `description`

## TAPD 工具说明

- **workspace_id**：从需求 URL 中提取，如 `tapd.woa.com/20359852/...` → `20359852`
- **story_id**：URL 末尾的长数字，如 `1020359852131687041`
- 需求链接格式：`https://tapd.woa.com/{workspace_id}/prong/stories/view/{story_id}`

## 注意事项

- 第3段平台选项：单端【iOS】/ 单端【安卓】/ 双端（iOS + 安卓）/ 创作者中台 / 纯后台
- 第5段如有 RDelivery 开关，需说明开关名称、开启/关闭时各自的预期表现
- 若信息不足，优先询问用户后再创建，避免留空
