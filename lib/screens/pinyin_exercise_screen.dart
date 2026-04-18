import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../data/hanzi_data.dart';
import '../data/pinyin_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../providers/game_config_provider.dart';
import '../utils/app_theme.dart';

class PinyinExerciseScreen extends ConsumerStatefulWidget {
  final bool mistakeMode;

  const PinyinExerciseScreen({super.key, this.mistakeMode = false});

  @override
  ConsumerState<PinyinExerciseScreen> createState() => _PinyinExerciseScreenState();
}

class _PinyinExerciseScreenState extends ConsumerState<PinyinExerciseScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();

  late AnimationController _timerController;

  // 可用于出题的汉字（有声母的）
  late List<HanziCharacter> _candidateChars;

  // 当前题目
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

  // 记录每题作答耗时（秒）
  final List<double> _responseTimes = [];
  double _questionStartTime = 0;

  // 本局新增 / 消灭的错题数
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
      // _totalQuestions 由后台配置决定，默认值 10 已在字段声明处设置
    }
  }

  void _nextQuestion() {
    if (_questionNum >= _totalQuestions) {
      setState(() => _gameComplete = true);
      return;
    }

    final shuffled = List<HanziCharacter>.from(_candidateChars)..shuffle(_random);
    _currentHanzi = shuffled.first;
    _correctInitial = extractInitial(_currentHanzi!.pinyin)!;

    // 4 个选项：1 个正确 + 3 个随机错误声母
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
    ref.read(learningNotifierProvider.notifier).addPinyinMistake(_correctInitial).then((_) {
      if (mounted) setState(() => _mistakesAdded++);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
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
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _questionNum++);
        _nextQuestion();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: CsAppBar(
        title: widget.mistakeMode ? '错题重练 🔴' : '声母测验 ✏️',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_score/$_totalQuestions',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: _gameComplete ? _buildCompletionScreen() : _buildGameBody(),
    );
  }

  Widget _buildGameBody() {
    if (_currentHanzi == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 20),
          _buildTimerAndQuestion(),
          const SizedBox(height: 32),
          _buildOptions(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('第 ${_questionNum + 1} 题',
                style: const TextStyle(fontSize: 16)),
            Text('共 $_totalQuestions 题',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _questionNum / _totalQuestions,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerAndQuestion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 倒计时环
          AnimatedBuilder(
            animation: _timerController,
            builder: (context, _) {
              final remaining = 1.0 - _timerController.value;
              final Color timerColor = remaining > 0.5
                  ? AppTheme.primaryGreen
                  : remaining > 0.2
                      ? AppTheme.primaryYellow
                      : Colors.red;
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: remaining,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    ),
                  ),
                  Text(
                    '${(_timeLimit * remaining).ceil()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // 汉字大字
          Text(
            _currentHanzi!.character,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentHanzi!.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '这个字的声母是什么？',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (_timedOut)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '⏰ 时间到！正确答案是 $_correctInitial',
                style: const TextStyle(
                    color: Colors.yellowAccent, fontSize: 15),
              ).animate().fadeIn().shake(),
            ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92));
  }

  Widget _buildOptions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _options.asMap().entries.map((entry) {
        final initial = entry.value;
        Color bgColor = Colors.white;
        Color borderColor = Colors.grey.shade200;
        Color textColor = const Color(0xFF333333);

        if (_answered) {
          if (initial == _correctInitial) {
            bgColor = AppTheme.primaryGreen.withOpacity(0.15);
            borderColor = AppTheme.primaryGreen;
            textColor = AppTheme.primaryGreen;
          } else if (_selectedAnswer == initial) {
            bgColor = Colors.red.withOpacity(0.08);
            borderColor = Colors.red;
            textColor = Colors.red;
          }
        }

        return GestureDetector(
          onTap: () => _selectAnswer(initial),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ).animate(delay: (entry.key * 80).ms).fadeIn().scale(
              begin: const Offset(0.85, 0.85),
            );
      }).toList(),
    );
  }

  Widget _buildCompletionScreen() {
    final percent = (_score / _totalQuestions * 100).toInt();
    final avgTime = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    String emoji;
    String message;
    if (percent >= 90) {
      emoji = '🏆';
      message = '太厉害了！';
    } else if (percent >= 70) {
      emoji = '🎉';
      message = '很不错！';
    } else if (percent >= 50) {
      emoji = '💪';
      message = '继续加油！';
    } else {
      emoji = '📚';
      message = '多练练就好了！';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 80))
                .animate()
                .scale(curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 16),
            Text(message,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold))
                .animate(delay: 300.ms)
                .fadeIn(),
            const SizedBox(height: 8),
            Text('正确率：$percent%',
                    style: const TextStyle(fontSize: 22, color: Colors.grey))
                .animate(delay: 400.ms)
                .fadeIn(),
            Text('$_score / $_totalQuestions 题正确',
                    style: const TextStyle(fontSize: 18, color: Colors.grey))
                .animate(delay: 500.ms)
                .fadeIn(),
            const SizedBox(height: 8),
            Text('平均用时：${avgTime.toStringAsFixed(1)} 秒',
                    style: const TextStyle(fontSize: 16, color: Colors.grey))
                .animate(delay: 600.ms)
                .fadeIn(),
            const SizedBox(height: 12),
            // 错题摘要
            if (widget.mistakeMode)
              _buildStatChip(
                  '已消灭 $_mistakesCleared 个错题 ✅',
                  AppTheme.primaryGreen)
            else if (_mistakesAdded > 0)
              _buildStatChip(
                  '本次新增 $_mistakesAdded 个错题 🔴',
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
                  leading: const Text('🔄'),
                  child: const Text('再来一次'),
                ),
                if (widget.mistakeMode && _mistakesCleared > 0)
                  ShadButton(
                    onPressed: () {
                      final remaining =
                          ref.read(learningNotifierProvider).pinyinMistakes.length;
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
                    leading: const Text('⚡'),
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
            fontSize: 15, color: color, fontWeight: FontWeight.w600),
      ),
    ).animate(delay: 650.ms).fadeIn();
  }
}
