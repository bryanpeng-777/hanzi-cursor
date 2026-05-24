import 'package:flutter/foundation.dart';

/// Harness Playground 路由注册表（kDebugMode 下使用）
class DevRouter {
  DevRouter._();

  static const t000PlaygroundRoute = '/dev/T000-landscape';

  /// 所有已注册的 Playground 入口（供文档与后续扩展）
  static Map<String, String> get playgroundEntries {
    if (!kDebugMode) return {};
    return {
      t000PlaygroundRoute: 'lib/dev/T000_playground.dart',
    };
  }
}
