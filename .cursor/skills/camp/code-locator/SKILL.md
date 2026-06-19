---
name: code-locator
description: 快速定位营地（王者营地）代码位置的专家。当用户描述某个功能异常、想排查某个业务逻辑、或问"这个功能的代码在哪里"时触发。通过四层索引体系（L1总索引→L2域详情→L3场景索引→L4代码读取）精确锁定模块路径，避免全局搜索。触发关键词："这个功能在哪"、"排查XXX问题"、"XXX的代码在哪"、"定位XXX模块"、"XXX的实现在哪"、"帮我找XXX相关代码"、"我想查XXX的逻辑"。也可作为其他 skill（bugfix、verify-code-changes、production-risk-checker 等）在「定位代码」步骤的辅助工具被内部调用。
---

# Code Locator - 营地代码快速定位（四层索引 + 多模式加速）

## 四层索引架构

```
Layer 1  CODE_MAP_INDEX.md   ← 总索引，5个超级分类 + 逆向查找表 + 模糊词速查
   ↓ 命中超级分类后
Layer 2  L2_xxx.md           ← 域级详情，5个文件，28个域的模块路径 + 关键文件
   ↓ 命中具体域后
Layer 3  L3_xxx.md           ← 场景索引，27个文件，场景描述 → 入口文件
   ↓ 命中具体场景后
Layer 4  Read 实际代码文件    ← 精准读取具体文件，分析代码逻辑
```

**设计原则**：每次只加载必要的那一层，不做全量扫描。

---

## 三种定位模式（按输入类型自动选择）

### 模式 A：场景描述定位（默认）

用户描述功能场景或问题 → 走 L1→L2→L3→L4 标准流程。

### 模式 B：Crash 堆栈 / 文件名定位（快速通道）

用户提供 crash 堆栈或明确文件名 → **跳过 L1/L2/L3，直接定位**：

1. 从堆栈提取文件名（如 `WEGChatRoomImp.m`、`ChatPage.dart`）
2. 查 L1 的 **Imp 逆向查找表** 或 **Features 目录映射** → 确认所属域
3. 如需更多上下文，读对应 L3 文件获取关联文件
4. 直接 Read 代码文件

**Imp 逆向查找表**（31个 Imp 文件 → 域映射）：

| Imp 文件 | 所属域 | L3 文件 |
|---------|--------|---------|
| `WEGLoginImp.m` | 登录 | L3_login |
| `WEGUserImp.m` | 登录/账号 | L3_login |
| `WEGProfileImp.m` | 个人主页 | L3_profile |
| `WEGRemarksImp.m` | 个人主页 | L3_profile |
| `WEGRecommendUserImp.m` | 社交 | L3_social |
| `WEGChatRoomImp.m` | 聊天 | L3_chat |
| `WEGChatMessageToolImp.m` | 聊天 | L3_chat |
| `WEGMessageImp.mm` | 聊天 | L3_chat |
| `WEGSearchImp.m` | 搜索 | L3_search |
| `WEGEditorImp.m` | 编辑器 | L3_editor |
| `WEGShareImp2.m` | 分享 | L3_share |
| `WEGNewsImp.m` | 社区/资讯 | L3_community |
| `WEGNewsManagerImp.m` | 社区/资讯 | L3_community |
| `WEGNewsSubjectImp.m` | 社区/资讯 | L3_community |
| `WEGGameImp.m` | 游戏广场 | L3_gamezone |
| `WEGGangUpImp.m` | 组队 | L3_team |
| `WEGEquipImp.m` | 英雄/装备 | L3_hero |
| `WEGFullScreenVideoImp.m` | 短视频 | L3_video |
| `WEGStoreProductImp.m` | 商城 | L3_commerce |
| `WEGProtobufRequestImp.m` | 网络 | L3_network |
| `WEGCommonImp.m` | 基础组件 | L3_common |
| `WEGBaseVCImp.m` | 基础组件 | L3_common |
| `WEGSmobaHelperCommonImp.m` | 基础组件 | L3_common |
| `WEGSmobaHelperImp.m` | 启动/路由 | L3_launch |
| `WEGSmobaHelperMinimizeImp.m` | 启动/路由 | L3_launch |
| `WEGSmobaHelperEnvironmentImp.m` | 设置 | L3_setting |
| `WEGABTestImp.m` | 启动/路由 | L3_launch |
| `WEGADManagerImp.m` | 基础组件 | L3_common |
| `WEGAnniversaryImp.m` | 活动 | L3_activity |
| `WEGMTANewsReportImp.m` | 监控 | L3_monitor |
| `WEGSmobaHelperTestImp.m` | 设置 | L3_setting |

