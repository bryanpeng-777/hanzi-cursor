// TDD 合约：T000 - 全局横屏适配

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  group('T000 全局横屏适配', () {
    test('test_design_size_is_landscape', () {
      expect(
        AppOrientation.isLandscapeDesignSize(AppOrientation.designSize),
        isTrue,
      );
      expect(AppOrientation.designSize.width, 812);
      expect(AppOrientation.designSize.height, 375);
    });

    test('test_preferred_orientations_landscape_only', () {
      expect(AppOrientation.preferredOrientations, hasLength(2));
      for (final o in AppOrientation.preferredOrientations) {
        expect(
          o == DeviceOrientation.landscapeLeft ||
              o == DeviceOrientation.landscapeRight,
          isTrue,
        );
      }
      expect(
        AppOrientation.preferredOrientations,
        isNot(contains(DeviceOrientation.portraitUp)),
      );
    });
  });
}
