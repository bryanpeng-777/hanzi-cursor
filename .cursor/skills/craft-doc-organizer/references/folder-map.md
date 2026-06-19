# Craft Knowledge Base — Folder Classification Map

This file defines the complete folder hierarchy and keyword-based classification rules.
When classifying a document, match its title and content against the keywords listed for each sub-folder.

---

## 1. Tech-iOS

iOS/Objective-C/Swift development knowledge.

| Sub-folder | Keywords & Topics |
|---|---|
| **UIKit-组件与布局** | UIView, UILabel, UIButton, UITableView, UICollectionView, UIScrollView, UIStackView, AutoLayout, Masonry, Frame布局, 约束, 列表, 瀑布流, WKWebView, UIWindow, UINavigationController, 导航栏, TabBar, StatusBar, 控件 |
| **事件与手势** | UITouch, UIControl, 事件响应, 手势, gesture, UIResponder, 响应链, hitTest, 点击, 拖拽, target-action |
| **动画与图形** | 动画, animation, CALayer, CoreGraphics, CoreAnimation, 转场, UIBezierPath, CADisplayLink, Lottie, 渐变, 阴影, 圆角 |
| **网络通信** | TCP, HTTP, HTTPS, FTP, Mars, AFNetworking, URLSession, protobuf, 网络, Socket, DNS, CDN, 数据传输, 请求, 接口, API调用 |
| **多线程与性能** | GCD, NSOperation, RunLoop, 锁, 性能优化, 多线程, 内存, leaks, 线程安全, 信号量, dispatch, 死锁, 卡顿, CPU, 主线程 |
| **源码阅读** | SDWebImage, YYKit, 源码分析, 第三方库源码, AFNetworking源码, Masonry源码, 源码解读 |
| **ObjC-语言特性** | KVC, KVO, Runtime, 方法交换, 关联对象, Swift, Category, Protocol, Block, ARC, MRC, 属性, 内省, 消息转发, isa, class, SEL, IMP, Objective-C语法 |
| **系统能力** | 推送, 证书, AVFoundation, FileManager, UserDefaults, FMDB, CoreData, Keychain, App生命周期, 沙盒, 剪贴板, 相册, 相机, 位置, 通知, HealthKit, StoreKit, 系统权限 |

---

## 2. Tech-Flutter

Flutter/Dart development knowledge.

| Sub-folder | Keywords & Topics |
|---|---|
| **Dart-语法** | Dart语法, Dart语言, Future, async/await, Stream, Isolate, Dart集合, 泛型, mixin, extension |
| **Flutter-框架与组件** | Widget, StatelessWidget, StatefulWidget, InheritedWidget, BuildContext, Key, Element, RenderObject, Flutter渲染, Flutter源码, CustomPaint, Sliver, Navigator, Route, 状态管理, Provider, Riverpod |
| **Flutter-营地实践** | TICA, setState, Flutter营地, PB使用, Flutter指令, Pigeon, CampService, build_runner, 营地Flutter, camp_ui, 混合栈, 路由注册 |
| **Flutter-视频模块** | Flutter视频, Flutter播放器, thumbplayer, 播放器组件, Flutter直播, Flutter投屏 |

---

## 3. Tech-Architecture

Software design and architecture knowledge.

| Sub-folder | Keywords & Topics |
|---|---|
| **设计原则** | SOLID, 单一职责, 开闭原则, 里氏替换, 接口隔离, 依赖倒置, DRY, KISS, YAGNI, 封装, 抽象, 面向对象, 解耦, 高内聚低耦合 |
| **设计模式** | 观察者模式, 策略模式, 工厂模式, 单例, 命令模式, 装饰器, 适配器, 代理模式, MVC, MVP, MVVM, 责任链, 建造者, 模板方法, 状态模式 |
| **架构模式** | MVVM, MVP, VIPER, Clean Architecture, UseCase, Repository, 领域驱动, 模块化, 组件化, 插件化, 微服务, 分层架构 |
| **代码质量** | 代码整洁, 重构, Code Review, 代码规范, 命名, 可读性, 可维护性, 技术债, 单元测试, TDD |

---

## 4. Tech-GameDev

Game development with Unity and related technologies.

| Sub-folder | Keywords & Topics |
|---|---|
| **Unity-基础与引擎** | Unity, 场景搭建, Unity引擎, GameObject, MonoBehaviour, Transform, Prefab, SceneManager, Unity生命周期, 编辑器, Inspector, Physics, Collider, 碰撞检测 |
| **图形与Shader** | Shader, 光照, 图形学, URP, HLSL, ShaderGraph, 渲染管线, 材质, 纹理, 法线贴图, PBR, 后处理, 阴影, 反射 |
| **资源管理** | Addressable, 资源管理, AssetBundle, 打包, WebGL, 热更新, 资源加载, 内存管理, 资源优化, 图集, 压缩 |
| **Puerts-脚本** | Puerts, TypeScript游戏, JS binding, 脚本绑定, TS开发 |
| **KingGuard-项目** | KingGuard, 敌人管线, 地图制作, 游戏开发实践, 关卡设计, 角色制作, 怪物AI, 技能系统, FPS, 2D RPG |

---

## 5. Tech-Toolchain

Developer tools and build systems.

