import 'dart:ui' show Size;

import 'package:flutter/services.dart';

/// 全局横屏配置（T000）
class AppOrientation {
  AppOrientation._();

  /// 横屏设计稿尺寸（原竖屏 375×812 宽高对调）
  static const Size designSize = Size(812, 375);

  static const List<DeviceOrientation> preferredOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  /// 锁定为横屏（App 启动时调用）
  static Future<void> lockLandscape() {
    return SystemChrome.setPreferredOrientations(preferredOrientations);
  }

  static bool isLandscapeDesignSize(Size size) =>
      size.width > size.height;
}
