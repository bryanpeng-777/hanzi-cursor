import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../data/hanzi_data.dart';
import '../data/pinyin_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../providers/game_config_provider.dart';
import '../utils/app_theme.dart';

// ─── Color palette from Figma design ───────────────────────────────────────
const _skyBlue = Color(0xFF73C8F0);
const _cardBg = Color(0xFFF8F9FB);
const _cardBorder = Color(0xFFA9D4F0);
const _timerBg = Color(0xFFF3F6FA);
const _orangeAccent = Color(0xFFF8754A);
const _feedbackBg = Color(0xFFF2F6FB);
const _feedbackBorder = Color(0xFFB1D3E7);

// Card accent colors per option position (orange / teal / blue / pink)
const _optionColors = [
  Color(0xFFFC6E4E),
  Color(0xFF63C4AF),
  Color(0xFF5FA1EA),
  Color(0xFFFB8082),
];

// ─── Quick lookup: initial symbol → PinyinItem ─────────────────────────────
final _initialBySymbol = <String, PinyinItem>{
  for (final p in allInitials) p.symbol: p,
};

class PinyinExerciseScreen extends ConsumerStatefulWidget {
  final bool mistakeMode;

  const PinyinExerciseScreen({super.key, this.mistakeMode = false});

  @override
  ConsumerState<PinyinExerciseScreen> createState() =>
      _PinyinExerciseScreenState();
}

