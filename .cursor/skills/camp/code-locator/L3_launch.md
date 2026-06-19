# L3 场景索引：启动 / 初始化 / 路由

> **所属域**：启动 / 初始化 / 路由 | **上级 L2**：L2_INFRA.md  
> **主路径**：`Features/WEGLauncher/` / `lib/trouter/` / `lib/navigator/` / `Features/RouteAction/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| App 启动 crash | 启动崩溃、启动闪退 | `Features/WEGLauncher/` | 看启动序列各模块初始化顺序 |
| App 启动后一直白屏 | 白屏、卡启动 | `Features/WEGLauncher/`（启动序列） | 搜 launchSequence / didFinishLaunching |
| Flutter 页面跳转失败 / 路由找不到 | 跳转失败、路由 404 | `lib/trouter/`<br>`Features/FlutterRouteUtils/` | 搜 TRouter / routeNotFound |
| iOS 跳转到 Flutter 页面失败 | native 跳 Flutter | `Features/FlutterRouteUtils/`<br>`Features/RouteAction/` | 搜 openFlutterPage / FlutterRouteUtils |
| Flutter 跳转到 iOS 原生页面失败 | Flutter 跳 native | `lib/trouter/`（TRouter 调用） | 搜 TRouter.open / routeToNative |
| ABTest 分组不生效 | ABTest、实验分组 | `Features/ABTest/`<br>`Features/Imps/WEGABTestImp.m` | 搜 isInABTestClassName: / WEGABExpInfoManager |
| App 主窗口展示异常 / 反馈服务提示不弹 | 主窗口、反馈提示 | `Features/Imps/WEGSmobaHelperImp.m` | 搜 appDelegateWindowMakeKeyAndVisible |
| 小窗场景状态不对（语音房/直播等） | 小窗、最小化 | `Features/Imps/WEGSmobaHelperMinimizeImp.m` | 搜 getCurrentMinimizeScene / CampMinimizeScene |
| Cube 模块注册失败 / 模块不可用 | Cube、模块化 | `xcodeproj/WEGCube/` | 搜 WEGCubeModuleManager / registerModule |
| iOS 路由拦截 / OpenURL 异常 | 路由管理、URL 拦截 | `Features/Manager/WEGRouteManager/` | 搜 WEGRouteManager / routeWithURL |
| 路由切换（A/B 路由选择） | 路由切换 | `Features/Manager/WEGRouteSwitcher/` | 搜 WEGRouteSwitcher |
| 开屏广告 / 启动页显示异常 | 开屏、启动页 | `Features/WEGLauncher/`（splash 子目录） | 搜 SplashViewController / splashAd |
| 某模块初始化失败导致功能不可用 | 模块初始化、服务注册 | `Features/ModuleLogic/` | 搜 registerModule / moduleDidLoad |
| 冷启动时间过长 | 启动慢、性能 | `Features/WEGLauncher/` + `Features/APM/` | 看启动序列耗时、懒加载逻辑 |
| 任务系统（签到/成就）不触发 | 任务系统、成就 | `Features/Task/` | 搜 TaskManager / checkTaskCondition |
| ZTSDK（染色SDK）未初始化 / 染色数据不上报 | ZTSDK、染色、sdkNotInitialized | `WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m`<br>`src/GameApp/Main/WEGAppLaunchEssentialServices.m`<br>`src/GameApp/Main/AppDelegate.m` | 追 haveAcceptLicense → onAcceptLicense 回调链 → initNeedNetworkSDK；iOS14+ 需等 ATT 回调才初始化 |

---

## 关键链路

```
App 启动
  → AppDelegate didFinishLaunchingWithOptions
  → xcodeproj/WEGLauncher/ 启动序列
  → Features/ModuleLogic/ 各模块注册
  → Features/WEGLauncher/ 主界面展示
  → 页面跳转 → Features/RouteAction/ 解析路由
  → Flutter 页面 → lib/navigator/ / lib/trouter/
```

---

## 排查起点建议

- **启动 crash**：查 `Features/WEGLauncher/` 的初始化顺序，找到哪个模块抛了异常
- **路由跳转失败**：先确认路由是否已注册（`lib/trouter/t_router_register.t_router.dart`），再看跳转逻辑
- **Flutter↔Native 路由**：`Features/FlutterRouteUtils/`（iOS 侧）+ `lib/trouter/`（Flutter 侧）

*最后更新：2026-03-30*
