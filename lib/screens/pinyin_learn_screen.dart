import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/pinyin_learn_ui_assets.dart';
import '../data/pinyin_data.dart';
import '../design/hanzi_design_spec.dart';
import '../utils/pinyin_speech.dart';
import '../widgets/pinyin_learn/figma_ui_image.dart';
import '../widgets/pinyin_learn/pinyin_learn_detail_modal.dart';

/// 拼音学习 — Figma node 9-2 网格 + 4-2 详情模态
class PinyinLearnScreen extends ConsumerStatefulWidget {
  const PinyinLearnScreen({super.key});

  @override
  ConsumerState<PinyinLearnScreen> createState() => _PinyinLearnScreenState();
}

class _PinyinLearnScreenState extends ConsumerState<PinyinLearnScreen> {
  int _tabIndex = 0;
  final _tts = FlutterTts();

  static const _tabActiveBg = Color(0xFF0BAEB9);
  static const _tabActiveBorder = Color(0xFFC1E5E7);
  static const _tabIdleBg = Color(0xFFEAE9E9);

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
  }

  Future<void> _speakPinyin(PinyinItem item) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(PinyinSpeech.frontSpeech(item));
  }

  void _openDetail(PinyinItem item) {
    PinyinLearnDetailModal.show(context, item);
  }

  @override
  Widget build(BuildContext context) {
    const learnedCount = 0;
    final progressTotal = allInitials.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledH = PinyinLearnCanvasSize.gridH *
            constraints.maxWidth /
            PinyinLearnCanvasSize.gridW;

        final canvas = SizedBox(
          width: constraints.maxWidth,
          height: scaledH,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: PinyinLearnCanvasSize.gridW,
              height: PinyinLearnCanvasSize.gridH,
              child: Stack(
                key: const Key('hanzi-pinyin-learn-landscape'),
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridCanvasBg,
                      description: '拼音学习全屏背景',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 115,
                    top: 157,
                    width: 1290,
                    height: 826,
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridPanelBg,
                      description: '主面板衬底',
                      fit: BoxFit.cover,
                    ),
                  ),
                  _buildTopBar(context),
                  _buildTabBar(),
                  _buildCardGrid(),
                  _buildStatsBar(learnedCount, progressTotal),
                  Positioned(
                    left: 99,
                    bottom: 214,
                    width: 166,
                    height: 155,
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridMascotPanda,
                      description: '左下熊猫',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Scaffold(
          body: scaledH > constraints.maxHeight + 0.5
              ? SingleChildScrollView(child: canvas)
              : Center(child: canvas),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      width: PinyinLearnCanvasSize.gridW,
      height: 158,
      child: Stack(
        children: [
          Positioned(
            left: 42,
            top: 33,
            width: 87,
            height: 90,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: FigmaUiImage(
                configKey: PinyinLearnUiAssets.gridBackBtn,
                description: '返回',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: 27,
            top: 16,
            width: 123,
            height: 123,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridAvatar,
              description: '头像',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Positioned(
      left: 543,
      top: 220,
      width: 450,
      height: 88,
      child: Stack(
        key: const Key('hanzi-pinyin-learn-tab-bar'),
        children: [
          Positioned(
            left: 228,
            child: _tabChip('韵母', 1),
          ),
          Positioned(
            left: 0,
            child: _tabChip('声母', 0),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        width: 214,
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _tabActiveBg : _tabIdleBg,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: selected ? _tabActiveBorder : const Color(0xFFD8DDDF),
            width: selected ? 4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansSc(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFFD4EEEE)
                : const Color(0xFF828283),
          ),
        ),
      ),
    );
  }

  Widget _buildCardGrid() {
    return Positioned(
      left: 163,
      top: 338,
      width: 1210,
      height: 520,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: _tabIndex != 0,
            child: Opacity(
              opacity: _tabIndex == 0 ? 1 : 0,
              child: _gridPanel(
                key: const Key('hanzi-pinyin-learn-initials-panel'),
                items: allInitials,
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _tabIndex != 1,
            child: Opacity(
              opacity: _tabIndex == 1 ? 1 : 0,
              child: _gridPanel(
                key: const Key('hanzi-pinyin-learn-finals-panel'),
                items: allFinals,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridPanel({required Key key, required List<PinyinItem> items}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.92,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _PinyinGridCard(
          item: item,
          onOpenDetail: () => _openDetail(item),
          onSpeak: () => _speakPinyin(item),
        );
      },
    );
  }

  Widget _buildStatsBar(int learnedCount, int progressTotal) {
    return Positioned(
      left: 95,
      bottom: 43,
      width: 1302,
      height: 152,
      key: const Key('hanzi-pinyin-learn-stats-bar'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridStatsBar,
              description: '底部统计条',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 140,
            top: 48,
            child: Text(
              '小朋友，继续加油哦!',
              style: GoogleFonts.notoSansSc(
                fontSize: 27,
                color: const Color(0xFF4B6C9F),
              ),
            ),
          ),
          Positioned(
            right: 420,
            top: 42,
            child: Text(
              '学习进度 $learnedCount/$progressTotal',
              style: GoogleFonts.notoSansSc(
                fontSize: 22,
                color: HanziDesignSpec.subtitleMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 180,
            top: 42,
            child: Text(
              '掌握拼音 $learnedCount个',
              style: GoogleFonts.notoSansSc(
                fontSize: 22,
                color: HanziDesignSpec.subtitleMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinyinGridCard extends StatelessWidget {
  const _PinyinGridCard({
    required this.item,
    required this.onOpenDetail,
    required this.onSpeak,
  });

  final PinyinItem item;
  final VoidCallback onOpenDetail;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final gridKey = item.symbol == 'b'
        ? const Key('hanzi-pinyin-learn-card-grid')
        : null;
    final ttsKey = item.symbol == 'b'
        ? const Key('hanzi-pinyin-learn-tts-initial-b')
        : null;

    return GestureDetector(
      key: gridKey,
      onTap: onOpenDetail,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF8),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 16,
              child: Text(
                item.symbol,
                style: GoogleFonts.notoSansSc(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF214B8C),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 52,
              child: Text(
                item.example,
                style: GoogleFonts.notoSansSc(
                  fontSize: 28,
                  color: const Color(0xFF5A585A),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 12,
              child: Text(
                item.examplePinyin,
                style: GoogleFonts.notoSansSc(
                  fontSize: 18,
                  color: const Color(0xFF757576),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: GestureDetector(
                key: ttsKey,
                onTap: onSpeak,
                behavior: HitTestBehavior.opaque,
                child: FigmaUiImage(
                  configKey: PinyinLearnUiAssets.gridCardSpeaker,
                  description: '听${item.symbol}',
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
