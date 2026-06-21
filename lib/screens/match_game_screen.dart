import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/hanzi_data.dart';
import '../design/hanzi_design_spec.dart';
import '../design/hanzi_shared_widgets.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../providers/game_config_provider.dart';

class MatchGameScreen extends ConsumerStatefulWidget {
  const MatchGameScreen({super.key});

  @override
  ConsumerState<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends ConsumerState<MatchGameScreen> {
  static const _matchGradient = [Color(0xFFFF6B6B), Color(0xFFFF8E53)];

  late List<HanziCharacter> _gameCharacters;
  late List<_MatchItem> _leftItems;
  late List<_MatchItem> _rightItems;
  String? _selectedLeft;
  String? _selectedRight;
  Set<String> _matchedPairs = {};
  int _score = 0;
  int _errors = 0;
  bool _gameComplete = false;
  int _wrongShakeTick = 0;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final wordCount =
        ref.read(gameConfigProvider).valueOrNull?.matchGameWordCount ?? 5;
    final allChars = allHanzi.toList()..shuffle();
    _gameCharacters = allChars.take(wordCount).toList();
    _leftItems = _gameCharacters
        .map((h) => _MatchItem(id: h.character, imageDescription: h.iconHint))
        .toList()
      ..shuffle();
    _rightItems = _gameCharacters
        .map((h) => _MatchItem(id: h.character, imageDescription: null))
        .toList()
      ..shuffle();
    _selectedLeft = null;
    _selectedRight = null;
    _matchedPairs = {};
    _score = 0;
    _errors = 0;
    _gameComplete = false;
    _wrongShakeTick = 0;
  }

  void _onSelectLeft(String id) {
    if (_matchedPairs.contains(id)) return;
    setState(() => _selectedLeft = id);
    _checkMatch();
  }

  void _onSelectRight(String id) {
    if (_matchedPairs.contains(id)) return;
    setState(() => _selectedRight = id);
    _checkMatch();
  }

