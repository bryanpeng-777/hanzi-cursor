---
name: galileo-trace
description: 当用户需要检索 trace 列表、span 列表，或已经有一个或多个 trace ID 需要批量查询完整 trace 详情时使用；内部通过 Galileo CLI 实现，适用于 Galileo CLI 的 trace list / trace list-spans / trace batch-get 命令。
---

# galileo trace

> PREREQUISITE: 先使用 `../galileo-shared/SKILL.md`，完成安装、鉴权、全局约定和安全规则检查。
> VERSION: 本 Skill 依赖 `v1.0.7` 及以上版本的 Galileo CLI；如果版本不满足，请根据 `../galileo-shared/SKILL.md` 重新下载安装最新 CLI。

    galileo trace list --query '...' --input '{...}'
    galileo trace list-spans --query '...' --input '{...}'
    galileo trace batch-get --input '{...}'

## Helper Commands

- `list`：按时间窗和查询语句检索 trace 列表，可按需附带完整 trace
- `list-spans`：按时间窗和查询语句检索 span 列表
- `batch-get`：按多个 `trace_id` 批量查询完整 trace

## Core Conventions

- `trace batch-get` 不使用 `--query`
- 业务参数统一放在 `--input` JSON 中
- `namespace` 支持 `Production` / `Development`，默认 `Production`
- `trace_ids` 必填，最大支持 `10` 个
- 请求后端时固定并发 `5`
- 不传 `output` 时输出终端摘要
- 传 `output` 时写完整 trace 数据到文件
- `format` 只在 `output` 存在时生效，支持 `json` / `jsonl`
- span 内部统一使用 `events` 命名，不沿用 PB 的 `logs`

## List

`galileo trace list` 适合先按条件搜索 trace，再决定是否需要完整链路数据。

输入和校验约定：

- `trace list` 使用 `--query` 承载检索语句，其余业务参数放在 `--input`
- `start` / `end` 必填
- `namespace` 支持 `Production` / `Development`，默认 `Production`
- 默认 `limit=10`
- 普通模式下 `limit` 最大为 `100`
- `full_data=true` 时，`limit` 最大为 `5`
- `limit` 只是返回上限，不保证一定返回这么多条；实际返回数量取决于时间窗、query 和后端命中结果
- 支持 `output` / `format` 导出结果，`format` 支持 `json` / `jsonl`

终端输出默认返回：

- `count`
- `items`
- `cursor`

每个 `item` 默认包含：

- `trace_id`
- `duration`
- `start_time`
- `end_time`
- `current_operation`
- `top_operation`
- `services`

如果传 `full_data=true`，每个 `item` 还会附带：

- `trace`

示例：

```bash
galileo trace list \
  --query 'env:formal' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "limit": 10,
    "full_data": false
  }'
```

如果需要导出：

```bash
galileo trace list \
  --query 'env:formal' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "limit": 5,
    "full_data": false,
    "output": "./trace-list.jsonl",
    "format": "jsonl"
  }'
```

## Batch Get

`galileo trace batch-get` 适合已知 traceID 时，批量拿完整 trace 数据。

终端输出适合先看摘要：

- `trace_id`
- `service_count`
- `span_count`
- `ignored_span_cnt`
- `root_operations`
- `error_span_count`

示例：

```bash
galileo trace batch-get \
  --input '{
    "trace_ids": ["trace-id-1", "trace-id-2"],
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "ignore_span_events": false
  }'
```

## Export

如果需要完整 trace 数据，传入 `output` 导出到文件：

```bash
galileo trace batch-get \
  --input '{
    "trace_ids": ["trace-id-1", "trace-id-2"],
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "ignore_span_events": false,
    "output": "./traces.json",
    "format": "json"
  }'
```

导出规则：

- `json`：整体输出为数组
- `jsonl`：一行一个 trace
- 导出结果保留完整 trace 内容，不做摘要裁剪

## List Spans

`galileo trace list-spans` 适合按时间窗和查询语句直接检索 span 明细。

输入和校验约定：

- `trace list-spans` 使用 `--query` 承载检索语句，其余业务参数放在 `--input`
- `start` / `end` / `target` 必填
- `namespace` 支持 `Production` / `Development`，默认 `Production`
- 默认 `limit=10`
- `limit` 最大为 `100`
- `sort_type` 仅支持 `asc` / `desc`
- 支持 `need_more_data`
- 支持 `output` / `format` 导出结果，`format` 支持 `json` / `jsonl`

终端输出默认返回：

- `count`
- `items`
- `cursor`

每个 `item` 是完整归一化 span，包含：

- `trace_id`
- `span_id`
- `parent_span_id`
- `operation_name`
- `start_time`
- `duration`
- `tags`
- `events`
- `process`

示例：

```bash
galileo trace list-spans \
  --query 'status.code=2' \
  --input '{
    "start": "-2h",
    "end": "now",
    "target": "PCG-123.galileo.apiserver",
    "namespace": "Production",
    "limit": 10,
    "sort_type": "asc"
  }'
```

## Discovering Commands

当不确定命令参数时，优先查看 help：

```bash
galileo trace -h
galileo trace list -h
galileo trace list-spans -h
galileo trace batch-get -h
```
