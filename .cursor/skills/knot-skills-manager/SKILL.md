---
name: knot-skills-manager
description: "Knot 平台 Skills 管理技能。提供查询 Skills 列表、上传/更新 Skill、打包发布、蓝盾流水线部署等完整操作指南和可执行脚本。当需要管理 Knot Skills（查看列表、上传、更新、打包、同步）时使用。触发词：knot skills、技能管理、skill 列表、上传 skill、更新 skill、打包 skill、同步 skill、knot 发布、skills 同步。"
---

# Knot Skills 管理技能

## 一、概述

Knot 是腾讯内部的 AI Agent 平台，Skills 是其核心能力扩展机制。本技能提供 Knot Skills 的完整管理能力，包括：
- 查询 Skills 列表
- 创建/更新 Skills
- 本地打包与批量发布
- 蓝盾流水线自动部署

## 二、Knot API 参考

### 基础信息

| 环境 | 域名 | API 基础路径 |
|------|------|-------------|
| 正式环境 | `knot.woa.com` | `https://knot.woa.com/apigw` |
| 测试环境 | `test.knot.woa.com` | `https://test.knot.woa.com/apigw` |

**Token 申请地址**：https://knot.woa.com/settings/token

**Token 本地缓存**：`~/.knot_token_cache.json`（key: `"token"`），脚本中可直接读取：
```python
import json
TOKEN = json.load(open(os.path.expanduser('~/.knot_token_cache.json')))['token']
```

**认证方式**：请求头 `X-knot-api-token: <your_token>`

### API 列表

#### 1. 查询 Skills 列表

```
POST /apigw/openapi/v1/skills/get
```

**请求体**：
```json
{
    "category": "managed"
}
```

**category 可选值**：
| 值 | 说明 |
|---|---|
| `"managed"` | 你创建/管理的 skills |
| `"usable"` | 你可使用的所有 skills（含公共） |
| `"official"` | 官方 skills |
| `""` | 全部 |

**curl 示例**：
```bash
curl -s -X POST "https://knot.woa.com/apigw/openapi/v1/skills/get" \
  -H "Content-Type: application/json" \
  -H "X-knot-api-token: <TOKEN>" \
  -d '{"category":"managed"}'
```

**返回格式**：
```json
{
    "code": 0,
    "data": [
        {
            "id": "3562",
            "skill_name": "jobimzhou-1772782805",
            "display_name": "mapgpt-request-proxy",
            "description": "mapgpt-request-proxy",
            "creator": "jobimzhou",
            "visibility": "private",
            "download_count": 3,
            "created_at": "2026-03-06 15:40:07",
            "updated_at": "2026-03-07 00:49:39"
        }
    ],
    "msg": "success"
}
```

#### 2. 创建 Skill（仅元信息，不含文件）

```
POST /apigw/openapi/v1/skills/add_without_file
```

**请求体**：
```json
{
    "display_name": "my-skill",
    "description": "Skill 描述",
    "share_member": null
}
```

- `display_name`：必填，Skill 显示名称
- `description`：必填，Skill 描述
- `share_member`：可选，共享成员信息

**返回格式**：
```json
{
    "code": 0,
    "data": {
        "id": 5691
    },
    "msg": "ok"
}
```

**curl 示例**：
```bash
curl -s -X POST "https://knot.woa.com/apigw/openapi/v1/skills/add_without_file" \
  -H "Content-Type: application/json" \
  -H "X-knot-api-token: <TOKEN>" \
  -d '{"display_name":"my-skill","description":"描述"}'
```

#### 3. 更新 Skill 文件

```
POST /apigw/openapi/v1/skills/update_file
```

**请求体**：
```json
{
    "id": "<skill_id>",
    "file_data": "<base64编码的zip文件内容>",
    "file_name": "skill-name.zip"
}
```

- `file_data`：zip 文件的 **base64 编码字符串**
- `file_name`：必须以 `.zip` 结尾
- zip 文件大小限制：**10MB**

**curl 示例**：
```bash
curl -s -X POST "https://knot.woa.com/apigw/openapi/v1/skills/update_file" \
  -H "Content-Type: application/json" \
  -H "X-knot-api-token: <TOKEN>" \
  -d '{"id":"3562","file_data":"<BASE64>","file_name":"my-skill.zip"}'
```

#### 4. 删除 Skill

> ⚠️ **Knot OpenAPI 目前没有暴露删除接口**，只能通过网页端手动删除。
>
> Skill 详情页地址格式：`https://knot.woa.com/skills/detail/<skill_id>`
>
> 如遇问题联系 Knot 管理员：`posyjiang`、`sisiychen`

## 三、Skill 目录规范

每个 Skill 目录必须包含 `SKILL.md` 文件，使用 YAML Frontmatter 声明元信息：

```markdown
---
name: my-skill-name
description: "技能描述文字"
---

# Skill 正文内容
...
```

