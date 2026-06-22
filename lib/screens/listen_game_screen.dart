import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cs_ui/cs_ui.dart';

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
  final _tts = FlutterTts();

  late HanziCharacter _currentHanzi;
  late List<HanziCharacter> _options;
  int _score = 0;
  int _questionNum = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _gameComplete = false;
  bool _isPlaying = false;
  int _wrongShakeTick = 0;

  int get _totalQuestions =>
      ref.read(gameConfigProvider).valueOrNull?.listenGameQuestionsCount ?? 8;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
    _nextQuestion();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
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

  Future<void> _playSound() async {
    setState(() => _isPlaying = true);
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.speak(_currentHanzi.character);
    if (mounted) setState(() => _isPlaying = false);
  }

  void _selectAnswer(String character) {
    if (_answered) return;
    final isCorrect = character == _currentHanzi.character;
    setState(() {
      _selectedAnswer = character;
      _answered = true;
      if (isCorrect) {
        _score++;
        ref
            .read(learningNotifierProvider.notifier)
            .addStars(_currentHanzi.character, 1);
      } else {
        _wrongShakeTick++;
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _questionNum++);
        _nextQuestion();
      }
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
            child: _ListenScoreBadge(
              score: _score,
              total: _totalQuestions,
            ),
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
                flex: 45,
                child: _buildListenPanel(),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 55,
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
                  '点击喇叭听读音，选出正确的汉字',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _ListenStatChip(
                label: '题号',
                value: '${_questionNum + 1}/$_totalQuestions',
              ),
              SizedBox(width: 8.w),
              _ListenStatChip(
                label: '得分',
                value: '$_score',
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

  Widget _buildListenPanel() {
    return HanziSurfaceCard(
      key: const Key('hanzi-listen-game-listen-panel'),
      shadowColor: _listenGradient.first,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '听一听',
            style: HanziDesignSpec.cardTitleStyle.copyWith(fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            '再点下方汉字作答',
            style: HanziDesignSpec.cardBodyStyle.copyWith(fontSize: 12.sp),
          ),
          const Spacer(),
          Center(
            child: GestureDetector(
              onTap: _playSound,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: ListenGameD2cLayout.playButtonSize.w,
                height: ListenGameD2cLayout.playButtonSize.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: _listenGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _listenGradient.first.withValues(
                        alpha: _isPlaying ? 0.55 : 0.35,
                      ),
                      blurRadius: _isPlaying ? 20 : 12,
                      spreadRadius: _isPlaying ? 4 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: CsImage(
                    configKey:
                        _isPlaying ? 'img_icon_playing' : 'img_icon_listen',
                    description: _isPlaying ? '播放中' : '点击播放',
                    width: 36.w,
                    height: 36.w,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _currentHanzi.pinyin,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansSc(
              fontSize: 44.sp,
              fontWeight: FontWeight.w800,
              color: HanziDesignSpec.titleInk,
              letterSpacing: 3,
              height: 1.1,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _currentHanzi.meaning,
            textAlign: TextAlign.center,
            style: HanziDesignSpec.cardBodyStyle.copyWith(fontSize: 13.sp),
          ),
          const Spacer(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.06);
  }

  Widget _buildOptionsPanel() {
    return HanziSurfaceCard(
      key: const Key('hanzi-listen-game-options-panel'),
      shadowColor: HanziDesignSpec.accentLearn,
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '选汉字',
            style: HanziDesignSpec.cardTitleStyle.copyWith(fontSize: 16.sp),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.35,
              children: _options.asMap().entries.map((entry) {
                final hanzi = entry.value;
                final isSelected = _selectedAnswer == hanzi.character;
                final isCorrect = hanzi.character == _currentHanzi.character;
                final isWrongSelected = _answered && isSelected && !isCorrect;

                return _ListenOptionTile(
                  key: ValueKey('listen_option_${hanzi.character}'),
                  hanzi: hanzi,
                  index: entry.key,
                  isSelected: isSelected,
                  isCorrect: isCorrect,
                  answered: _answered,
                  isWrongFlash: isWrongSelected,
                  wrongShakeTick: _wrongShakeTick,
                  onTap: () => _selectAnswer(hanzi.character),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideX(begin: 0.06);
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
                      _wrongShakeTick = 0;
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

class _ListenScoreBadge extends StatelessWidget {
  const _ListenScoreBadge({required this.score, required this.total});

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

class _ListenStatChip extends StatelessWidget {
  const _ListenStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
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
    required this.isCorrect,
    required this.answered,
    required this.isWrongFlash,
    required this.wrongShakeTick,
    required this.onTap,
  });

  final HanziCharacter hanzi;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final bool isWrongFlash;
  final int wrongShakeTick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = HanziDesignSpec.surfaceCard;
    Color borderColor = HanziDesignSpec.subtitleMuted.withValues(alpha: 0.2);
    double scale = 1.0;

    if (answered && isCorrect) {
      bgColor = HanziDesignSpec.accentLearn.withValues(alpha: 0.12);
      borderColor = HanziDesignSpec.accentLearn;
    } else if (isWrongFlash) {
      bgColor = HanziDesignSpec.accentMistake.withValues(alpha: 0.12);
      borderColor = HanziDesignSpec.accentMistake;
    } else if (isSelected) {
      bgColor = _ListenGameScreenState._listenGradient.first.withValues(alpha: 0.1);
      borderColor = _ListenGameScreenState._listenGradient.first;
      scale = 1.03;
    }

    Widget tile = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: answered ? null : onTap,
          borderRadius:
              BorderRadius.circular(ListenGameD2cLayout.optionRadius.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(ListenGameD2cLayout.optionRadius.r),
              border: Border.all(
                color: borderColor,
                width: isSelected || (answered && isCorrect) ? 2.5 : 1.5,
              ),
              boxShadow: isSelected && !answered
                  ? [
                      BoxShadow(
                        color: _ListenGameScreenState._listenGradient.first
                            .withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CsImage(
                  configKey: 'hanzi_icon_${hanzi.character}',
                  description: hanzi.iconHint,
                  width: 28.w,
                  height: 28.w,
                ),
                SizedBox(height: 4.h),
                Text(
                  hanzi.character,
                  style: GoogleFonts.notoSansSc(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    color: HanziDesignSpec.titleInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    tile = tile
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 280.ms)
        .scale(begin: const Offset(0.85, 0.85));

    if (isWrongFlash) {
      tile = tile
          .animate(key: ValueKey('listen_shake_$wrongShakeTick'))
          .shake(hz: 4, curve: Curves.easeInOut, duration: 450.ms);
    }

    return tile;
  }
}
