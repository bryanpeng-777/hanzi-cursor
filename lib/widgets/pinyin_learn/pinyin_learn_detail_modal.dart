import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/pinyin_learn_ui_assets.dart';
import '../../data/pinyin_data.dart';
import '../../design/hanzi_design_spec.dart';
import '../../utils/pinyin_speech.dart';
import 'figma_ui_image.dart';

/// 拼音学习详情 — 非全屏模态（Figma node 4-2）
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth * 0.92;
              final maxH = constraints.maxHeight * 0.78;
              final scale = (maxW / PinyinLearnCanvasSize.detailW)
                  .clamp(0.0, maxH / PinyinLearnCanvasSize.detailH);
              final w = PinyinLearnCanvasSize.detailW * scale;
              final h = PinyinLearnCanvasSize.detailH * scale;

              return SizedBox(
                width: w,
                height: h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: const Color(0xFFFBFBFA)),
                      ),
                      Positioned.fill(
                        child: FigmaUiImage(
                          configKey: PinyinLearnUiAssets.detailModalBg,
                          description: '拼音详情模态背景',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        left: w * 0.42,
                        top: h * 0.02,
                        child: Container(
                          width: 170 * scale,
                          height: 20 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD5D4D3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 50 * scale,
                        top: 45 * scale,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: FigmaUiImage(
                            configKey: PinyinLearnUiAssets.detailCloseBtn,
                            description: '关闭',
                            width: 113 * scale,
                            height: 115 * scale,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: h * 0.08,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLetterPanel(scale),
                            _buildTonePanel(scale),
                            _buildExamplesPanel(scale),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLetterPanel(double scale) {
    final item = widget.item;
    final isInitial = item.type == 'initial';
    return Expanded(
      flex: 597,
      child: Padding(
        padding: EdgeInsets.only(left: 50 * scale, bottom: 40 * scale),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF5EE),
                  borderRadius: BorderRadius.circular(44 * scale),
                  border: Border.all(color: const Color(0xFFE2EAE3), width: 3),
                ),
              ),
            ),
            Positioned(
              left: 40 * scale,
              top: 36 * scale,
              child: Row(
                children: [
                  FigmaUiImage(
                    configKey: PinyinLearnUiAssets.detailLearnedBadge,
                    description: '已学习',
                    width: 59 * scale,
                    height: 59 * scale,
                  ),
                  SizedBox(width: 12 * scale),
                  Text(
                    '已学习',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 33 * scale,
                      color: const Color(0xFF5DB574),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FigmaUiImage(
                    configKey: PinyinLearnUiAssets.detailLetterStroke,
                    description: '拼音大字笔顺',
                    width: 310 * scale,
                    height: 462 * scale,
                    fit: BoxFit.contain,
                  ),
                  if (!isInitial) ...[
                    SizedBox(height: 8 * scale),
                    Text(
                      item.symbol,
                      style: GoogleFonts.notoSansSc(
                        fontSize: 120 * scale,
                        fontWeight: FontWeight.w700,
                        color: HanziDesignSpec.titleInk,
                      ),
                    ),
                  ],
                  SizedBox(height: 16 * scale),
                  GestureDetector(
                    onTap: _speakPinyin,
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.detailLetterPanel,
                      description: '听拼音',
                      width: 179 * scale,
                      height: 179 * scale,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTonePanel(double scale) {
    final item = widget.item;
    final tones = item.tones.isNotEmpty
        ? item.tones
        : (item.type == 'initial'
            ? ['bā', 'bá', 'bǎ', 'bà']
            : <String>[]);
    final toneColors = [
      const Color(0xFF49A937),
      const Color(0xFF3588F1),
      const Color(0xFFFB7C20),
      const Color(0xFFF5587A),
    ];

    return Expanded(
      flex: 675,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 8 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFAF9),
            border: Border.all(color: const Color(0xFFEFEEEE), width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(24 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type == 'initial' ? '声母 ${item.symbol}' : '韵母 ${item.symbol}',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 48 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C4A6D),
                  ),
                ),
                SizedBox(height: 20 * scale),
                if (tones.isNotEmpty)
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        for (var i = 0; i < tones.length && i < 4; i++)
                          Center(
                            child: Text(
                              tones[i],
                              style: GoogleFonts.notoSansSc(
                                fontSize: 56 * scale,
                                fontWeight: FontWeight.w700,
                                color: toneColors[i % toneColors.length],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Text(
                  '「${item.mnemonic}」',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 28 * scale,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF747374),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamplesPanel(double scale) {
    final item = widget.item;
    final examples = item.blendExamples.take(2).toList();
    if (examples.isEmpty) {
      examples.addAll(['${item.example} ${item.examplePinyin}']);
    }

    return Expanded(
      flex: 875,
      child: Stack(
        children: [
          Positioned(
            right: 47 * scale,
            top: 80 * scale,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.detailRightIllustration,
              description: item.iconHint,
              width: 329 * scale,
              height: 778 * scale,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 20 * scale,
            top: 120 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final ex in examples.take(2))
                  Padding(
                    padding: EdgeInsets.only(bottom: 24 * scale),
                    child: _ExampleCard(
                      scale: scale,
                      label: ex,
                      hanzi: item.example,
                      onSpeak: () => _speakHanzi(item.example),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.scale,
    required this.label,
    required this.hanzi,
    required this.onSpeak,
  });

  final double scale;
  final String label;
  final String hanzi;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSpeak,
      child: Container(
        width: 539 * scale,
        padding: EdgeInsets.all(20 * scale),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF9),
          borderRadius: BorderRadius.circular(37 * scale),
          border: Border.all(color: const Color(0xFFECEBEA), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.notoSansSc(
                fontSize: 40 * scale,
                color: const Color(0xFF68BA7A),
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              hanzi,
              style: GoogleFonts.notoSansSc(
                fontSize: 64 * scale,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF605F5F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
