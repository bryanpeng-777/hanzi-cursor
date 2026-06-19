---
name: galileo-shared
description: 当用户准备使用依赖伽利略（Galileo） CLI 的 Skill 时使用，可以安装 Galileo CLI、检查本地环境和认证状态，并完成基础鉴权配置。
---

# 伽利略（Galileo）shared

    galileo <command>

## Helper Commands

- `version`：确认 `galileo` 是否可用
- `env`：查看当前运行环境
- `auth status`：检查当前是否已经登录
- `auth login`：保存本地 token
- `skills list`：查看内置 skills

## Install

Linux amd64：

```bash
mkdir -p "$HOME/.galileo/bin"
curl -fL "https://mirrors.tencent.com/repository/generic/gcli/linux/amd64/galileo" -o "$HOME/.galileo/bin/galileo"
chmod +x "$HOME/.galileo/bin/galileo"
```

其他平台下载地址：

- macOS amd64：`https://mirrors.tencent.com/repository/generic/gcli/darwin/amd64/galileo`
- macOS arm64：`https://mirrors.tencent.com/repository/generic/gcli/darwin/arm64/galileo`
- Linux amd64：`https://mirrors.tencent.com/repository/generic/gcli/linux/amd64/galileo`
- Linux arm64：`https://mirrors.tencent.com/repository/generic/gcli/linux/arm64/galileo`
- Windows amd64：`https://mirrors.tencent.com/repository/generic/gcli/windows/amd64/galileo.exe`

安装完成后，先执行 `galileo version` 确认 Galileo CLI 是否可用；如果命令不存在，说明 `galileo` 还不在 `PATH` 中，需要将安装目录加入 `PATH`，并重新加载 shell 配置或打开新的终端后再次验证。常见安装目录为 `$HOME/.galileo/bin`。

## Check Status

先确认 Galileo CLI 可用：

```bash
galileo version
```

再检查当前是否已经登录：

```bash
galileo auth status
```

## Auth

如果还没有 token，先从下面的页面获取：

- `https://galileo.woa.com/api-token`

如果 `auth status` 显示未登录，可以执行：

```bash
galileo auth login --token "$GALILEO_ACCESS_TOKEN"
```

或者直接设置环境变量：

```bash
export GALILEO_ACCESS_TOKEN="your_access_token"
galileo auth status
```

## Discovering Commands

```bash
galileo -h
galileo auth -h
galileo metric -h
galileo metric query --input '{...}'
galileo metric query-range --input '{...}'
galileo skills list
galileo skills show galileo-shared
```