### 模式 C：类名 / 方法名定位（精准搜索）

用户给出具体类名或方法名 → **有限范围 grep**：

1. 先猜测所属域（从类名前缀推断：`WEG` = iOS Feature，`Camp` = Flutter 公共组件）
2. 在猜测的域目录内搜索（`rg "ClassName" Features/XxxModule/`）
3. 未命中则扩大到 `Features/Imps/` 全部 Imp 文件搜索
4. 仍未命中则走标准 L1→L2→L3 流程

---

## 标准定位流程（模式 A 详细步骤）

### Step 1：读取 Layer 1 总索引

**立即**读取 `/Users/bryanpeng/.claude/skills/camp/code-locator/CODE_MAP_INDEX.md`

从中提取：
- 该功能属于哪个**超级分类**（用户社交 / 内容创作 / 媒体游戏 / 商业化 / 技术基础设施）
- 对应的 **L2 文件** 和 **L3 文件**

**加速规则**：如果用户描述直接命中 L1 中某域的关键词，**可跳过 L2 直接读 L3**。

---

### Step 2：读取 Layer 2 域级详情（可选跳过）

| 超级分类 | L2 文件 |
|---------|---------|
| 用户与社交 | `L2_USER_SOCIAL.md` |
| 内容与创作 | `L2_CONTENT.md` |
| 媒体与游戏 | `L2_GAME.md` |
| 商业化 | `L2_COMMERCE.md` |
| 技术基础设施 | `L2_INFRA.md` |

> 当用户描述清晰（如"聊天发消息失败"）时，**直接跳到 Step 3**。

---

### Step 3：读取 Layer 3 场景索引（核心步骤）

| 域 | L3 文件 |
|---|---------|
| 登录/账号 | `L3_login.md` |
| 用户中心/个人主页 | `L3_profile.md` |
| 社交/好友关系 | `L3_social.md` |
| 聊天/消息 | `L3_chat.md` |
| 通知/消息中心 | `L3_notify.md` |
| 举报/黑名单 | `L3_report.md` |
| 动态/Feed | `L3_feed.md` |
| 社区/话题/专栏 | `L3_community.md` |
| 搜索 | `L3_search.md` |
| 分享 | `L3_share.md` |
| 内容编辑器/发布 | `L3_editor.md` |
| 活动/运营 | `L3_activity.md` |
| 直播 | `L3_live.md` |
| 短视频 | `L3_video.md` |
| 战绩/对局 | `L3_battle.md` |
| 英雄/装备 | `L3_hero.md` |
| 赛事 | `L3_esport.md` |
| 组队/约战 | `L3_team.md` |
| 游戏广场/游戏区 | `L3_gamezone.md` |
| 战队/俱乐部主页 | `L3_team_profile.md` |
| 商城/道具/充值（含个人商城） | `L3_commerce.md` |
| 启动/初始化/路由 | `L3_launch.md` |
| Flutter-Native通信层 | `L3_bridge.md` |
| 网络/OneAPI/接口层 | `L3_network.md` |
| 基础组件/公共模块 | `L3_common.md` |
| 性能监控/埋点 | `L3_monitor.md` |
| 设置/隐私 | `L3_setting.md` |

所有 L3 文件路径前缀：`/Users/bryanpeng/.claude/skills/camp/code-locator/`

```
【L3 场景匹配结论】
匹配场景：XXX
入口文件：social-ios/src/GameApp/Features/XXX/WEGXxxImp.m
查找提示：搜索 "methodName" 方法
关联文件：flutter_module/lib/xxx/（Flutter 侧对应实现）
```

---

### Step 4：Layer 4 精准读取代码文件

