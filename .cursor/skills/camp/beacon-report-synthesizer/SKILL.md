---
name: beacon-report-synthesizer
description: >
  将灯塔看板巡检日报（beacon-dashboard-inspector 生成的 Markdown 汇总）二次加工为结构更丰富的综合监测报告。
  报告涵盖：数据概览、关键趋势分析（每看板prose摘要 + 版本vs全量对比）、漏斗指标分析（登录/充值漏斗）、
  异常检测、状态分类汇总、数据质量评估、优化优先级，共 7 个章节。
  触发场景：用户提到「巡检日报二次加工」「综合监测报告」「灯塔报告加工」「把巡检报告变成详细报告」
  「beacon synthesizer」「生成综合报告」「synthesis report」，或在灯塔巡检完成后想进一步输出更丰富的分析报告。
  即使用户只说「帮我把今天的巡检报告加工一下」「出个详细版报告」，只要涉及灯塔巡检数据，都应主动使用本技能。
---

# Beacon Report Synthesizer

将灯塔看板巡检日报二次加工为综合监测报告。

## 分工说明

| 部分 | 执行方式 |
|------|---------|
| Markdown 解析 + 指标提取 | `scripts/beacon_report_synthesizer.py`（确定性脚本） |
| 波动原因推断（关键词规则） | 脚本内置规则 |
| 版本 vs 全量差异对比 | 脚本内置规则（`compare_ver_vs_all_prose`） |
| 登录 / 充值漏斗衍生指标 | 脚本内置计算（`compute_derived_metrics`） |
| 优先级排序（环比幅度排序） | 脚本内置规则 |
| iWiki 读取 / 写回 | AI 调用 iWiki MCP 工具 |

脚本已覆盖 95% 的确定性逻辑，AI 只处理 iWiki 交互和用户沟通。

---

## 使用步骤

### Step 1：获取巡检日报

根据用户提供的输入形式：

**A. iWiki 文档 ID**（如 `4022012368`）：
```
用 iWiki MCP getDocument(docid="<ID>") 拉取内容 → 保存为临时文件
```

**B. 本地文件路径**：直接传给脚本的 `--input`

**C. 直接粘贴 Markdown 文本**：写入临时文件再运行脚本

### Step 2：运行合成脚本

```bash
python /Users/bryanpeng/work_tree_bugfix/scripts/beacon_report_synthesizer.py \
    --input <inspection_report.md> \
    --output <synthesis_report.md>
```

脚本依赖纯 Python 标准库，无需安装额外依赖。

输出文件默认命名建议：`synthesis_<YYYYMMDD>.md`

### Step 3：写入 iWiki（默认目录）

综合监测报告写入 **「灯塔巡检综合分析」** 文件夹，**不是**「灯塔巡检报告」（后者仅放 Phase 1 巡检日报）。

定位方式：调用 `getSpacePageTree`（parentid = 个人空间 homepageid），查找标题 **「灯塔巡检综合分析」**，取其 `docid` 作为 `SYNTHESIS_DIR_ID`（如 `4022042073`）。不存在则创建 `contenttype: "FOLDER"` 文件夹。

标题格式：`灯塔综合监测报告 YYYY-MM-DD HH:mm`（与巡检日报 `inspection_time` 对齐，须含时分，不得仅写日期）。**正文不要写 `#` 一级标题**，避免与 iWiki 页面标题重复。

---

## ⛔ iWiki 写入硬规则（Phase 2 必须遵守）

> 与 `beacon-dashboard-inspector` 的巡检日报规则同级，**优先级高于一切**。

1. **必须写入脚本生成的完整 `synthesis_report.md` 全文**，包含全部 **7 个章节**（见下文「输出格式」表）。**禁止**只写执行摘要、前三章节选、或「详见本地文件 / 详见巡检日报链接」代替正文。
2. **不得以任何理由压缩或省略章节。** 遇 iWiki MCP 单次体积限制，**只能分批写入**，不能删减内容。
3. **Phase 2 不得在未通过 Step 3.5 门禁验证前宣告完成**，也不得只推送企微摘要而不落完整 iWiki。
4. 若文档已存在但仅为摘要版：**用 `saveDocument` 以第 1 批正文覆盖全文**，再 `saveDocumentParts` 追加剩余批次（不要新建重复标题文档，除非用户明确要求）。

### Step 3.1：标准分批写入流程

iWiki MCP 单次 `body` / `after` 超过约 **4KB（JSON 编码后）** 会解析失败。中文 Markdown 建议按 **≤850 字符/批**（在换行处切分）分批，确保 `len(json.dumps(chunk)) < 4000`。

**推荐分片脚本（在 Step 2 输出路径上执行）：**

```bash
python3 << 'PY'
from pathlib import Path
import json
text = Path("<synthesis_report.md>").read_text()
maxlen = 850
parts, i = [], 0
while i < len(text):
    end = min(i + maxlen, len(text))
    if end < len(text):
        nl = text.rfind("\n", i, end)
        if nl > i:
            end = nl + 1
    parts.append(text[i:end])
    i = end
out = Path("/tmp/beacon_synthesis_iwiki_parts")
out.mkdir(exist_ok=True)
for j, p in enumerate(parts):
    (out / f"part_{j}.md").write_text(p)
    assert len(json.dumps(p)) < 4000, f"part {j} too large: {len(json.dumps(p))}"
print(f"split into {len(parts)} parts, total chars {len(text)}")
PY
```

