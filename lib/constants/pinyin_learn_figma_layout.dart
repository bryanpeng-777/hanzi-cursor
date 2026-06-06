/// Figma node `1-2`（1536×1024）→ 逻辑横屏画布（等比缩放，避免图片拉伸）。
abstract final class PinyinLearnFigmaLayout {
  static const double figmaW = 1536;
  static const double figmaH = 1024;
  static const double designW = 812;
  /// 与 Figma 画布同宽高比：1024 × (812/1536)
  static const double designH = figmaH * designW / figmaW;
  static const double scale = designW / figmaW;

  /// 等比缩放（宽高同一比例，保持切图不变形）
  static double s(double figmaPx) => figmaPx * scale;

  static double sx(double figmaX) => s(figmaX);
  static double sy(double figmaY) => s(figmaY);

  /// Figma 尺寸 × 卡片内缩放系数 → 逻辑像素
  static double innerPx(double figmaPx, double innerScale) =>
      s(figmaPx * innerScale);

  static double get headerBackLeft => sx(119);
  static double get headerBackTop => sy(47);
  static double get headerBackSize => sx(84);
  static double get headerBackHeight => sy(85);

  static double get titleDecoLeftPos => sx(552);
  static double get titleDecoLeftTop => sy(54);
  static double get titleDecoLeftW => sx(41);
  static double get titleDecoLeftH => sy(37);

  static double get titleLeft => sx(622);
  static double get titleTop => sy(40);
  static double get titleWidth => sx(300);
  static double get titleHeight => sy(87);

  static double get titleDecoRightLeft => sx(947);
  static double get titleDecoRightTop => sy(55);

  static double get headerAvatarLeft => sx(1329);
  static double get headerAvatarTop => sy(49);

  static double get mainPanelLeft => sx(76);
  static double get mainPanelTop => sy(132);

  static double get manualModeLeft => sx(425);
  static double get manualModeTop => sy(27);
  static double get manualModeW => sx(268);
  static double get manualModeH => sy(75);

  static double get autoModeLeft => sx(692);
  static double get autoModeTop => sy(27);
  static double get autoModeW => sx(267);

  static double get tabBarCanvasLeft => sx(158); // groups(76) + tabBar(82)
  static double get tabBarCanvasTop => sy(248); // groups(132) + tabBar(116)
  static const double tabBarCanvasTopFigma = 248;
  static const double tabBarHeightFigma = 67;
  static const double gridCanvasTopFigma = 240;
  /// Tab 栏底边与首行卡片之间的留白（Figma px）
  static const double tabToCardGapFigma = 36;
  static double get gridCardsTopInsetFigma {
    final tabBottom = tabBarCanvasTopFigma + tabBarHeightFigma;
    return tabBottom + tabToCardGapFigma - gridCanvasTopFigma;
  }
  static double get gridCardsTopInset => s(gridCardsTopInsetFigma);
  static double get tabBarLeft => sx(82);
  static double get tabBarTop => sy(116);
  static double get tabBarW => sx(1358);
  static double get tabBarH => sy(67);

  /// Tab 文案区（相对 tabBar 容器，Figma px）
  static const List<double> tabLabelLefts = [218, 581, 932];
  static const List<double> tabLabelWidths = [57, 56, 56];
  static const double tabIndicatorWidthFigma = 76;
  static const double tabIndicatorTopInBar = 62; // grid(108+70) - tabBar(116)

  static double tabIndicatorLeftFor(int tabIndex) {
    final labelLeft = tabLabelLefts[tabIndex];
    final labelW = tabLabelWidths[tabIndex];
    return s(labelLeft + labelW / 2 - tabIndicatorWidthFigma / 2);
  }

  static double get tabInitialsLeft => sx(218);
  static double get tabFinalsLeft => sx(581);
  static double get tabTonesLeft => sx(932);
  static double get tabLabelTop => sy(20);

  static double get tabIndicatorLeft => sx(209);
  static double get tabIndicatorTop => sy(70);
  static double get tabIndicatorW => sx(76);
  static double get tabIndicatorH => sy(6);

  static double get gridCanvasLeft => sx(157); // groups(76) + grid(81)
  static double get gridCanvasTop => sy(240); // groups(132) + grid(108)
  static double get gridAreaLeft => sx(81);
  static double get gridAreaTop => sy(108);
  static double get gridAreaW => sx(1218);
  static double get gridAreaH => sy(544);

  static double get statsLeft => sx(173); // groups(76) + stats(97)
  static double get statsTop => sy(809); // groups(132) + stats(677)
  static double get statsW => sx(1359);
  static double get statsH => sy(121);
}
