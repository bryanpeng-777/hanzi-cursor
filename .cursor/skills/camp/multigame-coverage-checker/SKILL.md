---
name: multigame-coverage-checker
description: 王者营地全量伽利略 Module 灰度保障每日巡检。对 iOS 和 Android 灰度版本中所有上报过的伽利略 module 进行覆盖率检查，结合代码行为知识判断每个 module 的上报是否符合预期，输出 iOS 和 Android 两份独立报告。当用户提到「多游巡检」「灰度检查」「模块覆盖检查」「multigame coverage」「每日巡检」「跑一下多游保障」「检查一下灰度版本上报」「全量module巡检」时触发。也可被 Knot 定时任务调用。
---

# 全量 Module 灰度保障每日巡检

> ⛔ **最高优先级执行规则（不可违反）**
>
> 1. **唯一执行方式**：运行 `python3 main.py`，将脚本的 stdout **原样返回**给用户
> 2. **禁止 AI 自行生成任何报告内容**：不得根据知识库或自身判断输出模块状态、表格或结论
> 3. **禁止对脚本输出做任何格式修改**：列名、列数、列顺序、数值均不得修改或删减
> 4. 脚本已处理所有查询、计算、判断和格式化，AI 只负责透传输出

---

## 使用方式

```bash
# 默认分析昨天数据
python3 main.py

# 指定日期
python3 main.py --date 2026-05-27

# 手动指定灰度版本（自动识别不准时使用）
python3 main.py --gray-version 10.112.0520
```

**前提**：需要 Galileo CLI 已安装并登录（`galileo auth status`）。

---

## 执行原理

脚本通过 `galileo logs analyze tags` 系统性查询所有数据，确定性计算触发率和偏差，不依赖 AI 执行，每个格子均有实际数值。

**版本识别逻辑**：过滤 AutoLogin < 500 的内部包 → 剩余版本按版本号排序 → 最新 = 灰度版本，次新 = 现网稳定版本。

| 步骤 | 内容 |
|------|------|
| Step 1 | 查 AutoLogin 分版本分布，识别灰度版本和现网版本 |
| Step 1.5 | 扫描灰度版本全量 module（group_by moduleName） |
| Step 2 | 并行查询所有 module × 灰度全天 + 现网 5min |
| Step 3 | 计算归一化触发率（count / AutoLogin+ManualLogin）和偏差 |
| Step 4 | 输出 iOS / Android 各两张表（已知 module + 新发现 module） |

| 平台 | Galileo Target |
|------|---------------|
| iOS | `iOS.camp-app` |
| Android | `Android.default.camp-app` |

---

## 模块知识库（核心，勿删）

来源：企微文档「终端伽利略信息汇总」 > 基础&核心指标 + Flutter基础&核心指标 两张表（2026-05-06 确认版本）。

> **行为类型说明：**
> - `AlwaysTriggered`：每次必触发，0条=❌异常
> - `UserAction-High`：用户高频操作触发，灰度小量可能为0（🟡可接受）
> - `UserAction-Low`：用户低频主动操作，灰度期大概率为0（✅正常）
> - `ErrorOnly`：仅在出错时上报，0条=✅正常，有报=需关注

---

### 高频基础模块（AlwaysTriggered）

| 模块名 | 平台 | 0条含义 | 代码位置提示 |
|--------|------|---------|------------|
| **AutoLogin** | 双平台 | ❌ 每次启动必触发（自动登录） | iOS: `WEGGalileoMetricBizCenter.m` |
| **AppStart** | 双平台 | ❌ App启动必触发 | Grep `moduleName.*AppStart` |
| **AppUpgrade** | 双平台 | ❌ 每次检查更新必触发 | Grep `moduleName.*AppUpgrade` |
| **InnerRouter** | 双平台 | ❌ 每次内部路由跳转必触发 | Grep `moduleName.*InnerRouter` |
| **OutRouter** | 双平台 | ❌ 外部路由跳转触发（频率较低但必有） | Grep `moduleName.*OutRouter` |
| **NetRequest** | 双平台 | ❌ 全量网络请求监控，必有数据 | Grep `moduleName.*NetRequest` |
| **Hippy** | 双平台 | ❌ Hippy容器生命周期，必触发 | Grep `moduleName.*Hippy` |
| **AppExitReason** | 双平台 | ❌ 每次App退出必记录 | Grep `moduleName.*AppExitReason` |
| **LoginMetric** | iOS | ❌ 登录耗时监控，iOS登录必触发 | iOS: `WEGGalileoMetricBizCenter.m` |
| **FlutterEngineCreateToFirstFrameInit** | Flutter双平台 | ❌ Flutter引擎启动必触发 | Grep `FlutterEngineCreateToFirstFrameInit` |
| **FlutterContainerLifeCycle** | Flutter双平台 | ❌ Flutter容器生命周期，必触发 | Grep `FlutterContainerLifeCycle` |

---

