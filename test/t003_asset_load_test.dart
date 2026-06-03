import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('figma_d2c splash assets are in bundle', () async {
    for (final path in [
      'assets/figma_d2c/splash_bg_canvas_image.png',
      'assets/figma_d2c/img_splash_logo.png',
      'assets/figma_d2c/splash_decor_top_left_icon.png',
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });
}