| Sub-folder | Keywords & Topics |
|---|---|
| **CocoaPods与依赖** | CocoaPods, Pod, framework, 静态库, 动态库, podspec, Podfile, 二进制化, 私有源, 依赖管理 |
| **Xcode与调试** | Xcode, LLDB, Instruments, 调试, 断点, Time Profiler, Allocations, 符号化, dSYM, 真机调试, 模拟器 |
| **Git与版本控制** | Git, GitHub, 变基, rebase, merge, 分支, cherry-pick, stash, reflog, submodule, 冲突解决 |
| **效率工具** | Dash, ProcessOn, SQL, Linux, 代理, 小技巧, Terminal, Homebrew, VSCode, Charles, Wireshark, 正则, 脚本, 自动化 |
| **构建与CI** | Docker, JDK, CI/CD, Jenkins, fastlane, 编译, 构建脚本, 打包, 证书管理 |

---

## 6. Project-营地

王者营地 (King's Camp) application business modules.

| Sub-folder | Keywords & Topics |
|---|---|
| **视频模块** | 视频播放, 旋转, TVKPlayer, 投屏, 视频详情, 竖屏, 横屏, 播放器, 弹幕播放, 视频列表, 视频缓存 |
| **直播模块** | 直播, 直播间, 直播推流, 直播拉流, 主播 |
| **开黑模块** | 开黑, 语音, 跨区, 组队, 语音房, 匹配 |
| **大同SDK** | 大同, Midas, 票据, 登录, 微信登录, QQ登录, 支付, 会员, 实名认证, SDK接入 |
| **支付与票据** | 支付, 充值, 票据验证, IAP, Apple Pay |
| **监控与质量** | Crash, ANR, RMonitor, 监控, 日志, 负反馈, 伽利略, Galileo, 性能监控, 卡顿率, 崩溃率, 启动耗时 |
| **AB实验与配置** | AB实验, Shiply, Toggle, 配置, 开关, Feature Flag, 灰度, 实验组 |
| **其他业务** | 弹幕, 聊天, 搜索, 消息, 开黑工具, Hippy, 社区, 帖子, 评论, 分享, 推荐, Feed, 活动, 红点, 皮肤, 英雄, 战绩 |

---

## 7. Project-AI

AI/LLM tools, pipelines, and practices.

| Sub-folder | Keywords & Topics |
|---|---|
| **AI-工具与学习** | ChatGPT, Cursor, Midjourney, AI工具, 模型, Claude, GPT, Copilot, Stable Diffusion, Prompt, LLM, 大模型, AI学习, AI入门 |
| **AI-管线与流水线** | AI管线, 流水线, Pipeline, 角色制作流水线, AI工作流, ComfyUI, ControlNet, 自动化管线 |
| **AI-落地实践** | AI落地, AI实践, AI产品, AI集成, AI辅助开发, AI效率提升 |

---

## 8. Archive-工作记录

Time-based work records and archives.

| Sub-folder | Keywords & Topics |
|---|---|
| **2026** | 2026年工作记录, 当前年度 |
| **2025** | 2025年工作记录 |
| **2024** | 2024年工作记录 |
| **2022-2023** | 2022-2023年工作记录, OKR |
| **工作日志** | 会议, 需求排期, 月会, 日常工作, 周报, 日报, TODO, 工作计划, 排期, 例会 |

Classification hint: documents with explicit year references (e.g., "2025Q3总结") go into the corresponding year sub-folder. Generic work notes without a clear year go to "工作日志".

---

## 9. Growth-方法论

Personal growth, learning, and philosophical reflections.

| Sub-folder | Keywords & Topics |
|---|---|
| **学习方法** | 学习法, 书籍, 训练, 主题学习, 费曼, 刻意练习, 笔记方法, 知识管理, 记忆, 复习, 读书笔记 |
| **编程感悟** | 效率, 高效开发, 延迟启动, 编码领悟, 技术成长, 工程师思维, 编程哲学, 代码人生 |
| **人生思考** | 人生, 思考, 努力, 方法论, 沟通, 目标, 规划, 心态, 成长, 反思, 坚持, 自律, 习惯, 动力, 职业发展, 价值观 |
| **思维模式** | 第一性原理, 批判性思维, 系统思维, 复利, 逆向思维, 心智模型 |
| **沟通与表达** | 沟通, 演讲, 表达, 汇报, PPT, 写作, 向上管理, 跨团队协作 |

---

## 10. Life-个人

Personal life, finance, and private records.

| Sub-folder | Keywords & Topics |
|---|---|
| **投资理财** | 股票, 财报, GDP, 投资, 基金, 理财, 保险, 房产, 税务, 期权, 复利 |
| **健康与运动** | 运动, 健身, 跑步, 饮食, 睡眠, 体检, 健康, 心理 |
| **生活记录** | 生活, 装修, 搬家, 月嫂, 旅行, 美食, 购物, 日常, 家庭, 育儿 |
| **账号与密码** | 密码, 账号, API Key, 序列号, 证书, token, 密钥 |

---

## Classification Tips

1. **Title-first**: Most documents can be classified by title alone. Only read content when the title is ambiguous (e.g., "笔记", "新文档", single character titles).
2. **Keyword overlap**: Some documents could fit multiple categories. Use the primary topic to decide. For example, "Flutter性能优化" → `Tech-Flutter/Flutter-营地实践` (Flutter is the primary domain), not `Tech-iOS/多线程与性能`.
3. **Business vs. Tech**: If a document discusses a technical solution within 营地's business context, prefer `Project-营地`. If it's a general technical note that happens to use 营地 as an example, prefer the appropriate `Tech-*` folder.
4. **Time-stamped content**: Documents with dates in titles (e.g., "0301周会", "2025Q2总结") → `Archive-工作记录` under the appropriate year.
5. **Catch-all**: If nothing matches well, present the document as "需确认" and let the user decide.
