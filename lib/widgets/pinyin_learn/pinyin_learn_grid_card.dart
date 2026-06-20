import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/pinyin_learn_grid_9_2_cards.dart';
import '../../data/pinyin_data.dart';
import 'figma_ui_image.dart';

/// Figma node 9-2 拼音网格卡片（粘土 3D 风格）
class PinyinLearnGridCard extends StatelessWidget {
  const PinyinLearnGridCard({
    super.key,
    required this.item,
    required this.index,
    required this.onOpenDetail,
    required this.onSpeak,
    this.useFallbackAccent = false,
  });

  final PinyinItem item;
  final int index;
  final VoidCallback onOpenDetail;
  final VoidCallback onSpeak;
  final bool useFallbackAccent;

  static const _letterColor = Color(0xFF214B8C);
  static const _cardBg = Color(0xFFFBFAF8);
  static const _exampleBorder = Color(0xFFD7CBBD);
  static const _exampleHanzi = Color(0xFF5C5B5C);
  static const _examplePinyin = Color(0xFF757576);

  @override
  Widget build(BuildContext context) {
    final visual = PinyinLearnGrid9Cards.visualFor(item.symbol, index);
    final hasCustomArt = visual.illustrationKey != null;

    return GestureDetector(
      onTap: onOpenDetail,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final scale = w / 279;

          return Container(
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(36 * scale),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 底部 accent 线
                Positioned(
                  left: 24 * scale,
                  right: 24 * scale,
                  bottom: 16 * scale,
                  height: 10 * scale,
                  child: useFallbackAccent
                      ? Container(
                          decoration: BoxDecoration(
                            color: PinyinLearnGrid9Cards.accentFallbackFor(index),
                            borderRadius: BorderRadius.circular(5 * scale),
                          ),
                        )
                      : FigmaUiImage(
                          configKey: visual.accentLineKey,
                          description: '${item.symbol} accent',
                          fit: BoxFit.fill,
                        ),
                ),
                // 例词框
                Positioned(
                  right: 20 * scale,
                  bottom: 32 * scale,
                  child: GestureDetector(
                    onTap: onSpeak,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 109 * scale,
                      height: 80 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFEFE),
                        border: Border.all(color: _exampleBorder),
                        borderRadius: BorderRadius.circular(14 * scale),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.examplePinyin,
                            style: GoogleFonts.notoSansSc(
                              fontSize: 20 * scale,
                              color: _examplePinyin,
                            ),
                          ),
                          Text(
                            item.example,
                            style: GoogleFonts.notoSansSc(
                              fontSize: 31 * scale,
                              fontWeight: FontWeight.w500,
                              color: _exampleHanzi,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 扬声器
                Positioned(
                  left: 20 * scale,
                  bottom: 38 * scale,
                  child: GestureDetector(
                    onTap: onSpeak,
                    behavior: HitTestBehavior.opaque,
                    child: FigmaUiImage(
                      configKey: visual.speakerKey,
                      description: '听${item.symbol}',
                      width: 87 * scale,
                      height: 87 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // 3D 插图
                if (hasCustomArt)
                  Positioned(
                    right: 18 * scale,
                    top: h * 0.28,
                    child: FigmaUiImage(
                      configKey: visual.illustrationKey!,
                      description: item.iconHint,
                      width: 126 * scale,
                      height: 130 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                // 声母大字
                Positioned(
                  left: 40 * scale,
                  top: h * 0.12,
                  child: visual.letterImageKey != null
                      ? FigmaUiImage(
                          configKey: visual.letterImageKey!,
                          description: item.symbol,
                          height: 110 * scale,
                          fit: BoxFit.contain,
                        )
                      : Text(
                          item.symbol,
                          style: GoogleFonts.notoSansSc(
                            fontSize: 110 * scale,
                            fontWeight: FontWeight.w700,
                            color: _letterColor,
                            height: 1,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
