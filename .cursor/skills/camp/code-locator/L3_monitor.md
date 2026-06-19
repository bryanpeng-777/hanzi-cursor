# L3 场景索引：性能监控 / 埋点

> **所属域**：性能监控 / 埋点 | **上级 L2**：L2_INFRA.md  
> **主路径**：各业务目录内 `OTTrace` / `TaskSpan` 调用 | `Features/APM/` / `lib/performance/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 伽利略指标不上报 / 数据为 0 | 伽利略、指标不上报 | 对应业务目录内 `OTTrace` / `TaskSpan` | 搜 OTTrace / TaskSpan + moduleName |
| 埋点参数不正确 / 字段缺失 | 参数不对、字段 | 对应业务目录的上报代码 | 搜 attributes / traceAttributes |
| 前置上报没有立即生效 | 前置上报、Before | 对应业务目录 | 确认使用 `OTTraceTypeBefore` / `campTypeBefore` |
| APM 监控数据异常 | APM、性能监控数据 | `Features/APM/` | 搜 APMMonitor / reportMetric |
| 性能服务数据（赛季/战力）获取失败 | 性能数据、PerformanceService | `lib/performance/service/` | 搜 PerformanceService / getSeasonInfo |
| 双通道网络监控异常 | MNA、双通道 | `Features/MnaDoubleTunnel/` | 搜 MnaManager / tunnelStatus |
| 某功能的伽利略 module 是什么 | moduleName、module | 先用 galileo-module-locator 技能定位 | — |
| 埋点上报代码在哪 | 上报在哪里 | 在对应业务目录搜 `OTTrace` 调用 | `rg "OTTrace" Features/XxxModule/` |
| MTA 曝光 / 上报异常 | MTA、曝光上报 | `Features/Manager/MTAManager/` | 搜 MTAManager / reportExposure |
| OneEvent 事件配置异常 | OneEvent、事件名 | `Features/OneEventBiz/`<br>`lib/camp_business/one/` | 搜 OneEventConfiguration / oneEvent |
| CampTools 伽利略配置异常 | CampTools、伽利略配置 | `xcodeproj/CampTools/`（Classes/Galileo） | 搜 CampTools + Galileo |
| TGA 管理 / TGA 数据异常 | TGA、TGA 数据 | `Features/Manager/WEGTgaManager/` | 搜 WEGTgaManager / tgaReport |
| MTA 资讯上报异常（Imp） | MTA 资讯 | `Features/Imps/WEGMTANewsReportImp.m` | 搜 MTANewsReport |
| 性能监控模块异常（iOS） | 性能监控 | `Features/WEGPerformanceMonitor/` | 搜 PerformanceMonitor |
| 业务基座层埋点（Flutter） | 基座埋点、base | `lib/camp_business/base/` | 搜 CampBizBase / reportTrace |
| 内存警告时上报 VC 存活数量 / VC 数量追踪 | ViewController数量, 内存泄漏, memoryWarning | `src/GameApp/Features/APM/WEGViewControllerTracker.m` | 搜 WEGViewControllerTracker / handleMemoryWarning |
| FOOM 检测 / OOM 监控 | FOOM, OOM, WEGFOOMEstimateRecord | `src/GameApp/Features/APM/WEGFOOMEstimateRecord.m` | 注意：ENABLE_FOOM 宏未开启，代码不生效；Bugly 替代方案见 CLAUDE.md |

---

## 关键说明

### iOS 伽利略上报规范
```objc
// 前置上报（默认使用）
[OTTrace campTraceWithName:@"moduleName"
                 campType:OTTraceTypeBefore
               attributes:@{@"key": @"value"}];
```

### Flutter 伽利略上报规范
```dart
// 前置上报（默认使用）
TaskSpan(
  moduleName: 'moduleName',
  campType: TaskSpan.campTypeBefore,
  attributes: {'key': 'value'},
).report();
```

---

## 排查起点建议

- **找埋点代码**：先用 L1/L2 找到业务目录，在该目录内搜 `OTTrace` 或 `TaskSpan`
- **伽利略 module 定位**：使用 `galileo-module-locator` 技能
- **前置上报不生效**：确认 `campType` 是否为 Before 类型
- **TGA 问题**：`Features/Manager/WEGTgaManager/`
- **MTA 问题**：`Features/Manager/MTAManager/` + `WEGMTANewsReportImp.m`

*最后更新：2026-03-30（新增：TGA管理器、MTA资讯Imp、性能监控模块、业务基座层 4 个新场景）*
