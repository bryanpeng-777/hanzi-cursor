import 'pinyin_learn_figma_layout.dart';

/// Figma node `1-2` 每个拼音卡片的绝对坐标（相对 grid 区，与 gridBg top=5 对齐）。
class PinyinLearnFigmaCardSpec {
  const PinyinLearnFigmaCardSpec({
    required this.left, required this.top, required this.width, required this.height,
    required this.letterLeft, required this.letterTop, required this.letterFontSize,
    required this.ttsLeft, required this.ttsTop, required this.ttsWidth, required this.ttsHeight,
    required this.ttsAsset, this.letterImageAsset, this.borderRadius = 18,
  });
  final double left, top, width, height;
  final double letterLeft, letterTop, letterFontSize;
  final double ttsLeft, ttsTop, ttsWidth, ttsHeight;
  final String ttsAsset;
  final String? letterImageAsset;
  final double borderRadius;
}

abstract final class PinyinLearnFigmaCards {
  static const String assetDir = 'assets/images/figma_pinyin_1_2';
  static const List<PinyinLearnFigmaCardSpec> initials = [
    // b
    PinyinLearnFigmaCardSpec(
      left: 22, top: 92, width: 144, height: 146,
      letterLeft: 58, letterTop: 26, letterFontSize: 54,
      ttsLeft: 55, ttsTop: 91, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/9426e1085ec86d7712d1261d9e729134.png', borderRadius: 19,
    ),
    // p
    PinyinLearnFigmaCardSpec(
      left: 175, top: 92, width: 140, height: 146,
      letterLeft: 55, letterTop: 36, letterFontSize: 53,
      ttsLeft: 52, ttsTop: 91, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/90d112b0e2a3f1dfed8c018b606aa614.png', borderRadius: 19,
    ),
    // m
    PinyinLearnFigmaCardSpec(
      left: 323, top: 92, width: 137, height: 146,
      letterLeft: 46, letterTop: 36, letterFontSize: 39,
      ttsLeft: 50, ttsTop: 91, ttsWidth: 38, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/11a3f74b3970a0bc01ed1a15d2d6172f.png', borderRadius: 18,
    ),
    // f
    PinyinLearnFigmaCardSpec(
      left: 468, top: 92, width: 139, height: 146,
      letterLeft: 58, letterTop: 27, letterFontSize: 54,
      ttsLeft: 51, ttsTop: 91, ttsWidth: 39, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/2ffe4570d163a0b7b6a8219e1a067814.png', borderRadius: 18,
    ),
    // d
    PinyinLearnFigmaCardSpec(
      left: 616, top: 92, width: 138, height: 146,
      letterLeft: 52, letterTop: 26, letterFontSize: 57,
      ttsLeft: 51, ttsTop: 91, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/3a5739761c39be4042a0d01da4cd5f1a.png', borderRadius: 18,
    ),
    // t
    PinyinLearnFigmaCardSpec(
      left: 762, top: 92, width: 139, height: 146,
      letterLeft: 58, letterTop: 32, letterFontSize: 54,
      ttsLeft: 52, ttsTop: 91, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/272de3e4e1d1338a2cd064dbb4a5b90c.png', borderRadius: 18,
    ),
    // n
    PinyinLearnFigmaCardSpec(
      left: 909, top: 92, width: 140, height: 146,
      letterLeft: 56, letterTop: 35, letterFontSize: 39,
      ttsLeft: 51, ttsTop: 90, ttsWidth: 39, ttsHeight: 39,
      ttsAsset: 'assets/images/figma_pinyin_1_2/0b61af61badf118757e728de96d41fc3.png', borderRadius: 19,
    ),
    // l
    PinyinLearnFigmaCardSpec(
      left: 1057, top: 92, width: 137, height: 146,
      letterLeft: 67, letterTop: 32, letterFontSize: 40,
      ttsLeft: 51, ttsTop: 91, ttsWidth: 38, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/d5fce16f9c365ee96022e8c252d23275.png', borderRadius: 18, letterImageAsset: 'assets/images/figma_pinyin_1_2/fe36c046359e02b2e4b2e0af4f3d2f1c.png',
    ),
    // g
    PinyinLearnFigmaCardSpec(
      left: 22, top: 246, width: 144, height: 142,
      letterLeft: 55, letterTop: 33, letterFontSize: 53,
      ttsLeft: 55, ttsTop: 87, ttsWidth: 37, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/8a91801f7436db722f3d9c1dc495905e.png', borderRadius: 19,
    ),
    // k
    PinyinLearnFigmaCardSpec(
      left: 175, top: 246, width: 140, height: 141,
      letterLeft: 55, letterTop: 23, letterFontSize: 56,
      ttsLeft: 52, ttsTop: 88, ttsWidth: 37, ttsHeight: 36,
      ttsAsset: 'assets/images/figma_pinyin_1_2/e3957c01a49a396fbae0c71b2598ea55.png', borderRadius: 19,
    ),
    // h
    PinyinLearnFigmaCardSpec(
      left: 323, top: 246, width: 137, height: 141,
      letterLeft: 55, letterTop: 23, letterFontSize: 53,
      ttsLeft: 50, ttsTop: 87, ttsWidth: 38, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/5dcc9e19cd9fc18e1baccad1fe9de56c.png', borderRadius: 18,
    ),
    // j
    PinyinLearnFigmaCardSpec(
      left: 468, top: 246, width: 139, height: 141,
      letterLeft: 58, letterTop: 24, letterFontSize: 70,
      ttsLeft: 52, ttsTop: 87, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/720421d6e516c2794251d476e80b41e4.png', borderRadius: 18,
    ),
    // q
    PinyinLearnFigmaCardSpec(
      left: 616, top: 246, width: 138, height: 141,
      letterLeft: 52, letterTop: 33, letterFontSize: 53,
      ttsLeft: 51, ttsTop: 88, ttsWidth: 37, ttsHeight: 36,
      ttsAsset: 'assets/images/figma_pinyin_1_2/ce7bff1d53e70a8e6a15e76c308ccf45.png', borderRadius: 18,
    ),
    // x
    PinyinLearnFigmaCardSpec(
      left: 762, top: 246, width: 139, height: 141,
      letterLeft: 54, letterTop: 33, letterFontSize: 39,
      ttsLeft: 52, ttsTop: 87, ttsWidth: 37, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/104c66ae80331a4c74d13fa76e5afb3d.png', borderRadius: 18,
    ),
    // zh
    PinyinLearnFigmaCardSpec(
      left: 909, top: 246, width: 139, height: 141,
      letterLeft: 41, letterTop: 23, letterFontSize: 51,
      ttsLeft: 52, ttsTop: 87, ttsWidth: 37, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/5e2f6618592c5f6708730410581cf95e.png', borderRadius: 18,
    ),
    // ch
    PinyinLearnFigmaCardSpec(
      left: 1058, top: 246, width: 137, height: 142,
      letterLeft: 39, letterTop: 23, letterFontSize: 51,
      ttsLeft: 50, ttsTop: 86, ttsWidth: 38, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/9ccca81fb433140d59a806b01f0f29d3.png', borderRadius: 18,
    ),
    // sh
    PinyinLearnFigmaCardSpec(
      left: 22, top: 394, width: 144, height: 138,
      letterLeft: 43, letterTop: 22, letterFontSize: 55,
      ttsLeft: 54, ttsTop: 82, ttsWidth: 39, ttsHeight: 38,
      ttsAsset: 'assets/images/figma_pinyin_1_2/3afa31d666e7bf6f51d7094637425505.png', borderRadius: 19,
    ),
    // r
    PinyinLearnFigmaCardSpec(
      left: 175, top: 395, width: 140, height: 136,
      letterLeft: 59, letterTop: 33, letterFontSize: 40,
      ttsLeft: 52, ttsTop: 81, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/757dc165d2cfbed54974664c3f6fd852.png', borderRadius: 19,
    ),
    // z
    PinyinLearnFigmaCardSpec(
      left: 323, top: 395, width: 137, height: 136,
      letterLeft: 55, letterTop: 31, letterFontSize: 39,
      ttsLeft: 51, ttsTop: 81, ttsWidth: 36, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/136a9133db19f534c2414aaa0d1d187c.png', borderRadius: 18,
    ),
    // c
    PinyinLearnFigmaCardSpec(
      left: 468, top: 395, width: 139, height: 136,
      letterLeft: 54, letterTop: 32, letterFontSize: 40,
      ttsLeft: 52, ttsTop: 81, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/51fed9e10824d57a7efdae66b9930aab.png', borderRadius: 18,
    ),
    // s
    PinyinLearnFigmaCardSpec(
      left: 616, top: 395, width: 138, height: 136,
      letterLeft: 56, letterTop: 32, letterFontSize: 40,
      ttsLeft: 51, ttsTop: 81, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/08bc2dfdade23ef0a1c9abcca8bec229.png', borderRadius: 18,
    ),
    // y
    PinyinLearnFigmaCardSpec(
      left: 762, top: 395, width: 138, height: 136,
      letterLeft: 55, letterTop: 31, letterFontSize: 52,
      ttsLeft: 52, ttsTop: 81, ttsWidth: 37, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/15d9e10dca921e4c3eda79a32e0be517.png', borderRadius: 18,
    ),
    // w
    PinyinLearnFigmaCardSpec(
      left: 909, top: 395, width: 140, height: 136,
      letterLeft: 46, letterTop: 31, letterFontSize: 40,
      ttsLeft: 51, ttsTop: 81, ttsWidth: 38, ttsHeight: 37,
      ttsAsset: 'assets/images/figma_pinyin_1_2/c29a910df6b40535272cdabf7f60ceb7.png', borderRadius: 19,
    ),
  ];
}
