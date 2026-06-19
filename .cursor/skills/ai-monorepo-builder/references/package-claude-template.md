# 包级 CLAUDE.md 模板

## 用途

为大仓中缺少 CLAUDE.md 的包创建基础文档，或为已有文档补充「大仓可用积木」章节。

---

## 完整新建模板

```markdown
# <包名>

<包的一句话描述>。

- **GitHub**: https://github.com/<owner>/<repo>
- **本地路径**: `<workspace>/<pkg-dir>`
- **类型**: <Flutter 包 / Flutter App / Node.js 服务 / ...>

---

## 项目结构

```
<pkg-dir>/
├── lib/          ← 主要源码
├── ...
└── pubspec.yaml
```

---

## 核心功能

（根据包的实际功能填写）

---

## 开发命令

```bash
# 安装依赖
flutter pub get   # Flutter 包
npm install       # Node.js 包

# 运行
flutter run
```

---

## 大仓可用积木

本包所在大仓中还有以下可复用基础模块：

| 积木 | 本地路径 | 提供能力 |
|------|---------|---------|
| <module-a> | `../<module-a>` | <一句话描述> |
| <module-b> | `../<module-b>` | <一句话描述> |

**本地引入方式**（pubspec_overrides.yaml，不提交）：
```yaml
dependency_overrides:
  <module-a>:
    path: ../<module-a>
```

**发布引用方式**（pubspec.yaml）：
```yaml
<module-a>:
  git:
    url: https://github.com/<owner>/<module-a>.git
    ref: main
```

---

## 踩坑记录

（遇到问题时在此补充）
```

---

## 仅追加「大仓可用积木」章节

当包已有 CLAUDE.md，只需在文末追加以下内容：

```markdown
---

## 大仓可用积木

本包所在大仓（`<workspace-name>`）中还有以下可复用基础模块：

| 积木 | 本地路径 | 提供能力 |
|------|---------|---------|
| <module-a> | `../<module-a>` | <一句话描述> |
| <module-b> | `../<module-b>` | <一句话描述> |

本地开发时在 `pubspec_overrides.yaml`（已加入 .gitignore）中配置 path 引用，
发布时 `pubspec.yaml` 里保持 Git URL 引用不变。
```
