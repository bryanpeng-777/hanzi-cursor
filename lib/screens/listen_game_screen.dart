import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/listen_game_d2c_layout.dart';
import '../data/hanzi_data.dart';
import '../design/hanzi_design_spec.dart';
import '../design/hanzi_shared_widgets.dart';
import '../models/hanzi_model.dart';
import '../providers/game_config_provider.dart';
import '../providers/learning_provider.dart';

class ListenGameScreen extends ConsumerStatefulWidget {
  const ListenGameScreen({super.key});

  @override
  ConsumerState<ListenGameScreen> createState() => _ListenGameScreenState();
}

class _ListenGameScreenState extends ConsumerState<ListenGameScreen> {
  static const _listenGradient = [Color(0xFF4ECDC4), Color(0xFF44A08D)];

  final _random = Random();
  late HanziCharacter _currentHanzi;
  late List<HanziCharacter> _options;
  int _score = 0;
  int _questionNum = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _gameComplete = false;
  bool _isPlaying = false;

  int get _totalQuestions =>
      ref.read(gameConfigProvider).valueOrNull?.listenGameQuestionsCount ?? 8;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_questionNum >= _totalQuestions) {
      setState(() => _gameComplete = true);
      return;
    }
    final shuffled = allHanzi.toList()..shuffle(_random);
    _currentHanzi = shuffled.first;
    final wrongOptions = shuffled.skip(1).take(3).toList();
    _options = [_currentHanzi, ...wrongOptions]..shuffle(_random);
    _selectedAnswer = null;
    _answered = false;
    setState(() {});
  }

  void _selectAnswer(String character) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = character;
      _answered = true;
      if (character == _currentHanzi.character) {
        _score++;
        ref
            .read(learningNotifierProvider.notifier)
            .addStars(_currentHanzi.character, 1);
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _questionNum++);
        _nextQuestion();
      }
    });
  }

  void _playSound() {
    setState(() => _isPlaying = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  double get _progress =>
      _totalQuestions == 0 ? 0 : _questionNum / _totalQuestions;

  @override
  Widget build(BuildContext context) {
    return HanziLandscapeScaffold(
      key: const Key('hanzi-listen-game-landscape'),
      backgroundColor: HanziDesignSpec.surfaceWarm,
      appBar: CsAppBar(
        title: '听音选字',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: _ScoreBadge(score: _score, total: _totalQuestions),
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
      key: const Key('hanzi-listen-game-body'),
      children: [
        _buildHeaderPanel(),
        SizedBox(height: 10.h),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _buildAudioPanel(),
              ),
              SizedBox(width: 10.w),
              Expanded(
                flex: 7,
                child: _buildOptionsPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      key: const Key('hanzi-listen-game-guide-header'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _listenGradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        boxShadow: [
          BoxShadow(
            color: _listenGradient.first.withValues(alpha: 0.35),
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
                  '听拼音，选出正确的汉字！',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _StatChip(
                label: '题号',
                value: '${_questionNum + 1}/$_totalQuestions',
              ),
              SizedBox(width: 8.w),
              _StatChip(
                label: '得分',
                value: '$_score',
                highlight: _score > 0,
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

  Widget _buildAudioPanel() {
    return HanziSurfaceCard(
      key: const Key('hanzi-listen-game-audio-panel'),
      shadowColor: _listenGradient.first,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _listenGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _playSound,
            borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: ListenGameD2cLayout.playButtonSize.w,
                    height: ListenGameD2cLayout.playButtonSize.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _isPlaying ? 0.55 : 0.25,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: _isPlaying
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: CsImage(
                        configKey: _isPlaying
                            ? 'img_icon_playing'
                            : 'img_icon_listen',
                        description: _isPlaying ? '播放中' : '点击播放',
                        width: 36.w,
                        height: 36.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _currentHanzi.pinyin,
                    key: const Key('hanzi-listen-game-pinyin'),
                    style: GoogleFonts.notoSansSc(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '点击喇叭听读音',
                    style: GoogleFonts.notoSansSc(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }

  Widget _buildOptionsPanel() {
    return HanziSurfaceCard(
      key: const Key('hanzi-listen-game-options-panel'),
      shadowColor: HanziDesignSpec.accentLearn,
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
                  color: HanziDesignSpec.accentLearn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: CsImage(
                    configKey: 'img_card_game_listen',
                    description: '听音选字',
                    width: 16.w,
                    height: 16.w,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选汉字',
                    style: HanziDesignSpec.cardTitleStyle.copyWith(
                      fontSize: 15.sp,
                    ),
                  ),
                  Text(
                    '选出你听到的字',
                    style: HanziDesignSpec.cardBodyStyle.copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 1.35,
              children: _options.asMap().entries.map((entry) {
                final hanzi = entry.value;
                return _ListenOptionTile(
                  key: ValueKey('listen_option_${hanzi.character}'),
                  hanzi: hanzi,
                  index: entry.key,
                  isSelected: _selectedAnswer == hanzi.character,
                  isAnswered: _answered,
                  isCorrect: hanzi.character == _currentHanzi.character,
                  onTap: () => _selectAnswer(hanzi.character),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideX(begin: 0.1);
  }

  Widget _buildCompletionScreen() {
    final percent = (_score / _totalQuestions * 100).toInt();
    String resultKey;
    String message;
    if (percent >= 80) {
      resultKey = 'img_result_excellent';
      message = '太厉害了！';
    } else if (percent >= 60) {
      resultKey = 'img_result_good';
      message = '很不错！';
    } else {
      resultKey = 'img_result_ok';
      message = '继续加油！';
    }

    return Center(
      child: HanziSurfaceCard(
        key: const Key('hanzi-listen-game-completion'),
        shadowColor: _listenGradient.first,
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
              '正确率 $percent% · $_score / $_totalQuestions 题正确',
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
                    opacity: i < (percent ~/ 34).clamp(0, 3) ? 1.0 : 0.25,
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
                  onPressed: () {
                    setState(() {
                      _score = 0;
                      _questionNum = 0;
                      _gameComplete = false;
                    });
                    _nextQuestion();
                  },
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
  const _ScoreBadge({required this.score, required this.total});

  final int score;
  final int total;

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
            '$score/$total',
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

class _ListenOptionTile extends StatelessWidget {
  const _ListenOptionTile({
    super.key,
    required this.hanzi,
    required this.index,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.onTap,
  });

  final HanziCharacter hanzi;
  final int index;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = HanziDesignSpec.surfaceCard;
    Color borderColor = HanziDesignSpec.subtitleMuted.withValues(alpha: 0.2);

    if (isAnswered && isSelected) {
      if (isCorrect) {
        bgColor = HanziDesignSpec.accentLearn.withValues(alpha: 0.15);
        borderColor = HanziDesignSpec.accentLearn;
      } else {
        bgColor = HanziDesignSpec.accentMistake.withValues(alpha: 0.12);
        borderColor = HanziDesignSpec.accentMistake;
      }
    } else if (isAnswered && isCorrect) {
      bgColor = HanziDesignSpec.accentLearn.withValues(alpha: 0.15);
      borderColor = HanziDesignSpec.accentLearn;
    } else if (isSelected) {
      borderColor = const Color(0xFF4ECDC4);
      bgColor = const Color(0xFF4ECDC4).withValues(alpha: 0.08);
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            ListenGameD2cLayout.optionTileRadius.r,
          ),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CsImage(
              configKey: 'hanzi_icon_${hanzi.character}',
              description: hanzi.iconHint,
              width: 24.w,
              height: 24.w,
            ),
            SizedBox(height: 4.h),
            Text(
              hanzi.character,
              style: GoogleFonts.notoSansSc(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                color: HanziDesignSpec.titleInk,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack);
  }
}
