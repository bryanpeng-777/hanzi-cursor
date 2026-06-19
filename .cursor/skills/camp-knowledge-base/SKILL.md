---
name: camp-knowledge-base
description: 营地问题分析体系的共享知识库。包含两类知识：(1) 动态数据：企业微信文档中的App开发组问题看板、伽利略告警记录（camp域）；(2) 静态规范：各域 reference/patterns 手工知识（galileo/dev/bugly域）。调用时指定 domain 参数加载对应域全部文件。触发词：camp-knowledge-base、加载知识库、读取知识、domain=camp/galileo/dev/bugly。
---

# camp-knowledge-base — 营地问题分析共享知识库

## 调用方式

调用方传入 `domain` 参数（camp / galileo / dev / bugly），按下方索引读取对应文件并返回全部内容。

---

## Domain 索引

### domain=camp（营地问题分析主知识库）

读取以下文件全部内容：

- `camp/reference.md` — 时间处理规范、userId 格式说明、伽利略 MCP 使用规范等常识（**必读**）
- `camp/problem-patterns.md` — 已知问题模式库（如 Flutter PlatformView ANR 等历史案例）
- `camp/wecom-tab-aWXCa2.md` — App开发组日常问题看板（大前端 Flutter）
- `camp/wecom-tab-q979lj.md` — App开发组日常问题看板（终端组）
- `camp/wecom-tab-NqfRyZ.md` — 伽利略日常问题处理记录（新P0、P1告警记录）
- `camp/wecom-tab-c8Rt7x.md` — 伽利略日常问题处理记录（NGR上线期间P0、P1）
- `camp/wecom-tab-BN9bzM.md` — 伽利略日常问题处理记录（问题记录）

### domain=galileo（伽利略告警分析知识）

- `galileo/reference.md` — 告警分析常识参考
- `galileo/alert-analysis-guide.md` — 告警分析指南
- `galileo/false-alarm-patterns.md` — 已知误报模式

### domain=dev（代码开发模式知识）

- `dev/reference.md` — 开发规范参考
- `dev/dev-patterns.md` — 已知开发问题模式

### domain=bugly（Bugly 异常分析知识）

- `bugly/reference.md` — Bugly 分析常识参考
- `bugly/crash-patterns.md` — 已知 Crash 模式
- `bugly/anr-patterns.md` — 已知 ANR 模式
- `bugly/foom-patterns.md` — 已知 FOOM 模式

---

## 执行步骤

1. 根据调用方传入的 `domain` 参数，确定对应文件列表
2. 逐个 Read 对应文件，将内容合并返回
3. 若 domain 未指定，默认返回 `camp` 域全部文件

---

## 注意事项

- 知识库由 `build-knowledge.sh` 定期重新打包（建议每周一次）
- `camp/wecom-tab-*.md` 为企业微信文档缓存，内容包含内部业务数据，不得泄漏到外部
- 若某文件不存在（如静态 patterns 为空），跳过该文件继续处理，不报错
