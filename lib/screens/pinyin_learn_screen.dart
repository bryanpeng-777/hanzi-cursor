import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/pinyin_learn_grid_9_2_cards.dart';
import '../constants/pinyin_learn_ui_assets.dart';
import '../data/pinyin_data.dart';
import '../providers/learning_provider.dart';
import '../utils/pinyin_speech.dart';
import '../widgets/pinyin_learn/figma_ui_image.dart';
import '../widgets/pinyin_learn/pinyin_learn_detail_modal.dart';
import '../widgets/pinyin_learn/pinyin_learn_grid_card.dart';
import '../widgets/pinyin_learn/pinyin_learn_stats_bar.dart';

/// 拼音学习 — Figma node 9-2（粘土 3D 海滩风网格 + 4-2 详情模态）
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

  List<PinyinItem> get _currentItems =>
      _tabIndex == 0 ? allInitials : allFinals;

  @override
  Widget build(BuildContext context) {
    final learning = ref.watch(learningNotifierProvider);
    final starCount = learning.totalStars;
    final learnedCount =
        (starCount ~/ 3).clamp(0, _currentItems.length);
    final progressTotal = _currentItems.length;

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
                  // 全屏海滩背景
                  Positioned.fill(
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridCanvasBg,
                      description: '拼音学习全屏背景',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 主面板衬底
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
                  _buildCardGrid(_currentItems),
                  Positioned(
                    left: 95,
                    bottom: 43,
                    width: 1302,
                    height: 152,
                    child: PinyinLearnStatsBar(
                      starCount: starCount,
                      learnedCount: learnedCount.clamp(0, progressTotal),
                      totalCount: progressTotal,
                    ),
                  ),
                  // 左下熊猫
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
                  // 右侧探出熊猫
                  Positioned(
                    right: 12,
                    bottom: 328,
                    width: 120,
                    height: 145,
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridSideDeco,
                      description: '右侧装饰熊猫',
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
            left: 552,
            top: 54,
            width: 62,
            height: 44,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridTitleDeco,
              description: '标题装饰',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 692,
            top: 50,
            width: 147,
            height: 74,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridHeaderDeco,
              description: '标题装饰右',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            right: 27,
            top: 16,
            width: 123,
            height: 123,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridHeaderAvatar,
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

  Widget _buildCardGrid(List<PinyinItem> items) {
    return Positioned(
      left: 163,
      top: 338,
      width: 1210,
      height: 520,
      child: GridView.builder(
        key: ValueKey('hanzi-pinyin-learn-grid-$_tabIndex'),
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 279 / 305,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return PinyinLearnGridCard(
            item: item,
            index: index,
            onOpenDetail: () => _openDetail(item),
            onSpeak: () => _speakPinyin(item),
            useFallbackAccent:
                !PinyinLearnGrid9Cards.initials.containsKey(item.symbol),
          );
        },
      ),
    );
  }
}
