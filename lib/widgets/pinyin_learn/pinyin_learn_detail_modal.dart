import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/pinyin_learn_d2c_4_2_layout.dart';
import '../../constants/pinyin_learn_ui_assets.dart';
import '../../data/pinyin_data.dart';
import '../../utils/pinyin_speech.dart';
import 'figma_ui_image.dart';

/// 拼音学习详情 — Figma node 4-2（tdesign-d2c 绝对坐标）
class PinyinLearnDetailModal extends StatefulWidget {
  const PinyinLearnDetailModal({super.key, required this.item});

  final PinyinItem item;

  static Future<void> show(BuildContext context, PinyinItem item) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭拼音详情',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) =>
          PinyinLearnDetailModal(key: const Key('hanzi-pinyin-learn-detail-modal'), item: item),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<PinyinLearnDetailModal> createState() => _PinyinLearnDetailModalState();
}

class _PinyinLearnDetailModalState extends State<PinyinLearnDetailModal> {
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
  }

  Future<void> _speakPinyin() async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(PinyinSpeech.frontSpeech(widget.item));
  }

  Future<void> _speakHanzi(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              final scale = (maxW / PinyinLearnD2c42Layout.canvasW)
                  .clamp(0.0, maxH / PinyinLearnD2c42Layout.canvasH);
              final w = PinyinLearnD2c42Layout.canvasW * scale;
              final h = PinyinLearnD2c42Layout.canvasH * scale;

              return SizedBox(
                width: w,
                height: h,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: PinyinLearnD2c42Layout.canvasW,
                    height: PinyinLearnD2c42Layout.canvasH,
                    child: _buildCanvas(context),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(BuildContext context) {
    final item = widget.item;
    final examples = _buildExampleCards(item);
    final tones = _tonesForItem(item);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: ColoredBox(color: PinyinLearnD2c42Layout.surface),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: PinyinLearnD2c42Layout.leftBorderW,
            height: PinyinLearnD2c42Layout.canvasH,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailBorderLeft,
              description: '左侧边饰',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.rightBorderLeft,
            top: 0,
            width: PinyinLearnD2c42Layout.rightBorderW,
            height: PinyinLearnD2c42Layout.canvasH,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailBorderRight,
              description: '右侧边饰',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.cornerDecoLeftLeft,
            top: 0,
            width: PinyinLearnD2c42Layout.cornerDecoSize,
            height: PinyinLearnD2c42Layout.cornerDecoSize,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailCornerTopLeft,
              description: '左上角装饰',
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.cornerDecoRightLeft,
            top: 0,
            width: PinyinLearnD2c42Layout.cornerDecoSize,
            height: 89,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailCornerTopRight,
              description: '右上角装饰',
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.bottomLeftDecoLeft,
            top: PinyinLearnD2c42Layout.bottomLeftDecoTop,
            width: PinyinLearnD2c42Layout.bottomLeftDecoW,
            height: PinyinLearnD2c42Layout.bottomLeftDecoH,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailBottomDeco,
              description: '左下角装饰',
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.dragHandleLeft,
            top: PinyinLearnD2c42Layout.dragHandleTop,
            width: PinyinLearnD2c42Layout.dragHandleW,
            height: PinyinLearnD2c42Layout.dragHandleH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFD5D4D3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFDCDCD9)),
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.closeLeft,
            top: PinyinLearnD2c42Layout.closeTop,
            width: PinyinLearnD2c42Layout.closeW,
            height: PinyinLearnD2c42Layout.closeH,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const FigmaUiImage(
                configKey: PinyinLearnUiAssets.detailCloseBtn,
                description: '关闭',
                fit: BoxFit.contain,
              ),
            ),
          ),
          _buildLetterPanel(),
          _buildTonePanel(item, tones),
          if (examples.isNotEmpty)
            _buildExampleCard(
              left: PinyinLearnD2c42Layout.example1Left,
              top: PinyinLearnD2c42Layout.example1Top,
              width: PinyinLearnD2c42Layout.example1W,
              height: PinyinLearnD2c42Layout.example1H,
              data: examples[0],
              cardIndex: 0,
            ),
          if (examples.length > 1)
            _buildExampleCard(
              left: PinyinLearnD2c42Layout.example2Left,
              top: PinyinLearnD2c42Layout.example2Top,
              width: PinyinLearnD2c42Layout.example2W,
              height: PinyinLearnD2c42Layout.example2H,
              data: examples[1],
              cardIndex: 1,
            ),
          Positioned(
            left: PinyinLearnD2c42Layout.illustrationLeft,
            top: PinyinLearnD2c42Layout.illustrationTop,
            width: PinyinLearnD2c42Layout.illustrationW,
            height: PinyinLearnD2c42Layout.illustrationH,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailRightIllustration,
              description: item.iconHint,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterPanel() {
    return Positioned(
      left: PinyinLearnD2c42Layout.letterPanelLeft,
      top: PinyinLearnD2c42Layout.letterPanelTop,
      width: PinyinLearnD2c42Layout.letterPanelW,
      height: PinyinLearnD2c42Layout.letterPanelH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 6,
            width: 586,
            height: 812,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PinyinLearnD2c42Layout.letterPanelBg,
                borderRadius: BorderRadius.circular(PinyinLearnD2c42Layout.letterPanelRadius),
                border: Border.all(
                  color: PinyinLearnD2c42Layout.letterPanelBorder,
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.learnedBadgeLeft,
            top: PinyinLearnD2c42Layout.learnedBadgeTop,
            width: PinyinLearnD2c42Layout.learnedBadgeSize,
            height: PinyinLearnD2c42Layout.learnedBadgeSize,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailLearnedBadge,
              description: '已学习角标',
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.learnedTextLeft,
            top: PinyinLearnD2c42Layout.learnedTextTop,
            child: Text(
              '已学习',
              style: GoogleFonts.notoSansSc(
                fontSize: 33,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5DB574),
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.letterStrokeLeft,
            top: PinyinLearnD2c42Layout.letterStrokeTop,
            width: PinyinLearnD2c42Layout.letterStrokeW,
            height: PinyinLearnD2c42Layout.letterStrokeH,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailLetterStroke,
              description: '拼音笔顺大字',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.speakerLeft,
            top: PinyinLearnD2c42Layout.speakerTop,
            width: PinyinLearnD2c42Layout.speakerSize,
            height: PinyinLearnD2c42Layout.speakerSize,
            child: GestureDetector(
              onTap: _speakPinyin,
              child: const FigmaUiImage(
                configKey: PinyinLearnUiAssets.detailLetterPanel,
                description: '听拼音',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTonePanel(PinyinItem item, List<String> tones) {
    return Positioned(
      left: PinyinLearnD2c42Layout.tonePanelLeft,
      top: PinyinLearnD2c42Layout.tonePanelTop,
      width: PinyinLearnD2c42Layout.tonePanelW,
      height: PinyinLearnD2c42Layout.tonePanelH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 5,
            top: 140,
            width: 662,
            height: 783,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PinyinLearnD2c42Layout.tonePanelBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(49),
                  topRight: Radius.circular(38),
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(42),
                ),
                border: Border.all(color: PinyinLearnD2c42Layout.tonePanelBorder, width: 2),
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnD2c42Layout.toneTitleLeft,
            top: PinyinLearnD2c42Layout.toneTitleTop,
            child: Text(
              item.type == 'initial' ? '声母${item.symbol}' : '韵母${item.symbol}',
              style: GoogleFonts.notoSansSc(
                fontSize: 91,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C4A6D),
                height: 1.1,
              ),
            ),
          ),
          for (final entry in [
            (PinyinLearnD2c42Layout.toneLine1Top, PinyinLearnUiAssets.detailToneLine1),
            (PinyinLearnD2c42Layout.toneLine2Top, PinyinLearnUiAssets.detailToneLine2),
            (PinyinLearnD2c42Layout.toneLine3Top, PinyinLearnUiAssets.detailToneLine3),
            (PinyinLearnD2c42Layout.toneLine4Top, PinyinLearnUiAssets.detailToneLine4),
          ])
            Positioned(
              left: PinyinLearnD2c42Layout.toneLineLeft,
              top: entry.$1,
              width: PinyinLearnD2c42Layout.toneLineW,
              height: 11,
              child: FigmaUiImage(
                configKey: entry.$2,
                description: '声调分隔线',
                fit: BoxFit.fill,
              ),
            ),
          Positioned(
            left: PinyinLearnD2c42Layout.toneDividerLeft,
            top: PinyinLearnD2c42Layout.toneDividerTop,
            width: PinyinLearnD2c42Layout.toneDividerW,
            height: PinyinLearnD2c42Layout.toneDividerH,
            child: const FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailToneDivider,
              description: '声调竖分隔',
              fit: BoxFit.fill,
            ),
          ),
          if (tones.isNotEmpty) ...[
            _toneText(
              tones[0],
              left: PinyinLearnD2c42Layout.toneBa1Left,
              top: PinyinLearnD2c42Layout.toneBa1Top,
              color: PinyinLearnD2c42Layout.toneColors[0],
            ),
            if (tones.length > 1)
              _toneText(
                tones[1],
                left: PinyinLearnD2c42Layout.toneBa2Left,
                top: PinyinLearnD2c42Layout.toneBa2Top,
                color: PinyinLearnD2c42Layout.toneColors[1],
              ),
            if (tones.length > 2)
              _toneText(
                tones[2],
                left: PinyinLearnD2c42Layout.toneB3Left,
                top: PinyinLearnD2c42Layout.toneB3Top,
                color: PinyinLearnD2c42Layout.toneColors[2],
                fontSize: tones[2].length <= 1 ? 141 : 129,
              ),
            if (tones.length > 3)
              _toneText(
                tones[3],
                left: PinyinLearnD2c42Layout.toneBa4Left,
                top: PinyinLearnD2c42Layout.toneBa4Top,
                color: PinyinLearnD2c42Layout.toneColors[3],
              ),
          ],
          Positioned(
            left: PinyinLearnD2c42Layout.toneMnemonicLeft,
            top: PinyinLearnD2c42Layout.toneMnemonicTop,
            width: 531,
            child: Text(
              item.mnemonic,
              style: GoogleFonts.notoSansSc(
                fontSize: 67,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF747374),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toneText(
    String text, {
    required double left,
    required double top,
    required Color color,
    double fontSize = 129,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Text(
        text,
        style: GoogleFonts.notoSansSc(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildExampleCard({
    required double left,
    required double top,
    required double width,
    required double height,
    required _ExampleCardData data,
    required int cardIndex,
  }) {
    final isFirst = cardIndex == 0;
    final blendColor = isFirst ? const Color(0xFFF56E8D) : const Color(0xFF68BA7A);
    final pinyinColor = isFirst ? const Color(0xFFF8718D) : const Color(0xFF69BA7D);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => _speakHanzi(data.hanzi),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: isFirst ? 3 : 8,
              top: isFirst ? 2 : 5,
              width: 535,
              height: isFirst ? 366 : 391,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFAF9),
                  borderRadius: BorderRadius.circular(37),
                  border: Border.all(
                    color: isFirst ? const Color(0xFFECEBEA) : const Color(0xFFEEEDED),
                    width: isFirst ? 3 : 2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: isFirst ? 270 : 258,
              top: isFirst ? 46 : 99,
              width: isFirst ? 268 : 275,
              height: isFirst ? 323 : 302,
              child: FigmaUiImage(
                configKey: isFirst
                    ? PinyinLearnUiAssets.detailExampleDecoA
                    : PinyinLearnUiAssets.detailExampleDecoB,
                description: '例词卡装饰',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: isFirst ? 63 : 56,
              top: isFirst ? 52 : 51,
              child: Text(
                data.blend,
                style: GoogleFonts.notoSansSc(
                  fontSize: 56,
                  color: blendColor,
                  height: 1.1,
                ),
              ),
            ),
            Positioned(
              left: isFirst ? 59 : 65,
              top: isFirst ? 152 : 151,
              child: Text(
                data.hanzi,
                style: GoogleFonts.notoSansSc(
                  fontSize: isFirst ? 81 : 75,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF605F5F),
                  height: 1.1,
                ),
              ),
            ),
            Positioned(
              left: isFirst ? 66 : 67,
              top: isFirst ? 258 : 261,
              child: Text(
                data.pinyinLine,
                style: GoogleFonts.notoSansSc(
                  fontSize: isFirst ? 51 : 49,
                  color: pinyinColor,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _tonesForItem(PinyinItem item) {
    if (item.tones.isNotEmpty) return item.tones;
    if (item.type == 'initial') {
      final s = item.symbol;
      return ['${s}ā', '${s}á', s, '${s}à'];
    }
    return [];
  }

  List<_ExampleCardData> _buildExampleCards(PinyinItem item) {
    final cards = <_ExampleCardData>[];
    for (var i = 0; i < item.blendExamples.length && i < 2; i++) {
      final raw = item.blendExamples[i];
      final parts = raw.split('→');
      final blend = parts.first.trim();
      final char = parts.length > 1 ? parts[1].trim() : '';
      final hanzi = i < item.exampleWords.length ? item.exampleWords[i] : char;
      cards.add(
        _ExampleCardData(
          blend: blend,
          hanzi: hanzi,
          pinyinLine: _pinyinLineFor(hanzi, item),
        ),
      );
    }
    if (cards.isEmpty) {
      cards.add(
        _ExampleCardData(
          blend: item.examplePinyin,
          hanzi: item.example,
          pinyinLine: item.examplePinyin,
        ),
      );
    }
    return cards;
  }

  String _pinyinLineFor(String hanzi, PinyinItem item) {
    if (hanzi.length == 2 && hanzi[0] == hanzi[1]) {
      final base = item.examplePinyin;
      final tail = base.replaceAll(RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]'), 'a');
      return '$base$tail';
    }
    if (hanzi == '白色') return 'báisè';
    if (hanzi.length == 1) return item.examplePinyin;
    return item.examplePinyin;
  }
}

class _ExampleCardData {
  const _ExampleCardData({
    required this.blend,
    required this.hanzi,
    required this.pinyinLine,
  });

  final String blend;
  final String hanzi;
  final String pinyinLine;
}
