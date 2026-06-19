# galileo-log

`galileo-log` 是伽利略（Galileo）CLI 的日志 skill，用于查询、导出和分析 Galileo 日志。

当前最低依赖的 Galileo CLI 版本为 `v1.0.7`。

它主要覆盖四类能力：

- 小批量日志查询
- 大批量日志导出
- tag 分布统计
- 日志正文模板聚类

这个 skill 适合以下场景：

- 需要快速查看某个 target 的最近错误日志
- 需要把日志批量导出到本地文件再做进一步分析
- 需要统计某些 tag 的值分布
- 需要对日志正文做模板聚类，定位主要错误模式

这个 skill 的核心调用入口是：

```bash
galileo logs <subcommand> --query '<dsl>' --input '{...}'
```

其中 `logs query` 和 `logs export` 支持 `sort_type`，可选值为 `asc` / `desc`，默认 `asc`。

使用这个 skill 之前，建议先完成共享前置步骤：

- 安装 `galileo`
- 配置 token
- 确认 `galileo auth status` 显示已登录

这些前置操作由 `galileo-shared` 负责。

如果你需要的是日志排查、日志导出或日志分析，请优先使用这个 skill。