  void _checkMatch() {
    if (_selectedLeft == null || _selectedRight == null) return;

    if (_selectedLeft == _selectedRight) {
      setState(() {
        _matchedPairs.add(_selectedLeft!);
        _score += 10;
        _selectedLeft = null;
        _selectedRight = null;
        if (_matchedPairs.length == _gameCharacters.length) {
          _gameComplete = true;
          _saveProgress();
        }
      });
    } else {
      setState(() => _errors++);
      _wrongShakeTick++;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) {
          setState(() {
            _selectedLeft = null;
            _selectedRight = null;
          });
        }
      });
    }
  }

  Future<void> _saveProgress() async {
    final notifier = ref.read(learningNotifierProvider.notifier);
    for (final hanzi in _gameCharacters) {
      await notifier.addStars(hanzi.character, 1);
    }
  }

  double get _progress =>
      _gameCharacters.isEmpty ? 0 : _matchedPairs.length / _gameCharacters.length;

  @override
  Widget build(BuildContext context) {
    return HanziLandscapeScaffold(
      backgroundColor: HanziDesignSpec.surfaceWarm,
      appBar: CsAppBar(
        title: '图字配对',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: _ScoreBadge(score: _score),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        HanziDesignSpec.pagePaddingH.w,
        4.h,
        HanziDesignSpec.pagePaddingH.w,
        HanziDesignSpec.pagePaddingV.h,
      ),
      body: _gameComplete ? _buildCompletionScreen() : _buildGameBody(),
    );
  }

  Widget _buildGameBody() {
    return Column(
      children: [
        _buildHeaderPanel(),
        SizedBox(height: 10.h),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildColumnPanel(
                title: '情境图',
                subtitle: '点一张图',
                iconKey: 'img_card_game_match',
                accent: _matchGradient.first,
                items: _leftItems,
                isImageColumn: true,
                selectedId: _selectedLeft,
                onSelect: _onSelectLeft,
              )),
              SizedBox(width: 8.w),
              _buildConnector(),
              SizedBox(width: 8.w),
              Expanded(child: _buildColumnPanel(
                title: '汉字',
                subtitle: '再点一个字',
                iconKey: 'img_card_hanzi_learn',
                accent: HanziDesignSpec.accentLearn,
                items: _rightItems,
                isImageColumn: false,
                selectedId: _selectedRight,
                onSelect: _onSelectRight,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _matchGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        boxShadow: [
          BoxShadow(
            color: _matchGradient.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '先点图，再点字，配成一对！',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _StatChip(
                label: '进度',
                value: '${_matchedPairs.length}/${_gameCharacters.length}',
              ),
              SizedBox(width: 8.w),
              _StatChip(
                label: '失误',
                value: '$_errors',
                highlight: _errors > 0,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8.h,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08);
  }

  Widget _buildConnector() {
    final hasSelection = _selectedLeft != null || _selectedRight != null;
    final bothSelected = _selectedLeft != null && _selectedRight != null;

    return SizedBox(
      width: 36.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: hasSelection
                  ? Colors.white
                  : HanziDesignSpec.subtitleMuted.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: hasSelection
                  ? HanziDesignSpec.cardShadow(color: _matchGradient.first)
                  : null,
            ),
            child: Icon(
              bothSelected ? Icons.link_rounded : Icons.swap_horiz_rounded,
              size: 18.sp,
              color: hasSelection
                  ? _matchGradient.first
                  : HanziDesignSpec.subtitleMuted,
            ),
          ),
          if (bothSelected) ...[
            SizedBox(height: 6.h),
            Text(
              '配对中',
              style: GoogleFonts.notoSansSc(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: HanziDesignSpec.subtitleMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnPanel({
    required String title,
    required String subtitle,
    required String iconKey,
    required Color accent,
    required List<_MatchItem> items,
    required bool isImageColumn,
    required String? selectedId,
    required ValueChanged<String> onSelect,
  }) {
    return HanziSurfaceCard(
      shadowColor: accent,
      padding: EdgeInsets.fromLTRB(10.w, 10.h, 10.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: CsImage(
                    configKey: iconKey,
                    description: title,
                    width: 16.w,
                    height: 16.w,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HanziDesignSpec.cardTitleStyle.copyWith(fontSize: 15.sp)),
                  Text(
                    subtitle,
                    style: HanziDesignSpec.cardBodyStyle.copyWith(fontSize: 11.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (context, index) {
                final item = items[index];
                final isMatched = _matchedPairs.contains(item.id);
                final isSelected = selectedId == item.id;
                final isWrongFlash = !isMatched &&
                    isSelected &&
                    _selectedLeft != null &&
                    _selectedRight != null &&
                    _selectedLeft != _selectedRight;

                return _MatchTile(
                  key: ValueKey('${isImageColumn ? 'L' : 'R'}_${item.id}'),
                  character: item.id,
                  imageDescription: item.imageDescription,
                  isImageTile: isImageColumn,
                  isMatched: isMatched,
                  isSelected: isSelected,
                  isWrongFlash: isWrongFlash,
                  wrongShakeTick: _wrongShakeTick,
                  accent: accent,
                  index: index,
                  onTap: () => onSelect(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final total = _gameCharacters.length;
    final accuracy = total == 0
        ? 100
        : ((total - _errors).clamp(0, total) / total * 100).round();

    String resultKey;
    String message;
    if (_errors == 0) {
      resultKey = 'img_result_excellent';
      message = '全对！太厉害了！';
    } else if (_errors <= 2) {
      resultKey = 'img_result_good';
      message = '配对完成！';
    } else {
      resultKey = 'img_result_ok';
      message = '继续加油！';
    }

    return Center(
      child: HanziSurfaceCard(
        shadowColor: _matchGradient.first,
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsImage(
              configKey: resultKey,
              description: message,
              width: 64.w,
              height: 64.w,
            )
                .animate()
                .scale(curve: Curves.elasticOut, duration: 600.ms),
            SizedBox(height: 10.h),
            Text(
              message,
              style: HanziDesignSpec.hubTitleStyle.copyWith(fontSize: 22.sp),
            ).animate(delay: 250.ms).fadeIn(),
            SizedBox(height: 6.h),
            Text(
              '得分 $_score · 失误 $_errors · 正确率 $accuracy%',
              style: HanziDesignSpec.cardBodyStyle.copyWith(fontSize: 13.sp),
            ).animate(delay: 400.ms).fadeIn(),
            SizedBox(height: 6.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Opacity(
                    opacity: i < (3 - _errors.clamp(0, 3)) ? 1.0 : 0.25,
                    child: CsImage(
                      configKey: 'img_icon_star',
                      description: '星星',
                      width: 20.w,
                      height: 20.w,
                    ),
                  ),
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(),
            SizedBox(height: 16.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadButton(
                  onPressed: () => setState(_initGame),
                  leading: CsImage(
                    configKey: 'img_icon_refresh',
                    description: '重来',
                    width: 18.w,
                    height: 18.w,
                  ),
                  child: const Text('再来一次'),
                ),
                SizedBox(width: 12.w),
                ShadButton.outline(
                  onPressed: () => context.pop(),
                  leading: Icon(Icons.home_rounded, size: 18.sp),
                  child: const Text('返回'),
                ),
              ],
            ).animate(delay: 650.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: HanziDesignSpec.surfaceWarm,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsImage(
            configKey: 'img_icon_star',
            description: '星星',
            width: 16.w,
            height: 16.w,
          ),
          SizedBox(width: 4.w),
          Text(
            '$score',
            style: GoogleFonts.notoSansSc(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: HanziDesignSpec.titleInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansSc(
              fontSize: 9.sp,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSansSc(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    super.key,
    required this.character,
    required this.imageDescription,
    required this.isImageTile,
    required this.isMatched,
    required this.isSelected,
    required this.isWrongFlash,
    required this.wrongShakeTick,
    required this.accent,
    required this.index,
    required this.onTap,
  });

  final String character;
  final String? imageDescription;
  final bool isImageTile;
  final bool isMatched;
  final bool isSelected;
  final bool isWrongFlash;
  final int wrongShakeTick;
  final Color accent;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = HanziDesignSpec.surfaceCard;
    Color borderColor = HanziDesignSpec.subtitleMuted.withValues(alpha: 0.2);
    double scale = 1.0;

    if (isMatched) {
      bgColor = HanziDesignSpec.accentLearn.withValues(alpha: 0.12);
      borderColor = HanziDesignSpec.accentLearn;
    } else if (isWrongFlash) {
      bgColor = HanziDesignSpec.accentMistake.withValues(alpha: 0.12);
      borderColor = HanziDesignSpec.accentMistake;
    } else if (isSelected) {
      bgColor = accent.withValues(alpha: 0.1);
      borderColor = accent;
      scale = 1.03;
    }

    Widget tile = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isMatched ? null : onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46.h,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
              boxShadow: isSelected && !isMatched
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isImageTile)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RiceGridPainter(
                        color: HanziDesignSpec.subtitleMuted.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                if (isImageTile && imageDescription != null)
                  CsImage(
                    configKey: 'hanzi_icon_$character',
                    description: imageDescription!,
                    width: 34.w,
                    height: 34.w,
                  )
                else if (!isImageTile)
                  Text(
                    character,
                    style: GoogleFonts.notoSansSc(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: HanziDesignSpec.titleInk,
                    ),
                  ),
                if (isMatched)
                  Positioned(
                    right: 6.w,
                    top: 6.h,
                    child: Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: const BoxDecoration(
                        color: HanziDesignSpec.accentLearn,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, size: 12.sp, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    tile = tile
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 280.ms)
        .slideX(begin: isImageTile ? -0.08 : 0.08);

    if (isWrongFlash) {
      tile = tile
          .animate(key: ValueKey('shake_$wrongShakeTick'))
          .shake(hz: 4, curve: Curves.easeInOut, duration: 450.ms);
    }

    return tile;
  }
}

class _RiceGridPainter extends CustomPainter {
  _RiceGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _RiceGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MatchItem {
  final String id;
  final String? imageDescription;

  _MatchItem({required this.id, required this.imageDescription});
}