class _PinyinExerciseScreenState extends ConsumerState<PinyinExerciseScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late AnimationController _timerController;

  late List<HanziCharacter> _candidateChars;
  HanziCharacter? _currentHanzi;
  String _correctInitial = '';
  List<String> _options = [];

  String? _selectedAnswer;
  bool _answered = false;
  bool _timedOut = false;
  bool _gameComplete = false;

  int _questionNum = 0;
  int _totalQuestions = 10;
  int _score = 0;

  final List<double> _responseTimes = [];
  double _questionStartTime = 0;
  int _mistakesAdded = 0;
  int _mistakesCleared = 0;
  double _timeLimit = 6.0;

  @override
  void initState() {
    super.initState();
    final config = ref.read(gameConfigProvider).valueOrNull;
    if (config != null) {
      _timeLimit = config.quizTimeLimitSeconds.toDouble();
      if (!widget.mistakeMode) {
        _totalQuestions = config.quizQuestionsCount;
      }
    }
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_timeLimit * 1000).toInt()),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onTimeout();
      });

    _buildCandidateList();
    _nextQuestion();
  }

  void _buildCandidateList() {
    final state = ref.read(learningNotifierProvider);
    if (widget.mistakeMode) {
      final mistakes = state.pinyinMistakes;
      _candidateChars = allHanzi
          .where((h) {
            final init = extractInitial(h.pinyin);
            return init != null && mistakes.contains(init);
          })
          .toList();
      _totalQuestions = _candidateChars.length.clamp(1, 10);
    } else {
      _candidateChars =
          allHanzi.where((h) => extractInitial(h.pinyin) != null).toList();
    }
  }

  void _nextQuestion() {
    if (_questionNum >= _totalQuestions) {
      setState(() => _gameComplete = true);
      return;
    }

    final shuffled = List<HanziCharacter>.from(_candidateChars)
      ..shuffle(_random);
    _currentHanzi = shuffled.first;
    _correctInitial = extractInitial(_currentHanzi!.pinyin)!;

    final allSymbols = allInitials.map((p) => p.symbol).toList();
    final wrongOptions = allSymbols
        .where((s) => s != _correctInitial)
        .toList()
      ..shuffle(_random);
    _options = [_correctInitial, ...wrongOptions.take(3)]..shuffle(_random);

    _selectedAnswer = null;
    _answered = false;
    _timedOut = false;
    setState(() {});

    _questionStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _timerController.reset();
    _timerController.forward();
  }

  void _onTimeout() {
    if (_answered) return;
    final elapsed =
        DateTime.now().millisecondsSinceEpoch / 1000.0 - _questionStartTime;
    _responseTimes.add(elapsed.clamp(0, _timeLimit));
    setState(() {
      _timedOut = true;
      _answered = true;
    });
    ref
        .read(learningNotifierProvider.notifier)
        .addPinyinMistake(_correctInitial)
        .then((_) {
      if (mounted) setState(() => _mistakesAdded++);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _questionNum++);
        _nextQuestion();
      }
    });
  }

  void _selectAnswer(String initial) {
    if (_answered) return;
    _timerController.stop();
    final elapsed =
        DateTime.now().millisecondsSinceEpoch / 1000.0 - _questionStartTime;
    _responseTimes.add(elapsed.clamp(0, _timeLimit));

    final isCorrect = initial == _correctInitial;
    setState(() {
      _selectedAnswer = initial;
      _answered = true;
    });

    final notifier = ref.read(learningNotifierProvider.notifier);
    if (isCorrect) {
      _score++;
      notifier.addStars(_currentHanzi!.character, 1);
      if (widget.mistakeMode) {
        notifier.removePinyinMistake(_correctInitial).then((_) {
          if (mounted) setState(() => _mistakesCleared++);
        });
      }
    } else {
      notifier.addPinyinMistake(_correctInitial).then((_) {
        if (mounted) setState(() => _mistakesAdded++);
      });
    }
  }

  void _goNext() {
    setState(() => _questionNum++);
    _nextQuestion();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_gameComplete) return _buildCompletionScreen();
    return Scaffold(
      backgroundColor: _skyBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildGameBody()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SizedBox(
      height: 58,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            _headerBackButton(),
            const SizedBox(width: 8),
            _headerTitlePill(),
            const SizedBox(width: 8),
            Expanded(child: _headerProgressBar()),
            const SizedBox(width: 8),
            _headerTimerPill(),
            const SizedBox(width: 8),
            _headerAvatarPill(),
          ],
        ),
      ),
    );
  }

  Widget _headerBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: _orangeAccent, size: 22),
      ),
    );
  }

  Widget _headerTitlePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        widget.mistakeMode ? '错题重练' : '拼音测验',
        style: const TextStyle(
          color: _orangeAccent,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _headerProgressBar() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _questionNum / _totalQuestions,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_questionNum',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF636363),
            ),
          ),
          Text(
            '/$_totalQuestions题',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _headerTimerPill() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _timerBg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _cardBorder, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) {
              final remaining =
                  (1.0 - _timerController.value) * _timeLimit;
              final mins =
                  (remaining ~/ 60).toString().padLeft(2, '0');
              final secs =
                  (remaining.toInt() % 60).toString().padLeft(2, '0');
              return Text(
                '$mins:$secs',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF636363),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerAvatarPill() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _cardBorder,
            child: const Icon(Icons.person_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('宝宝',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 12),
                  Text('$_score',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Game body ─────────────────────────────────────────────────────────

  Widget _buildGameBody() {
    if (_currentHanzi == null) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7FD4F5),
            Color(0xFFB5E8F7),
            Color(0xFFDDF3FC),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(flex: 4, child: _buildQuestionCard()),
          const SizedBox(height: 10),
          Expanded(flex: 6, child: _buildOptionsRow()),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── Question card ─────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    final pinyin = _currentHanzi!.pinyin;
    // Derive the vowel/final part by stripping the initial
    final vowelPart = _correctInitial.isNotEmpty
        ? pinyin.replaceFirst(_correctInitial, '')
        : pinyin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _cardBorder.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '读一读，选出正确的声母',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666667),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Pinyin display: "?- ā" style
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '?-',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4D4D4E),
                    letterSpacing: -1,
                  ),
                ),
                if (vowelPart.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    vowelPart,
                    style: const TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w700,
                      color: _orangeAccent,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Character with circular timer progress ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, _) {
                      final remaining = 1.0 - _timerController.value;
                      final timerColor = remaining > 0.5
                          ? AppTheme.primaryGreen
                          : remaining > 0.2
                              ? AppTheme.primaryYellow
                              : Colors.red;
                      return CircularProgressIndicator(
                        value: remaining,
                        strokeWidth: 4,
                        backgroundColor:
                            Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            timerColor),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentHanzi!.character,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333334),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_timedOut)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '时间到！正确声母是 $_correctInitial',
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13),
                ).animate().fadeIn().shake(),
              ),
          ],
        ),
      ).animate().fadeIn(duration: 280.ms).scale(
            begin: const Offset(0.94, 0.94),
          ),
    );
  }

  // ─── Answer option cards ────────────────────────────────────────────────

  Widget _buildOptionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: _options.asMap().entries.map((entry) {
          final idx = entry.key;
          final initial = entry.value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _buildOptionCard(idx, initial),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionCard(int idx, String initial) {
    final isCorrect = initial == _correctInitial;
    final isSelected = _selectedAnswer == initial;
    final accentColor = _optionColors[idx];

    Color cardColor = Colors.white;
    Color borderColor = accentColor.withOpacity(0.35);
    Color textColor = const Color(0xFF333335);
    Color numBgColor = accentColor;

    if (_answered) {
      if (isCorrect) {
        cardColor = AppTheme.primaryGreen.withOpacity(0.10);
        borderColor = AppTheme.primaryGreen;
        textColor = AppTheme.primaryGreen;
        numBgColor = AppTheme.primaryGreen;
      } else if (isSelected) {
        cardColor = Colors.red.withOpacity(0.07);
        borderColor = Colors.red;
        textColor = Colors.red;
        numBgColor = Colors.red;
      } else {
        numBgColor = accentColor.withOpacity(0.5);
      }
    }

    // Use the example character for this initial (if found)
    final pinyinItem = _initialBySymbol[initial];
    final exampleChar = pinyinItem?.example ?? '';
    final iconHint = pinyinItem?.iconHint ?? '声母$initial示意图';

    return GestureDetector(
      onTap: () => _selectAnswer(initial),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Numbered badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: numBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${idx + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Example character image
            CsImage(
              configKey: 'hanzi_icon_$exampleChar',
              description: iconHint,
              width: 52,
              height: 52,
            ),
            const SizedBox(height: 4),
            // Initial text
            Text(
              initial,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            // Example character name
            if (exampleChar.isNotEmpty)
              Text(
                exampleChar,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ).animate(delay: (idx * 80).ms).fadeIn().scale(
            begin: const Offset(0.85, 0.85),
          ),
    );
  }

  // ─── Bottom bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    if (!_answered) return const SizedBox(height: 8);

    final isCorrect = _selectedAnswer == _correctInitial;
    final message = _timedOut
        ? '⏰ 时间到！正确声母是 $_correctInitial'
        : isCorrect
            ? '加油哦！你真棒，继续努力！'
            : '别灰心！正确声母是 $_correctInitial';

    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: _feedbackBg,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _feedbackBorder, width: 2),
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isCorrect && !_timedOut
                            ? const Color(0xFF5592DB)
                            : Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _goNext,
            child: Container(
              width: 100,
              height: 60,
              decoration: BoxDecoration(
                color: _orangeAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  '下一题',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(
          begin: 1.2,
          end: 0.0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─── Completion screen ──────────────────────────────────────────────────

  Widget _buildCompletionScreen() {
    final percent = (_score / _totalQuestions * 100).toInt();
    final avgTime = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    String resultKey;
    String message;
    if (percent >= 90) {
      resultKey = 'img_result_excellent';
      message = '太厉害了！';
    } else if (percent >= 70) {
      resultKey = 'img_result_good';
      message = '很不错！';
    } else if (percent >= 50) {
      resultKey = 'img_result_ok';
      message = '继续加油！';
    } else {
      resultKey = 'img_result_study_more';
      message = '多练练就好了！';
    }

    return Scaffold(
      backgroundColor: _skyBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CsImage(
                  configKey: resultKey,
                  description: message,
                  width: 80,
                  height: 80,
                ).animate().scale(
                      curve: Curves.elasticOut,
                      duration: 600.ms,
                    ),
                const SizedBox(height: 16),
                Text(message,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold))
                    .animate(delay: 300.ms)
                    .fadeIn(),
                const SizedBox(height: 8),
                Text('正确率：$percent%',
                        style: const TextStyle(
                            fontSize: 22, color: Colors.white70))
                    .animate(delay: 400.ms)
                    .fadeIn(),
                Text('$_score / $_totalQuestions 题正确',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white70))
                    .animate(delay: 500.ms)
                    .fadeIn(),
                const SizedBox(height: 8),
                Text('平均用时：${avgTime.toStringAsFixed(1)} 秒',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white60))
                    .animate(delay: 600.ms)
                    .fadeIn(),
                const SizedBox(height: 12),
                if (widget.mistakeMode)
                  _buildStatChip(
                      '已消灭 $_mistakesCleared 个错题',
                      AppTheme.primaryGreen)
                else if (_mistakesAdded > 0)
                  _buildStatChip(
                      '本次新增 $_mistakesAdded 个错题',
                      Colors.redAccent),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ShadButton(
                      onPressed: () {
                        setState(() {
                          _score = 0;
                          _questionNum = 0;
                          _mistakesAdded = 0;
                          _mistakesCleared = 0;
                          _responseTimes.clear();
                          _gameComplete = false;
                        });
                        _buildCandidateList();
                        _nextQuestion();
                      },
                      leading: CsImage(
                          configKey: 'img_icon_refresh',
                          description: '重新练习',
                          width: 20,
                          height: 20),
                      child: const Text('再来一次'),
                    ),
                    if (widget.mistakeMode && _mistakesCleared > 0)
                      ShadButton(
                        onPressed: () {
                          final remaining = ref
                              .read(learningNotifierProvider)
                              .pinyinMistakes
                              .length;
                          if (remaining > 0) {
                            setState(() {
                              _score = 0;
                              _questionNum = 0;
                              _mistakesAdded = 0;
                              _mistakesCleared = 0;
                              _responseTimes.clear();
                              _gameComplete = false;
                            });
                            _buildCandidateList();
                            _nextQuestion();
                          } else {
                            context.pop();
                          }
                        },
                        backgroundColor: Colors.redAccent,
                        leading: CsImage(
                            configKey: 'img_icon_lightning',
                            description: '继续错题',
                            width: 20,
                            height: 20),
                        child: const Text('继续错题'),
                      ),
                    ShadButton.outline(
                      onPressed: () => context.pop(),
                      leading: const Icon(Icons.home),
                      child: const Text('返回'),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    ).animate(delay: 650.ms).fadeIn();
  }
}
