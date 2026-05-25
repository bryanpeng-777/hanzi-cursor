// TDD 合约：T001 - 设计系统与共享 UI 基座

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_app/design/hanzi_design_spec.dart';
import 'package:hanzi_app/utils/app_orientation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T001 设计系统与共享 UI 基座', () {
    test('test_theme_tokens_defined', () {
      expect(HanziDesignSpec.canvasWidth, AppOrientation.designSize.width);
      expect(HanziDesignSpec.canvasHeight, AppOrientation.designSize.height);

      expect(HanziDesignSpec.headerBlue, const Color(0xFF28A2E9));
      expect(HanziDesignSpec.titleInk, const Color(0xFF284059));
      expect(HanziDesignSpec.accentLearn, const Color(0xFF3EC9A7));
      expect(HanziDesignSpec.accentQuiz, const Color(0xFFFF7A5C));
      expect(HanziDesignSpec.accentMistake, const Color(0xFFFF6A88));

      expect(HanziDesignSpec.pagePaddingH, greaterThan(0));
      expect(HanziDesignSpec.cardRadius, greaterThan(0));
      expect(HanziDesignSpec.hubTitleStyle.fontSize, greaterThan(0));
    });
  });
}