**写入顺序：**

| 步骤 | MCP 工具 | 说明 |
|------|---------|------|
| 1 | `createDocument` **或** `saveDocument` | 新文档：`createDocument`，`parentid=SYNTHESIS_DIR_ID`，`body=part_0`；**覆盖已有摘要文档**：`saveDocument`，`docid=<已有ID>`，`body=part_0` |
| 2…N | `saveDocumentParts` | `id=docid`，`title` 保持不变，每次 `after=part_k`（k≥1）顺序追加 |
| 完成 | — | 记录 `SYNTHESIS_IWIKI_URL=https://iwiki.woa.com/p/<docid>` |

**切割注意：**

- 在 `\n` 处切分，**不要在表格行中间截断**；优先在 `\n---\n` 或 `## ` 标题前切分。
- `getDocument` 的 `docid` 参数类型为 **string**（如 `"4022121854"`），勿传 number。
- 特殊字符 `—`、`×` 若触发 JSON 解析错误，可替换为 `-`、`x` 后重试该批。

### Step 3.5：写入门禁验证（必须通过）

调用 `getDocument(docid="<docid>")` 拉取全文，**逐项检查**以下 7 个章节标题均存在：

```
一、数据概览
二、关键趋势分析
三、核心指标分析   # 或「漏斗指标分析」— 以脚本当前输出为准
四、异常检测
五、状态分类汇总
六、数据质量评估
七、优化优先级
```

并确认：

- 拉取正文字符数与本地 `synthesis_report.md` 的 `len(text)` **相差不超过 5%**（iWiki 表格渲染可能合并少量换行）
- 正文**不得**包含「二次加工」字样或脚本自动生成页脚

**任一项不通过**：继续 `saveDocumentParts` 补写缺失批次，或 `saveDocument` 覆盖重写；**不得**向用户报告 Phase 2 已完成。

### Step 4：处理输出

根据用户需求选择：

| 用户意图 | 操作 |
|---------|------|
| 写入 iWiki 文档 | **默认且必须**：完整 7 章按 Step 3.1～3.5 写入「灯塔巡检综合分析」 |
| 写入本地文件 | 告知 `--output` 路径（**不能替代** iWiki 完整落库） |
| 直接展示结果 | 对话中可展示摘要；**iWiki 仍须写全文** |
| 无特殊要求 | iWiki 写全文 + 对话给 3～5 条要点 + 两个文档链接 |

---

## 输入格式参考

巡检日报由 `beacon-dashboard-inspector` 生成，标准结构如下：

```markdown
# 灯塔看板巡检日报 YYYY-MM-DD HH:MM

**巡检时间**：...
**数据区间**：...
**版本口径**：...

## 巡检概览
| 看板 | 指标总数 | 异常 | 立即排查 | 建议观察 | 状态 |
...

## <看板名>
| 指标 | 版本 今日 | 版本 昨日 | 版本 环比 | 全量 今日 | 全量 昨日 | 全量 环比 | 状态 |
...

## 巡检结论
...
```

---

## 输出格式

综合监测报告包含 **7 个章节**：

| 章节 | 内容摘要 |
|------|---------|
| 📊 一、数据概览 | 看板汇总表 + 核心统计（异常/波动/正常计数） + 整体结论句 |
| 📈 二、关键趋势分析 | 每个有指标数据的看板：**prose 摘要**（不展示原始表格） + **版本 vs 全量对比段** |
| 📐 三、漏斗指标分析 | 跨看板交叉计算：**用户登录漏斗**（4步转化）+ **充值漏斗**（5步含渗透率/人均次数） |
| 🔍 四、异常检测 | 列出全部正常看板；按「立即排查」「建议观察」分组并附理由 |
| 📋 五、状态分类汇总 | 按「全部正常 / 仅建议观察 / 含立即排查」三组聚合看板 |
| 📊 六、数据质量评估 | 数据完整性、数值合理性、趋势一致性、异常/波动数量评分 |
| 📈 七、优化优先级 | 按环比幅度排序为 🔴P0 / 🟡P1 / 🟡P2 / 🟢P3，附处置建议 |

---

## 关键趋势分析：每看板的 prose 摘要逻辑

每个看板不再输出原始数据表，而是生成一段自然语言总结，包含：

1. **总体一句话**：共 N 项指标，X 项异常（含立即排查 / 建议观察）
2. **代表性指标亮点**（≤3 条）：优先成功率/完成率，其次人数/次数；去除"新口径"重复版本
3. **波动项说明**（每条 ⚠️）：指标值 + 环比 + 推断原因（关键词规则）
4. **异常项告警**（每条 ❌）：指标值 + 环比 + 提示立即排查

紧随摘要，输出 `📊 版本 vs 全量` 对比段（见下节）。

---

## 版本 vs 全量对比逻辑

