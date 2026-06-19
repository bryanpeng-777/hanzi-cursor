# 日志分析策略参考

本文档帮助主 LLM 理解营地日志的**结构特征**，从而更精准地定位问题。核心原则：**先识别日志格式 → 再按 tag 缩小范围 → 最后按时间+内容精确命中**。

---

## 一、日志行结构识别

营地 mars xlog 解码后的日志行有**固定的方括号分段格式**，双端共用同一结构：

### 统一格式

```
[LEVEL][TIMESTAMP][PID, TID][TAG][SOURCE_INFO][MESSAGE
```

每个字段用 `[]` 包裹，字段含义：

| 字段 | 格式 | 用途 |
|------|------|------|
| LEVEL | `I`/`W`/`E`/`F`/`D` | **分级过滤的关键**（Info/Warn/Error/Fatal/Debug） |
| TIMESTAMP | `yyyy-MM-dd +TZ HH:mm:ss.SSS` | 时间窗口过滤的锚点 |
| PID, TID | `19056, 1*` 或 `0, 306872320*` | PID 区分进程，TID 追踪同一线程因果链 |
| TAG | 模块名 | **按模块定位的关键** |
| SOURCE_INFO | `, , 0` 或 `文件名, 方法名, 行号` | iOS 常含源文件信息 |
| MESSAGE | `[线程名]具体内容` | Android 消息前通常有 `[线程名]` 前缀 |

### Android 真实示例

```
[I][2026-05-11 +8.0 09:05:37.277][19056, 1*][ApplicationInitHelper][, , 0][[main]version: 10.111.0304, versionCode: 2057955910
[E][2026-05-11 +8.0 09:05:37.320][19056, 1*][EventInvocationHandler][, , 0][[main]interface com.tencent.gamehelper.common.account.api.AccountEvent invoke failed e:null
[W][2026-05-11 +8.0 09:05:37.333][19056, 2890][GalileoReport][, , 0][[DefaultDispatcher-worker-4]reportMetricLogInner 9 failed, galileoAndroidSdk is null
[I][2026-05-11 +8.0 09:05:39.283][19056, 1*][GamesManager][, , 0][[main]auto download or install game switch: true
```

**Android 特点**：
- TAG 是 Java/Kotlin 类名：`GamesManager`、`LoginManager`、`EventInvocationHandler`
- 消息前有 `[线程名]`：`[main]`、`[DefaultDispatcher-worker-4]`、`[OkHttp https://...]`
- TID 为 `1*` 表示主线程

### iOS 真实示例

```
[I][2026-05-12 +80 12:14:30.162][0, 306872320*][smoba][ChatTimHandler.m, -[ChatTimHandler onConnecting], 145][[chat] imsdk onConnecting
[E][2026-05-12 +80 12:14:39.337][0, 306872320*][flutter_rmonitor_config][, , 0][RMonitorConfig configUserAndAppInfo error
[W][2026-05-12 +80 12:37:15.789][0, 310788096*][smoba][LoginOperator.m, -[LoginOperator _loginDidFailWithError:], 618][[Login]FailReason:Error Domain=kWebServiceErrorDomain Code=-50000
[I][2026-05-12 +80 12:14:30.176][0, 306872320*][smoba][WEGRDLoggerImpl.m, ...][ShiplySDK][RDeliveryLog][Info] ...
```

**iOS 特点**：
- TAG 为 `smoba`（原生 OC）或 `flutter_模块名`（Flutter 层）或 `smoba-swift`（Swift 层）
- SOURCE_INFO 包含**源文件+方法名+行号**（如 `ChatTimHandler.m, -[ChatTimHandler onConnecting], 145`）
- Flutter 相关日志 TAG 统一为 `flutter_` 前缀

### 关键识别技巧

1. **看第一个 `[]` 确定级别**：`[E]` = ERROR，优先关注
2. **看第四个 `[]` 确定模块**：即 TAG 字段，用于缩小搜索范围
3. **Android `[线程名]` 在消息开头**：可用于追踪同一线程的操作序列
4. **iOS 源文件信息在第五个 `[]`**：直接定位代码位置

---

## 二、按 Tag 缩小搜索范围

**核心原则：先确定问题所属模块的 Tag，只在该 Tag 的日志行中搜索。** 避免在海量无关 Tag 中浪费 context。

### Tag → 模块 → 问题类型 速查表

