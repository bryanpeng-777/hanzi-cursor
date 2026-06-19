# cs-lottie 插件

CS Lottie 动画管理：CsLottie 控件 + lottie_manifest.json，统一管理动画生命周期（本地 / 远程 / 占位）。

**禁止**在接入 cs-ui 的项目中直接使用 `Lottie.asset` / `Lottie.network`。

---

## [INSTALL] 安装步骤

### 前置检查

1. 确认 cs-ui 插件已安装
2. 检查 `~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json` 是否存在
3. 扫描直接动画引用：`Lottie.asset(` / `Lottie.network(`

### 初始化动画管理文件

若 lottie_manifest.json 不存在，创建初始结构：
```json
{
  "project": "<project_name>",
  "animations": []
}
```

manifest 存储路径：`~/.claude/knowledge/ui-assistant/{project}/lottie_manifest.json`

### 迁移现有动画引用

对每个直接 Lottie 调用执行：
1. 生成 configKey（格式：`snake_case_anim`，以 `_anim` 结尾）
2. 在 lottie_manifest.json 中注册动画插槽
3. 在 `default_configs.json` 中设置兜底（已有本地 .json/.lottie 则设 `asset` 字段）
4. 替换代码：
   ```dart
   // Before: Lottie.asset('assets/animations/loading.json')
   // After:  CsLottie(configKey: 'loading_anim')
   ```

---

## [UPDATE] 更新步骤

跟随 cs-ui 的 cs_commit 更新。扫描是否有新的直接 Lottie 引用被引入。

---

## [VERIFY] 验证检查点

| ID | 检查项 | 命令 | 期望 |
|----|--------|------|------|
| LA1 | Lottie 直接用法清零 | `grep -rn "Lottie\.asset\|Lottie\.network" lib/` | 零残余 |

---

## [USAGE] 使用辅助

### 添加新动画

```dart
CsLottie(
  configKey: 'success_anim',   // lottie_manifest.json 中的 key
  width: 200,
  height: 200,
  repeat: false,               // true=循环播放，false=播放一次
)
```

### 三种显示模式

`CsLottie` 读取 `default_configs.json` 决定显示：
1. `url` 非空 → 远程动画（优先，支持热更新）
2. `url` 为 null，`asset` 非空 → 本地 .json/.lottie 文件
3. 两者均 null → 占位动画（`CsPlaceholderLottie`，带脉冲图标）

### 设置远程动画（热更新）

通过 cs-backend 的 ConfigManager 设置：
```
key: success_anim
value: https://cdn.example.com/success.lottie
type: string
```

### 动画播放控制（高级）

```dart
// 需要控制播放时机，使用 animationController
CsLottie(
  configKey: 'confetti_anim',
  controller: _lottieController,  // AnimationController
  onLoaded: (composition) {
    _lottieController.forward();
  },
)
```

### lottie_manifest.json 结构

```json
{
  "project": "my_app",
  "animations": [
    {
      "configKey": "loading_anim",
      "description": "加载中动画",
      "status": "local_asset",
      "asset_path": "assets/animations/loading.json",
      "remote_url": null
    }
  ]
}
```
