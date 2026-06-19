# dev-assistant diff-rules

最后同步时间：2026-06-17

## 已删除/简化的内容

### 1. 本地知识文件读取 → 替换为 camp-knowledge-base 技能调用
原文：`~/.claude/knowledge/dev-assistant/shared/reference.md` 等
Knot版：调用 camp-knowledge-base 技能（domain=dev）

### 2. `{project}/rule.md` 项目专属规范读取 → 删除
原文：`~/.claude/knowledge/dev-assistant/{project}/rule.md`（CS框架规范）
Knot版：删除，Knot 上无项目专属路径

### 3. 多个子技能路由 → 简化保留核心两个
原文：bugfix、camp/code-locator、flutter-deps-search、camp/compile、galileo-metric、camp/git-commit
Knot版：保留 bugfix（走 code-locator + 分析）、camp/code-locator 两个核心路由

### 4. `flutter-deps-search`、`camp/compile`、`galileo-metric`、`camp/git-commit` 子技能 → 删除
原文：四个 Flutter/iOS 开发相关子技能的完整流程
Knot版：删除，Knot 版仅提供代码定位和分析功能，不执行实际编译和提交

### 5. 直接修改文件 → 改为给出修改建议
原文：dev-assistant 会直接使用 Write/Edit 工具修改代码文件
Knot版：只提供分析和修复建议，不直接修改文件

### 6. 域知识更新 → 删除
原文：写入 knowledge 目录并 git push
Knot版：删除

### 7. Flutter 引擎源码分析专项流程 → 删除
原文：处理 Flutter 引擎级堆栈的专项分析流程
Knot版：删除，超出 Knot 版本范围
