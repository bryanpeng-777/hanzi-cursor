import 'package:flutter/foundation.dart';

/// Harness Playground 路由注册表（kDebugMode 下使用）
class DevRouter {
  DevRouter._();

  static const t000PlaygroundRoute = '/dev/T000-landscape';
  static const t001PlaygroundRoute = '/dev/T001-design-system';

  /// 所有已注册的 Playground 入口（供文档与后续扩展）
  static Map<String, String> get playgroundEntries {
    if (!kDebugMode) return {};
    return {
      t000PlaygroundRoute: 'lib/dev/T000_playground.dart',
      t001PlaygroundRoute: 'lib/dev/T001_playground.dart',
    };
  }
}
