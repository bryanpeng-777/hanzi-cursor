# L3 场景索引：商城 / 道具 / 充值 / 个人商城

> **所属域**：商城 / 道具 / 充值 / 个人商城 | **上级 L2**：L2_COMMERCE.md  
> **主路径**：`lib/mall/` / `lib/personal_mall/` / `Features/Imps/WEGStoreProductImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 商城页面打不开 | 商城、商店 | `lib/mall/` | 搜 MallPage / openMall |
| 内购 / 充值失败（IAP 流程失败） | 充值失败、内购、购买失败 | `WEGStoreProductImp.m` | 搜 purchaseProduct / SKPayment |
| 苹果支付票据验证失败 | 票据验证、receipt | `WEGStoreProductImp.m` | 搜 verifyReceipt / validatePurchase |
| 补单流程没有触发 | 补单、漏单 | `WEGStoreProductImp.m` | 搜 restorePurchases / pendingTransaction |
| 钻石余额显示错误 / 不刷新 | 钻石、余额 | `lib/camp_business/diamond_indicator/` | 搜 DiamondIndicator / fetchBalance |
| 道具记录为空 / 加载失败 | 道具记录、消费记录 | `lib/prop_record/`<br>`lib/prop_record_detail/` | 搜 PropRecordPage / fetchPropRecord |
| 限定权益不显示 | 限定权益、特权 | `lib/limited_benefits/` | 搜 LimitedBenefitsPage |
| 游戏黑卡权益显示异常 | 黑卡、月卡 | `lib/game_black/` | 搜 GameBlackPage / blackCardBenefit |
| 商品详情页加载失败 | 商品详情 | `lib/mall/`（product_detail 子目录） | 搜 ProductDetailPage / fetchProduct |
| 个人橱窗/个人商城页面异常 | 个人商城、橱窗 | `lib/personal_mall/`（personal_mall_home） | 搜 PersonalMallHome / personalMall |
| 个人橱窗商品编辑/添加失败 | 橱窗商品、添加商品、编辑商品 | `lib/personal_mall/`（goods_editor / goods_add） | 搜 GoodsEditor / GoodsAdd |
| 个人橱窗商品搜索不到 | 橱窗搜索、商品搜索 | `lib/personal_mall/`（goods_search） | 搜 GoodsSearch |
| 橱窗欢迎语/标签设置异常 | 欢迎语、橱窗标签 | `lib/personal_mall/`（welcome_setting） | 搜 WelcomeSetting |

---

## 关键链路（IAP 充值核心流程）

```
用户点击购买
  → WEGStoreProductImp.m purchaseProduct:
  → StoreKit 发起支付 → 苹果支付弹窗
  → 支付成功 → SKPaymentTransactionStatePurchased
  → WEGStoreProductImp.m 上传票据验证
  → 服务端验证成功 → 发放道具
  → 失败 → 补单逻辑（restorePurchases）
```

---

## 排查起点建议

- **所有 IAP 问题**：`WEGStoreProductImp.m` 是唯一入口，重点看 transaction 状态处理
- **测试环境注意**：充值接口有测试/正式环境区分，先确认环境配置（`WEGSmobaHelperEnvironmentImp.m`）
- **余额显示**：`lib/camp_business/diamond_indicator/` + 接口刷新时机

*最后更新：2026-03-30*
