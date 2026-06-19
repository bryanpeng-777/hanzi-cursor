# 腾讯灯塔 (Beacon) API 数据源参考

## 平台概述

腾讯灯塔（Tencent Beacon）是腾讯内部大数据分析平台，提供全链路数据分析解决方案。
- **官网**: https://beacon.qq.com/
- **管理端**: https://analytics.beacon.tencent.com/
- **文档站**: https://doc.beacon.qq.com/

## 核心子产品

| 产品 | 定位 | 说明 |
|------|------|------|
| **DataInsight** | BI 分析引擎 | 融合分析引擎，支持多种分析模型（事件分析、留存分析、漏斗分析等） |
| **DataTalk** | 数据可视化 | 开放自由的看板搭建平台，支持多端多数据源 |
| **灯塔 SDK** | 数据采集 | 客户端行为事件上报通道，日活 10 亿+ 终端 |

## API 接入方式

### 1. 灯塔 Analytics API

**基础地址**: `https://analytics.beacon.tencent.com`

**认证方式**:
- Header: `X-Beacon-AppId: <APP_ID>`
- Header: `Authorization: Bearer <API_KEY>`

**常用接口**:

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 应用信息 | GET | `/api/v1/apps/{app_id}/info` | 获取应用基本信息 |
| 看板列表 | GET | `/api/v1/apps/{app_id}/dashboards` | 获取所有看板 |
| 看板数据 | GET | `/api/v1/apps/{app_id}/dashboards/{id}/data` | 获取指定看板数据 |
| 实时概览 | GET | `/api/v1/apps/{app_id}/realtime/overview` | 实时统计数据 |
| 事件分析 | POST | `/api/v1/apps/{app_id}/analysis/event` | 自定义事件查询 |
| 留存分析 | POST | `/api/v1/apps/{app_id}/analysis/retention` | 留存率分析 |
| 漏斗分析 | POST | `/api/v1/apps/{app_id}/analysis/funnel` | 转化漏斗分析 |
| SQL查询 | POST | `/api/v1/apps/{app_id}/query/sql` | SQL 直查模式 |

### 2. DataTalk 变量系统

DataTalk 看板支持以下数据查询方式：

- **拖拽分析变量**: 通过拖拽指标/维度查询，支持 JS 后置处理
- **SQL 变量**: 手写 SQL 查询，支持一键生成 SQL
- **API 变量**: 任意外部 API 作为数据源
- **函数变量**: JS 自由组合多个变量

### 3. 数据源支持

DataTalk 支持的数据源类型：
- 业务 DB 直连
- 灯塔分析转存（DataInsight）
- 多种数据库（MySQL、ClickHouse 等）
- 灯塔融合计算引擎
- 本地文档上传（CSV/Excel）
- 腾讯文档
- OpenAPI 外部接口

## 数据导出方式

当 API 接入不可用时，可通过以下方式导出数据：

1. **看板导出**: 在 DataTalk/DataInsight 看板页面，点击导出按钮下载 CSV/Excel
2. **报表邮件**: 配置定时邮件推送，附带数据表格
3. **企业微信推送**: 通过企业微信机器人推送实时数据摘要

## 常见指标说明

| 指标 | 英文 | 说明 |
|------|------|------|
| 日活跃用户 | DAU | 当日访问应用的独立用户数 |
| 月活跃用户 | MAU | 当月访问应用的独立用户数 |
| 新增用户 | New Users | 首次使用应用的用户数 |
| 留存率 | Retention Rate | 初始事件后N日回访的用户比例 |
| 事件次数 | Event Count | 特定事件的触发次数 |
| 事件用户数 | Event Users | 触发特定事件的独立用户数 |
| 转化率 | Conversion Rate | 漏斗各步骤间的转化比例 |
| 人均使用时长 | Avg Session Duration | 用户平均每次使用时长 |
| 页面浏览量 | PV | 页面被浏览的总次数 |
| 独立访客数 | UV | 独立访问用户数 |

## 注意事项

1. **API Key 安全**: 切勿在代码中硬编码 API Key，建议通过环境变量传入
2. **请求频率**: 遵守灯塔 API 限流策略，避免高频请求
3. **数据时效**: 实时数据通常有 5-15 分钟延迟，T+1 数据在次日凌晨生成
4. **权限控制**: 确保 AppID 对应的应用有数据查询权限
5. **内网访问**: 部分 API 可能仅限内网（办公网络/VPN）访问
