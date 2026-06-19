---
name: tga-release
description: 蓝盾流水线发布助手（TGA 电视台模块）。修改 TGALibs / TGAFoundation / TGALiveSDK 代码后，按依赖顺序触发对应蓝盾流水线打包出 tag，再自动更新本地 podfile 版本号供验证。当用户提到「电视台发布」「TGA 打包」「触发流水线」「出 tag」「更新 podfile」「蓝盾发布」「tga-release」时触发。即使用户只说「帮我把电视台这次改动发布一下」，也应主动使用此技能。
---

# TGA 蓝盾流水线发布助手

**脚本分工**：
- `scripts/trigger_pipeline.py` 负责触发蓝盾流水线、查询构建状态（确定性操作）
- AI 负责判断触发哪些流水线、按顺序编排、提取 tag、更新 podfile

流水线详情见 `references/pipelines.md`。

---

## Step 0：将改动提交并合并到 master

TGA 各仓库（TGAFoundation、TGA_Main_Proj）的 master 分支受服务端保护，无法直接 push（API 层面同样被拦截），必须走以下流程：

1. **创建 bugfix 分支并推送**：
   ```bash
   git checkout -b bugfix/${userID}_${bugID}
   git push -u origin bugfix/${userID}_${bugID}
   ```

2. **通过工蜂 MCP 创建 MR**：使用 `create_merge_request` 工具（project_id 填仓库全路径，如 `iOS_WZRYTV_SmobaHelper/TGAFoundation`），source_branch 为 bugfix 分支，target_branch 为 master

3. **等用户合并后**再继续后续步骤

> ⚠️ 必须先合并到 master，再触发 **master 分支**的流水线。否则流水线构建的是旧代码，tag 不会更新。

---

## Step 1：确认改动范围

询问或推断本次改动的仓库（可多选）：

```
本次改动了哪些仓库？
  [ ] TGALibs（基础 framework 层）
  [ ] TGAFoundation（中间件层）
  [ ] TGALiveSDK（业务层，TGA_Main_Proj）
```

**自动推断规则**（有修改文件路径时）：
- 路径含 `TGALibs/` → TGALibs
- 路径含 `TGAFoundation/` → TGAFoundation
- 路径含 `TGA_Main_Proj/` 或 `TGALiveSDK/` → TGALiveSDK

---

## Step 2：确定流水线触发顺序

按依赖链**从底层到上层**触发，改动了哪层就从那层开始，上层全部触发：

```
改动了 TGALibs     → 触发顺序：TGALibs → TGAFoundation → TGALiveSDK
改动了 TGAFoundation → 触发顺序：TGAFoundation → TGALiveSDK
改动了 TGALiveSDK  → 触发顺序：TGALiveSDK（仅此一条）
```

向用户展示待触发的流水线列表，确认后开始执行。

---

## Step 3：逐层触发并等待

对每条流水线，按顺序执行：

### 3.1 触发流水线

```bash
python ~/.claude/skills/camp/tga-release/scripts/trigger_pipeline.py \
  trigger \
  --pipeline-id <pipeline_id> \
  --token <your_blue_shield_token>
```

脚本返回 `build_id`，记录备用。

### 3.2 等待构建完成

```bash
python ~/.claude/skills/camp/tga-release/scripts/trigger_pipeline.py \
  status \
  --build-id <build_id> \
  --token <your_blue_shield_token>
```

> ⚠️ `status` 子命令只接受 `--build-id` 和 `--token`，不支持 `--pipeline-id` 或 `--wait` 参数。

脚本返回当前构建状态（RUNNING / SUCCEED / FAILED）。RUNNING 时需手动轮询（每 30 秒调用一次），直到状态变为 SUCCEED。

构建成功后，在对应仓库执行以下命令获取新 tag：
```bash
git fetch --tags && git tag --sort=-version:refname | grep "^v3\." | head -3
```

### 3.3 TGAFoundation 特殊步骤（wzry_specs_sync.sh）

TGAFoundation 流水线完成后，**必须执行**此步骤，将新 tag 的 podspec 同步到 WZRYSpecs，否则 TGALiveSDK pod install 时会报「找不到对应版本」。

**前置条件**：
- 需要 `http://git.woa.com/iOS_WZRYTV/DependencyScripts` 仓库的访问权限（联系 robbiewu 开权限）
- 本地需有 WZRYSpecs 仓库克隆：`/Users/bryanpeng/work_tree_bugfix/WZRYSpecs`