优先顺序：
1. **L3 指定的入口文件**（首选）
2. **Imp 文件**（iOS 入口协议实现）：`Features/Imps/WEGXxxImp.m`
3. **目录主文件**（与目录同名的 `.dart` / `.m`）
4. **报错堆栈优先**：有明确堆栈时，按堆栈文件名直接定位

---

### Step 5：输出定位结论

```
【代码定位结论】

主要实现位置：
  [文件路径:行号] 描述

关联文件：
  [文件路径] 描述

下一步建议：
  - 重点关注：XXX 函数 / 类 / 方法
  - 需要追踪的数据流：A → B → C
```

---

## 关键架构知识（提升定位准确度）

### Flutter 三层目录关系

```
lib/business/X/     ← 路由入口层（58个子目录，每个为独立页面入口，含 TRouter 路由注册）
lib/X/              ← 业务实现层（核心逻辑、页面、ViewModel、Repository）
lib/camp_business/   ← 公共业务层（跨模块复用的组件/网络/类型/基座）
packages/            ← 独立 Package（camp_common 工具库、camp_ui 组件库）
```

**重要**：`lib/business/chat/` 只是 `lib/chat/` 的路由入口包装，核心逻辑在 `lib/chat/`。

### iOS 五大代码区域

```
Features/Imps/       ← 31 个 Imp 协议实现文件（iOS 功能入口，最佳切入点）
Features/XxxModule/  ← 独立功能模块（65+ 个目录）
Features/Manager/    ← 管理器类（30 个，全局单例服务）
Features/Component/  ← UI/功能组件（15 个，可复用组件）
xcodeproj/XxxPod/    ← CocoaPods 子工程（20+ 个，核心基础库）
```

### 跨端对应关系

| Flutter 目录 | iOS 目录 | 说明 |
|-------------|---------|------|
| `lib/chat/` | `Features/Imps/WEGChatRoomImp.m` + `Features/Channel/` | 聊天 |
| `lib/camp_login/` | `Features/CampLogin/` + `WEGLoginImp.m` | 登录 |
| `lib/gangup/` | `Features/WEGGangUp/` + `WEGGangUpImp.m` | 组队 |
| `lib/mall/` | `WEGStoreProductImp.m` | 商城 |
| `lib/camp_business/share/` | `Features/CampShare/` + `WEGShareImp2.m` | 分享 |
| `lib/camp_webview/` | `Features/webHook/` | WebView |
| `lib/trouter/` | `Features/FlutterRouteUtils/` | 路由通信 |
| `packages/camp_ui/` | `Features/WEGUI/` | UI 组件库 |
| `packages/camp_common/` | `Features/Common/` + `xcodeproj/CampCore/` | 公共工具 |

---

## 歧义消解规则

| 用户说的词 | 可能的域（按上下文选择） | 消解策略 |
|----------|-------------------|---------| 
| "消息" | 聊天消息 vs 系统通知 vs Push推送 | 有"发/收/撤回" → 聊天；有"通知/提醒/红点" → 通知 |
| "首页" | 推荐首页(Feed) vs 游戏广场 vs 个人主页 | 有"内容/帖子/卡片" → Feed；有"游戏/战力" → 游戏广场 |
| "分享" | 分享面板 vs 战绩分享 vs 直播分享 | 先定位核心功能域，分享是附属动作 |
| "卡片" | Feed卡片 vs 名片 vs 商品卡片 | 有"列表/流" → Feed；有"个人/名片" → 个人主页 |
| "视频" | 短视频 vs 直播 vs 视频消息 | 有"播放/列表" → 短视频；有"直播间" → 直播；有"聊天" → 聊天 |
| "搜索" | 全局搜索 vs 游戏昵称搜索 | 有"昵称/游戏好友" → 游戏昵称搜索；否则 → 全局搜索 |
| "设置" | 用户设置 vs 隐私设置 vs 环境配置 | 有"环境/测试/正式" → 环境配置；否则 → 通用设置 |
| "频道" | IM频道/群 vs 直播频道 | 有"群消息/群聊" → 聊天域 Channel；有"直播" → 直播域 |
| "刷新" | 下拉刷新 vs 数据刷新 vs 登录态刷新 | 看上下文中的功能场景 |
| "crash" | 任意域 | 必须看堆栈，使用模式 B 快速通道 |

