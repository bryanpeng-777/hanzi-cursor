---
name: bugly-gray-monitor
description: "监控王者营地 iOS 灰度版本（最新版本且用户数≥50）与现网稳定版本的 Crash/ANR 率对比，发现灰度期间指标异常升高并告警。无需任何参数，直接调用即可。"
---

# bugly-gray-monitor

监控王者营地 iOS 灰度版本与现网稳定版本的 Crash / ANR 率对比，若灰度版本任一指标较现网版本升高 ≥50%，输出告警。

## 使用方式

```bash
python3 main.py
```

## 强制输出模板

> ⚠️ AI 必须严格按此模板填充，不得增减字段、调整顺序或改变格式。每个 `{{占位符}}` 替换为实际数据，无数据时按「字段说明」表填写默认值，不得留空或自由发挥。

```
🔬 Bugly 灰度监控日报 · {{YYYY-MM-DD}}

灰度版本：{{gray_version}}（用户数：{{gray_users}}）
现网版本：{{stable_version}}（用户数：{{stable_users}}）

💥 Crash  灰度：{{gray_crash_rate}}%  |  现网：{{stable_crash_rate}}%  {{crash_arrow}} {{crash_delta}}%  {{crash_status}}
📵 ANR    灰度：{{gray_anr_rate}}%    |  现网：{{stable_anr_rate}}%    {{anr_arrow}} {{anr_delta}}%    {{anr_status}}

【{{alert_title}}】
{{alert_items}}

【需关注新增问题】
{{new_issues}}
```

**字段说明：**

| 占位符 | 取值规则 | 无数据时 |
|--------|---------|---------|
| `{{crash_arrow}}` / `{{anr_arrow}}` | 升高填 `↑`，降低填 `↓`，持平填 `→` | `→` |
| `{{crash_delta}}` / `{{anr_delta}}` | 填正负百分比数字，如 `+50` 或 `-25` | `0` |
| `{{crash_status}}` / `{{anr_status}}` | 超阈值（≥50%）填 `⚠️ 告警`，否则填 `✅ 正常` | `✅ 正常` |
| `{{alert_title}}` | 有告警填 `⚠️ 灰度异常告警`，全部正常填 `✅ 灰度指标正常` | `✅ 灰度指标正常` |
| `{{alert_items}}` | 每条格式：`- 指标名 率：X%（较现网 Y% 升高/降低 Z%，触发阈值）`；无告警填 `无` | `无` |
| `{{new_issues}}` | 每条格式：`- Issue #ID \| 异常类型 \| 影响 N 台 \| 方法名 \| 链接`；无新增填 `无新增问题` | `无新增问题` |

---

**Knot 定时任务建议触发时间：每日 09:00**
