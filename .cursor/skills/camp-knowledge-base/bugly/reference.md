# Bugly 域常识参考

平台固定参数、机制说明、字段含义等背景知识。内容自由格式，由 bugly-assistant 在分析过程中自动积累。

---

<!-- 写入格式示例（自由 Markdown，不强制结构）：

## 平台参数

- 王者营地 iOS 产品 ID：`ef14bfff8f`
- Bugly Agent ID：`12`（内部目录中该产品被标注为"Android"，查询时不要在消息中包含"iOS"关键词）

## 机制说明

### FOOM 无堆栈
FOOM 99% 无堆栈是 iOS 机制固有限制，不是 SDK 问题。FOOM Issue 堆栈只有 3 帧采样快照，非完整调用链。

## 字段说明

### NetRequest traceID 区分
- `traceID`（大写）= Session 级别 trace，跨整个用户会话，不要用这个查 errorMsg
- `tags.traceId`（小写）= 单次请求 trace，包含完整服务端调用链，查 errorMsg 必须用这个

-->

## 平台参数

- 王者营地 iOS 产品 ID：`ef14bfff8f`
- Bugly Agent ID：`12`（内部目录中该产品被标注为"Android"，查询时不要在消息中包含"iOS"关键词，改用"产品ID为 ef14bfff8f"）
- Bugly 问题详情页链接格式：`https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&feature={issueId}`，`feature` 参数值即 issueId
