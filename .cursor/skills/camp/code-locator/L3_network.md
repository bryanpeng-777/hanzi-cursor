# L3 场景索引：网络 / OneAPI / 接口层

> **所属域**：网络 / OneAPI / 接口层 | **上级 L2**：L2_INFRA.md  
> **主路径**：`xcodeproj/OneAPIBiz/` / `lib/camp_business/network/` / `xcodeproj/WEGLongLink/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 网络请求失败 / 超时（iOS） | 请求失败、超时、网络错误 | `xcodeproj/OneAPIBiz/`<br>`Features/OneAPIBiz/` | 搜 OneAPI / requestFailed / errorCode |
| 网络请求失败（Flutter） | Flutter 请求失败 | `lib/camp_business/network/`<br>`lib/common/`（network 子目录） | 搜 NetworkService / requestError |
| 接口返回业务错误码 | 错误码、业务失败 | `Features/OneAPIBiz/` | 搜 businessError / handleError |
| Protobuf 解析失败 / crash | Protobuf、解析失败 | `Features/Imps/WEGProtobufRequestImp.m`<br>`xcodeproj/WEGGlue/.../WEGProtobufRequest.mm` | 搜 parseFromData / protobuf parse |
| 请求被拦截 / Hook 异常 | 拦截、hook、请求被改 | `Features/oneAPIHook/` | 搜 OneAPIHook / interceptRequest |
| 长连接断开 / 重连失败 | 长连接、断开、实时推送 | `xcodeproj/WEGLongLink/` | 搜 LongLink / reconnect |
| Webview 页面打不开 | Webview、H5 页面 | `lib/camp_webview/`<br>`Features/webHook/` | 搜 CampWebView / WebHook |
| 小程序加载失败 | 小程序、MiniApp | `Features/MiniApp/` | 搜 MiniAppLoader / launchMiniApp |
| 网络状态切换后数据不刷新 | 网络切换、4G/WiFi | `Features/MnaDoubleTunnel/` | 搜 networkStatusChange / MNA |
| 接口调用到了测试环境 | 测试环境、接口环境 | `WEGSmobaHelperEnvironmentImp.m` | 检查 host / baseURL 配置 |
| Tux 信息流 / 调研页面异常 | Tux、信息流、调研 | `Features/Tux/` | 搜 TuxPlatformView / CampTuxBottomSurvey |
| Open 平台 SDK 授权失败 | OpenSDK、授权 | `Features/OpenSDK/` | 搜 OpenSDKManager / OpenAuthViewController |
| Hippy 页面打不开 / Hook 异常 | Hippy、Hippy页面 | `Features/hippyHook/` | 搜 HippyHook |
| VPN 隧道异常 | VPN、PacketTunnel | `xcodeproj/PacketTunnel/` | 搜 PacketTunnelProvider |
| WebService 管理异常 | WebService | `Features/Manager/WebServiceManager/` | 搜 WebServiceManager |
| CommonOpenApi 启动异常 | OpenApi 启动 | `Features/Component/CommonOpenApiLauncher/` | 搜 CommonOpenApiLauncher |
| WebOpenApi 启动异常 | Web OpenApi | `Features/Component/WebOpenApiLauncher/` | 搜 WebOpenApiLauncher |
| 底部栏 Web 入口异常 | 底部栏 Web | `lib/business/bottom_bar_web/` | 搜 BottomBarWeb |

---

## 关键链路

```
iOS 发起网络请求
  → xcodeproj/OneAPIBiz/ OneAPI 封装
  → Features/oneAPIHook/ 拦截处理
  → 实际 HTTP 请求（含 ZTSDK 染色头）
  → 回包 → Protobuf 解析
  → 业务回调

Flutter 发起网络请求
  → lib/camp_business/network/ NetworkService
  → 调用 OneData（lib/one_data/）或直接 HTTP
  → 回包处理

WebView/H5 加载
  → lib/camp_webview/（Flutter 侧）
  → Features/webHook/（iOS 侧 Hook）
  → WebService 管理 → Features/Manager/WebServiceManager/
```

---

## 排查起点建议

- **iOS 所有接口问题**：`xcodeproj/OneAPIBiz/` 是核心，看错误码和请求参数
- **环境问题（测试/正式）**：`WEGSmobaHelperEnvironmentImp.m` 确认当前 host
- **Protobuf crash（高频）**：`WEGProtobufRequest.mm` 中 parseFromData 返回 nil 未处理
- **WebView 问题**：Flutter 侧 `lib/camp_webview/`，iOS 侧 `Features/webHook/`
- **长连接**：`xcodeproj/WEGLongLink/`

*最后更新：2026-03-30（新增：VPN隧道、WebService、CommonOpenApi、WebOpenApi、底部栏Web 5 个新场景）*
