# Layer 2 详情：商业化

> **归属超级分类**：D - 商业化  
> **覆盖域**：商城/道具/充值、个人商城/橱窗  
> **路径根**：Flutter `flutter_module/lib/` | iOS `social-ios/src/GameApp/`

---

## 1. 商城 / 道具 / 充值 　　　📄 [场景展开 → L3_commerce.md](L3_commerce.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 商城主页 | `lib/mall/` | — |
| 道具记录列表 | `lib/prop_record/` | — |
| 道具记录详情 | `lib/prop_record_detail/` | — |
| 内购 / 充值 / 苹果支付（IAP） | — | `Features/Imps/WEGStoreProductImp.m` |
| 限定权益 | `lib/limited_benefits/` | — |
| 钻石指示器 / 余额显示 | `lib/camp_business/diamond_indicator/` | — |
| 游戏黑卡 | `lib/game_black/` | — |
| 商品详情页 | `lib/mall/`（product_detail 子目录） | — |
| 购买流程 / 支付确认 | `lib/mall/`（payment 子目录） | `Features/Imps/WEGStoreProductImp.m` |
| 订单历史 | `lib/mall/`（order 子目录，如有） | — |
| 皮肤购买 / 道具兑换 | `lib/mall/`（exchange 子目录） | — |
| **商品页路由入口** | `lib/business/shop/` | — |
| 商城路由入口 | `lib/business/mall/` | — |

**关键 Imp**：`WEGStoreProductImp.m`（IAP 苹果内购核心）

---

## 2. 个人商城 / 橱窗 　　　📄 [场景展开 → L3_commerce.md](L3_commerce.md)

| 子功能 | Flutter 路径 | iOS 路径 |
|--------|-------------|---------|
| 个人商城主页 | `lib/personal_mall/`（personal_mall_home） | — |
| 商品管理（编辑/添加/搜索） | `lib/personal_mall/`（goods_editor / goods_add / goods_search） | — |
| 欢迎语 / 橱窗标签设置 | `lib/personal_mall/`（welcome_setting） | — |

> 个人商城 = 用户个人主页上的「橱窗/带货」功能（社交电商类），与主商城 `lib/mall/` 是独立模块

---

## 注意事项

- **IAP 苹果内购**：iOS 侧核心实现在 `WEGStoreProductImp.m`，涉及 StoreKit 流程（购买、票据验证、补单）
- **虚拟货币（钻石）**：余额展示在 `diamond_indicator`，扣款逻辑通常在网络层（OneAPI）
- **充值环境隔离**：测试环境 vs 正式环境的区分见 `WEGSmobaHelperEnvironmentImp.m`（L2_INFRA）
- **商品页 vs 商城**：`lib/business/shop/` 是路由入口，核心逻辑在 `lib/mall/`

---

## 附录：常用 Imp 速查（商业化域）

| Imp 文件 | 功能 |
|---------|------|
| `WEGStoreProductImp.m` | 商城 / 内购 / 苹果支付 |

---

*最后更新：2026-03-30（新增：lib/business/shop 路由入口）*
