# 企业微信文档 MCP 服务 — 工具参考手册

## 工具一览

| 工具名 | 功能 | 必填参数 | 可选参数 |
|--------|------|----------|----------|
| `wecom_doc_login` | 扫码登录 | 无 | 无 |
| `wecom_doc_status` | 检查登录状态 | 无 | 无 |
| `wecom_doc_fetch` | 读取文档内容 | `url` | `tab` |
| `wecom_doc_screenshot` | 截图 | `url` | `output_path` |
| `wecom_doc_write` | 文档追加文本 | `url`, `content` | `type_delay`, `line_delay` |
| `wecom_doc_write_sheet` | 表格单元格写入 | `url`, `cell`, `content` | `mode`, `tab`, `type_delay` |

## 支持的文档类型

| URL 路径 | 类型 | 读取 | 写入 |
|----------|------|------|------|
| `/doc/` | 在线文档 | ✅ | ✅ 追加文本 |
| `/sheet/` | 在线表格 | ✅ | ✅ 单元格写入 |
| `/smartsheet/` | 智能表格 | ✅ | ✅ 单元格写入 |
| `/slide/` | 幻灯片 | ✅ 文本+截图 | ❌ |
| `/mindmap/` | 思维导图 | ✅ 节点+截图 | ❌ |
| `/flowchart/` | 流程图 | ✅ 文本+截图 | ❌ |

## 详细参数说明

### wecom_doc_fetch

读取企微文档内容，根据文档类型自动选择最佳提取策略。

```
参数:
  url (必填)  企微文档完整 URL
              示例: https://doc.weixin.qq.com/sheet/e3_xxx
                    https://doc.weixin.qq.com/doc/w3_xxx
  tab (可选)  表格的 tab/sheet 标识，用于获取指定工作表
              从 sheetList 中的 tab= 值获取
```

**表格提取策略优先级**：Excel 导出 > opendoc API > JS 内存扫描

**表格返回数据**：
- `sheetList`：所有工作表列表（含 tab ID、名称、是否隐藏）
- `sheets`：各工作表的二维表格数据
- 指定 `tab` 时只返回对应工作表数据

### wecom_doc_write

向 doc 类型文档**末尾追加**纯文本。不支持富文本格式。

```
参数:
  url (必填)      企微文档 URL（必须是 /doc/ 类型）
  content (必填)  要追加的文本，支持 \n 换行
  type_delay      每字符输入延时(ms)，默认 10
  line_delay      每行间等待(ms)，默认 300
```

### wecom_doc_write_sheet

向 sheet 类型表格的**指定单元格**写入内容。

```
参数:
  url (必填)      企微表格 URL（必须是 /sheet/ 或 /smartsheet/）
  cell (必填)     单元格地址，如 A1, N1, B3, AA100
  content (必填)  要写入的文本
  mode            "append"(追加到末尾，默认) 或 "overwrite"(覆盖)
  tab             工作表 tab 标识（切换到指定工作表）
  type_delay      每字符输入延时(ms)，默认 15
```

**写入策略优先级**：JS API 直写 > 箭头键导航+剪贴板 > 名称框定位+键盘输入

## 常见使用场景

### 1. 读取表格并分析数据
```
用户: 帮我获取这个表格的数据 https://doc.weixin.qq.com/sheet/e3_xxx
→ 调用 wecom_doc_fetch(url=...) 获取所有工作表数据
```

### 2. 读取指定工作表
```
用户: 获取这个表格中"项目排期"的数据 https://doc.weixin.qq.com/sheet/e3_xxx
→ 先不带 tab 调用 wecom_doc_fetch 获取 sheetList
→ 从返回的 sheetList 中找到"项目排期"的 tab ID
→ 带 tab 参数再次调用获取指定工作表
```

### 3. 向文档追加内容
```
用户: 在这个文档末尾加一段总结 https://doc.weixin.qq.com/doc/w3_xxx
→ 调用 wecom_doc_write(url=..., content="...")
```

### 4. 向表格写入数据
```
用户: 在 A5 单元格写入"完成" https://doc.weixin.qq.com/sheet/e3_xxx
→ 调用 wecom_doc_write_sheet(url=..., cell="A5", content="完成", mode="overwrite")
```

### 5. 批量写入表格行
```
用户: 在网络设备名称表中增加一行数据
→ 先调用 wecom_doc_fetch 确认当前数据最后一行行号
→ 逐个单元格调用 wecom_doc_write_sheet 写入新行数据
```

### 6. 截图文档
```
用户: 帮我截图这个文档 https://doc.weixin.qq.com/slide/xxx
→ 调用 wecom_doc_screenshot(url=...)
```

## 故障排查

| 错误信息 | 原因 | 解决方法 |
|----------|------|----------|
| "未登录或登录已过期" | Cookie 过期 | 调用 `wecom_doc_login` 重新扫码 |
| "无效的单元格地址" | cell 格式错误 | 使用 A1 格式（字母+数字） |
| "此工具仅支持 doc 类型" | URL 类型不匹配 | doc 用 write，sheet 用 write_sheet |
| 表格数据为空 | 页面未完全加载 | 重试，或检查文档权限 |
