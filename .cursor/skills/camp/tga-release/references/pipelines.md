# TGA 蓝盾流水线配置

## 平台信息

- **蓝盾平台**：https://devops.woa.com
- **项目**：`sgame-tv`

## 流水线列表

| 仓库 | 流水线 ID | 流水线链接 | 触发顺序 |
|------|----------|-----------|---------|
| TGALibs | `p-e1d81e453b594e48b71d79e10818fa1f` | https://devops.woa.com/console/pipeline/sgame-tv/p-e1d81e453b594e48b71d79e10818fa1f | 1（最先） |
| TGAFoundation | `p-6bac50ae3760411c816e8f9ab04af98a` | https://devops.woa.com/console/pipeline/sgame-tv/p-6bac50ae3760411c816e8f9ab04af98a | 2 |
| TGALiveSDK | `p-b9021eb34394484ca814383d3a705e7d` | https://devops.woa.com/console/pipeline/sgame-tv/p-b9021eb34394484ca814383d3a705e7d | 3（最后） |

## 触发顺序规则

```
改动 TGALibs     → TGALibs(1) → TGAFoundation(2) → TGALiveSDK(3)
改动 TGAFoundation → TGAFoundation(2) → TGALiveSDK(3)
改动 TGALiveSDK  → TGALiveSDK(3)
```

## 特殊步骤

**TGAFoundation 发版后必须执行（缺少此步 TGALiveSDK pod install 会报找不到版本）：**
```bash
# 先 pull 确保工作区干净（流水线会自动 commit podspec 版本号）
cd /Users/bryanpeng/work_tree_bugfix/TGAFoundation
git pull origin master

# SPECS_PATH 指向 WZRYSpecs 根目录（含 Specs/ 子目录的父目录）
SPECS_PATH=/Users/bryanpeng/work_tree_bugfix/WZRYSpecs ./wzry_specs_sync.sh
```
> 将 TGAFoundation 的新 tag podspec 同步到 WZRYSpecs 仓库，TGALiveSDK 才能通过 CocoaPods 找到新版本。
>
> 需要 `http://git.woa.com/iOS_WZRYTV/DependencyScripts` 仓库访问权限（联系 robbiewu）。
> 执行成功后输出 `update Specs success`。
>
> pod install 后若仍报找不到版本，执行 `pod repo update woa-ios_wzrytv_thirdsdk-wzryspecs` 更新本地 spec 缓存。

## 鉴权说明

蓝盾 API 通过**蓝鲸 API 网关**访问，Header 格式：
```
X-Bkapi-Authorization: {"access_token": "xxx"}
```

**access_token 获取**（需已登录蓝盾）：
1. 打开：https://devops.woa.com/ms/auth/api/user/bkToken/get
2. 页面直接返回 JSON，取其中 access_token 字段
3. 若报错先登录：https://devops.woa.com/console/，再重试

有效期约 180 天，过期后重新获取。

**已存储 Token（bryanpeng）**：
```
uTmUVi5wmbWxjHbHoYgDCVzOm9hd4S
```
> 更新日期：2026-04-20，有效期约 180 天

## 蓝盾 API 接口（参考）

API 网关基础 URL：`https://bk-apigateway.apigw.o.woa.com/prod`

触发流水线：
```
POST /api/v3/apigw-user/projects/{projectId}/pipelines/{pipelineId}/builds
X-Bkapi-Authorization: {"access_token": "xxx"}
```

查询构建状态：
```
GET /api/v3/apigw-user/projects/{projectId}/pipelines/{pipelineId}/builds/{buildId}/status
X-Bkapi-Authorization: {"access_token": "xxx"}
```