每个看板末尾自动输出一行 `📊 版本 vs 全量：...`，规则如下：

| 情况 | 输出内容 |
|------|---------|
| 趋势相反（方向不同）且至少一侧幅度 ≥1pp | ⚠️ 标注"趋势相反，疑似版本专属波动" |
| 同向但 MoM 偏差 ≥5pp | 标注方向差异，偏差 >5pp 加 ⚠️ |
| 同向偏差 2–5pp | 标注"版本略优/略劣" |
| 率类指标（成功率/失败率）绝对值差 ≥0.5pp | 额外标注 pp 差 |
| 偏差 <2pp 且无率差 | 计为"趋势一致"，最终汇总一句 |

**特殊处理：**
- 负向指标（失败/报错/取消）：增幅低 = 版本更好，方向标签取反
- 新口径/新版本重复指标：自动去重，只保留一条
- 无版本数据的看板（版本列全为 `-`）：跳过对比

---

## 漏斗指标分析：漏斗计算逻辑

### 用户登录漏斗（依赖看板：营地业务大盘、登录成功、进入首页）

| 步骤 | 指标来源 | 衍生计算 |
|------|---------|---------|
| 1. APP 启动 | 营地业务大盘 · APP启动总人数 | 基准 |
| 2. → 进入主界面 | 营地业务大盘 · 进入主界面总人数 | 主界面人数 ÷ 启动人数 |
| 3. → 登录成功 | 登录成功 · 登录成功总人数 | 登录人数 ÷ 主界面人数 |
| 4. → 进入首页 | 进入首页 · 进入首页总人数 | 首页人数 ÷ 登录人数 |
| 整体 | — | 首页人数 ÷ 启动人数 |

每步同时输出版本 / 全量转化率及差值（pp）。若版本转化率比全量低 >1.5pp，标注 ⚠️。

### 充值漏斗（依赖看板：营地业务大盘、充值）

| 步骤 | 指标来源 | 衍生计算 |
|------|---------|---------|
| 1. DAU | 营地业务大盘 · APP启动总人数 | 基准 |
| 2. 发起充值用户 | 充值 · 发起充值总人数 | 充值人数 ÷ DAU = **渗透率** |
| 3. 发起充值次数 | 充值 · 发起充值总次数 | 充值次数 ÷ 充值人数 = **人均次数** |
| 4. 充值成功 | 充值 · 充值成功次数 + 发起充值总次数 | 成功次数 ÷ 发起次数 = **完成率** |
| 5. 发货失败 | 充值 · 发货失败次数 | 直接取值，0 次为健康 |

洞察阈值：渗透率版本比全量低 >0.1pp 时 ⚠️；完成率版本比全量低 >2pp 时 ⚠️。

---

## 典型工作流示例

### 场景 A：从 iWiki 读取，加工后写回新文档

```
1. iWiki MCP：getDocument(docid="4022012368") → 拿到巡检日报 Markdown
2. 写入临时文件：/tmp/inspection_today.md
3. 运行脚本：beacon_report_synthesizer.py --input /tmp/inspection_today.md --output /tmp/synthesis_today.md
4. 按 Step 3.1 分片 → createDocument/saveDocument(part_0) → saveDocumentParts 追加其余 part
5. Step 3.5 门禁验证 7 章齐全后，输出 SYNTHESIS_IWIKI_URL
```

### 场景 B：本地文件直接加工

```bash
python /Users/bryanpeng/work_tree_bugfix/scripts/beacon_report_synthesizer.py \
    --input daily_inspection.md \
    --output synthesis_report.md
```

### 场景 C：与巡检工具串联（stdin 模式）

```bash
cat inspection.md | python /Users/bryanpeng/work_tree_bugfix/scripts/beacon_report_synthesizer.py \
    > synthesis_report.md
```

---

## 脚本路径与依赖

- **脚本**：`/Users/bryanpeng/work_tree_bugfix/scripts/beacon_report_synthesizer.py`
- **依赖**：Python 标准库（无需 pip install）
- **兼容性**：Python 3.8+

若脚本不存在或版本过旧，参考 `beacon-dashboard-analyzer` 技能中的「综合监测报告二次加工」章节重新生成。

---

## 注意事项

- **iWiki 落库失败是 Phase 2 失败**：不允许用「本地路径 + 摘要」代替完整 7 章写入；用户未明确要求时，默认必须写入「灯塔巡检综合分析」
- 若某看板只在「巡检概览」出现、无详细指标表，「关键趋势分析」章节会跳过该看板（避免空内容）
- 「衍生指标分析」漏斗依赖特定看板名称；若看板名变化导致找不到指标，该漏斗节点显示 `-`，不影响其他章节
- 波动原因推断基于关键词匹配（报错/失败/播放/反馈等），若推断不准，可在 iWiki 写回前手动调整
- 「数据完整性」评估基于「有指标表数据的看板数 / 总看板数」，覆盖率 ≥70% 显示为完整
- 充值完成率优先从 `充值成功次数 ÷ 发起充值总次数` 计算（更准确），若次数缺失则降级使用 `充值完成率` 字段
