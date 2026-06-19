---
name: bugly-version-report
description: "查询王者营地 Bugly 现网最新版本 vs 大盘的 Crash、FOOM、ANR 对比数据，生成日报。无需任何参数，直接调用即可。"
---

# bugly-version-report

查询王者营地 Bugly 现网最新版本 vs 大盘的 Crash、FOOM、ANR 数据对比，输出结构化日报。

## 使用方式

直接调用，无需参数：

```bash
python3 main.py
```

## 强制输出模板

> ⚠️ AI 必须严格按此模板填充，不得增减字段、调整顺序或改变格式。每个 `{{占位符}}` 替换为实际数据，无数据时按「字段说明」表填写默认值，不得留空或自由发挥。

```
📊 Bugly 日报 · {{YYYY-MM-DD}}

## 第一部分：指标对比

对比：最新版本 {{latest_version}} vs 大盘

💥 Crash  最新版：{{latest_crash_rate}}%  |  大盘：{{pool_crash_rate}}%  {{crash_trend}}  新增：{{crash_new_count}} 个
🧠 FOOM   最新版：{{latest_foom_rate}}%   |  大盘：{{pool_foom_rate}}%   {{foom_trend}}   新增：{{foom_new_count}} 个
📵 ANR    最新版：{{latest_anr_rate}}%    |  大盘：{{pool_anr_rate}}%    {{anr_trend}}    新增：{{anr_new_count}} 个

【{{summary_title}}】
{{summary_items}}

## 第二部分：最新版本新增问题列表

💥 Crash 新增问题（{{crash_new_count}} 条）
{{crash_new_issues}}

🧠 FOOM 新增问题（{{foom_new_count}} 条）
{{foom_new_issues}}

📵 ANR 新增问题（{{anr_new_count}} 条）
{{anr_new_issues}}
```

**字段说明：**

| 占位符 | 取值规则 | 无数据时 |
|--------|---------|---------|
| `{{crash_trend}}` / `{{foom_trend}}` / `{{anr_trend}}` | 最新版 < 大盘填 `↓ 好转`；最新版 > 大盘填 `↑ 注意`；相差 ≤0.01% 填 `→ 持平` | `→ 持平` |
| `{{summary_title}}` | 有注意项填 `⚠️ 需要关注`，全部好转或持平填 `✅ 指标正常` | `✅ 指标正常` |
| `{{summary_items}}` | 每条格式：`- 指标名 率：X%（超出大盘 Y%）`；无注意项填 `无` | `无` |
| `{{crash_new_issues}}` / `{{foom_new_issues}}` / `{{anr_new_issues}}` | 每条格式：`- Issue #ID \| 异常类型 \| 影响 N 台 \| 方法名 \| 链接`；无新增填 `无新增问题` | `无新增问题` |

---

**Knot 定时任务建议触发时间：每日 09:00**
