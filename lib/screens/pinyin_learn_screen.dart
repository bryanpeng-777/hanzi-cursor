import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cs_ui/cs_ui.dart';
import 'package:go_router/go_router.dart';
import '../constants/pinyin_learn_figma_assets.dart';
import '../constants/pinyin_learn_figma_cards.dart';
import '../constants/pinyin_learn_figma_grid.dart';
import '../constants/pinyin_learn_figma_layout.dart';
import '../data/pinyin_data.dart';
import '../design/hanzi_design_spec.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import '../utils/pinyin_speech.dart';

/// 拼音学习 — Figma node `1-2` 横屏重设计
class PinyinLearnScreen extends ConsumerStatefulWidget {
  const PinyinLearnScreen({super.key});

  @override
  ConsumerState<PinyinLearnScreen> createState() => _PinyinLearnScreenState();
}

class _PinyinLearnScreenState extends ConsumerState<PinyinLearnScreen> {
  bool _isAutoMode = false;
  int _tabIndex = 0;

  static const Color _tabActive = Color(0xFF42BAC4);
  static const Color _tabIdle = Color(0xFF406485);
  static const Color _manualLabel = Color(0xFFD2F2EE);
  static const Color _autoLabel = Color(0xFF75889E);
  static const Color _tipText = Color(0xFF788799);

