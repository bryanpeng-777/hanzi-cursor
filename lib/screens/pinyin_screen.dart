import 'package:cs_ui/cs_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/pinyin_figma_assets.dart';
import '../constants/pinyin_hub_figma_layout.dart';
import '../providers/learning_provider.dart';

/// 拼音 Hub — Codia / Figma node `9-55`「拼音乐园」
///
/// 1536×1024 设计稿经 [PinyinHubFigmaLayout] 映射到 812×375 横屏画布，
/// 外层 [FittedBox] 按屏宽等比缩放，保留 Codia 绝对定位层级关系。
class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

  static const Color _titleInk = Color(0xFF202B34);
  static const Color _subtitleMuted = Color(0xFF5F869D);
  static const Color _accentLearn = Color(0xFF2EB28A);
  static const Color _accentQuiz = Color(0xFFFB8A25);
  static const Color _accentMistake = Color(0xFFFA748A);
  static const Color _cardSubtitle = Color(0xFF939395);
  static const Color _tipText = Color(0xFFF67F7C);
  static const Color _tipBg = Color(0xFFFCEBE8);
  static const Color _tipBorder = Color(0xFFEAEBF0);
  static const Color _sloganColor = Color(0xFF478EDD);
  static const Color _headerBlue = Color(0xFF2C91F1);
  static const Color _headerWatermark = Color(0xFFE7F2FC);

  static TextStyle _textStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
  }) {
    return GoogleFonts.notoSansSc(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount =
        ref.watch(learningNotifierProvider).pinyinMistakes.length;
    final points = ref.watch(learningNotifierProvider).totalStars;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledH = PinyinHubFigmaLayout.designH *
            constraints.maxWidth /
            PinyinHubFigmaLayout.designW;
        final needsScroll = scaledH > constraints.maxHeight + 0.5;

        final hub = SizedBox(
          width: constraints.maxWidth,
          height: scaledH,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: PinyinHubFigmaLayout.designW,
              height: PinyinHubFigmaLayout.designH,
              child: Stack(
                key: const Key('hanzi-pinyin-hub-landscape'),
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      PinyinFigmaAssetPaths.canvasBackdrop,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  _watermark(
                    PinyinFigmaAssetPaths.watermarkA,
                    left: PinyinHubFigmaLayout.watermarkALeft,
                    top: PinyinHubFigmaLayout.watermarkATop,
                    width: PinyinHubFigmaLayout.watermarkAWidth,
                    height: PinyinHubFigmaLayout.watermarkAHeight,
                  ),
                  _watermark(
                    PinyinFigmaAssetPaths.watermarkE,
                    left: PinyinHubFigmaLayout.watermarkELeft,
                    top: PinyinHubFigmaLayout.watermarkETop,
                    width: PinyinHubFigmaLayout.watermarkEWidth,
                    height: PinyinHubFigmaLayout.watermarkEHeight,
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.decorDotLeft,
                    top: PinyinHubFigmaLayout.decorDotTop,
                    child: IgnorePointer(
                      child: _asset(
                        PinyinFigmaAssetPaths.decorDot,
                        PinyinHubFigmaLayout.decorDotSize,
                        PinyinHubFigmaLayout.decorDotSize,
                      ),
                    ),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.headerPinyinLeft,
                    top: PinyinHubFigmaLayout.headerPinyinTop,
                    width: PinyinHubFigmaLayout.headerPinyinWidth,
                    height: PinyinHubFigmaLayout.headerPinyinHeight,
                    child: _headerPinyinChip(),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.headerBabyLeft,
                    top: PinyinHubFigmaLayout.headerBabyTop,
                    width: PinyinHubFigmaLayout.headerBabyWidth,
                    height: PinyinHubFigmaLayout.headerBabyHeight,
                    child: _headerBabyChip(points),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: PinyinHubFigmaLayout.titleTop,
                    child: Text(
                      '拼音乐园',
                      key: const Key('hanzi-pinyin-hub-header-chip'),
                      textAlign: TextAlign.center,
                      style: _textStyle(
                        fontSize: PinyinHubFigmaLayout.titleFontSize,
                        color: _titleInk,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.subtitleLearnLeft,
                    top: PinyinHubFigmaLayout.subtitleTop,
                    child: Text(
                      '快乐拼读',
                      style: _textStyle(
                        fontSize: PinyinHubFigmaLayout.subtitleFontSize,
                        color: _subtitleMuted,
                      ),
                    ),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.subtitleOpenLeft,
                    top: PinyinHubFigmaLayout.subtitleTop,
                    child: Text(
                      '自信开',
                      style: _textStyle(
                        fontSize: PinyinHubFigmaLayout.subtitleFontSize,
                        color: _subtitleMuted,
                      ),
                    ),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.learnCardLeft,
                    top: PinyinHubFigmaLayout.learnCardTop,
                    width: PinyinHubFigmaLayout.learnCardWidth,
                    height: PinyinHubFigmaLayout.learnCardHeight,
                    child: _learnCard(context),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.quizCardLeft,
                    top: PinyinHubFigmaLayout.quizCardTop,
                    width: PinyinHubFigmaLayout.quizCardWidth,
                    height: PinyinHubFigmaLayout.quizCardHeight,
                    child: _quizCard(context),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.mistakeCardLeft,
                    top: PinyinHubFigmaLayout.mistakeCardTop,
                    width: PinyinHubFigmaLayout.mistakeCardWidth,
                    height: PinyinHubFigmaLayout.mistakeCardHeight,
                    child: _mistakeCard(context, mistakeCount),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.tipBarLeft,
                    top: PinyinHubFigmaLayout.tipBarTop,
                    width: PinyinHubFigmaLayout.tipBarWidth,
                    height: PinyinHubFigmaLayout.tipBarHeight,
                    child: _tipBar(),
                  ),
                  Positioned(
                    left: PinyinHubFigmaLayout.sloganLeft,
                    top: PinyinHubFigmaLayout.sloganTop,
                    child: _slogan(),
                  ),
                ],
              ),
            ),
          ),
        );

        if (needsScroll) {
          return SingleChildScrollView(
            key: const Key('hanzi-pinyin-hub-scroll'),
            physics: const ClampingScrollPhysics(),
            child: hub,
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: hub,
        );
      },
    );
  }

  static Widget _asset(
    String path,
    double width,
    double height, {
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }

  static Widget _watermark(
    String path, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.35,
          child: _asset(path, width, height),
        ),
      ),
    );
  }

  Widget _headerPinyinChip() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: PinyinHubFigmaLayout.headerPinyinBgLeft,
          top: PinyinHubFigmaLayout.headerPinyinBgTop,
          child: _asset(
            PinyinFigmaAssetPaths.headerPinyinBg,
            PinyinHubFigmaLayout.headerPinyinBgWidth,
            PinyinHubFigmaLayout.headerPinyinBgHeight,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerPinyinWatermarkLeft,
          top: PinyinHubFigmaLayout.headerPinyinWatermarkTop,
          child: Text(
            'a',
            style: _textStyle(
              fontSize: PinyinHubFigmaLayout.headerPinyinWatermarkFontSize,
              color: _headerWatermark,
              fontWeight: FontWeight.w400,
              height: 1.0,
            ),
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerPinyinIconLeft,
          top: PinyinHubFigmaLayout.headerPinyinIconTop,
          child: _asset(
            PinyinFigmaAssetPaths.headerPinyinIcon,
            PinyinHubFigmaLayout.headerPinyinIconWidth,
            PinyinHubFigmaLayout.headerPinyinIconHeight,
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerPinyinLabelLeft,
          top: PinyinHubFigmaLayout.headerPinyinLabelTop,
          child: Text(
            '拼音',
            style: _textStyle(
              fontSize: PinyinHubFigmaLayout.headerPinyinLabelFontSize,
              color: _headerBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerBabyChip(int points) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: PinyinHubFigmaLayout.headerBabyBgLeft,
          top: PinyinHubFigmaLayout.headerBabyBgTop,
          child: _asset(
            PinyinFigmaAssetPaths.headerBabyBg,
            PinyinHubFigmaLayout.headerBabyBgWidth,
            PinyinHubFigmaLayout.headerBabyBgHeight,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerBabyAvatarLeft,
          top: PinyinHubFigmaLayout.headerBabyAvatarTop,
          child: _asset(
            PinyinFigmaAssetPaths.headerBabyAvatar,
            PinyinHubFigmaLayout.headerBabyAvatarWidth,
            PinyinHubFigmaLayout.headerBabyAvatarHeight,
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerBabyLabelLeft,
          top: PinyinHubFigmaLayout.headerBabyLabelTop,
          child: Text(
            '宝宝',
            style: _textStyle(
              fontSize: PinyinHubFigmaLayout.headerBabyLabelFontSize,
              color: const Color(0xFF7B7C7E),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerBabyPointsLeft,
          top: PinyinHubFigmaLayout.headerBabyPointsTop,
          child: Text(
            '$points',
            style: _textStyle(
              fontSize: PinyinHubFigmaLayout.headerBabyPointsFontSize,
              color: const Color(0xFF898A8D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          left: PinyinHubFigmaLayout.headerBabyArrowLeft,
          top: PinyinHubFigmaLayout.headerBabyArrowTop,
          child: _asset(
            PinyinFigmaAssetPaths.headerBabyArrow,
            PinyinHubFigmaLayout.headerBabyArrowWidth,
            PinyinHubFigmaLayout.headerBabyArrowHeight,
          ),
        ),
      ],
    );
  }

  Widget _learnCard(BuildContext context) {
    return GestureDetector(
      key: const Key('hanzi-pinyin-hub-learn'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/pinyin-learn'),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _asset(
                PinyinFigmaAssetPaths.cardLearnBg,
                PinyinHubFigmaLayout.learnCardWidth,
                PinyinHubFigmaLayout.learnCardHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: PinyinHubFigmaLayout.learnTitleLeft,
            top: PinyinHubFigmaLayout.learnTitleTop,
            child: Text(
              '开始学习',
              style: _textStyle(
                fontSize: PinyinHubFigmaLayout.learnTitleFontSize,
                color: _accentLearn,
              ),
            ),
          ),
          Positioned(
            left: PinyinHubFigmaLayout.learnSubtitleLeft,
            top: PinyinHubFigmaLayout.learnSubtitleTop,
            child: Text(
              '系统学拼音，打好基础',
              style: _textStyle(
                fontSize: PinyinHubFigmaLayout.learnSubtitleFontSize,
                color: _cardSubtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quizCard(BuildContext context) {
    return GestureDetector(
      key: const Key('hanzi-pinyin-hub-quiz'),
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/pinyin-exercise'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFCFC),
          borderRadius: BorderRadius.circular(PinyinHubFigmaLayout.sy(36)),
          border: Border.all(color: const Color(0xFFBDDDEE)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: PinyinHubFigmaLayout.quizTitleLeft,
              top: PinyinHubFigmaLayout.quizTitleTop,
              child: Text(
                '拼音测验',
                style: _textStyle(
                  fontSize: PinyinHubFigmaLayout.quizTitleFontSize,
                  color: _accentQuiz,
                ),
              ),
            ),
            Positioned(
              left: PinyinHubFigmaLayout.quizSubtitleLeft,
              top: PinyinHubFigmaLayout.quizSubtitleTop,
              child: Text(
                '巩固拼音，检验掌握',
                style: _textStyle(
                  fontSize: PinyinHubFigmaLayout.quizSubtitleFontSize,
                  color: const Color(0xFF969799),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Positioned(
              left: PinyinHubFigmaLayout.quizIllusLeft,
              top: PinyinHubFigmaLayout.quizIllusTop,
              child: IgnorePointer(
                child: CsImage(
                  configKey: 'img_card_pinyin_quiz',
                  description: '拼音测验卡插画',
                  width: PinyinHubFigmaLayout.quizIllusWidth,
                  height: PinyinHubFigmaLayout.quizIllusHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: PinyinHubFigmaLayout.quizArrowLeft,
              top: PinyinHubFigmaLayout.quizArrowTop,
              child: IgnorePointer(
                child: _asset(
                  PinyinFigmaAssetPaths.cardQuizArrow,
                  PinyinHubFigmaLayout.quizArrowWidth,
                  PinyinHubFigmaLayout.quizArrowHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mistakeCard(BuildContext context, int mistakeCount) {
    final hasMistakes = mistakeCount > 0;

    return GestureDetector(
      key: const Key('hanzi-pinyin-hub-mistake'),
      behavior: HitTestBehavior.opaque,
      onTap: hasMistakes
          ? () => context.push('/pinyin-exercise', extra: {'mistakeMode': true})
          : null,
      child: Opacity(
        opacity: hasMistakes ? 1 : 0.58,
        child: Stack(
          children: [
            if (hasMistakes)
              Positioned.fill(
                child: IgnorePointer(
                  child: _asset(
                    PinyinFigmaAssetPaths.cardMistakeBg,
                    PinyinHubFigmaLayout.mistakeCardWidth,
                    PinyinHubFigmaLayout.mistakeCardHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else
              const ColoredBox(color: Color(0xFFF5F5F5)),
            Positioned(
              left: PinyinHubFigmaLayout.mistakeTitleLeft,
              top: PinyinHubFigmaLayout.mistakeTitleTop,
              child: Text(
                '错题本',
                style: _textStyle(
                  fontSize: PinyinHubFigmaLayout.mistakeTitleFontSize,
                  color: hasMistakes ? _accentMistake : Colors.grey.shade500,
                ),
              ),
            ),
            Positioned(
              left: PinyinHubFigmaLayout.mistakeSubtitleLeft,
              top: PinyinHubFigmaLayout.mistakeSubtitleTop,
              child: Text(
                '错题回顾，查漏补缺',
                style: _textStyle(
                  fontSize: PinyinHubFigmaLayout.mistakeSubtitleFontSize,
                  color: const Color(0xFF969698),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasMistakes) ...[
              Positioned(
                left: PinyinHubFigmaLayout.mistakeIllusLeft,
                top: PinyinHubFigmaLayout.mistakeIllusTop,
                child: IgnorePointer(
                  child: _asset(
                    PinyinFigmaAssetPaths.cardMistakeIllus,
                    PinyinHubFigmaLayout.mistakeIllusWidth,
                    PinyinHubFigmaLayout.mistakeIllusHeight,
                  ),
                ),
              ),
              Positioned(
                left: PinyinHubFigmaLayout.mistakeArrowLeft,
                top: PinyinHubFigmaLayout.mistakeArrowTop,
                child: IgnorePointer(
                  child: _asset(
                    PinyinFigmaAssetPaths.cardMistakeArrow,
                    PinyinHubFigmaLayout.mistakeArrowWidth,
                    PinyinHubFigmaLayout.mistakeArrowHeight,
                  ),
                ),
              ),
              if (mistakeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _MistakeBadge('$mistakeCount'),
                ),
            ] else
              Center(
                child: CsImage(
                  configKey: 'img_card_pinyin_mistakes_empty',
                  description: '无错题',
                  width: PinyinHubFigmaLayout.mistakesEmptyIconSize,
                  height: PinyinHubFigmaLayout.mistakesEmptyIconSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tipBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tipBg,
        borderRadius:
            BorderRadius.circular(PinyinHubFigmaLayout.sy(32)),
        border: Border.all(color: _tipBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: PinyinHubFigmaLayout.sx(16)),
        child: Row(
          children: [
            _asset(
              PinyinFigmaAssetPaths.tipIcon,
              PinyinHubFigmaLayout.tipIconWidth,
              PinyinHubFigmaLayout.tipIconHeight,
            ),
            SizedBox(width: PinyinHubFigmaLayout.sx(12)),
            Expanded(
              child: Text(
                '每天坚持学习，拼音进步看得见!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textStyle(
                  fontSize: PinyinHubFigmaLayout.tipFontSize,
                  color: _tipText,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slogan() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _asset(
          PinyinFigmaAssetPaths.sloganDecor,
          PinyinHubFigmaLayout.sloganDecorWidth,
          PinyinHubFigmaLayout.sloganDecorHeight,
        ),
        SizedBox(width: PinyinHubFigmaLayout.sx(8)),
        Text(
          '拼得快乐，读得自信！',
          style: _textStyle(
            fontSize: PinyinHubFigmaLayout.sloganFontSize,
            color: _sloganColor,
          ),
        ),
      ],
    );
  }
}

class _MistakeBadge extends StatelessWidget {
  const _MistakeBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFE4940),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansSc(
          color: const Color(0xFFFFF3F1),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