**执行步骤**：

```bash
# 1. 先拉取最新 master（流水线会自动提交 podspec 版本号，需 pull 后才是干净状态）
cd /Users/bryanpeng/work_tree_bugfix/TGAFoundation
git pull origin master

# 2. 执行同步脚本（SPECS_PATH 指向 WZRYSpecs 根目录，不是 Specs 子目录）
SPECS_PATH=/Users/bryanpeng/work_tree_bugfix/WZRYSpecs ./wzry_specs_sync.sh
```

> **注意**：
> - `SPECS_PATH` 必须指向含有 `Specs/` 子目录的父目录（`WZRYSpecs`），而非 `WZRYSpecs/Specs`
> - 脚本会检查工作区是否干净（`git diff-index`），若有未提交文件会报错退出。先 `git pull` 确保本地与 origin/master 一致
> - 执行成功后输出 `update Specs success`，并在 WZRYSpecs 中新增 `Specs/TGAFoundation/<version>/` 目录

### 3.4 更新下游 podspec（跨仓库改动时）

- 改了 TGALibs → 在 TGAFoundation 的 `.podspec` 中更新 TGALibs 版本引用
- 改了 TGAFoundation → 在 `TGA_Main_Proj/TGALiveSDK.podspec` 中更新 TGAFoundation 版本引用：
  ```ruby
  # 路径：/Users/bryanpeng/work_tree_bugfix/TGA_Main_Proj/TGALiveSDK.podspec
  s.dependency 'TGAFoundation', '旧版本'  →  新版本（如 3.895.101.5）
  ```
  更新后同样需要走 **bugfix 分支 + 工蜂 MR** 合并到 master，再触发 TGALiveSDK 流水线

---

## Step 4：更新本地 podfile

所有流水线完成后，更新 podfile 中的 `:tag =>` 版本号：

**podfile 位置**：`/Users/bryanpeng/work_tree_bugfix/social-ios/xcodeproj/Podfile`（或其 `def pods_tga` 所在文件）

将：
```ruby
pod 'TGALiveSDK', :git => "...", :tag => "v旧版本", :modular_headers => false
pod 'TGAFoundation', :git => "...", :tag => "v旧版本", :modular_headers => false
```

更新为新 tag，然后提示用户：

```
✅ Podfile 已更新：
   TGALiveSDK: v旧版本 → v新版本
   TGAFoundation: v旧版本 → v新版本（如有）
```

---

## Step 5：本地验证

Podfile 更新完成后，按顺序执行以下步骤：

### 5.1 确认 TGA 本地源开关已关闭

检查 `social-ios/xcodeproj/local.properties.rb`（注意是 `.rb` 后缀，Ruby 语法），确认 `$enable_tga_local_source` 这行已被**注释掉**：

```ruby
# $enable_tga_local_source = true   # 本地调试时取消注释，发布前务必注释掉
```

> 若该行未注释（值为 `true`），Pod 会走本地 path 源码而非 tag 版本，导致验证的不是正式版本。
> 注意：不是改为 `false`，而是**整行注释掉**。

### 5.2 更新本地 spec 仓库缓存（首次或新版本时）

若 pod install 报错「None of your spec sources contain a spec satisfying the dependency: `TGAFoundation (= x.x.x.x)`」，需先更新本地 spec 仓库缓存：

```bash
pod repo update woa-ios_wzrytv_thirdsdk-wzryspecs
```

然后再重新执行 pod install。

### 5.3 执行 pod install

```bash
cd /Users/bryanpeng/work_tree_bugfix/social-ios/xcodeproj
pod install
```

### 5.4 编译运行 App 验证效果

在 Xcode 中编译并运行 App，验证本次 TGA 修改是否生效。

---

## Step 6：验证确认

用户验证通过后，询问是否需要提交代码：

```
验证通过？说「提交」我来调用 git-commit 技能帮你规范提交。
```

---

## 注意事项

- **必须按顺序**：上游未完成不能触发下游（否则 podspec 版本不一致）
- **Token 获取**：蓝盾 API token 需用户提前配置，首次使用时提示用户提供
- **Dry-run 模式**：用户说「dry-run」「模拟」时，只打印命令和参数，不实际触发 API
- **流水线地址**：详见 `references/pipelines.md`