  @override
  Widget build(BuildContext context) {
    const learnedCount = 0;
    final progress = allInitials.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledH = PinyinLearnFigmaLayout.designH *
            constraints.maxWidth /
            PinyinLearnFigmaLayout.designW;
        final needsScroll = scaledH > constraints.maxHeight + 0.5;

        final canvas = SizedBox(
          width: constraints.maxWidth,
          height: scaledH,
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: PinyinLearnFigmaLayout.designW,
              height: PinyinLearnFigmaLayout.designH,
              child: Stack(
                key: const Key('hanzi-pinyin-learn-landscape'),
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      PinyinLearnFigmaAssetPaths.canvasBackdrop,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  _buildHeader(context),
                  _buildMainPanel(learnedCount, progress),
                  Positioned(
                    left: PinyinLearnFigmaLayout.sx(13),
                    top: PinyinLearnFigmaLayout.sy(947),
                    width: PinyinLearnFigmaLayout.sx(527),
                    height: PinyinLearnFigmaLayout.sy(77),
                    child: Image.asset(
                      PinyinLearnFigmaAssetPaths.bottomBar,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Scaffold(
          body: needsScroll
              ? SingleChildScrollView(child: canvas)
              : Center(child: canvas),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: PinyinLearnFigmaLayout.headerBackLeft,
          top: PinyinLearnFigmaLayout.headerBackTop,
          width: PinyinLearnFigmaLayout.headerBackSize,
          height: PinyinLearnFigmaLayout.headerBackHeight,
          child: GestureDetector(
            onTap: () => context.pop(),
            child: Image.asset(
              PinyinLearnFigmaAssetPaths.backBtn,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.titleDecoLeftPos,
          top: PinyinLearnFigmaLayout.titleDecoLeftTop,
          width: PinyinLearnFigmaLayout.titleDecoLeftW,
          height: PinyinLearnFigmaLayout.titleDecoLeftH,
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.titleDecoLeft,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.titleLeft,
          top: PinyinLearnFigmaLayout.titleTop,
          width: PinyinLearnFigmaLayout.titleWidth,
          height: PinyinLearnFigmaLayout.titleHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '拼音学习',
              key: const Key('hanzi-pinyin-learn-header-title'),
              style: TextStyle(
                color: HanziDesignSpec.titleInk,
                fontWeight: FontWeight.w600,
                fontSize: PinyinLearnFigmaLayout.sx(73),
                height: PinyinLearnFigmaLayout.sy(88) /
                    PinyinLearnFigmaLayout.sx(73),
              ),
            ),
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.titleDecoRightLeft,
          top: PinyinLearnFigmaLayout.titleDecoRightTop,
          width: PinyinLearnFigmaLayout.titleDecoLeftW,
          height: PinyinLearnFigmaLayout.titleDecoLeftH,
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.titleDecoRight,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.headerAvatarLeft,
          top: PinyinLearnFigmaLayout.headerAvatarTop,
          width: PinyinLearnFigmaLayout.sx(82),
          height: PinyinLearnFigmaLayout.sy(83),
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.headerAvatar,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildMainPanel(int learnedCount, int progress) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: PinyinLearnFigmaLayout.sx(127),
          top: PinyinLearnFigmaLayout.sy(135),
          width: PinyinLearnFigmaLayout.sx(1273),
          height: PinyinLearnFigmaLayout.sy(817),
          child: Image.asset(
            PinyinLearnFigmaAssetPaths.panelBg,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.sx(501),
          top: PinyinLearnFigmaLayout.sy(159),
          width: PinyinLearnFigmaLayout.manualModeW,
          height: PinyinLearnFigmaLayout.manualModeH,
          child: GestureDetector(
            onTap: () => setState(() => _isAutoMode = false),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (!_isAutoMode)
                  Positioned.fill(
                    child: Image.asset(
                      PinyinLearnFigmaAssetPaths.manualModeBg,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                Positioned(
                  left: PinyinLearnFigmaLayout.sx(52),
                  top: PinyinLearnFigmaLayout.sy(20),
                  child: Row(
                    children: [
                      Image.asset(
                        PinyinLearnFigmaAssetPaths.manualModeIcon,
                        width: PinyinLearnFigmaLayout.s(37),
                        height: PinyinLearnFigmaLayout.s(37),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: PinyinLearnFigmaLayout.sx(12)),
                      Text(
                        '手动模式',
                        style: TextStyle(
                          color: _isAutoMode ? _autoLabel : _manualLabel,
                          fontWeight: FontWeight.w500,
                          fontSize: PinyinLearnFigmaLayout.sx(26),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: PinyinLearnFigmaLayout.sx(768),
          top: PinyinLearnFigmaLayout.sy(159),
          width: PinyinLearnFigmaLayout.autoModeW,
          height: PinyinLearnFigmaLayout.manualModeH,
          child: GestureDetector(
            onTap: () => setState(() => _isAutoMode = true),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE4E9EE),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    PinyinLearnFigmaAssetPaths.autoModeIcon,
                    width: PinyinLearnFigmaLayout.s(45),
                    height: PinyinLearnFigmaLayout.s(40),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: PinyinLearnFigmaLayout.sx(12)),
                  Text(
                    '自动模式',
                    style: TextStyle(
                      color: _autoLabel,
                      fontWeight: FontWeight.w500,
                      fontSize: PinyinLearnFigmaLayout.sx(25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildContentArea(),
        if (!_isAutoMode) _buildTabBar(),
        Positioned(
          left: PinyinLearnFigmaLayout.statsLeft,
          top: PinyinLearnFigmaLayout.statsTop,
          width: PinyinLearnFigmaLayout.statsW,
          height: PinyinLearnFigmaLayout.statsH,
          child: _buildStatsBar(learnedCount, progress),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Positioned(
      left: PinyinLearnFigmaLayout.tabBarCanvasLeft,
      top: PinyinLearnFigmaLayout.tabBarCanvasTop,
      width: PinyinLearnFigmaLayout.tabBarW,
      height: PinyinLearnFigmaLayout.tabBarH,
      child: Stack(
        key: const Key('hanzi-pinyin-learn-tab-bar'),
        clipBehavior: Clip.none,
        children: [
          _tabLabel('声母', 0, PinyinLearnFigmaLayout.s(218)),
          _tabLabel('韵母', 1, PinyinLearnFigmaLayout.s(581)),
          _tabLabel('四声', 2, PinyinLearnFigmaLayout.s(932)),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: PinyinLearnFigmaLayout.tabIndicatorLeftFor(_tabIndex),
            top: PinyinLearnFigmaLayout.s(
              PinyinLearnFigmaLayout.tabIndicatorTopInBar,
            ),
            width: PinyinLearnFigmaLayout.tabIndicatorW,
            height: PinyinLearnFigmaLayout.tabIndicatorH,
            child: Image.asset(
              PinyinLearnFigmaAssetPaths.tabIndicator,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabLabel(String label, int index, double left) {
    final selected = _tabIndex == index;
    return Positioned(
      left: left,
      top: PinyinLearnFigmaLayout.sy(20),
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _tabActive : _tabIdle,
              fontWeight: FontWeight.w500,
              fontSize: PinyinLearnFigmaLayout.sx(label == '声母' ? 28 : 27),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    return Positioned(
      left: PinyinLearnFigmaLayout.gridCanvasLeft,
      top: PinyinLearnFigmaLayout.gridCanvasTop,
      width: PinyinLearnFigmaLayout.gridAreaW,
      height: PinyinLearnFigmaLayout.gridAreaH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: PinyinLearnFigmaLayout.sy(5),
            right: 0,
            height: PinyinLearnFigmaLayout.sy(531),
            child: Image.asset(
              PinyinLearnFigmaAssetPaths.gridBg,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            top: PinyinLearnFigmaLayout.gridCardsTopInset,
            child: _isAutoMode
                ? _AutoModeView()
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IgnorePointer(
                        ignoring: _tabIndex != 0,
                        child: Opacity(
                          opacity: _tabIndex == 0 ? 1 : 0,
                          child: _FigmaLetterGrid(
                            key: const Key(
                              'hanzi-pinyin-learn-initials-panel',
                            ),
                            items: allInitials,
                            useExactFigmaLayout: true,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: _tabIndex != 1,
                        child: Opacity(
                          opacity: _tabIndex == 1 ? 1 : 0,
                          child: _FigmaLetterGrid(
                            key: const Key(
                              'hanzi-pinyin-learn-finals-panel',
                            ),
                            items: allFinals,
                            useExactFigmaLayout: false,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: _tabIndex != 2,
                        child: Opacity(
                          opacity: _tabIndex == 2 ? 1 : 0,
                          child: _TonesView(
                            key: const Key(
                              'hanzi-pinyin-learn-tones-panel',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(int learnedCount, int progress) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: PinyinLearnFigmaLayout.s(71),
          top: PinyinLearnFigmaLayout.s(-5),
          width: PinyinLearnFigmaLayout.s(1029),
          height: PinyinLearnFigmaLayout.s(118),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: PinyinLearnFigmaLayout.s(8),
                top: PinyinLearnFigmaLayout.s(8),
                width: PinyinLearnFigmaLayout.s(1013),
                height: PinyinLearnFigmaLayout.s(104),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FA),
                    borderRadius:
                        BorderRadius.circular(PinyinLearnFigmaLayout.s(50)),
                    border: Border.all(color: const Color(0xFFDBECF8)),
                  ),
                ),
              ),
              Positioned(
                left: PinyinLearnFigmaLayout.s(32),
                top: PinyinLearnFigmaLayout.s(24),
                width: PinyinLearnFigmaLayout.s(76),
                height: PinyinLearnFigmaLayout.s(73),
                child: Image.asset(
                  PinyinLearnFigmaAssetPaths.tipIcon,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                left: PinyinLearnFigmaLayout.s(117),
                top: PinyinLearnFigmaLayout.s(28),
                width: PinyinLearnFigmaLayout.s(234),
                child: Text(
                  '点击喇叭听拼音，翻转卡片学例字~\n每天学一学，拼音真有趣！',
                  style: TextStyle(
                    color: _tipText,
                    fontSize: PinyinLearnFigmaLayout.s(19),
                    height: 1.5,
                  ),
                ),
              ),
              _buildStatsChip(
                left: 538,
                top: 13,
                width: 222,
                height: 95,
                innerLeft: 6,
                innerTop: 5,
                innerWidth: 213,
                innerHeight: 86,
                innerRadius: 39,
                innerColor: const Color(0xFFF9FBFD),
                innerBorderColor: const Color(0xFFE5F1F9),
                iconAsset: PinyinLearnFigmaAssetPaths.statsProgressIcon,
                iconLeft: 38,
                iconTop: 23,
                iconW: 51,
                iconH: 52,
                label: '学习进度',
                labelColor: const Color(0xFF5E83A0),
                labelTop: 24,
                value: '$learnedCount/$progress',
                valueColor: const Color(0xFF67C9C0),
                valueTop: 53,
                valueFontSize: 20,
                textLeft: 104,
              ),
              _buildStatsChip(
                left: 781,
                top: 12,
                width: 229,
                height: 98,
                innerLeft: 5,
                innerTop: 5,
                innerWidth: 217,
                innerHeight: 93,
                innerRadius: 44,
                innerRadiusBottomRight: 7,
                innerRadiusTopRight: 44,
                innerRadiusBottomLeft: 40,
                innerColor: const Color(0xFFF7FBFD),
                innerBorderColor: const Color(0xFFE6F2FA),
                iconAsset: PinyinLearnFigmaAssetPaths.statsMasteryIcon,
                iconLeft: 42,
                iconTop: 25,
                iconW: 42,
                iconH: 50,
                label: '掌握拼音',
                labelColor: const Color(0xFF6688A2),
                labelTop: 25,
                value: '${learnedCount}个',
                valueColor: const Color(0xFF65C8BD),
                valueTop: 54,
                valueFontSize: 18,
                textLeft: 101,
                innerBorderWidth: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsChip({
    required double left,
    required double top,
    required double width,
    required double height,
    required double innerLeft,
    required double innerTop,
    required double innerWidth,
    required double innerHeight,
    required double innerRadius,
    required String iconAsset,
    required double iconLeft,
    required double iconTop,
    required double iconW,
    required double iconH,
    required String label,
    required Color labelColor,
    required double labelTop,
    required String value,
    required Color valueColor,
    required double valueTop,
    required double valueFontSize,
    required double textLeft,
    double innerRadiusBottomRight = 39,
    double innerRadiusTopRight = 39,
    double innerRadiusBottomLeft = 39,
    double innerBorderWidth = 1,
    Color innerColor = const Color(0xFFF7FBFD),
    Color innerBorderColor = const Color(0xFFE6F2FA),
  }) {
    return Positioned(
      left: PinyinLearnFigmaLayout.s(left),
      top: PinyinLearnFigmaLayout.s(top),
      width: PinyinLearnFigmaLayout.s(width),
      height: PinyinLearnFigmaLayout.s(height),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: PinyinLearnFigmaLayout.s(innerLeft),
            top: PinyinLearnFigmaLayout.s(innerTop),
            width: PinyinLearnFigmaLayout.s(innerWidth),
            height: PinyinLearnFigmaLayout.s(innerHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: innerColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(PinyinLearnFigmaLayout.s(innerRadius)),
                  topRight:
                      Radius.circular(PinyinLearnFigmaLayout.s(innerRadiusTopRight)),
                  bottomRight: Radius.circular(
                      PinyinLearnFigmaLayout.s(innerRadiusBottomRight)),
                  bottomLeft: Radius.circular(
                      PinyinLearnFigmaLayout.s(innerRadiusBottomLeft)),
                ),
                border: Border.all(
                  color: innerBorderColor,
                  width: innerBorderWidth,
                ),
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnFigmaLayout.s(iconLeft),
            top: PinyinLearnFigmaLayout.s(iconTop),
            width: PinyinLearnFigmaLayout.s(iconW),
            height: PinyinLearnFigmaLayout.s(iconH),
            child: Image.asset(iconAsset, fit: BoxFit.contain),
          ),
          Positioned(
            left: PinyinLearnFigmaLayout.s(textLeft),
            top: PinyinLearnFigmaLayout.s(labelTop),
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: PinyinLearnFigmaLayout.s(18),
                height: 1.2,
              ),
            ),
          ),
          Positioned(
            left: PinyinLearnFigmaLayout.s(textLeft),
            top: PinyinLearnFigmaLayout.s(valueTop),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: PinyinLearnFigmaLayout.s(valueFontSize),
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 手动模式：拼音字母网格（宽卡片自动换行） ───────────────────────────────────

class _FigmaLetterGrid extends ConsumerWidget {
  const _FigmaLetterGrid({
    super.key,
    required this.items,
    this.useExactFigmaLayout = false,
  });

  final List<PinyinItem> items;
  final bool useExactFigmaLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(learningNotifierProvider).pinyinMistakes;

    if (useExactFigmaLayout) {
      final specs = PinyinLearnFigmaCards.initials;
      final count = items.length.clamp(0, specs.length);
      return _scrollableGrid(
        itemCount: count,
        grid: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < count; i++)
              _figmaGridCell(
                index: i,
                item: items[i],
                spec: specs[i],
                hasMistake: mistakes.contains(items[i].symbol),
              ),
          ],
        ),
      );
    }

    return _scrollableGrid(
      itemCount: items.length,
      grid: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < items.length; i++)
            _genericGridCell(
              index: i,
              item: items[i],
              hasMistake: mistakes.contains(items[i].symbol),
            ),
        ],
      ),
    );
  }

  Widget _scrollableGrid({required int itemCount, required Widget grid}) {
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: PinyinLearnFigmaLayout.gridAreaW,
          height: PinyinLearnFigmaLayout.s(
            PinyinLearnFigmaGrid.contentHeightFor(itemCount),
          ),
          child: grid,
        ),
      ),
    );
  }

  Widget _figmaGridCell({
    required int index,
    required PinyinItem item,
    required PinyinLearnFigmaCardSpec spec,
    required bool hasMistake,
  }) {
    final rect = PinyinLearnFigmaGrid.cellRect(index);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _PinyinCard(
        item: item,
        hasMistake: hasMistake,
        figmaSpec: spec,
      ),
    );
  }

  Widget _genericGridCell({
    required int index,
    required PinyinItem item,
    required bool hasMistake,
  }) {
    final rect = PinyinLearnFigmaGrid.cellRect(index);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: _PinyinCard(
        item: item,
        hasMistake: hasMistake,
      ),
    );
  }
}

// ─── 手动模式：四声页 ───────────────────────────────────────────────────────────

class _TonesView extends StatefulWidget {
  const _TonesView({super.key});

  @override
  State<_TonesView> createState() => _TonesViewState();
}

class _TonesViewState extends State<_TonesView> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('zh-CN');
  }

  static const _toneData = [
    {
      'tone': '一声 ā',
      'mark': '—',
      'desc': '平平的，像在唱歌',
      'example': '妈 māma',
      'iconKey': 'pinyin_tone_1',
      'iconDesc': '一声示例',
      'color': Color(0xFF4CAF50),
    },
    {
      'tone': '二声 á',
      'mark': '/',
      'desc': '往上升，像在问问题',
      'example': '麻 máma',
      'iconKey': 'pinyin_tone_2',
      'iconDesc': '二声示例',
      'color': Color(0xFF2196F3),
    },
    {
      'tone': '三声 ǎ',
      'mark': '∨',
      'desc': '先降后升，像在叹气',
      'example': '马 mǎ',
      'iconKey': 'pinyin_tone_3',
      'iconDesc': '三声示例',
      'color': Color(0xFFFF9800),
    },
    {
      'tone': '四声 à',
      'mark': '\\',
      'desc': '快快往下，像在命令',
      'example': '骂 mà',
      'iconKey': 'pinyin_tone_4',
      'iconDesc': '四声示例',
      'color': Color(0xFFE91E8C),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _toneData.length,
      itemBuilder: (context, i) {
        final data = _toneData[i];
        final color = data['color'] as Color;
        return GestureDetector(
          onTap: () => _tts.speak(data['example'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      data['mark'] as String,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['tone'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['desc'] as String,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CsImage(
                            configKey: data['iconKey'] as String,
                            description: data['iconDesc'] as String,
                            width: 16, height: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['example'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.volume_up_rounded,
                    color: Colors.grey, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── 手动模式：拼音卡片（折叠/展开） ────────────────────────────────────────────

class _PinyinCard extends StatefulWidget {
  final PinyinItem item;
  final bool hasMistake;
  final PinyinLearnFigmaCardSpec? figmaSpec;

  const _PinyinCard({
    required this.item,
    required this.hasMistake,
    this.figmaSpec,
  });

  @override
  State<_PinyinCard> createState() => _PinyinCardState();
}

class _PinyinCardState extends State<_PinyinCard> {
  bool _expanded = false;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  /// 正面：读拼音音节（中文 TTS，非英文字母）
  Future<void> _speakPinyin() async {
    await _tts.stop();
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(PinyinSpeech.frontSpeech(widget.item));
  }

  /// 背面：读例字汉字
  Future<void> _speakExample() async {
    await _tts.stop();
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(widget.item.example);
  }

  static const Color _cardLetter = Color(0xFF18496E);
  static const Color _cardBorder = Color(0xFF98D0C7);

  @override
  Widget build(BuildContext context) {
    final spec = widget.figmaSpec;
    if (spec != null && !_expanded) {
      return GestureDetector(
        onTap: _toggle,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildFigmaCollapsed(spec),
            if (widget.hasMistake) _mistakeBadge(),
          ],
        ),
      );
    }

    if (!_expanded) {
      return GestureDetector(
        onTap: _toggle,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorder),
                ),
              ),
            ),
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.symbol,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: _cardLetter,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: _speakPinyin,
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.volume_up_rounded,
                          size: 20,
                          color: _cardBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.hasMistake) _mistakeBadge(),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _expanded
                  ? AppTheme.primaryOrange.withOpacity(0.08)
                  : const Color(0xFFFDFDFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _expanded
                    ? AppTheme.primaryOrange
                    : Colors.grey.shade200,
                width: _expanded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _expanded ? _buildExpanded() : _buildCollapsedLegacy(),
          ),
          if (widget.hasMistake) _mistakeBadge(),
        ],
      ),
    );
  }

  Widget _mistakeBadge() {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFigmaCollapsed(PinyinLearnFigmaCardSpec spec) {
    final inner = PinyinLearnFigmaGrid.innerScaleFor(spec);
    final innerX = PinyinLearnFigmaGrid.innerScaleXFor(spec);
    final innerY = PinyinLearnFigmaGrid.innerScaleYFor(spec);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(PinyinLearnFigmaLayout.innerPx(5, inner)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(spec.borderRadius * inner),
                border: Border.all(color: _cardBorder),
              ),
            ),
          ),
        ),
        if (spec.letterImageAsset != null)
          Positioned(
            left: PinyinLearnFigmaLayout.innerPx(spec.letterLeft, innerX),
            top: PinyinLearnFigmaLayout.innerPx(spec.letterTop, innerY),
            child: Image.asset(
              spec.letterImageAsset!,
              width: PinyinLearnFigmaLayout.innerPx(7, inner),
              height: PinyinLearnFigmaLayout.innerPx(41, inner),
              fit: BoxFit.contain,
            ),
          )
        else
          Positioned(
            left: PinyinLearnFigmaLayout.innerPx(spec.letterLeft, innerX),
            top: PinyinLearnFigmaLayout.innerPx(spec.letterTop, innerY),
            child: Text(
              widget.item.symbol,
              style: TextStyle(
                fontSize: PinyinLearnFigmaLayout.innerPx(
                  spec.letterFontSize,
                  inner,
                ),
                fontWeight: FontWeight.w600,
                color: _cardLetter,
                height: 1.0,
              ),
            ),
          ),
        Positioned(
          left: PinyinLearnFigmaLayout.innerPx(spec.ttsLeft, innerX),
          top: PinyinLearnFigmaLayout.innerPx(spec.ttsTop, innerY),
          child: GestureDetector(
            key: widget.item.symbol == 'b'
                ? const Key('hanzi-pinyin-learn-tts-initial-b')
                : null,
            onTap: _speakPinyin,
            behavior: HitTestBehavior.opaque,
            child: Image.asset(
              spec.ttsAsset,
              width: PinyinLearnFigmaLayout.innerPx(spec.ttsWidth, inner),
              height: PinyinLearnFigmaLayout.innerPx(spec.ttsHeight, inner),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedLegacy() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.item.symbol,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _cardLetter,
          ),
        ),
        const SizedBox(height: 4),
        if (widget.item.symbol == 'b')
          GestureDetector(
            key: const Key('hanzi-pinyin-learn-tts-initial-b'),
            onTap: _speakPinyin,
            child: Image.asset(
              PinyinLearnFigmaAssetPaths.ttsIconB,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          )
        else
          GestureDetector(
            onTap: _speakPinyin,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.volume_up_rounded,
              size: 24,
              color: _cardBorder,
            ),
          ),
      ],
    );
  }

  Widget _buildExpanded() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拼音符号 + 配图
          Row(
            children: [
              Text(
                widget.item.symbol,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const Spacer(),
              CsImage(configKey: 'pinyin_icon_${widget.item.symbol}', description: widget.item.iconHint, width: 16, height: 16),
            ],
          ),
          const SizedBox(height: 2),
          // 例字 + 拼音（背面喇叭读汉字）
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.item.example}  ${widget.item.examplePinyin}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
              ),
              GestureDetector(
                key: const Key('hanzi-pinyin-learn-tts-example'),
                onTap: _speakExample,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 18,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 四声行（韵母专用）
          if (widget.item.tones.isNotEmpty)
            Wrap(
              spacing: 4,
              children: widget.item.tones
                  .asMap()
                  .entries
                  .map((e) => Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.levelColors[
                              e.key.clamp(0, AppTheme.levelColors.length - 1)],
                        ),
                      ))
                  .toList(),
            ),
          if (widget.item.tones.isNotEmpty) const SizedBox(height: 4),
          // 口诀
          Text(
            '「${widget.item.mnemonic}」',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          // 组词
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.item.exampleWords
                .map((w) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF555555)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── 自动模式 ──────────────────────────────────────────────────────────────────

class _AutoModeView extends StatefulWidget {
  @override
  State<_AutoModeView> createState() => _AutoModeViewState();
}

class _AutoModeViewState extends State<_AutoModeView> {
  bool _initialsSelected = true; // true=声母 false=韵母
  bool _started = false;

  late List<PinyinItem> _items;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _autoTimer;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
    _items = allInitials;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _startAuto() {
    setState(() {
      _items = _initialsSelected ? allInitials : allFinals;
      _currentIndex = 0;
      _isPlaying = true;
      _started = true;
    });
    _speakAndAdvance();
  }

  void _speakAndAdvance() async {
    if (!mounted || !_isPlaying) return;
    final item = _items[_currentIndex];
    await _tts.speak(item.example);
    // 朗读完成后停 2 秒再切换
    _autoTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || !_isPlaying) return;
      if (_currentIndex < _items.length - 1) {
        setState(() => _currentIndex++);
        _speakAndAdvance();
      } else {
        setState(() => _isPlaying = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _autoTimer?.cancel();
      _tts.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _speakAndAdvance();
    }
  }

  void _goTo(int index) {
    _autoTimer?.cancel();
    _tts.stop();
    setState(() => _currentIndex = index);
    if (_isPlaying) _speakAndAdvance();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildSelector();

    final item = _items[_currentIndex];
    final isLast = _currentIndex == _items.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 进度条
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第 ${_currentIndex + 1} 个',
                  style: const TextStyle(fontSize: 16)),
              Text('共 ${_items.length} 个',
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _items.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryOrange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),

          // 大卡片
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.85),
                    const Color(0xFF764BA2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 大拼音符号
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate(key: ValueKey(item.symbol)).fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  // 例字 + 配图
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.example,
                          style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 12),
                      CsImage(configKey: 'pinyin_icon_${item.symbol}', description: item.iconHint, width: 36, height: 36),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.examplePinyin,
                    style: TextStyle(
                      fontSize: 22,
                      color: AppTheme.primaryYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 四声行（韵母）
                  if (item.tones.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      children: item.tones
                          .asMap()
                          .entries
                          .map((e) => Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.levelColors[
                                      e.key.clamp(
                                          0,
                                          AppTheme.levelColors.length - 1)],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // 口诀
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '「${item.mnemonic}」',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 拼读示范
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: item.blendExamples
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                b,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  // 组词
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: item.exampleWords
                        .map((w) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                w,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 250.ms),

          const SizedBox(height: 20),

          // 控制按钮
          if (!_isPlaying && isLast)
            const Text('全部学完了！',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen))
                .animate()
                .fadeIn()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: Icons.skip_previous_rounded,
                  onTap: _currentIndex > 0
                      ? () => _goTo(_currentIndex - 1)
                      : null,
                ),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                _ControlBtn(
                  icon: Icons.skip_next_rounded,
                  onTap: !isLast ? () => _goTo(_currentIndex + 1) : null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择学习内容',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _initialsSelected = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 110,
                      decoration: BoxDecoration(
                        color: _initialsSelected
                            ? AppTheme.primaryOrange.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _initialsSelected
                              ? AppTheme.primaryOrange
                              : Colors.grey.shade200,
                          width: _initialsSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CsImage(configKey: 'img_tab_initials', description: '声母', width: 32, height: 32),
                          const SizedBox(height: 8),
                          const Text('声母',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${allInitials.length} 个',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _initialsSelected = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 110,
                      decoration: BoxDecoration(
                        color: !_initialsSelected
                            ? AppTheme.primaryBlue.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !_initialsSelected
                              ? AppTheme.primaryBlue
                              : Colors.grey.shade200,
                          width: !_initialsSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CsImage(configKey: 'img_tab_finals', description: '韵母', width: 32, height: 32),
                          const SizedBox(height: 8),
                          const Text('韵母',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${allFinals.length} 个',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _startAuto,
                leading: const Icon(Icons.play_arrow_rounded),
                child: const Text('开始自动学习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ControlBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey.shade200,
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppTheme.primaryOrange : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}
