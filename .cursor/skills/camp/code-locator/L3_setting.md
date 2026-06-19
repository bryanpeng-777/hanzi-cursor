# L3 场景索引：设置 / 隐私

> **所属域**：设置 / 隐私 | **上级 L2**：L2_INFRA.md  
> **主路径**：`lib/setting/` / `Features/Imps/WEGSmobaHelperEnvironmentImp.m` / `Features/DataSecurity/`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 设置页面打不开 | 设置页面 | `lib/setting/` | 搜 SettingPage / openSetting |
| 新版设置页异常 | 新设置 | `lib/business/new_setting/` | 搜 NewSettingPage |
| 设置 v2 版本异常 | 设置v2 | `lib/business/setting2/` | 搜 Setting2Page |
| 内容可见性设置不生效 | 内容可见、隐私设置 | `lib/article_visibility/` | 搜 ArticleVisibility / setVisibility |
| 环境切换（测试/正式）不生效 | 测试环境、切环境 | `WEGSmobaHelperEnvironmentImp.m` | 搜 switchEnvironment / currentHost |
| 数据安全功能异常 | 数据安全 | `Features/DataSecurity/` | 搜 DataSecurity |
| 开关 / RDelivery 配置值不符合预期 | 开关、RDelivery、配置 | `WEGSmobaHelperEnvironmentImp.m` | **先确认 App 当前拉取的是测试还是正式环境** |
| 隐私协议弹窗不弹 | 隐私协议、用户协议 | `Features/Imps/WEGSmobaHelperCommonImp.m` | 搜 showPrivacyAlert / privacyPolicy |
| 账号注销入口找不到 | 注销账号 | `lib/setting/`（账号管理子页） | 搜 deleteAccount / AccountDeletion |
| 青少年模式页面异常 | 青少年模式、teenager | `lib/business/teenager_mode/` | 搜 TeenagerModePage |
| 截图设置异常 | 截图设置 | `lib/business/screenshot_setting/` | 搜 ScreenshotSettingPage |
| 关于页面打不开 | 关于、版本信息 | `lib/business/about/` | 搜 AboutPage / appVersion |
| 测试辅助功能异常 | 测试辅助、debug | `Features/Imps/WEGSmobaHelperTestImp.m` | 搜 WEGSmobaHelperTest |
| iOS 设置页（旧版）异常 | iOS 设置 | `Features/Setting Willremove/` | 搜 SettingViewController |

---

## 特别说明：开关/RDelivery 不符合预期排查

最常见原因是**环境不匹配**：
1. 检查 `WEGSmobaHelperEnvironmentImp.m` 确认当前连接的服务器环境
2. 确认 RDelivery 配置是否发布到了对应环境（测试/正式）
3. 重新拉取配置（杀进程重启 App）

---

## 排查起点建议

- **开关问题**：90% 是环境问题，先看 `WEGSmobaHelperEnvironmentImp.m`
- **隐私相关**：`lib/article_visibility/`（内容可见性）和 `WEGSmobaHelperCommonImp.m`（协议弹窗）是两个独立逻辑
- **设置页有多个版本**：`lib/setting/`（主）、`lib/business/new_setting/`（新版）、`lib/business/setting2/`（v2）、`Features/Setting Willremove/`（iOS 旧版）
- **青少年模式**：`lib/business/teenager_mode/` 是独立路由入口

*最后更新：2026-03-30（新增：青少年模式、截图设置、关于页面、新版设置、setting2、测试辅助 6 个新场景）*
