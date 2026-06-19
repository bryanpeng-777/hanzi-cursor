# Go To Directory

快速导航到常用工作目录。当用户说"进入"、"打开"、"去"、"cd到"、"切换到"某个工作目录时，根据语义匹配执行对应的 `cd` 命令。

## 目录映射表

以下是所有已注册的工作目录，左侧为语义别名（支持模糊匹配），右侧为实际路径：

- **主仓 / 主工作目录 / work** → `/Users/bryanpeng/work`
  - 包含 flutter_module、social-ios 主开发目录
- **二号仓 / work2** → `/Users/bryanpeng/work2`
  - 包含 camp-ai、camp_design、WEGCpp、ios-exporter 等项目
- **三号仓 / work3** → `/Users/bryanpeng/work3`
  - 包含 TUX、opentelemetry、crash 分析等工具项目
- **bugfix仓 / 修bug / bugfix / work_tree_bugfix** → `/Users/bryanpeng/work_tree_bugfix`
  - bugfix 专用 worktree，含 flutter_module 和 social-ios
- **学习目录 / workbryan / 个人项目** → `/Users/bryanpeng/workbryan`
- **workbuddy** → `/Users/bryanpeng/.workbuddy`
- **codebuddy** → `/Users/bryanpeng/.codebuddy`

## 行为规则

1. 用户提到目录相关的关键词时，从映射表中匹配最接近的条目
2. 直接执行 `cd <目标路径>` ，不需要额外确认
3. 如果用户的描述无法明确匹配到某个目录，列出最可能的几个选项让用户选择
4. 如果用户提到的目录不在映射表中，提示用户是否要将其添加到映射表

## 维护

需要新增或修改目录映射时，直接编辑本文件的「目录映射表」部分。