**必须字段**：
- `name`：Skill 名称，用于自动匹配和创建
- `description`：Skill 描述

## 四、本地打包

### 单个 Skill 打包

```bash
# 进入 skills 目录的上层
cd /path/to/skills/parent

# 打包某个 skill（zip 内根目录为 skill 名）
zip -r my-skill.zip my-skill/ -x "*.DS_Store" "*__pycache__*"
```

> ⚠️ **关键陷阱：zip 内根目录名必须与 SKILL.md 的 `name` 字段完全一致**，否则 Knot 报：
> `invalid skill zip structure: skill name 'xxx' in SKILL.md does not match directory name 'yyy'`
>
> - `name`（SKILL.md 里）= zip 根目录名 → **必须一致**
> - `display_name`（API 参数）= Knot UI 展示名 → **可以不同**，通过 `add_without_file` 的 `display_name` 参数单独指定

### 批量打包脚本

项目提供 `pack_skills.sh` 脚本，自动完成两层打包：

```bash
bash pack_skills.sh
```

**功能**：
1. 扫描 `.codebuddy/skills/` 下所有含 `SKILL.md` 的目录
2. 每个 Skill 单独打包为 `dist/individual/<skill_name>.zip`
3. 所有 zip 汇总打包为 `dist/skills.zip`

## 脚本分工

> **脚本全自动处理**：解析 SKILL.md、打包 zip、按 name 查找/创建/更新 Skill（`scripts/knot_upload.py`）
> **AI 处理**：批量同步决策、错误分析

```bash
# 上传/更新单个 Skill（自动按 display_name 匹配）
python3 scripts/knot_upload.py <skill_dir>

# 指定 Skill ID（更快，跳过查询）
python3 scripts/knot_upload.py <skill_dir> --skill-id 3562

# 测试环境
python3 scripts/knot_upload.py <skill_dir> --env test.knot.woa.com

# 只打包不上传（验证用）
python3 scripts/knot_upload.py <skill_dir> --dry-run
```

---

## 五、通过脚本同步 Skill 到 Knot

以下 Python 脚本可直接在本地运行，实现查询和更新 Skill：

### 查询 managed skills 列表

```bash
python3 -c "
import requests, json, sys

TOKEN = '<YOUR_TOKEN>'
ENV = 'knot.woa.com'

resp = requests.post(
    f'https://{ENV}/apigw/openapi/v1/skills/get',
    headers={'Content-Type': 'application/json', 'X-knot-api-token': TOKEN},
    json={'category': 'managed'}
)
# 注意：data 是对象 {list: [...], total_count: N}，不是直接的数组
skills = resp.json().get('data', {}).get('list', [])
print(f'共 {len(skills)} 个 managed skills:')
for s in skills:
    print(f'  ID={s[\"id\"]}  {s[\"display_name\"]}  vis={s.get(\"visibility\",\"\")}  downloads={s.get(\"download_count\",0)}')
"
```

### 上传/更新单个 Skill

```bash
python3 -c "
import requests, json, os, zipfile, base64, tempfile, sys

TOKEN = '<YOUR_TOKEN>'
ENV = 'knot.woa.com'
SKILL_DIR = '<SKILL目录路径>'
SKILL_ID = '<SKILL_ID或留空>'  # 留空则按 name 自动匹配

BASE_URL = f'https://{ENV}/apigw'
HEADERS = {'Content-Type': 'application/json', 'X-knot-api-token': TOKEN}

# 1. 解析 SKILL.md
skill_md = os.path.join(SKILL_DIR, 'SKILL.md')
name = desc = None
with open(skill_md, 'r') as f:
    content = f.read()
    if content.startswith('---'):
        fm = content.split('---')[1]
        for line in fm.split('\n'):
            if ':' in line:
                k, v = line.split(':', 1)
                if k.strip() == 'name': name = v.strip().strip('\"')
                if k.strip() == 'description': desc = v.strip().strip('\"')

print(f'Skill: {name} - {desc}')

# 2. 打包为 zip
tmp = tempfile.NamedTemporaryFile(suffix='.zip', delete=False)
tmp.close()
with zipfile.ZipFile(tmp.name, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, _, files in os.walk(SKILL_DIR):
        for f in files:
            fp = os.path.join(root, f)
            arcname = os.path.join(name, os.path.relpath(fp, SKILL_DIR))
            zf.write(fp, arcname)

with open(tmp.name, 'rb') as f:
    b64 = base64.b64encode(f.read()).decode()
os.remove(tmp.name)

# 3. 上传
if SKILL_ID:
    resp = requests.post(f'{BASE_URL}/openapi/v1/skills/update_file', headers=HEADERS,
        json={'id': SKILL_ID, 'file_data': b64, 'file_name': f'{name}.zip'})
    print(f'更新 skill {SKILL_ID}: {resp.json()}')
else:
    # 按 name 查找
    skills = requests.post(f'{BASE_URL}/openapi/v1/skills/get', headers=HEADERS,
        json={'category': 'managed'}).json().get('data', [])
    match = [s for s in skills if s.get('display_name') == name]
    if len(match) == 1:
        sid = match[0]['id']
        resp = requests.post(f'{BASE_URL}/openapi/v1/skills/update_file', headers=HEADERS,
            json={'id': sid, 'file_data': b64, 'file_name': f'{name}.zip'})
        print(f'更新已有 skill {sid}: {resp.json()}')
    elif len(match) == 0:
        resp = requests.post(f'{BASE_URL}/openapi/v1/skills/add_without_file', headers=HEADERS,
            json={'display_name': name, 'description': desc or ''})
        new_id = resp.json().get('data', {}).get('id')
        if new_id:
            requests.post(f'{BASE_URL}/openapi/v1/skills/update_file', headers=HEADERS,
                json={'id': str(new_id), 'file_data': b64, 'file_name': f'{name}.zip'})
        print(f'创建并上传新 skill {new_id}')
    else:
        print(f'存在 {len(match)} 个同名 skill，请指定 SKILL_ID')
"
```

