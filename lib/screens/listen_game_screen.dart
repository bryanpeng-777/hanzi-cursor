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
import '../models/hanzi_model.dart';
import '../providers/game_config_provider.dart';
import '../providers/learning_provider.dart';

class ListenGameScreen extends ConsumerStatefulWidget {
  const ListenGameScreen({super.key});

  @override
  ConsumerState<ListenGameScreen> createState() => _ListenGameScreenState();
}

class _ListenGameScreenState extends ConsumerState<ListenGameScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('hanzi-listen-game-landscape'),
      backgroundColor: HanziDesignSpec.surfaceWarm,
      body: SafeArea(
        child: _gameComplete ? _buildCompletionScreen() : _buildGameBody(),
      ),
    );
  }

  Widget _buildGameBody() {
    return Stack(
      key: const Key('hanzi-listen-game-body'),
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CsImage(
            configKey: 'figma_listen_canvas_backdrop',
            description: '听音选字页面背景',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: ListenGameD2cLayout.sx(101),
          right: ListenGameD2cLayout.sx(116),
          bottom: 0,
          height: ListenGameD2cLayout.sy(36),
          child: CsImage(
            configKey: 'figma_listen_bottom_deco',
            description: '听音选字底部装饰',
            fit: BoxFit.fitWidth,
          ),
        ),
        Column(
          children: [
            _buildFigmaHeader(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ListenGameD2cLayout.sx(20),
                  ListenGameD2cLayout.sy(8),
                  ListenGameD2cLayout.sx(20),
                  ListenGameD2cLayout.sy(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 45,
                      child: _buildAudioPanel(),
                    ),
                    SizedBox(width: ListenGameD2cLayout.sx(12)),
                    Expanded(
                      flex: 55,
                      child: _buildOptionsPanel(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFigmaHeader() {
    final headerH = ListenGameD2cLayout.sy(ListenGameD2cLayout.headerH);

    return SizedBox(
      key: const Key('hanzi-listen-game-guide-header'),
      height: headerH.clamp(48, 56),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CsImage(
            configKey: 'figma_listen_header_bg',
            description: '听音选字顶栏背景',
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ListenGameD2cLayout.sx(16),
              vertical: ListenGameD2cLayout.sy(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: CsImage(
                    configKey: 'figma_listen_back_btn',
                    description: '返回',
                    width: ListenGameD2cLayout.sx(ListenGameD2cLayout.backBtnSize)
                        .clamp(36, 44),
                    height: ListenGameD2cLayout.sx(ListenGameD2cLayout.backBtnSize)
                        .clamp(36, 44),
                  ),
                ),
                Expanded(
                  child: Text(
                    '听音选字',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansSc(
                      fontSize: ListenGameD2cLayout.sx(54).clamp(20, 26).sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(ListenGameD2cLayout.colorTitle),
                      height: 1.1,
                    ),
                  ),
                ),
                _buildProgressPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ListenGameD2cLayout.sx(18),
        vertical: ListenGameD2cLayout.sy(8),
      ),
      decoration: BoxDecoration(
        color: const Color(ListenGameD2cLayout.colorProgressPill),
        borderRadius: BorderRadius.circular(
          ListenGameD2cLayout.sx(33).r,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CsImage(
            configKey: 'figma_listen_progress_star',
            description: '进度星星',
            width: ListenGameD2cLayout.sx(28).clamp(18, 24),
            height: ListenGameD2cLayout.sx(28).clamp(18, 24),
          ),
          SizedBox(width: 6.w),
          Text(
            '${_questionNum + 1}/$_totalQuestions',
            style: GoogleFonts.notoSansSc(
              fontSize: ListenGameD2cLayout.sx(39).clamp(16, 20).sp,
              fontWeight: FontWeight.w600,
              color: const Color(ListenGameD2cLayout.colorProgressText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPanel() {
    return GestureDetector(
      key: const Key('hanzi-listen-game-audio-panel'),
      onTap: _playSound,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ListenGameD2cLayout.sx(ListenGameD2cLayout.optionCardRadius).r,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CsImage(
              configKey: 'figma_listen_audio_panel_bg',
              description: '听音选字左侧听音面板',
              fit: BoxFit.cover,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _isPlaying ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: CsImage(
                    configKey: 'figma_listen_play_btn',
                    description: _isPlaying ? '播放中' : '点击播放',
                    width: ListenGameD2cLayout.sx(ListenGameD2cLayout.playBtnSize)
                        .clamp(88, 120),
                    height: ListenGameD2cLayout.sx(ListenGameD2cLayout.playBtnSize)
                        .clamp(88, 120),
                  ),
                ),
                SizedBox(height: ListenGameD2cLayout.sy(20)),
                Text(
                  _currentHanzi.pinyin,
                  key: const Key('hanzi-listen-game-pinyin'),
                  style: GoogleFonts.notoSansSc(
                    fontSize: ListenGameD2cLayout.sx(138).clamp(44, 58).sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(ListenGameD2cLayout.colorPinyin),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: ListenGameD2cLayout.sy(12)),
                Text(
                  '点击听读音，选出正确汉字',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansSc(
                    fontSize: ListenGameD2cLayout.sx(33).clamp(12, 14).sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(ListenGameD2cLayout.colorHint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsPanel() {
    return Container(
      key: const Key('hanzi-listen-game-options-panel'),
      padding: EdgeInsets.all(ListenGameD2cLayout.sx(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(
          ListenGameD2cLayout.sx(ListenGameD2cLayout.optionCardRadius).r,
        ),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: ListenGameD2cLayout.sx(10),
        mainAxisSpacing: ListenGameD2cLayout.sy(10),
        childAspectRatio: 0.95,
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
    );
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
      child: Container(
        key: const Key('hanzi-listen-game-completion'),
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: HanziDesignSpec.surfaceCard,
          borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
          boxShadow: HanziDesignSpec.cardShadow(
            color: const Color(ListenGameD2cLayout.colorProgressPill),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsImage(
              configKey: resultKey,
              description: message,
              width: 64.w,
              height: 64.w,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              style: HanziDesignSpec.hubTitleStyle.copyWith(fontSize: 22.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              '正确率 $percent% · $_score / $_totalQuestions 题正确',
              style: HanziDesignSpec.cardBodyStyle.copyWith(fontSize: 13.sp),
            ),
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
            ),
          ],
        ),
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
    final showSelected = isSelected && !isAnswered;
    final showCorrect = isAnswered && isCorrect;
    final showWrong = isAnswered && isSelected && !isCorrect;

    Color borderColor = const Color(ListenGameD2cLayout.colorCardBorder);
    double borderWidth = ListenGameD2cLayout.optionBorderDefault;

    if (showSelected || showCorrect) {
      borderColor = const Color(ListenGameD2cLayout.colorSelectedBorder);
      borderWidth = ListenGameD2cLayout.optionBorderSelected;
    } else if (showWrong) {
      borderColor = HanziDesignSpec.accentMistake;
      borderWidth = ListenGameD2cLayout.optionBorderSelected;
    } else if (isAnswered && isCorrect) {
      borderColor = const Color(ListenGameD2cLayout.colorSelectedBorder);
      borderWidth = ListenGameD2cLayout.optionBorderSelected;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(ListenGameD2cLayout.colorCardBg),
          borderRadius: BorderRadius.circular(
            ListenGameD2cLayout.sx(ListenGameD2cLayout.optionCardRadius).r,
          ),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Stack(
          children: [
            if (showSelected || showCorrect)
              Positioned(
                top: ListenGameD2cLayout.sy(8),
                right: ListenGameD2cLayout.sx(8),
                child: CsImage(
                  configKey: 'figma_listen_option_check_icon',
                  description: '已选中',
                  width: ListenGameD2cLayout.sx(24).clamp(16, 22),
                  height: ListenGameD2cLayout.sx(24).clamp(16, 22),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CsImage(
                  configKey: 'hanzi_icon_${hanzi.character}',
                  description: hanzi.iconHint,
                  width: ListenGameD2cLayout.sx(120).clamp(48, 72),
                  height: ListenGameD2cLayout.sx(120).clamp(48, 72),
                ),
                SizedBox(height: ListenGameD2cLayout.sy(6)),
                Text(
                  hanzi.character,
                  style: GoogleFonts.notoSansSc(
                    fontSize: ListenGameD2cLayout.sx(94).clamp(34, 44).sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(ListenGameD2cLayout.colorCharText),
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