| 问题类型 | Android TAG | iOS TAG | 说明 |
|----------|-------------|---------|------|
| 登录/账号 | `LoginManager`, `AccountEvent`, `EventInvocationHandler` | `smoba`+`LoginOperator`, `flutter_camp_login_services` | iOS 登录在 `LoginOperator.m` |
| 支付/充值 | `PayManager`, `MidasManager` | `smoba`+`PayManager` | — |
| 网络 | `NetSecurityServiceImpl`, `OneAPI`, `OneAPIRequestServiceImpl` | `smoba`+`ChatTimHandler`, `WebServiceManager` | Android 网络层走 OkHttp |
| IM/消息 | `IMManager`, `imsdk` | `smoba`+`ChatTimHandler` | IMSDK 在子进程日志中 |
| 游戏下载 | `GamesManager`, `CampPreDownloadManager`, `AppUpdateUtil` | `flutter_getMallGameList` | 含 Dolphin 下载 |
| 启动/初始化 | `ApplicationInitHelper`, `GlobalApplicationAgent`, `AppLaunchService`, `CampLaunchTask`, `AnchorTask` | `smoba`+`AppDelegate`, `OTViewSpanStackManager` | 启动链路 Tag |
| 配置/开关 | `ToggleConvertShiplyManager`, `Res_Shiply_ResHubCenterManager` | `smoba`+`WEGRDLoggerImpl`(含 ShiplySDK) | Shiply 远程配置 |
| Flutter | `flutter_MonitorManager`, `FlutterPatch` | `flutter_*`（所有 flutter_ 前缀） | Flutter 引擎+业务 |
| 视频播放 | `TVK_VIDEO`, `TVKPlayer[*]`, `MediaPlayerMgr` | — | 腾讯视频 SDK |
| 性能监控 | `SpeedCostUtil`, `PerformanceConfigManager`, `GalileoReport` | `flutter_LaunchMetricMonitor`, `flutter_LooperMetricMonitor` | 埋点/监控 |

### 噪声 Tag（通常可忽略）

| TAG | 原因 |
|-----|------|
| `[TVKDnsResolver]`, `TPMediaDecoderList`, `TPDrmCapability`, `TPCodecUtils` | 视频 SDK 内部，与业务无关 |
| `mars.xlog.log` | xlog 框架自身初始化日志 |
| `MmkvSpWrapper` | 存储读写噪声 |
| `LifecycleLog` | Activity 生命周期日志，数量大但信息密度低 |
| `HippyInterceptor`, `GlobalInterceptorCenter` | Hippy 框架拦截器，正常运行噪声 |
| `flutter_LooperMetricMonitor`（仅 "has started"） | 重复启动警告，无意义 |
| `flutter_LaunchMetricMonitor`（仅 "miss sampling"） | 采样未命中，正常现象 |

### grep 策略：Tag 精确过滤

```bash
# 因为日志格式是 [TAG]，grep 时要包含方括号
# 登录问题（Android）
rg "\[LoginManager\]|\[AccountEvent\]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# 登录问题（iOS）
rg "LoginOperator|camp_login" decoded_logs/smoba_*.log

# 网络问题（Android）
rg "\[NetSecurityServiceImpl\]|\[OneAPI\]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# 游戏下载（Android）
rg "\[GamesManager\]|\[CampPreDownloadManager\]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# Shiply 配置问题
rg "\[ToggleConvertShiplyManager\]|\[Res_Shiply\]" decoded_logs/*.log
```

**关键技巧**：先用 Tag 过滤缩小到几百行，再在这些行中按时间/关键词精确搜索。

---

## 三、按时间精准定位

### 时间戳利用策略

1. **锚定反馈时间**：`feedback.json` 的 `create_time` 是用户提交反馈的时间，问题通常发生在**此时间之前 1~10 分钟**
2. **注意时区偏移**：Android 为 `+8.0`，iOS 为 `+80`（格式略有差异）
3. **构造时间正则**：

```bash
# create_time = "2026-05-11 20:35:56"
# 问题大概发生在 20:30~20:35（反馈提交前 1~5 分钟）

# Android（注意 +8.0 中的点需要转义）
rg "2026-05-11 \+8\.0 20:3[0-5]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# iOS
rg "2026-05-12 \+80 12:3[0-7]" decoded_logs/smoba_*.log

# 组合：时间窗口 + Tag（用管道）
rg "2026-05-11 \+8\.0 20:3[0-5]" decoded_logs/com.tencent.gamehelper.smoba_*.log | grep "\[LoginManager\]"

# 组合：时间窗口 + 仅 ERROR
rg "2026-05-11 \+8\.0 20:3[0-5]" decoded_logs/com.tencent.gamehelper.smoba_*.log | grep "^\[E\]"
```

