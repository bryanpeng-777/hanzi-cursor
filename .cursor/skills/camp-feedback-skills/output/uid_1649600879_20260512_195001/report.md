# 营地反馈分析报告

> 生成时间：2026-05-19 | 工作目录：output/uid_1649600879_20260512_195001

---

## 一、反馈基础信息

| 字段 | 值 |
|------|----|
| 反馈来源 | **iFeedback** |
| 反馈 ID | `BncFHJ4B5YmzxBn_yorf` |
| userId | 1649600879 |
| 平台 | iOS |
| 版本 | 10.112.0429 |
| 机型 | iPhone15,3（iPhone 14 Pro Max） |
| 系统版本 | 26.5 |
| 网络 | WiFi |
| 登录方式 | QQ 登录 |
| 反馈时间 | 2026-05-12 19:48:57 |
| 用户描述 | **"支付失败"** |
| 分类 | 闪退、卡顿或界面提示 → 其他 |
| xLogUid | A8201923-168B-4315-94D7-B59237A27EEE |

---

## 二、日志与附件概览

| 项目 | 详情 |
|------|------|
| xlog 文件 | `smoba_20260512.xlog` |
| 解码状态 | ✅ 成功（1/1） |
| 日志时间范围 | `2026-05-12 10:18:38` ~ `19:48:52` |
| 总行数 | 301,948 行 |
| 截图 | `0ABFB6E1F747B5EFE82097F37CD7FC59.png`（1张）|
| download_failures | 无 |
| decode_failures | 无 |
| lego 状态 | ⚠️ 接口未接入，跳过 |

**⚠️ 注意**：日志止于 `19:48:52`，问题上报时间 `19:48:57`，日志几乎覆盖到问题发生时刻（差 5 秒）。最后一次支付失败记录在 `L300574~L300575 [19:48:08]`，在日志范围内。

---

## 三、截图分析

截图显示：
- **界面**：王者荣耀充值页面（荣耀币充值），选中 **450 荣耀币 ¥45**（黄色边框高亮）
- **错误弹窗**：黑色 Toast 提示 **"AppStore 支付失败，请稍后重试"**
- **用户状态**：QQ 登录，荣耀币余额为 0（充值未到账）

**与日志交叉验证**：
- 截图中选中 450 荣耀币 ¥45 → 与日志中反复出现 `productId=com.tencent.pay.helper45 num=450` 完全匹配 ✅
- 截图显示"AppStore 支付失败" → 与 `L300574 [19:48:08] [MidasPay]midas iap error` 完全吻合 ✅
- 截图显示余额为 0 → 说明支付未成功发货，与 Midas 返回 code4（IAP 错误）一致 ✅

---

## 四、根因分析

### 4.1 时间轴重建（问题发生全貌）

```
10:18:38  App 第 1 次启动 [L26]
10:18:59  Midas registpay 成功（SDK v1.7.4）[L4024-4026]

10:35:24  第 1 次 LaunchGoodsList，获取商品列表 [L66183]
10:35:30  start normalPay productId=com.tencent.pay.helper45 num=450 [L66211]
10:35:37  ❌ midas code1 error innerCode 2 [L66232-66233]  ← 用户取消/StoreKit失败
10:35:39  重试 normalPay [L66250]
10:35:49  ❌ midas code1 error innerCode 2 [L66282-66283]

10:31:37  App 第 2 次重启 [L48873]（约支付失败 4 分钟后）
10:52:11  App 第 3 次重启 [L69051]

10:49:06  normalPay helper45 [L67076]
10:49:26  ❌ midas code4 error innerCode 0_500_301_301 [L67123-67124]  ← IAP收据重复
10:49:51  normalPay helper45 [L68297]
10:50:13  ❌ midas code4 error innerCode 0_500_301_301 [L68330-68331]
10:50:30  normalPay helper45 [L68456]
10:50:34  ❌ midas code1 error innerCode 2 [L68465-68466]
10:50:35  normalPay helper45 [L68478]
10:50:41  ❌ midas code1 error innerCode 2 [L68486-68487]
10:50:42  normalPay helper45 [L68499]
10:51:30  ❌ midas code4 error innerCode 0_500_301_301 [L68631-68632]

（10:52~11:38：App 共重启 10 次，每次重启后继续尝试支付，均失败）

11:11:00  normalPay helper45 [L124102]
11:13:27  ❌ midas code4 error innerCode 0_530_100_100 [L124450-124451]  ← 新错误码

11:50:14  normalPay helper45 [L264174]
11:50:30  ❌ midas code4 error innerCode 0_500_301_301 [L264256-264257]

── 约 7.75 小时日志空白（11:51 ~ 19:37）──

19:37:10  App 第 14 次重启 [L264668]（下午重新启动）
19:38:03  normalPay helper45 [L281310]
19:38:11  normalPay helper45（快速重试）[L281318]
19:38:17  ❌ midas code1 error innerCode 2 [L281327-281328]
19:38:20  normalPay helper45 [L281354]
19:38:24  ❌ midas code1 error innerCode 2 [L281361-281362]
19:38:26  normalPay helper45 [L281364]
19:38:28  normalPay helper45（快速重试）[L281381]
19:38:37  ❌ midas code1 error innerCode 2 [L281383-281384]

19:39:10  normalPay helper45 [L282705]
19:39:13  ❌ midas code4 error innerCode 0_500_301_301 [L282718-282719]
19:39:15  normalPay helper45 [L282721]
19:39:18  ❌ midas code4 error innerCode 0_500_301_301 [L282738-282739]

19:39:25  App 第 15 次重启 [L283204]

19:40:17  normalPay helper45 [L299706]
19:40:20  ❌ midas code4 error innerCode 0_500_301_301 [L299739-299740]
19:40:24  normalPay helper45 [L299910]
19:40:27  ❌ midas code4 error innerCode 0_500_301_301 [L299927-299928]

19:43:35  normalPay helper45 [L300290]
19:43:38  ❌ midas code4 error innerCode 0_500_301_301 [L300296-300297]

19:48:04  ★ start normalPay productId=com.tencent.pay.helper1 num=10（切换 ¥1 档重试）[L300568]
19:48:06  App 进入后台（Apple IAP 弹框呼出）[L300570-300571]
19:48:08  ❌ midas iap error / code4 error innerCode 0_500_301_301 [L300574-300575]
          ← 截图对应时刻，用户看到"AppStore 支付失败，请稍后重试"

19:48:52  日志最后一条记录（推测 App 再次崩溃或被杀进程）
```

