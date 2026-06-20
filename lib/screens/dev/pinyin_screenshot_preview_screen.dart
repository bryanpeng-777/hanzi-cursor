import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/pinyin_learn_figma_assets.dart';
import '../../design/hanzi_design_spec.dart';

/// screenshot-to-flutter 演示：由 UI 截图还原的拼音声母学习页（812×375 横屏）。
class PinyinScreenshotPreviewScreen extends ConsumerStatefulWidget {
  const PinyinScreenshotPreviewScreen({super.key});

  static const double designW = HanziDesignSpec.canvasWidth;
  static const double designH = HanziDesignSpec.canvasHeight;

  @override
  ConsumerState<PinyinScreenshotPreviewScreen> createState() =>
      _PinyinScreenshotPreviewScreenState();
}

class _PinyinScreenshotPreviewScreenState
    extends ConsumerState<PinyinScreenshotPreviewScreen> {
  int _tabIndex = 0;
  final FlutterTts _tts = FlutterTts();

  static const _initialCards = [
    _ScreenshotCard(
      letter: 'b',
      pinyin: 'bā',
      hanzi: '八',
      accent: Color(0xFFFF8FAB),
      artAsset:
          'assets/images/figma_pinyin_1_2/9426e1085ec86d7712d1261d9e729134.png',
    ),
    _ScreenshotCard(
      letter: 'p',
      pinyin: 'pó',
      hanzi: '婆',
      accent: Color(0xFFFFB347),
      artAsset:
          'assets/images/figma_pinyin_1_2/90d112b0e2a3f1dfed8c018b606aa614.png',
    ),
    _ScreenshotCard(
      letter: 'm',
      pinyin: 'mā',
      hanzi: '妈',
      accent: Color(0xFF7ED957),
      artAsset:
          'assets/images/figma_pinyin_1_2/11a3f74b3970a0bc01ed1a15d2d6172f.png',
    ),
    _ScreenshotCard(
      letter: 'f',
      pinyin: 'fó',
      hanzi: '佛',
      accent: Color(0xFFB388FF),
      artAsset:
          'assets/images/figma_pinyin_1_2/2ffe4570d163a0b7b6a8219e1a067814.png',
    ),
    _ScreenshotCard(
      letter: 'd',
      pinyin: 'dà',
      hanzi: '大',
      accent: Color(0xFF64B5F6),
      artAsset:
          'assets/images/figma_pinyin_1_2/3a5739761c39be4042a0d01da4cd5f1a.png',
    ),
    _ScreenshotCard(
      letter: 't',
      pinyin: 'tǔ',
      hanzi: '土',
      accent: Color(0xFF4DD0E1),
      artAsset:
          'assets/images/figma_pinyin_1_2/272de3e4e1d1338a2cd064dbb4a5b90c.png',
    ),
    _ScreenshotCard(
      letter: 'n',
      pinyin: 'ní',
      hanzi: '泥',
      accent: Color(0xFFFF8FAB),
      artAsset:
          'assets/images/figma_pinyin_1_2/0b61af61badf118757e728de96d41fc3.png',
    ),
    _ScreenshotCard(
      letter: 'l',
      pinyin: 'lì',
      hanzi: '力',
      accent: Color(0xFFFFB347),
      artAsset:
          'assets/images/figma_pinyin_1_2/d5fce16f9c365ee96022e8c252d23275.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scaledH =
              PinyinScreenshotPreviewScreen.designH *
              constraints.maxWidth /
              PinyinScreenshotPreviewScreen.designW;
          final canvas = SizedBox(
            width: constraints.maxWidth,
            height: scaledH,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: PinyinScreenshotPreviewScreen.designW,
                height: PinyinScreenshotPreviewScreen.designH,
                child: _ScreenshotCanvas(
                  tabIndex: _tabIndex,
                  onTabChanged: (i) => setState(() => _tabIndex = i),
                  onBack: () => context.pop(),
                  onSpeak: _speak,
                  cards: _initialCards,
                ),
              ),
            ),
          );

          if (scaledH > constraints.maxHeight + 0.5) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: canvas,
            );
          }
          return Align(alignment: Alignment.topCenter, child: canvas);
        },
      ),
    );
  }
}

