# 宝宝识字 测试台账

> 由 cs-test-manager 维护。记录所有测试用例的设计与状态。
> 最后更新：2026-04-18

---

## 概览

- 总用例：22 条
- 已实现：5 条（自动化）/ 0 条（手动）
- 计划中：12 条（自动化）/ 5 条（手动）

---

## 汉字学习模块

| # | 测试项 | 方式 | 说明 | 状态 |
|---|--------|------|------|------|
| L1 | 点击「我学会了」→ isLearned 变为 true | 自动 | LearningNotifier.markAsLearned | 计划中 |
| L2 | 学会汉字 → totalStars 正确增加 starsEarned | 自动 | starsEarned=3 时 totalStars += 3 | 计划中 |
| L3 | 重复点击「我学会了」→ stars 不重复累加 | 自动 | isLearned 已为 true 时幂等 | 计划中 |
| L4 | 收藏 / 取消收藏切换 → isFavorite 正确翻转 | 自动 | LearningNotifier.toggleFavorite | 计划中 |
| L5 | 学习进度持久化 → 重启 App 后数据保留 | 手动 | 真机验证 SharedPreferences 持久化 | 计划中 |

## 拼音测验模块

| # | 测试项 | 方式 | 说明 | 状态 |
|---|--------|------|------|------|
| P1 | 答错 → 声母加入 pinyinMistakes | 自动 | LearningNotifier.addPinyinMistake | 计划中 |
| P2 | 答对（错题重练）→ 声母从 pinyinMistakes 移除 | 自动 | LearningNotifier.removePinyinMistake | 计划中 |
| P3 | 清除全部错题 → pinyinMistakes 为空 | 自动 | LearningNotifier.clearPinyinMistakes | 计划中 |
| P4 | 倒计时到零 → 自动判错 + 进入下一题 | 手动 | 等待计时器触发，需真机观察 | 计划中 |

## 汉字测验模块

| # | 测试项 | 方式 | 说明 | 状态 |
|---|--------|------|------|------|
| H1 | 答对 ≥ 70% → 关卡标记为已通关 | 自动 | LearningNotifier.markHanziLevelPassed | 计划中 |
| H2 | 通过第 1 关 → 第 2 关解锁 | 自动 | isHanziLevelUnlocked(2) 为 true | 计划中 |
| H3 | 错题重练模式 → 仅考察错题集中的字 | 自动 | mistakeMode=true 时 candidateChars 仅来自 hanziQuizMistakes | 计划中 |
| H4 | 最高分更新 → getHanziQuizBestScore 返回更大值 | 自动 | 新分数 > 历史分才更新 | 计划中 |

## 游戏模块

| # | 测试项 | 方式 | 说明 | 状态 |
|---|--------|------|------|------|
| G1 | 图字配对全部配对完成 → 显示结算页 | 手动 | MatchGameScreen 真机操作 | 计划中 |
| G2 | 听音选字答对 → addStars 被调用 | 自动 | ListenGameScreen 答对时 stars 增加 | 计划中 |

## 路由 & 登录模块

| # | 测试项 | 方式 | 说明 | 状态 |
|---|--------|------|------|------|
| R1 | SplashScreen 延迟 2s → 自动跳转 HomeScreen | 手动 | 启动 App 观察路由行为 | 计划中 |
| R2 | 识字详情页返回 → 回到学习网格 | 手动 | context.pop() 验证 | 计划中 |
| A1 | 未登录 + 受保护路由 → redirect 返回 '/login' | 自动 | RouterNotifier.redirect 逻辑 | 已实现 |
| A2 | 已登录 + '/login' → redirect 返回 '/' | 自动 | RouterNotifier.redirect 逻辑 | 已实现 |
| A3 | 公开路由（/splash / /forgot-password）→ redirect 返回 null | 自动 | 白名单不被拦截 | 已实现 |
| A4 | AuthNotifier 初始值反映当前登录状态 | 自动 | build() 返回 AuthManager.isLoggedIn | 已实现 |
| A5 | RouterNotifier 监听器在 auth 状态变化时被触发 | 自动 | addListener → notifyListeners | 已实现 |

---

## 用例状态说明

| 状态 | 含义 |
|---|---|
| `计划中` | TDD 阶段设计好、测试代码尚未编写 |
| `已实现` | 测试代码已就绪，每次运行应通过 |
| `skip` | 暂时跳过，需注明原因 |

> 「通不通过」由每次运行实时输出决定，不持久化到此文件，避免状态过期误导。

---

## 如何运行

```bash
# 单元测试
flutter test

# Widget 测试
flutter test test/widget_test.dart
```

> 目前无 integration_test 目录，手动用例需人工执行后在此台账中记录结论。
