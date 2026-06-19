# galileo-trace

`galileo-trace` 是伽利略（Galileo）CLI 的 trace skill，用于检索 trace 列表、span 列表，或按多个 traceID 批量查询完整 trace 信息。

它主要覆盖两类能力：

- 按条件检索 trace 列表
- 按条件检索 span 列表
- 在终端快速查看 trace 摘要
- 将完整 trace 数据导出到本地文件

这个 skill 适合以下场景：

- 先按时间窗和查询条件找 trace，再决定要不要拿完整链路
- 按时间窗和查询条件直接看 span 明细
- 已经拿到一个或多个 traceID，需要补全完整链路信息
- 需要查看完整 span、事件、请求体或回包体
- 需要把完整 trace 数据落文件后做进一步分析

这个 skill 的核心调用入口是：

```bash
galileo trace list --query '...' --input '{...}'
galileo trace list-spans --query '...' --input '{...}'
galileo trace batch-get --input '{...}'
```

使用这个 skill 之前，建议先完成共享前置步骤：

- 安装 `galileo`
- 配置 token
- 确认 `galileo auth status` 显示已登录

这些前置操作由 `galileo-shared` 负责。

补充说明：

- `trace list` 的 `limit` 只是返回上限，不保证一定返回这么多条
- `trace list-spans` 默认返回完整 span 明细，支持 `cursor` 续跑
- 实际返回数量取决于时间窗、query 和后端命中结果
- 如果你需要的是完整 trace 查询和导出，请优先使用这个 skill