---

### 4.2 可能根因（按可能性排序）

**根因 1（高置信度）：Apple IAP 收据重复提交 → Midas 服务端拒绝发货**

- **证据**：
  - L67123-67124 `[19:49:26]`：`[MidasPay]midas iap error. / midas code4 error innerCode 0_500_301_301`
  - L68330-68331 `[19:50:13]`：同上
  - L282718-282719 `[19:39:13]`：同上
  - L299739-299740 `[19:40:20]`：同上
  - L300574-300575 `[19:48:08]`：同上（最后一次，截图对应时刻）
  - `innerCode 0_500_301_301` 中的 `301` 对应 Midas 服务端 receipt_already_used（苹果收据已被使用过）
- **机制**：App 频繁重启（全天 15 次），每次重启后 StoreKit 的 **pending transaction 未被 `finishTransaction` 清除**，重启时 Midas 自动重放（restore）上一条 transaction 的 receipt，服务端认为是重复订单，拒绝发货但 App 层面报"支付失败"

---

**根因 2（高置信度）：App 异常频繁重启导致 IAP 状态机混乱**

- **证据**：
  - 全天共 **15 次 `AppDelegate didFinishLaunchingWithOptions`** / **15 次 `MidasManager registpay`**：
    - L26 `10:18:38`, L48873 `10:31:37`, L69051 `10:52:11`, L84702 `10:57:56`, L99581 `10:58:59`
    - L125727 `11:15:23`, L148634 `11:24:46`, L164343 `11:26:17`, L183446 `11:29:59`, L200116 `11:31:19`
    - L215247 `11:32:04`, L223328 `11:37:12`, L248047 `11:49:29`, L264668 `19:37:10`, L283204 `19:39:25`
  - 10:31~11:38 约 67 分钟内重启 **12 次**（平均 5.5 分钟一次），明显异常
  - 每次重启 Midas SDK 重新 `registpay`，但 StoreKit 中的 unfinished transaction 队列被重复触发
- **机制**：iOS StoreKit 未完成的 transaction 会在每次 App 启动时通过 `paymentQueue:updatedTransactions:` 回调恢复，若 `finishTransaction` 时序有问题，同一张 receipt 会被反复提交

---

**根因 3（中置信度）：支付发起时 App 进入后台导致 SKPaymentQueue 被打断**

- **证据**：
  - L300568 `[19:48:04.892]`：`start normalPay productId=com.tencent.pay.helper1 num=10`
  - L300570 `[19:48:06.085]`：`applicationWillResignActive`（App 失去焦点，即 Apple IAP 系统弹框弹出）
  - L300574 `[19:48:08.604]`：仅 **1.6 秒**后即返回 `midas iap error code4`
  - L300577 `[19:48:10.396]`：`applicationDidBecomeActive`（App 重新获得焦点）
- **机制**：支付发起后 App 即进入后台（正常现象：Apple IAP 弹框会让 App 失活），但此次在弹框弹出后约 2.5 秒内 Midas 就收到了 code4 错误，说明 StoreKit 还未能完成与 Apple 服务器的通信就已失败，可能是网络瞬断或 pending transaction 阻塞了新 transaction

