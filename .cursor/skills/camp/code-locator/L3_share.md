# L3 场景索引：分享

> **所属域**：分享 | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/camp_business/share/` / `Features/CampShare/` / `Features/Imps/WEGShareImp2.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 点分享按钮无响应 / 分享面板不弹出 | 分享面板、分享底部弹窗 | `lib/camp_business/share/` | 搜 showShareSheet / ShareBottomSheet |
| 分享到微信 / QQ 失败 | 分享到微信、分享失败 | `WEGShareImp2.m` | 搜 shareToWeChat / shareToQQ |
| 分享卡片 / 海报生成失败 | 分享卡片、海报 | `lib/camp_business/share/`（card 子目录） | 搜 generateShareCard / ShareCardWidget |
| 二维码扫描失败 / 打不开 | 二维码、扫码 | `lib/qr_scan/` | 搜 QRScanPage / scanQRCode |
| 选择分享渠道后无跳转 | 转发渠道、分享渠道 | `lib/forward_channel/` | 搜 ForwardChannelPage / selectChannel |
| 分享链接打开后内容不对 | 分享链接、Deep Link | `Features/RouteAction/` | 搜 handleShareLink / openFromURL |

---

## 排查起点建议

- **分享到第三方（微信/QQ）失败**：`WEGShareImp2.m` 是核心，检查 SDK 配置和回调
- **分享面板不弹**：`lib/camp_business/share/` 的 showShareSheet 调用链
- **二维码问题**：`lib/qr_scan/` 独立模块，权限问题优先排查

*最后更新：2026-03-30*