## 六、蓝盾流水线自动部署

`knot_skills` 是蓝盾（BK-CI）插件，可在流水线中自动打包并发布 Skill。

### 插件参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `knot_env` | 下拉选择 | 是 | `knot.woa.com`（正式）或 `test.knot.woa.com`（测试） |
| `knot_token` | 密码 | 是 | 个人 Token |
| `skills_id` | 下拉选择 | 否 | 指定更新的 Skill ID，不填则按 name 自动匹配 |
| `skills_dir` | 文本 | 是 | Skill 目录路径（支持相对/绝对路径） |

### 执行逻辑

1. 读取 `skills_dir` 下的 `SKILL.md`，提取 `name` 和 `description`
2. 将目录打包为 zip 并 base64 编码（限制 10MB）
3. 上传逻辑：
   - 指定了 `skills_id` → 直接更新该 Skill 文件
   - 未指定 → 按 `display_name` 查找：
     - 无同名 → 自动创建并上传
     - 唯一同名 → 自动更新
     - 多个同名 → 报错，要求指定 `skills_id`

### 本地调试

```bash
# 1. 创建 input.json
cat > input.json <<EOF
{
    "knot_env": "knot.woa.com",
    "knot_token": "<YOUR_TOKEN>",
    "skills_id": "",
    "skills_dir": "./.codebuddy/skills/my-skill"
}
EOF

# 2. 安装依赖
pip install -r knot_skills/requirements.txt

# 3. 运行
python -m knot_skills.command_line
```

## 七、Skill 在线查看

每个 Skill 的详情页地址：

```
https://knot.woa.com/skills/detail/<skill_id>
```

## 八、常见问题

### Q: 如何清理重复的 Skill？
A: Knot OpenAPI 没有删除接口，只能在网页端 `https://knot.woa.com/skills/detail/<id>` 手动删除。

### Q: 如何让团队成员使用我的 Skill？
A: 上传/编辑 Skill 时开启"共享"开关，选择要共享的团队成员，管理员审批后生效。联系 `posyjiang`/`sisiychen` 催办。

### Q: Skill 包大小限制？
A: 通过 API 上传限制 10MB（base64 编码前），通过网页上传限制 100MB。

### Q: 如何上架为全公司可见？
A: 联系 `posyjiang` 申请将 Skill 上架为公共可见。

## 九、Auto-Sync：技能改动自动同步到 Knot

通过 **git post-commit hook + `core.hooksPath`**，实现本地修改 commit 后自动上传指定技能到 Knot，无需手动触发。

### 文件结构

```
~/.claude/skills/knot-skills-manager/
├── hooks/
│   └── post-commit        ← hook 脚本，git 追踪，改了 commit 即生效
├── setup-hooks.sh         ← 新机器一次性初始化
└── knot-camp-skills.json  ← 记录监听的技能路径和 Knot ID
```

### 工作原理

```
修改技能文件 → git commit
    ↓
post-commit hook 自动执行
    ↓
检测本次提交是否改了监听目录
    ↓
有改动 → 自动打包上传到 Knot ✅
无改动 → 静默退出
```

### 新机器初始化（一次性）

```bash
# clone 后运行一次
bash ~/.claude/skills/knot-skills-manager/setup-hooks.sh
```

内部执行：`git config core.hooksPath knot-skills-manager/hooks`

> **关键**：`core.hooksPath` 存在 `.git/config`（不被 git 追踪），新机器必须手动执行一次，这是 git 安全模型的底线，无法绕过。
> hook 文件本身在 `knot-skills-manager/hooks/`（git 追踪），修改后 commit 即生效，无需重新安装。
