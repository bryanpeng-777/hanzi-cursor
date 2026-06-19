---
name: private-pod-publisher
description: 王者营地 iOS 私有 CocoaPods 库升级发布技能。将新版 framework 文件发布到私有 git 仓库（git.woa.com/koh_social/iOS/），同步更新 CampBinSpecs/CampBinPods，并更新项目 Podfile 版本号。当用户提到「升级私有库」「发布 pod」「上传 framework」「更新 SDK」「pod 版本升级」「私有库发布」「private-pod-publisher」，或者提供了新版 framework 文件路径并希望接入到项目时，应主动使用此技能。即使用户只说「帮我把这个库升级一下」且上下文是 iOS CocoaPods 私有库，也应主动使用。
---

# Private Pod Publisher

将新版 framework 发布到王者营地私有 CocoaPods 仓库的完整流程。

---

## 前置知识

### 本地仓库结构

```
~/publish_pod/
├── publish.sh              ← 发布脚本（自动完成 clone → rsync → lfs track → tag → push → pod push）
├── <PodName>/              ← 每个私有库的源目录（你维护和编辑的地方）
│   ├── <PodName>.podspec   ← 版本号在这里改
│   └── <PodName>/
│       └── <PodName>.framework  ← framework 在这里替换
└── pod/                    ← 脚本工作目录（自动生成的临时克隆，不需要手动维护）
```

> 如果 `~/publish_pod/<PodName>/` 目录不存在（被删除或首次使用），先从远端克隆：
> ```bash
> cd ~/publish_pod && git clone https://git.woa.com/koh_social/iOS/<PodName>.git
> ```

### publish.sh 关键行为

- 从 `~/publish_pod/pod/` 目录运行，参数为相对路径 `../<PodName>`
- 脚本从 podspec 中读取版本号（不会自动修改版本），以该版本打 tag
- `updateSource` 函数只处理 `:path =>` 形式的 source，**不会自动更新已有的 `:tag =>`**
- 因此：修改版本时必须同时改 `s.version` 和 `s.source` 里的 `:tag =>` 两处
- 发布完成后自动执行 `pod force repo push CampBinPods`，但**不会**更新 CampBinSpecs

### Spec Repos 关系

| Repo | 本地路径 | 作用 |
|------|---------|------|
| CampBinSpecs | `~/.cocoapods/repos/woa-koh_social-ios-campbinspecs` | pod install 依赖解析（必须有） |
| CampBinPods | `~/.cocoapods/repos/woa-koh_social-ios-campbinpods` | binary pod 存储（publish.sh 自动更新） |

pod install 失败并报 "None of your spec sources contain a spec" 时，通常是 CampBinSpecs 没有新版本，需要手动补充（见 Step 3）。

---

## 执行步骤

### Step 1：准备 framework 文件

确认新 framework 的来源路径，对每个要升级的库执行替换：

```bash
SDK=<新 framework 所在目录>   # 例如 ~/work_tree_bugfix/aiworkspace/CRChannelReport.2.2.29.58f02f6
BASE=~/publish_pod

rm -rf $BASE/<PodName>/<PodName>/<PodName>.framework
cp -R $SDK/<PodName>.framework $BASE/<PodName>/<PodName>/<PodName>.framework
```

### Step 2：修改 podspec 版本号

每个 podspec 需要改 **2 处**（`s.version` + `:tag =>`）：

```ruby
# ~/publish_pod/<PodName>/<PodName>.podspec

s.version = '<新版本号>'  # 例如 '1.0.1.260512'
s.source  = {:git => 'https://git.woa.com/koh_social/iOS/<PodName>.git', :tag => '<新版本号>'}
```

版本号命名规范：`1.0.1.YYMMDD`（年月日），如 `1.0.1.260512`。

### Step 3：运行 publish.sh

```bash
cd ~/publish_pod/pod
../publish.sh ../<PodName>
```

输出末尾出现 `semyon: success!` 表示发布成功。

**若需要同时发布多个库**，依次执行（每次等上一个完成）：

```bash
cd ~/publish_pod/pod
../publish.sh ../ChannelReport
../publish.sh ../TDataMaster
../publish.sh ../TDMIDFA
```

**若 CampBinSpecs 未自动更新**（publish.sh 不保证更新 CampBinSpecs），手动补充：

```bash
SPECS=~/.cocoapods/repos/woa-koh_social-ios-campbinspecs

mkdir -p $SPECS/<PodName>/<新版本号>
sed 's/<旧版本号>/<新版本号>/g' $SPECS/<PodName>/<旧版本号>/<PodName>.podspec \
  > $SPECS/<PodName>/<新版本号>/<PodName>.podspec

cd $SPECS && git add <PodName>/<新版本号> && \
  git commit -m "Add <PodName> <新版本号>" && \
  git pull --rebase && git push
```

### Step 4：更新 Podfile

在 `social-ios/xcodeproj/Podfile` 中把对应 `binary_pod` 的版本号改为新版本：

```ruby
binary_pod "<PodName>", "<新版本号>"
```

### Step 5：pod install

```bash
cd ~/work_tree_bugfix/social-ios/xcodeproj && pod install
```

若报 "could not find compatible versions"，先更新本地 spec repo：

```bash
pod repo update woa-koh_social-ios-campbinpods
pod repo update woa-koh_social-ios-campbinspecs
```

然后再执行 pod install。

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `pod install` 找不到新版本 | CampBinSpecs 未更新 | 手动执行 Step 3 的 CampBinSpecs 补充步骤 |
| publish.sh 报 `Could not pull` | git lfs 历史无法拉取（正常现象）| 可忽略，不影响发布 |
| `~/publish_pod/<PodName>/` 不存在 | 源目录被删除 | `git clone https://git.woa.com/koh_social/iOS/<PodName>.git` 重新克隆 |
| tag 已存在 | 同版本号曾发布过 | 脚本会自动强制覆盖（`OVERRIDE_TAG`），正常处理 |
| `updateSource` 不更新 tag | podspec 已是 git source 格式 | 手动修改 `:tag =>` 字段（Step 2 已包含此步） |

---

## 涉及的库（当前项目）

项目中通过 `binary_pod` 引入的私有染色 SDK 库：

| 库名 | git 仓库 | Podfile 位置 |
|------|---------|------------|
| ChannelReport | `git.woa.com/koh_social/iOS/ChannelReport` | xcodeproj/Podfile 第 224 行 |
| TDataMaster | `git.woa.com/koh_social/iOS/TDataMaster` | xcodeproj/Podfile 第 225 行 |
| TDMIDFA | `git.woa.com/koh_social/iOS/TDMIDFA` | xcodeproj/Podfile 第 226 行 |
