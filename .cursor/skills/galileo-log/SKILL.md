---
name: galileo-log
description: 当用户需要查询、导出或分析 Galileo 日志时使用，包括导出大量日志数据、统计 tags、聚类日志模板；内部通过 Galileo CLI 实现，适用于 Galileo CLI 的 logs query、logs export 和 logs analyze 等命令。
---

# galileo logs

> PREREQUISITE: 先使用 `../galileo-shared/SKILL.md`，完成安装、鉴权、全局约定和安全规则检查。
> VERSION: 本 Skill 依赖 `v1.0.7` 及以上版本的 Galileo CLI；如果版本不满足，请根据 `../galileo-shared/SKILL.md` 重新下载安装最新 CLI。

    galileo logs <subcommand> --query '<dsl>' --input '{...}'

## Helper Commands

- `query`：小批量查询日志，适合终端查看
- `export`：批量导出原始日志到本地文件
- `analyze tags`：统计指定 tag 的分布
- `analyze templates`：对日志正文做模板聚类
- `syntax`：查看日志 DSL 语法速查

## Core Conventions

- 日志过滤入口统一使用 `--query`
- 除 `--query` 外，其他业务参数统一放在 `--input` JSON 中
- `target` 对外只传单个值
- `namespace` 支持 `Production` / `Development`，默认 `Production`
- `start` / `end` 支持 RFC3339 绝对时间，以及 `-2h`、`-30m`、`now` 这类相对时间
- `logs query` / `logs export` 支持 `sort_type`
- `sort_type` 仅支持 `asc` / `desc`，默认 `asc`

## Query Syntax

`--query` 使用 Galileo 日志 DSL。常见写法：

- 分词检索：`message:test`
- 精确检索：`level = debug`
- 短语检索：`message:"my test message"`
- 正则检索：`message:/my.*log/`
- 存在检索：`level:*`
- 不存在检索：`not level:*`
- 不等于检索：`not level = debug`

避免这些容易出错的写法：

- 不要传裸 `*`
- 不要把 `*` 当作“查询全部”的通配符
- 不确定时先用明确条件，例如 `level:error`

不确定语法时，先执行 syntax 了解更多语法：

```bash
galileo logs syntax
```

## Query

`galileo logs query` 适合交互式查看小批量结果。

- 默认返回 `1` 条
- 最大支持 `100` 条
- 输出固定为 `json`
- 支持 `sort_type`，可选 `asc` / `desc`

示例：

```bash
galileo logs query \
  --query 'level:error' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "limit": 1,
    "sort_type": "asc"
  }'
```

## Export

`galileo logs export` 适合批量导出原始日志到文件。

- 默认导出 `100` 条
- 最大支持 `2000` 条
- 只有 `export` 支持 `format`
- `format` 支持 `jsonl` / `json`
- 内部按每页 `200` 条自动翻页，可能触发多次后端请求并消耗多次限频
- 返回结果会包含 `next_cursor`，下次可以放回 `cursor` 继续导出
- 支持 `sort_type`，可选 `asc` / `desc`

示例：

```bash
galileo logs export \
  --query 'level:error' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "limit": 100,
    "sort_type": "desc",
    "cursor": "",
    "output": "./logs.jsonl",
    "format": "jsonl"
  }'
```

## Analyze

### tags

`galileo logs analyze tags` 用于查看 tag 分布。

```bash
galileo logs analyze tags \
  --query 'level:error' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "tags": ["timestamp"]
  }'
```

### templates

`galileo logs analyze templates` 用于查看正文模板聚类。

```bash
galileo logs analyze templates \
  --query 'level:error' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "tags": ["timestamp"]
  }'
```

## Trace Logs

如果查询条件命中 `traceID`，并且需要跨 target 拉取关联日志，必须显式开启：

```json
{
  "trace_all_targets": true
}
```

这个能力会增加查询成本，不要默认开启。

## Discovering Commands

当不确定某个子命令支持哪些参数时，优先查看 help：

```bash
galileo logs -h
galileo logs query -h
galileo logs export -h
galileo logs analyze tags -h
galileo logs analyze templates -h
```
