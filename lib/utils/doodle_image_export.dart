import 'dart:ui' as ui;

import 'doodle_image_export_io.dart'
    if (dart.library.html) 'doodle_image_export_web.dart';

/// 将涂鸦画板导出并保存/分享
Future<String?> exportDoodlePng({
  required ui.Image image,
  required String fileName,
}) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;
  final bytes = byteData.buffer.asUint8List();
  return saveDoodlePngBytes(bytes: bytes, fileName: fileName);
}
