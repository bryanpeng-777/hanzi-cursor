/// Figma node `9-55`（1536×1024）→ 逻辑横屏画布 812×375。
///
/// 与 tdesign-d2c `intermediate.tsx` 中 `s()` 换算一致（四舍五入到整像素）。
abstract final class PinyinHubFigmaLayout {
  static const double designW = 812;
  static const double designH = 375;

  static double sx(double figmaX) =>
      (figmaX * designW / 1536).roundToDouble();
  static double sy(double figmaY) =>
      (figmaY * designH / 1024).roundToDouble();

  /// Codia / Figma 字号 → 812×375 逻辑画布字号（按高度等比缩放）。
  static double sf(double figmaFontSize) =>
      (figmaFontSize * designH / 1024).roundToDouble();

  // 水印 / 装饰
  static double get watermarkALeft => sx(496);
  static double get watermarkATop => sy(121);
  static double get watermarkAWidth => sx(32);
  static double get watermarkAHeight => sy(79);

  static double get watermarkELeft => sx(1013);
  static double get watermarkETop => sy(120);
  static double get watermarkEWidth => sx(31);
  static double get watermarkEHeight => sy(79);

  static double get decorDotLeft => sx(894);
  static double get decorDotTop => sy(234);
  static double get decorDotSize => sx(26);

  // 顶栏拼音胶囊（根坐标 25,16）
  static double get headerPinyinLeft => sx(25);
  static double get headerPinyinTop => sy(16);
  static double get headerPinyinWidth => sx(235);
  static double get headerPinyinHeight => sy(102);
  static double get headerPinyinBgLeft => sx(49);
  static double get headerPinyinBgTop => sy(13);
  static double get headerPinyinBgWidth => sx(186);
  static double get headerPinyinBgHeight => sy(73);
  static double get headerPinyinIconLeft => sx(7);
  static double get headerPinyinIconTop => sy(6);
  static double get headerPinyinIconWidth => sx(87);
  static double get headerPinyinIconHeight => sy(92);
  static double get headerPinyinLabelLeft => sx(110);
  static double get headerPinyinLabelTop => sy(27);
  static double get headerPinyinWatermarkLeft => sx(37);
  static double get headerPinyinWatermarkTop => sy(31);
  static double get headerPinyinWatermarkFontSize => sf(57);
  static double get headerPinyinLabelFontSize => sf(34);

  // 顶栏宝宝胶囊（根坐标 1288,18）
  static double get headerBabyLeft => sx(1288);
  static double get headerBabyTop => sy(18);
  static double get headerBabyWidth => sx(216);
  static double get headerBabyHeight => sy(105);
  static double get headerBabyBgLeft => sx(17);
  static double get headerBabyBgTop => sy(14);
  static double get headerBabyBgWidth => sx(198);
  static double get headerBabyBgHeight => sy(87);
  static double get headerBabyAvatarLeft => sx(10);
  static double get headerBabyAvatarTop => sy(7);
  static double get headerBabyAvatarWidth => sx(88);
  static double get headerBabyAvatarHeight => sy(89);
  static double get headerBabyLabelLeft => sx(117);
  static double get headerBabyLabelTop => sy(26);
  static double get headerBabyPointsLeft => sx(144);
  static double get headerBabyPointsTop => sy(58);
  static double get headerBabyArrowLeft => sx(114);
  static double get headerBabyArrowTop => sy(60);
  static double get headerBabyArrowWidth => sx(23);
  static double get headerBabyArrowHeight => sy(22);
  static double get headerBabyLabelFontSize => sf(24);
  static double get headerBabyPointsFontSize => sf(19);

  // 标题区
  static double get titleTop => sy(99);
  static double get titleFontSize => sf(107);
  static double get subtitleTop => sy(225);
  static double get subtitleLearnLeft => sx(601);
  static double get subtitleOpenLeft => sx(781);
  static double get subtitleFontSize => sf(36);

  // 学习卡（根 128,300）
  static double get learnCardLeft => sx(128);
  static double get learnCardTop => sy(300);
  static double get learnCardWidth => sx(615);
  static double get learnCardHeight => sy(519);
  static double get learnTitleLeft => sx(65);
  static double get learnTitleTop => sy(44);
  static double get learnSubtitleLeft => sx(66);
  static double get learnSubtitleTop => sy(120);
  static double get learnTitleFontSize => sf(55);
  static double get learnSubtitleFontSize => sf(27);

  // 测验卡（根 749,313）
  static double get quizCardLeft => sx(749);
  static double get quizCardTop => sy(313);
  static double get quizCardWidth => sx(304);
  static double get quizCardHeight => sy(501);
  static double get quizTitleLeft => sx(48);
  static double get quizTitleTop => sy(39);
  static double get quizSubtitleLeft => sx(48);
  static double get quizSubtitleTop => sy(103);
  static double get quizIllusLeft => sx(24);
  static double get quizIllusTop => sy(162);
  static double get quizIllusWidth => sx(257);
  static double get quizIllusHeight => sy(218);
  static double get quizArrowLeft => sx(114);
  static double get quizArrowTop => sy(398);
  static double get quizArrowWidth => sx(77);
  static double get quizArrowHeight => sy(78);
  static double get quizTitleFontSize => sf(41);
  static double get quizSubtitleFontSize => sf(23);

  // 错题卡（根 1059,307）
  static double get mistakeCardLeft => sx(1059);
  static double get mistakeCardTop => sy(307);
  static double get mistakeCardWidth => sx(304);
  static double get mistakeCardHeight => sy(513);
  static double get mistakeTitleLeft => sx(59);
  static double get mistakeTitleTop => sy(47);
  static double get mistakeSubtitleLeft => sx(55);
  static double get mistakeSubtitleTop => sy(108);
  static double get mistakeIllusLeft => sx(66);
  static double get mistakeIllusTop => sy(166);
  static double get mistakeIllusWidth => sx(165);
  static double get mistakeIllusHeight => sy(227);
  static double get mistakeArrowLeft => sx(120);
  static double get mistakeArrowTop => sy(404);
  static double get mistakeArrowWidth => sx(76);
  static double get mistakeArrowHeight => sy(81);
  static double get mistakeTitleFontSize => sf(40);
  static double get mistakeSubtitleFontSize => sf(23);

  // 提示条 / Slogan
  static double get tipBarLeft => sx(421);
  static double get tipBarTop => sy(832);
  static double get tipBarWidth => sx(694);
  static double get tipBarHeight => sy(73);
  static double get tipIconWidth => sx(47);
  static double get tipIconHeight => sy(46);
  static double get tipFontSize => sf(27);

  static double get sloganLeft => sx(542);
  static double get sloganTop => sy(932);
  static double get sloganDecorWidth => sx(36);
  static double get sloganDecorHeight => sy(50);
  static double get sloganFontSize => sf(40);

  static double get mistakesEmptyIconSize => sx(120);
}