---

## 降级搜索策略（索引未覆盖时）

当 L1→L3 均未命中时，**按以下顺序做有限范围搜索**（不做全局扫描）：

1. **从关键词推断目录名**：用户说"XX功能" → 尝试 `ls flutter_module/lib/ | rg -i "XX"` 
2. **搜索 TRouter 路由表**：`rg "关键词" flutter_module/lib/trouter/t_router_register.t_router.dart` → 从路由名反查页面
3. **搜索 Imp 文件**：`rg "关键词" social-ios/src/GameApp/Features/Imps/` → 31个Imp文件是iOS功能总入口
4. **搜索 Pigeon 接口**：`rg "关键词" flutter_module/pigeons/` → 跨端通信接口定义
5. **Feature 目录名模糊匹配**：`ls social-ios/src/GameApp/Features/ | rg -i "关键词"`

**命中后立即更新对应 L3 文件**，避免下次重复降级。

---

## 注意事项

- **四层索引是权威路径**：L1 → L2 → L3 → L4，不得跳过 L1 直接猜路径（模式B/C除外）
- **iOS 和 Flutter 是两套并行实现**：某功能可能在两侧都有代码，注意区分
- **Imp 文件是 iOS 侧统一入口**：`Features/Imps/WEGXxxImp.m` 适合作为 iOS 功能切入点
- **Flutter 路由入口**：`lib/trouter/` 是 TRouter 路由注册，可从路由名反查页面
- **跨分类功能**：部分功能横跨多个 L2（如"战绩分享"涉及 L2_GAME + L2_CONTENT），需两个 L2 都查
- **lib/business/ 是路由入口层**：不含核心逻辑，核心逻辑在 `lib/同名目录/`

---

## 作为辅助工具被其他 Skill 调用

其他 skill 在需要定位代码时，**无需重新读取 SKILL.md**，只需执行：

1. 读 `CODE_MAP_INDEX.md` → 命中超级分类 + L3 文件名
2. 读对应 L3 文件 → 场景匹配 → 入口文件
3. Read 具体代码文件

**调用方式模板**（在其他 skill 中写入）：

```
> 代码定位（四层索引）：
> 1. 读 /Users/bryanpeng/.claude/skills/camp/code-locator/CODE_MAP_INDEX.md → 找到域 + L3 文件
> 2. 读对应 L3_xxx.md → 场景匹配找到入口文件
> 3. Read 具体代码文件，不做全局搜索
```

---

## 索引更新协议

发现以下情况时，**立即同步更新**对应层级文件：

1. 发现了 L1/L2/L3 中未收录的新场景、模块或路径
2. 某路径已移动或重命名
3. 遇到新的典型排查场景，应补录到 L3
4. 降级搜索命中了新路径

| 更新场景 | 需更新的文件 |
|---------|------------|
| 新增超级分类 | L1 + 新建 L2 + 新建 L3 |
| 新增模块路径 | 对应 L2 + L1 关键词列 |
| 新增排查场景 | 对应 L3（最常用的更新） |
| 路径变更 | 对应 L2 + L3 入口文件列 |
| 降级命中新路径 | L3 + L1 关键词列 |

**索引文件路径**（均在 `/Users/bryanpeng/.claude/skills/camp/code-locator/`）：
- L1：`CODE_MAP_INDEX.md`
- L2（5个）：`L2_USER_SOCIAL.md` / `L2_CONTENT.md` / `L2_GAME.md` / `L2_COMMERCE.md` / `L2_INFRA.md`
- L3（27个）：`L3_login.md` / `L3_profile.md` / `L3_social.md` / `L3_chat.md` / `L3_notify.md` / `L3_report.md` / `L3_feed.md` / `L3_community.md` / `L3_search.md` / `L3_share.md` / `L3_editor.md` / `L3_activity.md` / `L3_live.md` / `L3_video.md` / `L3_battle.md` / `L3_hero.md` / `L3_esport.md` / `L3_team.md` / `L3_gamezone.md` / `L3_team_profile.md` / `L3_commerce.md` / `L3_launch.md` / `L3_bridge.md` / `L3_network.md` / `L3_common.md` / `L3_monitor.md` / `L3_setting.md`
