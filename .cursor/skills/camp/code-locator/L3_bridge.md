# L3 场景索引：Flutter-Native 通信层 / 胶水层

> **所属域**：Flutter-Native 通信层 | **上级 L2**：L2_INFRA.md  
> **主路径**：`Features/WEGGlue/` / `xcodeproj/WEGGlue/` / `lib/camp_business/`（Pigeon 生成代码）

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| Flutter 调用 iOS 方法无响应 | Flutter 调 Native、Pigeon 无响应 | `Features/WEGGlue/`（Pigeon 实现侧）<br>`lib/camp_business/`（Pigeon 调用侧） | 搜对应 Pigeon 接口方法名 |
| iOS 调用 Flutter 方法无响应 | Native 调 Flutter | `xcodeproj/WEGGlue/`（调用侧）<br>`lib/camp_business/`（Pigeon 接收侧） | 搜 FlutterMethodChannel / Pigeon callback |
| ZTSDK 染色数据获取失败 | ZTSDK、染色、染色数据 | `xcodeproj/WEGGlue/WEGGlue/Classes/Logic/ZTSDKSDK/ZTSDKManager.m`<br>`xcodeproj/OneAPIBiz/OneAPIBiz/Classes/ZTSDK/WEGZTSDKOneAPI.m` | 搜 ZTSDKManager / getColorData |
| Flutter 路由跨端跳转失败 | 跨端跳转、TRouter | `lib/trouter/`<br>`Features/FlutterRouteUtils/` | 搜 TRouter.open / FlutterRouteUtils |
| Pigeon 接口 crash | Pigeon crash | `flutter_module/pigeons/`（接口定义）<br>`Features/WEGGlue/`（iOS 实现） | 搜崩溃方法名 + nil 参数处理 |
| Flutter 业务数据无法传到 iOS | 数据传递、通信 | `Features/WEGFlutterBiz/`<br>`xcodeproj/WEGFlutterBiz/` | 搜 FlutterBiz / sendToNative |
| 混合栈页面导航异常（返回键/手势） | 混合栈、返回手势 | `lib/navigator/`<br>`Features/FlutterRouteUtils/` | 搜 FlutterNavigator / popRoute |
| Protobuf nil 导致 crash | Protobuf nil、Promise reject nil | `xcodeproj/WEGGlue/WEGGlue/Classes/WEGCppBiz/request/WEGProtobufRequest.mm` | 搜 parseFromData / reject:nil |
| C++ 桥接层异常 | C++、WEGCpp | `Features/WEGCpp/` | 搜 WEGCpp / cppBridge |
| Flutter 业务管理器异常 | FlutterBusiness | `Features/Manager/WEGFlutterBusinessManager/` | 搜 WEGFlutterBusinessManager |
| Pigeon 接口定义与实现不匹配 | 接口不匹配、方法签名 | `flutter_module/pigeons/`（源定义）<br>`Features/WEGGlue/`（iOS实现）<br>`lib/camp_business/`（Flutter生成代码） | 对比三处接口签名是否一致 |

---

## 关键链路

```
Flutter 调 iOS（Pigeon）
  → lib/camp_business/ 生成的 Pigeon Flutter API
  → Features/WEGGlue/ 对应的 Pigeon iOS 实现
  → iOS 业务逻辑

iOS 调 Flutter（Pigeon Event Channel）
  → xcodeproj/WEGGlue/ 发起调用
  → lib/camp_business/ Pigeon 接收端
  → Flutter 业务逻辑

ZTSDK 染色流程
  → ZTSDKManager.m 触发
  → WEGZTSDKOneAPI.m 发请求
  → 回调数据注入到请求

C++ 桥接
  → Features/WEGCpp/ C++ 代码
  → xcodeproj/WEGGlue/ 封装调用
```

---

## 排查起点建议

- **任何 Flutter↔iOS 通信问题**：先确认是哪个 Pigeon 接口，再看 `Features/WEGGlue/` 对应实现
- **ZTSDK 问题**：`ZTSDKManager.m` 是唯一入口
- **Protobuf nil crash（常见）**：`WEGProtobufRequest.mm` 中 parseFromData 后未判空
- **C++ 层问题**：`Features/WEGCpp/` 是底层桥接
- **Flutter 业务管理**：`Features/Manager/WEGFlutterBusinessManager/` 管理 Flutter 业务生命周期

*最后更新：2026-03-30（新增：C++桥接、FlutterBusinessManager、接口不匹配 3 个新场景）*