4. **时间间隔异常检测**：两条相邻日志时间差 > 3s 通常意味着阻塞/卡死

### 时间窗口选择指引

| 问题类型 | 建议时间窗口 | 原因 |
|----------|-------------|------|
| 闪退/崩溃 | create_time 前 **1~2 分钟** | 崩溃后用户很快提交反馈 |
| 登录失败 | create_time 前 **2~5 分钟** | 用户可能重试几次再反馈 |
| 持续性问题（卡顿/断连） | create_time 前 **5~10 分钟** | 用户忍受一段时间后反馈 |
| 下载/更新问题 | create_time 前 **10~30 分钟** | 下载过程较长 |

---

## 四、按内容模式分层读取

**核心原则：日志级别是天然的信息密度指标，按 E→W→I 顺序逐层深入。**

### 分层策略

```
第一层（必看）：ERROR + FATAL
  → 直接错误/崩溃信号，命中率最高

第二层（按需）：WARN
  → 潜在问题预警，常包含"降级""重试""超时"等关键词

第三层（追因）：INFO（仅在错误行附近 ±30 行）
  → 还原正常流程，确认"哪一步之后出的错"

第四层（兜底）：DEBUG/VERBOSE
  → 仅当前三层无法定位时才查看，通常噪声极大
```

### grep 分层示例

```bash
# 第一层：直接看 ERROR + FATAL（行首方括号匹配）
rg "^\[E\]|^\[F\]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# 若第一层命中 → 扩展上下文即可得出结论
rg -n "^\[E\]" decoded_logs/com.tencent.gamehelper.smoba_20260511.log -B 10 -A 5

# 第一层无命中 → 第二层 WARN
rg "^\[W\]" decoded_logs/com.tencent.gamehelper.smoba_*.log

# 第二层也无命中 → 按 Tag 看正常流程是否中断
rg "\[LoginManager\]" decoded_logs/com.tencent.gamehelper.smoba_*.log | tail -20
# 看最后一条日志是什么状态 → 流程走到哪里断了

# iOS 同理
rg "^\[E\]|^\[W\]" decoded_logs/smoba_*.log
rg "LoginOperator" decoded_logs/smoba_*.log
```

---

## 五、高价值日志模式识别

以下日志模式**出现即有价值**，LLM 看到时应重点关注：

### 状态变化（精确问题时刻）

```
[E][2026-05-11 +8.0 09:05:39.392][19056, 1*][CampPreDownloadManager][, , 0][[main]download state changed: Idle
[I][2026-05-11 +8.0 09:05:40.097][19056, 1*][GamesManager][, , 0][[main]reportGalileoStart, gameKey: 30005
```
→ 状态转换 + 关键操作 = 问题发生的精确时刻

### 错误码（根因直接线索）

```
[W][2026-05-12 +80 12:37:15.789][0, 310788096*][smoba][LoginOperator.m, ...][Login]FailReason:Error Domain=kWebServiceErrorDomain Code=-50000
[I][2026-05-12 +80 12:14:30.162][0, 306872320*][smoba][ChatTimHandler.m, ...][chat] imsdk onConnectFailed:9512, ERR_ADDRESS_UNREACHABLE
```
→ 错误码 (`-50000`, `9512`) + 错误描述 = 根因线索

### 配置/开关异常（启动阶段常见）

```
[E][2026-05-11 +8.0 09:05:37.308][19056, 1*][ToggleConvertShiplyManager][, , 0][[main]isEnableWithDataSet is null ,data:null
[E][2026-05-11 +8.0 09:05:37.421][19056, 2899][ToggleConvertShiplyManager][, , 0][[AnchorThread#1]getToggleConfig is null ,data:null
```
→ Shiply 配置为 null = 远程配置未拉取到，可能影响后续功能开关

### 类找不到/反射失败（SDK 兼容问题）

```
[E][2026-05-11 +8.0 09:05:37.539][19056, 2899][TVKPlayer[TVKModuleUpdaterFactory]][...][AnchorThread#1]createModuleUpdaterImpl has exception:java.lang.ClassNotFoundException: com.tencent.qqlive.tvkplayer...
```
→ ClassNotFoundException 通常是 SDK 版本不匹配或动态加载失败

