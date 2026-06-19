---
name: metric-verification
description: 系统化验证伽利略监控指标的上报流程，包括代码检查、调试日志添加、编译运行和指标验证。当用户提到"验证指标"、"验证埋点"、"检查上报"、"测试指标"时触发。
---

# Metric Verification

## Overview

这个 skill 提供了一套系统化的流程来验证伽利略监控指标是否正确上报。适用于新建或修改埋点后的验证工作。

## Verification Workflow

### Step 1: 代码检查

首先检查指标上报代码是否符合规范：

1. **查找指标定义**：搜索指标名称（如 `FlutterViewErrorShow`）
2. **检查上报代码**：
   - 确认调用了 `GalileoReporter.reportMetricErrorLogImmediate` 或类似方法
   - 确认 `moduleName` 参数正确
   - 确认 `status` 参数（通常失败用 -1）
   - 确认 `campType` 参数（bryanpeng 创建的指标默认使用 `TaskSpan.campTypeBefore` 前置上报）
   - 检查 `params` 参数是否包含必要信息
3. **检查触发点**：找到触发上报的代码位置（如 Hook 回调、事件监听器等）

### Step 2: 添加调试日志

在关键位置添加调试日志，便于追踪执行流程：

```dart
// 在触发点添加日志
Log.d('MetricTag', 'Hook triggered: param1=$param1, param2=$param2');

// 在上报前添加日志
Log.d('MetricTag', 'Reporting metric: moduleName=XXX, status=$status');

// 在上报后获取 spanId
final spanId = await GalileoReporter.reportMetricErrorLogImmediate(...);
Log.d('MetricTag', 'Metric reported: spanId=$spanId');
```

**日志添加原则**：
- 使用清晰的 tag 标识（如指标名称或 Hook 名称）
- 记录关键参数值
- 记录执行路径（是否进入条件分支）
- 记录上报结果（spanId）

### Step 3: 编译和运行

1. **编译代码**：使用 `compile` skill
   ```bash
   # Flutter 代码生成（如需要）
   python3 build_runner.py
   
   # 构建 iOS framework
   ./tools/build-ios-framework.sh
   ```

2. **运行应用**：
   - 如果是 Flutter 模块，需要通过 iOS 应用运行
   - 确保连接了测试设备或模拟器

### Step 4: 触发指标上报

根据指标类型，执行相应的操作来触发上报：

**常见触发场景**：
- **FlutterViewErrorShow**: 打开一个会出错的 Flutter 页面
- **FlutterListLoad**: 下拉刷新或上拉加载失败
- **图片加载错误**: 加载不存在的图片
- **网络请求失败**: 触发网络错误

### Step 5: 查看日志和验证

1. **查看控制台日志**：
   - 在 Xcode Console 或终端中查看日志输出
   - 确认 Hook 是否被触发
   - 确认上报方法是否被调用
   - 确认返回的 spanId 是否有效（非空）

2. **验证限流逻辑**（如有）：
   - 多次快速触发，验证限流是否生效
   - 等待限流时间后再次触发，验证是否能正常上报

3. **查看伽利略平台**：
   - 登录伽利略平台
   - 搜索指标名称
   - 确认数据是否上报成功
   - 检查上报的参数是否正确

### Step 6: 清理调试代码

验证完成后，清理临时添加的调试日志：

```dart
// 删除或注释掉调试日志
// Log.d('MetricTag', 'Hook triggered: ...');
```

**注意**：保留必要的日志用于线上问题排查，删除纯测试用的日志。

## Common Verification Examples

### Example 1: 验证 FlutterViewErrorShow

```dart
// 1. 检查上报代码
static Future<String> reportFlutterViewErrorShow({
  String? errorMessage,
}) {
  // 检查限流逻辑
  final now = DateTime.now();
  if (_lastFlutterViewErrorShowTime != null &&
      now.difference(_lastFlutterViewErrorShowTime!) < _flutterViewErrorShowInterval) {
    return Future.value('');
  }
  _lastFlutterViewErrorShowTime = now;

  // 检查参数构建
  final params = <String, dynamic>{};
  if (errorMessage != null && errorMessage.isNotEmpty) {
    params['error_msg'] = errorMessage;
  }

  // 检查上报调用
  return GalileoReporter.reportMetricErrorLogImmediate(
    moduleName: 'FlutterViewErrorShow',
    status: -1,
    params: params,
    campType: TaskSpan.campTypeBefore,
  );
}

// 2. 找到触发点
ErrorPageHook.onErrorPageShow = (errorMessage) {
  // 添加调试日志
  Log.d('FlutterViewErrorShow', 'Error page shown: $errorMessage');
  
  GalileoBizCenter.reportFlutterViewErrorShow(errorMessage: errorMessage);
};

// 3. 验证步骤
// - 打开一个会出错的 Flutter 页面
// - 查看日志是否输出 "Error page shown: ..."
// - 检查是否有 spanId 返回
// - 在伽利略平台查询指标数据
```

### Example 2: 验证带限流的指标

```dart
// 验证限流逻辑
// 1. 快速触发多次（在限流时间内）
// 2. 观察日志，应该只有第一次上报
// 3. 等待限流时间后再次触发
// 4. 观察日志，应该能再次上报
```

## Troubleshooting

### 问题：Hook 没有被触发
- 检查 Hook 是否正确注册（在 `initCampDesign()` 等初始化方法中）
- 检查触发条件是否满足
- 确认相关功能是否正常工作

### 问题：上报方法被调用但 spanId 为空
- 检查是否被限流拦截
- 检查 GalileoReporter 是否正确初始化
- 检查网络连接

### 问题：伽利略平台查不到数据
- 等待数据同步（可能有延迟）
- 确认指标名称拼写正确
- 确认使用的环境（测试/生产）
- 检查上报参数是否符合平台要求

## Quick Reference

### 常用日志模板

```dart
// Hook 触发日志
Log.d('HookName', 'Hook triggered: param=$param');

// 条件判断日志
Log.d('MetricName', 'Check condition: isSuccess=$isSuccess');

// 上报日志
Log.d('MetricName', 'Reporting: moduleName=$moduleName, status=$status');

// 限流日志
Log.d('MetricName', 'Rate limited, skipping report');

// 结果日志
Log.d('MetricName', 'Report completed: spanId=$spanId');
```

## Resources

This skill includes example resource directories that demonstrate how to organize different types of bundled resources:

### scripts/
Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

**Examples from other skills:**
- PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
- DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

**Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

**Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

### references/
Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

**Examples from other skills:**
- Product management: `communication.md`, `context_building.md` - detailed workflow guides
- BigQuery: API reference documentation and query examples
- Finance: Schema documentation, company policies

**Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

### assets/
Files not intended to be loaded into context, but rather used within the output Claude produces.

**Examples from other skills:**
- Brand styling: PowerPoint template files (.pptx), logo files
- Frontend builder: HTML/React boilerplate project directories
- Typography: Font files (.ttf, .woff2)

**Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

---

**Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
