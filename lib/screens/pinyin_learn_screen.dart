import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/pinyin_learn_d2c_9_2_layout.dart';
import '../constants/pinyin_learn_grid_9_2_cards.dart';
import '../constants/pinyin_learn_ui_assets.dart';
import '../data/pinyin_data.dart';
import '../providers/learning_provider.dart';
import '../utils/pinyin_speech.dart';
import '../widgets/pinyin_learn/figma_ui_image.dart';
import '../widgets/pinyin_learn/pinyin_learn_detail_modal.dart';
import '../widgets/pinyin_learn/pinyin_learn_grid_card.dart';
import '../widgets/pinyin_learn/pinyin_learn_stats_bar.dart';

/// 拼音学习 — Figma node 9-2（tdesign-d2c 布局 + 4-2 详情模态）
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
    final learnedCount = (starCount ~/ 3).clamp(0, _currentItems.length);
    final progressTotal = _currentItems.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledH = PinyinLearnD2c92Layout.canvasH *
            constraints.maxWidth /
            PinyinLearnD2c92Layout.canvasW;

        final canvas = SizedBox(
          width: constraints.maxWidth,
          height: scaledH,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: PinyinLearnD2c92Layout.canvasW,
              height: PinyinLearnD2c92Layout.canvasH,
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
                    left: PinyinLearnD2c92Layout.panelLeft,
                    top: PinyinLearnD2c92Layout.panelTop,
                    width: PinyinLearnD2c92Layout.panelW,
                    height: PinyinLearnD2c92Layout.panelH,
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
                    left: PinyinLearnD2c92Layout.statsLeft,
                    top: PinyinLearnD2c92Layout.statsTop,
                    width: PinyinLearnD2c92Layout.statsW,
                    height: PinyinLearnD2c92Layout.statsH,
                    child: PinyinLearnStatsBar(
                      starCount: starCount,
                      learnedCount: learnedCount,
                      totalCount: progressTotal,
                    ),
                  ),
                  Positioned(
                    left: PinyinLearnD2c92Layout.mascotLeft,
                    top: PinyinLearnD2c92Layout.mascotTop,
                    width: 166,
                    height: 155,
                    child: FigmaUiImage(
                      configKey: PinyinLearnUiAssets.gridMascotPanda,
                      description: '左下熊猫',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    left: PinyinLearnD2c92Layout.sideDecoLeft,
                    top: PinyinLearnD2c92Layout.sideDecoTop,
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
      width: PinyinLearnD2c92Layout.canvasW,
      height: PinyinLearnD2c92Layout.headerH,
      child: Stack(
        children: [
          Positioned(
            left: PinyinLearnD2c92Layout.backLeft,
            top: PinyinLearnD2c92Layout.backTop,
            width: PinyinLearnD2c92Layout.backW,
            height: PinyinLearnD2c92Layout.backH,
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
            left: PinyinLearnD2c92Layout.titleDecoLeft,
            top: PinyinLearnD2c92Layout.titleDecoTop,
            width: 171,
            height: 99,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridTitleDeco,
              description: '标题装饰',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: PinyinLearnD2c92Layout.headerDecoLeft,
            top: PinyinLearnD2c92Layout.headerDecoTop,
            width: 147,
            height: 74,
            child: FigmaUiImage(
              configKey: PinyinLearnUiAssets.gridHeaderDeco,
              description: '标题装饰右',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: PinyinLearnD2c92Layout.avatarLeft,
            top: PinyinLearnD2c92Layout.avatarTop,
            width: PinyinLearnD2c92Layout.avatarSize,
            height: PinyinLearnD2c92Layout.avatarSize,
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
    return Stack(
      key: const Key('hanzi-pinyin-learn-tab-bar'),
      children: [
        Positioned(
          left: PinyinLearnD2c92Layout.tabInitialsLeft,
          top: PinyinLearnD2c92Layout.tabInitialsTop,
          child: _tabChip(
            '声母',
            0,
            PinyinLearnD2c92Layout.tabInitialsW,
            PinyinLearnD2c92Layout.tabInitialsH,
          ),
        ),
        Positioned(
          left: PinyinLearnD2c92Layout.tabFinalsLeft,
          top: PinyinLearnD2c92Layout.tabFinalsTop,
          child: _tabChip(
            '韵母',
            1,
            PinyinLearnD2c92Layout.tabFinalsW,
            PinyinLearnD2c92Layout.tabFinalsH,
          ),
        ),
      ],
    );
  }

  Widget _tabChip(String label, int index, double width, double height) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        width: width,
        height: height,
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
            fontSize: index == 0 ? 34 : 33,
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
      left: PinyinLearnD2c92Layout.gridLeft,
      top: PinyinLearnD2c92Layout.gridTop,
      width: PinyinLearnD2c92Layout.gridW,
      height: PinyinLearnD2c92Layout.gridH,
      child: GridView.builder(
        key: ValueKey('hanzi-pinyin-learn-grid-$_tabIndex'),
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: PinyinLearnD2c92Layout.gridCrossAxisCount,
          mainAxisSpacing: PinyinLearnD2c92Layout.gridMainSpacing,
          crossAxisSpacing: PinyinLearnD2c92Layout.gridCrossSpacing,
          childAspectRatio:
              PinyinLearnD2c92Layout.cardW / PinyinLearnD2c92Layout.cardH,
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