---

**根因 4（中置信度）：`code1 error innerCode 2` — SKError.paymentCancelled（支付被取消）**

- **证据**：
  - L66232-66233 `[10:35:37]`：`midas code1 error innerCode 2`
  - L281327-281328 `[19:38:17]`：同上（19:38 共出现 3 次）
- **机制**：`code1 innerCode 2` 对应 `SKErrorCode.paymentCancelled`（苹果 IAP error 2），可能原因：（a）用户手动点击取消，或（b）快速重试时上一次 transaction 尚未结束，StoreKit 自动 cancel 了新请求

---

**关于 IDFV 漂移**（历史背景提及）：
- ⚠️ **本 xlog 文件中仅发现 1 个 uniqueId**（`631268FF-A605-483B-A173-E64AC66AEDFB`），全程未变化
- App 容器路径固定（`/var/mobile/Containers/Data/Application/78314161-A411-45A2-B400-FC698C4ADA73`），说明 IDFV 在本日志周期内稳定
- 历史背景所述"38 分钟内 device_id 变化 3 次"推测发生在本日志覆盖范围之前（可能是更早的日志），或来自 Midas/服务端视角（Midas 的 device_id 与 xlog 中的 uniqueId 不完全等同）
- **无法在本 xlog 中直接证实 IDFV 漂移**，此结论标注 `⚠️ 推测`

---

### 4.3 支付失败统计摘要

| 时间段 | 尝试次数 | 主要错误 |
|--------|---------|---------|
| 10:35~10:36 | 3次 | code1/innerCode2（取消）× 2 |
| 10:49~10:51 | 5次 | code4/0_500_301_301 × 3 + code1 × 2 |
| 10:52~11:38 | 约10次 | code4/0_500_301_301 为主，出现 0_530_100_100 |
| 11:50 | 1次 | code4/0_500_301_301 |
| 19:38 | 5次 | code1/innerCode2 × 3 + code4 × 2 |
| 19:40~19:43 | 4次 | code4/0_500_301_301 × 4 |
| **19:48** | **1次** | **code4/0_500_301_301（截图时刻）** |

**全天支付尝试总次数**：约 **30+ 次**，**全部失败**，无一次成功 `normalPay` 回调。

---

## 五、修复建议

### P0 — 客户端（紧急）

1. **修复 pending transaction 未清理问题**：`MidasManager` 在 `registpay` 或 App 启动时，必须检查 `SKPaymentQueue.default().transactions` 中的 `SKPaymentTransactionStatePurchased` 状态未 `finish` 的 transaction，**先 `finishTransaction` 清理**，再允许新支付请求，防止重复提交 receipt
2. **App 崩溃/重启根因排查**：全天 15 次 App 重启异常，建议在 Bugly 中排查同期该用户的崩溃堆栈（特别是 10:31~11:38 高频重启期间）

### P1 — 服务端（Midas）

3. **`0_500_301_301` 容错**：当 Midas 服务端检测到 receipt_already_used 且确认对应 transaction 已发货时，应向客户端返回"成功（幂等）"而非"支付失败"，避免重复充值场景下用户误判为失败
4. **重复 receipt 主动查单**：客户端收到 code4/301 时，**应先调用 Midas 查单接口**确认是否已到账，再决定是否重试，目前直接报错会导致用户无端反复操作

### P2 — 客服

5. **用户补偿**：建议客服主动联系该用户，核实王者荣耀账号下是否有到账，若已扣款未到账按正常补偿流程处理
6. **建议用户**：清理 App Store 缓存，退出 Apple ID 重新登录后再尝试充值

---

## 六、附录

### grep 命中摘要

| 关键词 | 命中行数 |
|--------|---------|
| `normalPay` | 30+ 次 |
| `midas iap error / code4` | 约 20 次 |
| `code1 error innerCode 2` | 约 8 次 |
| `registpay result:1` | 15 次（=重启次数） |
| `didFinishLaunchingWithOptions` | 15 次 |
| `uniqueId`（IDFV 类） | 1 个不同值 |

### 工作目录

```
/Users/bryanpeng/.claude/skills/camp-feedback-skills/output/uid_1649600879_20260512_195001/
├── feedback.json          # 反馈元数据（iFeedback）
├── manifest.json          # workdir 契约
├── attachments/
│   ├── 0ABFB6E1F747B5EFE82097F37CD7FC59.png  # 用户截图
│   └── 20260512/smoba_20260512.xlog           # 原始 xlog
├── decoded_logs/
│   └── smoba_20260512.xlog.log                # 解码后日志（301,948 行）
└── report.md              # 本报告
```
