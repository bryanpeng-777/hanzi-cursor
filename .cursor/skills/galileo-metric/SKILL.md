---
name: galileo-metric
description: 伽利略监控埋点专家入口，用于新建、设计、审查伽利略埋点。当用户提到"新建伽利略埋点"、"设计埋点方案"、"埋点规范"或与 Galileo 监控相关的工作时触发
context: fork
agent: galileo-expert  
---

# 伽利略监控埋点

## 使用说明

此 skill 是伽利略埋点专家的入口点。当用户需要与伽利略监控埋点相关的工作时，将调用 `galileo-expert` subagent 提供专业支持。

### 何时使用

- 新建伽利略埋点
- 设计埋点方案
- 检查埋点代码的规范性和正确性
- 了解伽利略埋点规范和最佳实践
- 修复埋点相关问题
- Galileo 监控相关的任何工作

### 工作流程

当 skill 被触发时，会：

1. 收集用户需求和上下文
2. 调用 `galileo-expert` subagent 进行处理
3. subagent 基于 `/references/galileo.md` 提供专业指导
4. 返回完整的埋点设计方案或审查结果
5. **代码实现后，自动启动 Ralph Loop 做编译验证**：
   > 📍 读取并执行 `/Users/bryanpeng/.claude/skills/ralph-loop/SKILL.md`
   > - Prompt：「实现 [moduleName] 伽利略埋点，确保代码编译通过」
   > - 退出条件：`compilation`（iOS）或 `dart-analyze`（Flutter）
   > - 最大重试：3
6. 编译通过后，调用 `galileo-spec-checker` 做规范验证（可选）

### galileo-expert 提供的能力

galileo-expert subagent 专门处理伽利略埋点相关工作，包括：

- **埋点设计**：基于漏斗模型（Start → Step → End）设计完整的埋点方案
- **规范检查**：检查埋点代码是否符合伽利略规范
- **代码示例**：提供 iOS 和 Flutter 的实现示例
- **问题诊断**：分析埋点代码中的常见问题（status 字段、生命周期、命名规范等）
- **最佳实践**：提供伽利略埋点的最佳实践建议

## 直接使用

对于简单的埋点查询或需要专业分析的场景，直接调用 galileo-expert：

```xml
<Task subagent_type="galileo-expert" description="Galileo埋点设计" prompt="用户需求描述" />
```

galileo-expert 会基于 galileo.md 文档提供完整的分析和指导。
