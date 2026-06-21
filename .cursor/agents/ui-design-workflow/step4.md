# Step 4 详细执行规范：编译检查 + 测试用例 + integration test

> **门禁**：Step 3 ✅。
>
> **Pre-check（进入本步前必须输出）：**
> ```
> 🔍 Pre-check — 进入 Step 4
>   • {dev_changes_summary}：✅ 已设置（{N} 个文件）/ ❌ 缺失 → 回退补做 Step 3
>   • {translation_map}（用户已确认）：✅ / ❌ → 回退补做 Step 3
>   结论：✅ 门禁通过，开始 Step 4 / ❌ 门禁未通过，先补做 Step 3
> ```

---

## 4-A：编译检查（Ralph Loop，最多 3 轮）

```bash
cd {Workspace Path} && fvm flutter analyze 2>&1
```

通过后：
```bash
cd {Workspace Path} && fvm flutter build ios --debug --simulator --no-codesign 2>&1 | tail -20
```

**结果判断（最多 3 轮）：**
- 通过 → 继续 4-B
- 失败 → 定位出错文件/行号，直接在主会话修复，进入下一轮
- 3 轮仍未通过 → 列出错误和已尝试修复，**禁止继续 4-B**，提示用户手动处理

---

## 4-B：调用 test-assistant 写入测试用例

Read `~/.claude/agents/test-assistant.md`，通过 **Task**（`subagent_type="generalPurpose"`）启动：

```
你是 test-assistant（测试小助手）。

===== test-assistant.md 全文 =====
{test-assistant.md 全文}
==================================

【任务】针对以下 UI 改动执行两个任务：
1. 新增测试用例写入台账（3-5 条，涵盖 Key 挂载、视觉回归、环境标签）
2. 读取现有 integration test 文件，检查因新 UI 结构变化可能失效的断言

【UI 设计方案摘要】{design_spec 全文}
【代码变更摘要】{dev_changes_summary}
【界面描述】{screen_input}
【项目】{project} | Workspace：{Workspace Path}
台账路径：~/.claude/knowledge/test-assistant/{project}/test_manifest.md

输出：新增用例列表（用例名+验证点）、兼容性检查结论、台账路径
```

等待返回，提取 `{test_report}`。

---

## 4-C：编写 integration test 代码（内联执行）

根据 `{test_report}` 中的用例，**直接在主会话**追加到对应 `_test.dart` 文件（如 `integration_test/scenarios/home_test.dart`）：

- 每条用例用 `testWidgets(...)` 实现
- 使用 `find.byKey` / `find.text` / `find.textContaining`
- 等待时间：`pumpAndSettle(const Duration(seconds: 8))`
- 追加完成后在台账中将对应用例状态更新为「已实现」

---

## 4-D：执行测试（Ralph Loop，最多 3 轮）

检测可用模拟器：
```bash
xcrun simctl list devices | grep Booted
```

无已启动模拟器时，列出可用设备请用户选择。

```bash
cd {Workspace Path} && fvm flutter test integration_test/scenarios/home_test.dart -d {simulator_id} 2>&1
```

**结果判断（最多 3 轮）：**
- 全部通过 → 退出循环，**无论如何都进入 4-E 清理**
- 有失败 → 分析原因（测试代码写法 or UI 代码问题），修改后下一轮
- 3 轮仍未通过 → 列出未通过用例和失败原因，**无论如何都进入 4-E 清理**，然后提示用户手动处理

---

## 4-E：测试后清理（无论测试是否通过，必须执行）

```bash
cd {Workspace Path} && fvm flutter clean && fvm flutter pub get 2>&1 | tail -5
```

> ⚠️ `fvm flutter test` 会在 `/tmp` 创建临时 `listener.dart`，测试结束后文件被删除，但 Xcode 会将路径缓存到 DerivedData，导致后续普通编译报 `PhaseScriptExecution failed`。`flutter clean` 清除缓存即可修复。

Step 4 标 ✅，输出 GATE PASS，进入 Step 5。

**GATE PASS 输出（完成后立即输出，然后停止）：**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE PASS — Step 4 完成
产出：
  • 编译：✅ 通过（第 {N} 轮）
  • {test_report}：新增 {N} 条用例，兼容性检查 {通过/发现 K 处冲突}
  • integration test：✅ 全部通过（第 {N} 轮）/ ⚠️ 已达上限，需手动处理（flutter clean 已执行）
  • 构建缓存：已清理（flutter clean，无论测试是否通过）
下一步：Step 5（说「继续」开始图片同步）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