### 用户触发高频模块（UserAction-High）

| 模块名 | 平台 | 0条含义 | 代码位置提示 |
|--------|------|---------|------------|
| **ManualLogin** | 双平台 | 🟡 手动登录才触发 | iOS: `WEGGalileoMetricBizCenter.m` |
| **MultiGameAuth** | 双平台 | 🟡 进入多游授权面板才触发 | iOS: `WEGGalileoGameAuthCenter.m` |
| **GameDownload** | Android | 🟡 用户触发游戏下载才上报 | Grep `moduleName.*GameDownload` |

---

### 错误类模块（ErrorOnly，0条=正常）

| 模块名 | 平台 | 0条含义 | 代码位置提示 |
|--------|------|---------|------------|
| **Crash** | 双平台 | ✅ 崩溃上报，0条=无崩溃 | Grep `moduleName.*Crash` |
| **BackGroundKill** | iOS | ✅ 后台被系统杀死 | Grep `BackGroundKill` |
| **VideoPlayFail** | 双平台 | ✅ 视频播放失败 | Grep `moduleName.*VideoPlayFail` |
| **ImageLoadFail** | 双平台 | ✅ 图片加载失败，0条=无失败 | Grep `moduleName.*ImageLoadFail` |
| **PAGLoadFail** | 双平台 | ✅ PAG动画加载失败 | Grep `moduleName.*PAGLoadFail` |
| **XGPush** | 双平台 | ✅ 信鸽注册/绑定失败 | Grep `moduleName.*XGPush` |
| **GameZoneLaunchOtherGameFail** | 双平台 | ✅ 专区启动其他游戏失败 | Grep `GameZoneLaunchOtherGameFail` |
| **ZTParamMissing** | iOS | ✅ 染色参数缺失时上报 | Grep `ZTParamMissing` |
| **JumpSchemaWhitelist** | iOS | ✅ URL被白名单拦截/为空时上报 | Grep `JumpSchemaWhitelist` |
| **OneApi** | 双平台 | ✅ OneApi调用失败 | Grep `moduleName.*OneApi` |
| **ExchangeUrl** | 双平台 | ✅ 换链失败时上报 | Grep `moduleName.*ExchangeUrl` |
| **FlutterErrorReport** | Flutter双平台 | ✅ Flutter异常上报 | Grep `FlutterErrorReport` |
| **FlutterImageLoadFail** | Flutter双平台 | ✅ Flutter图片加载失败 | Grep `FlutterImageLoadFail` |
| **FlutterVideoPlayError** | Flutter双平台 | ✅ Flutter视频播放错误 | Grep `FlutterVideoPlayError` |
| **FlutterSSEError** | Flutter双平台 | ✅ Flutter SSE报错 | Grep `FlutterSSEError` |
| **FlutterDataParseError** | Flutter双平台 | ✅ Flutter数据解析报错（理论上极少触发） | Grep `FlutterDataParseError` |
| **FlutterViewErrorShow** | Flutter双平台 | ✅ Flutter视图错误展示，0条=无错误 | Grep `FlutterViewErrorShow` |

---

### 用户触发低频模块（UserAction-Low，灰度期大概率为0，属正常）

| 模块名 | 平台 | 代码位置提示 |
|--------|------|------------|
| **Pay** | 双平台 | Grep `moduleName.*Pay` |
| **VideoPay** | 双平台 | Grep `moduleName.*VideoPay` |
| **FeedBack** | 双平台 | Grep `moduleName.*[Ff]eedback` |
| **Register** | 双平台 | Grep `moduleName.*Register` |
| **QRScan** | 双平台 | Grep `moduleName.*QRScan` |
| **SplashAd** | 双平台 | Grep `moduleName.*SplashAd` |
| **AppStoreUrlOpen** | iOS | Grep `AppStoreUrlOpen` |
| **BigImage** | 双平台 | Grep `moduleName.*BigImage` |
| **SelfFullUpdate** | Android | Grep `moduleName.*SelfFullUpdate` |
| **FlutterListLoad** | Flutter双平台 | Grep `FlutterListLoad` |
| **FlutterConch** | Flutter双平台 | Grep `FlutterConch` |
| **FlutterGestureRecognize** | Flutter双平台 | Grep `FlutterGestureRecognize` |

---

### 跳过项（Galileo框架内部，不纳入业务巡检）

以下 module 属于 Galileo SDK 或日志框架内部上报，无业务含义，巡检时自动跳过：
`galileoFirstTraceWithParams` / `galileoFirstLogWithParams` / `galileoFirstLog` / `history` / `cmd` / `LogStatistic` / `OneAPIResponse` / `SpanStatistic` / `DeviceInfo` / `Shiply`

---

**MultiGameAuth 特殊说明**：success-end 设计上不上报，只有 error-end。因此 start/step 有数据即为正常，无需关注 end 缺失。

---

**Knot 定时任务建议触发时间：每日 09:00**