### 版本信息（定位问题范围）

```
[I][2026-05-11 +8.0 09:05:37.277][19056, 1*][ApplicationInitHelper][, , 0][[main]version: 10.111.0304, versionCode: 2057955910, gitVersion: a59914ab88
```
→ 版本号 + gitVersion = 精确定位代码分支

### iOS Flutter 类型转换错误

```
[E][2026-05-12 +80 12:14:47.980][0, 306872320*][flutter_[UserHomeRootModel] ][, , 0][type 'Null' is not a subtype of type 'String' in type cast
[E][2026-05-12 +80 12:14:51.617][0, 306872320*][flutter_getMallGameList][, , 0][parse error: FormatException: Unexpected end of input (at character 1)
```
→ Dart 类型错误 + JSON 解析失败 = 服务端返回数据异常或为空

---

## 六、分析路径决策树

```
用户描述 + 截图
      │
      ▼
识别问题类型 → 确定优先 Tag
      │
      ▼
时间窗口 + Tag 组合 grep
      │
      ├─ 命中 ERROR/FATAL → 扩展上下文 ±30 行 → 得出结论
      │
      ├─ 命中 WARN/状态变化 → 向前追溯"最后正常状态" → 定位断点
      │
      └─ 无命中 → 扩大时间窗口 or 换 Tag → 看正常流程最后停在哪
                     │
                     └─ 仍无命中 → 标注"⚠️ 日志中无直接证据"
```

---

## 七、常见陷阱

| 陷阱 | 现象 | 正确做法 |
|------|------|----------|
| 被 INFO 日志淹没 | 几万行 INFO 中找问题 | 先 grep `^\[E\]`/`^\[F\]`，再按 Tag 缩小 |
| 匹配到历史错误 | 找到 ERROR 但时间不对 | **必须核对时间戳**是否在反馈时间窗内 |
| Tag 判断错误 | 登录问题去看 PayManager | 先从用户描述映射正确的 Tag |
| 子进程日志误导 | phoenix/widget 的错误与主进程无关 | 主进程文件优先，子进程仅在主进程无线索时补充 |
| 忽略时间间隔 | 两行日志差了 10 秒没注意 | 关注相邻日志的时间差，>3s 通常是异常 |
| 只看错误不看上文 | 只报告"发生了 crash" | ERROR 行的**前 10~30 行**通常包含触发原因 |
| grep 原始 xlog | 二进制文件 grep 无结果 | 只在 `decoded_logs/` 中搜索 |
| 把噪声 ERROR 当问题 | TVK/TP 的 ClassNotFound | 查看噪声 Tag 列表，排除已知无害错误 |
| iOS 时区格式不同 | `+80` vs `+8.0` grep 不到 | Android 用 `\+8\.0`，iOS 用 `\+80` |

---

## 八、日志文件命名规则与优先级

### 文件命名结构

| 平台 | 文件名模式 | 说明 | 优先级 |
|------|-----------|------|--------|
| Android 主进程 | `com.tencent.gamehelper.smoba_YYYYMMDD.log` | 营地主进程日志 | ⭐⭐⭐ 最高 |
| Android 游戏进程 | `com.tencent.gamehelper.smoba_game_YYYYMMDD.log` | 游戏辅助进程 | ⭐⭐ |
| Android Widget 子进程 | `com.tencent.gamehelper.smoba_widgetProvider_YYYYMMDD.log` | 桌面小组件 | ⭐ 低 |
| Android 推送子进程 | `com.tencent.gamehelper.smoba_xg_vip_service_YYYYMMDD.log` | 信鸽推送 | ⭐ 低 |
| Android IMSDK | `imsdk_C_YYYYMMDD.log` | IM 消息 SDK | ⭐ 低（消息问题时看） |
| Android MOCMNA | `mocmna_<UID>_ex_android_YYYYMMDD.log` | 网络诊断 | ⭐ 低 |
| Android GCloud | `GCloudCore_YYYYMMDDHH.log` | GCloud SDK（按小时） | ⭐ 低 |
| iOS 主进程 | `smoba_YYYYMMDD.log` | 营地主进程日志 | ⭐⭐⭐ 最高 |

### 选择策略

1. **优先选日期最接近 `create_time` 的主进程文件**
2. 多天日志时，先看反馈当天，再看前一天（跨天场景）
3. 子进程/SDK 日志只在主进程无线索时作为补充