class _ScreenshotCanvas extends StatelessWidget {
  const _ScreenshotCanvas({
    required this.tabIndex,
    required this.onTabChanged,
    required this.onBack,
    required this.onSpeak,
    required this.cards,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onBack;
  final Future<void> Function(String text) onSpeak;
  final List<_ScreenshotCard> cards;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.canvasBackdrop,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: 16,
          top: 10,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: onBack,
            child: Image.asset(
              PinyinLearnFigmaAssetPaths.backBtn,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: 280,
          top: 12,
          child: _SegmentToggle(
            tabIndex: tabIndex,
            onChanged: onTabChanged,
          ),
        ),
        Positioned(
          right: 16,
          top: 8,
          width: 48,
          height: 48,
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.headerAvatar,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: 24,
          top: 58,
          right: 24,
          bottom: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: HanziDesignSpec.cardShadow(
                color: HanziDesignSpec.cardShadowBlue,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: tabIndex == 0
                        ? _CardGrid(cards: cards, onSpeak: onSpeak)
                        : Center(
                            child: Text(
                              '韵母卡片（演示页仅还原声母截图）',
                              style: GoogleFonts.notoSansSc(
                                fontSize: 16,
                                color: HanziDesignSpec.subtitleMuted,
                              ),
                            ),
                          ),
                  ),
                ),
                const _ProgressFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({
    required this.tabIndex,
    required this.onChanged,
  });

  final int tabIndex;
  final ValueChanged<int> onChanged;

  static const _active = Color(0xFF42BAC4);
  static const _idleBg = Color(0xFFE8EEF2);
  static const _idleText = Color(0xFF406485);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _idleBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _chip('声母', 0),
          _chip('韵母', 1),
        ],
      ),
    );
  }

  Widget _chip(String label, int index) {
    final selected = tabIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _active : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansSc(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _idleText,
          ),
        ),
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.onSpeak,
  });

  final List<_ScreenshotCard> cards;
  final Future<void> Function(String text) onSpeak;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _ClayCard(
          data: cards[index],
          onSpeak: () => onSpeak(cards[index].pinyin),
        );
      },
    );
  }
}

class _ClayCard extends StatelessWidget {
  const _ClayCard({
    required this.data,
    required this.onSpeak,
  });

  final _ScreenshotCard data;
  final VoidCallback onSpeak;

  static const _letterBlue = Color(0xFF18496E);
  static const _speakerTeal = Color(0xFF42BAC4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF98D0C7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 4,
            top: 4,
            width: 58,
            height: 58,
            child: Image.asset(data.artAsset, fit: BoxFit.contain),
          ),
          Positioned(
            left: 10,
            top: 6,
            child: Text(
              data.letter,
              style: GoogleFonts.notoSansSc(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _letterBlue,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: onSpeak,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: _speakerTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                '${data.pinyin} ${data.hanzi}',
                style: GoogleFonts.notoSansSc(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _letterBlue,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: data.accent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FA),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDBECF8)),
      ),
      child: Row(
        children: [
          Image.asset(
            PinyinLearnFigmaAssetPaths.tipIcon,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '小朋友，继续加油哦！',
              style: GoogleFonts.notoSansSc(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF788799),
              ),
            ),
          ),
          _starBadge('16', filled: true),
          _dotLine(),
          _starBadge('20'),
          _dotLine(),
          _starBadge('30'),
          _dotLine(),
          _starBadge('40'),
          _dotLine(),
          _starBadge('50'),
          const SizedBox(width: 6),
          Icon(Icons.card_giftcard_rounded, color: Colors.blue.shade400, size: 28),
        ],
      ),
    );
  }

  Widget _starBadge(String value, {bool filled = false}) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFFD23F) : const Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: Text(
        value,
        style: GoogleFonts.notoSansSc(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: filled ? const Color(0xFF284059) : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _dotLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        '···',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade400,
          letterSpacing: -2,
        ),
      ),
    );
  }
}

class _ScreenshotCard {
  const _ScreenshotCard({
    required this.letter,
    required this.pinyin,
    required this.hanzi,
    required this.accent,
    required this.artAsset,
  });

  final String letter;
  final String pinyin;
  final String hanzi;
  final Color accent;
  final String artAsset;
}
