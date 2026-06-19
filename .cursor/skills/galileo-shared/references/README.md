# galileo-shared

`galileo-shared` 是伽利略（Galileo）CLI 的共享基础 skill，用于解决使用 Galileo CLI 前的准备问题。

它主要覆盖三类能力：

- 安装 Galileo CLI
- 检查本地运行环境
- 配置和确认认证状态

安装完成后，建议先执行：

```bash
galileo version
```

如果命令不存在，说明 `galileo` 还不在 `PATH` 中，需要将安装目录加入 `PATH`，并重新加载 shell 配置或打开新的终端后再验证。常见安装目录为 `$HOME/.galileo/bin`。

这个 skill 适合以下场景：

- 当前机器上还没有安装 `galileo`
- 不确定 CLI 是否已经可用
- 不确定当前是否已经完成登录
- 需要获取 token 并完成基础鉴权

建议把它作为所有依赖 `galileo` CLI 的 skill 前置步骤。

对应的核心命令包括：

- `galileo version`
- `galileo env`
- `galileo auth status`
- `galileo auth login --token ...`

如果你需要的是安装、鉴权、环境准备，请优先使用这个 skill。
