---
name: flutter-visual-theme-switcher
description: Flutter 视觉主题切换技能。在 cs_ui 包支持的风格中选择一套，自动修改 cs_app_theme.dart 中的 activeStyle 指针，实现一键切换「清新简约」或「卡通风」等主题。当用户说「切换主题」「切换到卡通风」「切换到清新简约」「换个主题」「apply theme」「switch theme」等相关词时触发。即使用户只说「用卡通风」，也应主动使用此技能。
---

# Flutter 视觉主题切换技能

在 cs_ui 包的多套主题之间一键切换。Skill 作为「设计规范 → 代码」的翻译官：
- `references/*.md` = 设计意图（给 AI 读）
- `cs_ui/lib/src/theme/xxx_theme.dart` = 代码实现（给 Flutter 跑）
- `cs_app_theme.dart` 中的 `activeStyle` = 唯一切换点

---

## 核心文件路径

| 文件 | 作用 |
|---|---|
| `cs_ui/lib/src/theme/cs_app_theme.dart` | 切换点，修改 `activeStyle` 这一行 |
| `cs_ui/lib/src/theme/fresh_minimal_theme.dart` | 清新简约主题代码 |
| `cs_ui/lib/src/theme/cartoon_theme.dart` | 卡通风主题代码 |
| `references/fresh-minimal.md` | 清新简约设计规范 |
| `references/cartoon.md` | 卡通风设计规范 |

---

## 脚本分工

> **脚本处理**：文件替换 + dart analyze（`scripts/switch_theme.sh`）
> **AI 处理**：风格选择确认、新增风格时的规范读取与代码生成

```bash
# 一键切换（确认风格后直接运行）
bash scripts/switch_theme.sh <theme-name> [project-root]
# 示例：bash scripts/switch_theme.sh cartoon /Users/me/cs
```

---

## 执行流程

### Step 1：列出可用风格

扫描本技能 `references/` 目录，列出所有 `.md` 文件对应的风格：

```
可用主题风格：
  [1] fresh-minimal — 清新简约（冷灰蓝 + 8px 圆角）
  [2] cartoon — 卡通风（珊瑚粉 + 20px 圆角）
  [3] nature — 自然绿（翡翠绿 + 10px 圆角）

请选择风格编号，或直接说风格名称。
```

### Step 2：确认目标风格

- 用户已明确指定（如「切换到卡通风」）→ 直接进入 Step 3
- 用户未指定 → 展示列表等待选择

### Step 3：读取设计规范

读取对应的 `references/<style>.md`，重点获取：
- 完整色板 token
- 圆角规范
- 按钮高度
- `ShadThemeData` 代码片段（文件底部已有完整代码，可直接使用）

### Step 4：更新主题文件（如需）

如果目标风格的 `xxx_theme.dart` 已存在且内容与规范一致，跳过此步。

如果需要更新（规范有改动，或是新增风格），覆盖/新建对应的 `xxx_theme.dart`，
内容使用 reference 文件底部「ShadThemeData 代码片段」章节中的完整代码。

### Step 5：修改 activeStyle 指针（核心动作）

定位 `cs_ui/lib/src/theme/cs_app_theme.dart`，找到这一行：

```dart
static const CsThemeStyle activeStyle = CsThemeStyle.xxxxx;
```

将 `xxxxx` 替换为目标风格的枚举值：
- `fresh-minimal` → `CsThemeStyle.freshMinimal`
- `cartoon` → `CsThemeStyle.cartoon`

### Step 6：验证并提示

运行 `dart analyze cs_ui/lib/` 确认无编译错误，然后提示用户：

```
✅ 主题已切换为「<风格名>」！

Hot Reload 步骤：
  1. 确保 flutter run 正在运行
  2. 在终端按 r 触发 Hot Reload
  3. 或重新运行 flutter run

切换效果：
  - 颜色系统：<xxx>
  - 全局圆角：<xxx>
  - 按钮高度：<xxx>
```

---

## 新增风格流程

用户想添加第 N 套风格时：

1. **新建 reference 规范**：在 `references/` 下创建 `<name>.md`，按已有文件格式填写设计 token 和代码片段
2. **新建主题文件**：在 `cs_ui/lib/src/theme/` 下创建 `<name>_theme.dart`，使用 reference 文件中的代码片段
3. **注册枚举值**：在 `cs_app_theme.dart` 中：
   - 在 `CsThemeStyle` 枚举添加新值
   - 在 `_themeForStyle` 和 `_darkThemeForStyle` 的 switch 中补充 case
4. **切换**：将 `activeStyle` 改为新枚举值

> 已有组件代码（`CsApp`、各业务 widget）无需改动。

---

## 已知风格枚举值对应表

| reference 文件 | CsThemeStyle 枚举值 |
|---|---|
| `fresh-minimal.md` | `CsThemeStyle.freshMinimal` |
| `cartoon.md` | `CsThemeStyle.cartoon` |
| `nature.md` | `CsThemeStyle.nature` |

> 新增风格后在此表追加一行。

---

## 注意事项

- **只改 `activeStyle` 一行**：不要修改 `CsApp`、`DemoApp` 等上层文件
- **cs_framework 不动**：视觉主题完全在 `cs_ui` 包内，不要改 cs_framework
- **Dart analyze 必须通过**：切换后务必执行 analyze 确认无错误再提示用户
- **路径基准**：操作文件时以项目根目录（含 `cs_ui/` 和 `cs_infra/` 的那个目录）为基准
