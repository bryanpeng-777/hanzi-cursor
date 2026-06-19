# Git 提交格式规范

## 提交信息格式要求

### 标准格式
```
<type>(scope): <description> --story=<story_id>
```
或
```
<type>: <description> --story=<story_id>
```

### Bug 修复格式
```
fix(scope): <description> --bug=<bug_id>
```
或
```
fix: <description> --bug=<bug_id>
```

## 参数说明

### type（必填）
提交类型，**只允许以下两种**：
- `feat` - 新功能（包括重构、文档、测试、依赖更新等所有非 bug 修复的变更）
- `fix` - Bug 修复（修复问题、异常）

> 注意：docs、style、refactor、perf、test、chore、revert 等类型均不被允许，一律归并到 feat。

### scope（可选）
提交影响的功能模块或范围，例如：
- `荣耀榜英雄选择面板`
- `依赖` 或 `dependency`
- `模块`
- `database`
- `router`
- `network`
- `ui`

### description（必填）
简洁描述提交内容，建议不超过 20 字。

### TAPD ID（必填）
TAPD 需求或 Bug ID，必须为至少 9 位数字，不能全为 0。

- `fix` 类型必须使用 `--bug=<bug_id>`
- 其他类型必须使用 `--story=<story_id>`

## 示例

### 功能提交
```
feat(荣耀榜英雄选择面板): 新增手势滑动功能 --story=128912475
```

### Bug 修复
```
fix: 更新组件库，Android 动态照片适配同名视频方式 --bug=153348782
```

### 依赖更新
```
feat(dependency): Replace module version --story=123456789
```

### 无作用域
```
feat: 王者万象棋官方tab-flutter重构 --story=128912475
```

## 校验规则

提交信息必须通过 `tools/commit-msg.sh` 钩子校验，主要规则包括：

1. 格式必须符合 `<type>(scope): <description> --<param>=<id>` 的模式
2. type 必须是 `feat` 或 `fix`（其他类型均不允许）
3. 如果 type 是 `fix`，必须使用 `--bug=` 参数
4. 如果 type 不是 `fix`，必须使用 `--story=` 参数
5. TAPD ID 必须至少是 9 位数字
6. TAPD ID 不能全为 0（如 `000000000`）
7. Merge 提交豁免校验

## 常见错误

### 错误 1：类型和参数不匹配
```
feat: 修复登录问题 --bug=123456789  # 错误：feat 应该使用 --story
```
正确：
```
fix: 修复登录问题 --bug=123456789
```

### 错误 2：ID 无效
```
feat: 新增功能 --story=123  # 错误：ID 必须至少 9 位
```
正确：
```
feat: 新增功能 --story=123456789
```

### 错误 3：ID 全为零
```
fix: 修复问题 --bug=000000000  # 错误：ID 不能全为零
```

### 错误 4：格式错误
```
feat: 新增功能--story=123456789  # 错误：缺少空格
```
正确：
```
feat: 新增功能 --story=123456789
```
