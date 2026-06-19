---
name: oa-pages
description: 在腾讯内网 pages.woa.com 上创建或更新静态网站。通过 HTTP API 直接部署，无需 CI/CD 或 git 操作。当用户说「帮我把内容部署到 pages.woa.com」「在 OA Pages 上创建一个网站」「更新 OA Pages 的页面」「更新 bryanpeng-ai.pages.woa.com」「把这个 HTML 推到 pages」「oa-pages」，或者需要把 AI 生成的内容部署为内网可访问的网站时，使用此技能。即使用户只说「部署一下」「发布到内网」且上下文与 pages.woa.com 相关，也应主动使用。
---

# OA Pages 部署技能

pages.woa.com 是腾讯内网静态网站托管平台，提供完整 HTTP API。AI 可直接调用，无需 CI/CD、无需 git 操作，一次 API 调用完成部署。

## 完整工作流

### Step 1：检查 API Key

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null
echo $OA_PAGES_API_KEY
```

- **输出非空** → 直接使用，继续 Step 2
- **输出为空** → 按下方「获取 API Key」引导用户配置，配置完成后继续

#### 获取 API Key（仅在未配置时展示）

> ⚠️ 请勿将 API Key 发送到聊天中！
>
> 1. 打开 https://pages.woa.com/admin，登录后点击「申请 API Key」，复制（只显示一次）
> 2. 在**终端**（不是聊天窗口）执行：
>    ```bash
>    echo 'export OA_PAGES_API_KEY="你的API_KEY"' >> ~/.zshrc && source ~/.zshrc
>    ```
> 3. 完成后告诉我「好了」

---

### Step 2：确定操作类型

| 用户意图 | 操作 | API |
|---------|------|-----|
| 新建网站 | 创建 | `POST /api/sites` |
| 修改已有内容 | 更新 | `PUT /api/sites/:cname` |

**如果是更新**：直接跳到 Step 4，无需检查域名。

---

### Step 3：（仅创建）确定域名并检查可用性

调用 `scripts/deploy.py check <cname>` 检查域名：

```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py check bryanpeng-ai.pages.woa.com
```

- `AVAILABLE` → 域名可用，告知用户确认
- `TAKEN` → 域名已占用，建议其他名称并重新检查
- 域名必须以 `.woa.com` 结尾

---

### Step 4：准备文件内容

文件以 `{"路径": "内容"}` 的 JSON 映射传递：
- 文本文件（HTML/CSS/JS）直接传字符串内容
- 二进制文件（图片等）需 base64 编码
- 请求体总大小不超过 5MB
- 至少包含一个 `index.html`

---

### Step 5：调用 API 部署

使用 `scripts/deploy.py`：

**创建新网站：**
```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py create \
  --cname "mysite.pages.woa.com" \
  --description "网站描述" \
  --files '{"index.html": "<html>...</html>", "sharing/index.html": "..."}'
```

**更新已有网站：**
```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py update \
  --cname "mysite.pages.woa.com" \
  --files '{"index.html": "<html>...新内容...</html>"}'
```

脚本自动从 `$OA_PAGES_API_KEY` 读取 Key，无需手动传入。

---

### Step 6：展示结果

创建成功后告知：

```
✅ 网站已创建成功！
🌐 访问地址：https://xxx.pages.woa.com
🔒 当前权限：白名单模式（仅创建者可访问）

权限管理：https://pages.woa.com/admin/xxx.pages.woa.com
可选权限：公开（内网免登录）/ tof 验证（需 iOA 登录）/ 白名单
```

---

## 其他常用操作

### 修改权限

```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py patch \
  --cname "mysite.pages.woa.com" \
  --visibility "public"  # public | tof | whitelist
```

### 查看网站文件列表

```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py files \
  --cname "mysite.pages.woa.com"
```

### 删除网站（不可逆，需告知用户）

```bash
python3 ~/.claude/skills/oa-pages/scripts/deploy.py delete \
  --cname "mysite.pages.woa.com"
```

---

## 重要说明

- **OrangeCI 已归档**：`.orange-ci.yml` 方案已失效，不要使用
- **oa-pages git 分支方案已过时**：`settings/integrations` 页面 404，webhook 路径不存在
- **新网站默认白名单模式**（仅创建者可访问），需手动在 admin 调整权限
- **更新只支持通过 API 创建的网站**（不支持 git 方式创建的）
- **skill.md 参考文档**：https://pages.woa.com/skill.md（内网可访问）
