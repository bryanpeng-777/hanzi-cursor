import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../data/hanzi_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../providers/game_config_provider.dart';
import '../utils/app_theme.dart';

class HanziQuizScreen extends ConsumerStatefulWidget {
  final int? level;
  final bool mistakeMode;

  const HanziQuizScreen({super.key, this.level, this.mistakeMode = false});

  @override
  ConsumerState<HanziQuizScreen> createState() => _HanziQuizScreenState();
}

class _HanziQuizScreenState extends ConsumerState<HanziQuizScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();

  late AnimationController _timerController;

  late List<HanziCharacter> _candidateChars;

  HanziCharacter? _currentHanzi;
  List<String> _options = [];

  String? _selectedAnswer;
  bool _answered = false;
  bool _timedOut = false;
  bool _gameComplete = false;

  int _questionNum = 0;
  int _totalQuestions = 0;
  int _score = 0;

  final List<double> _responseTimes = [];
  double _questionStartTime = 0;

  int _mistakesAdded = 0;
  int _mistakesCleared = 0;

  double _timeLimit = 6.0;
  int _passThreshold = 70;

  @override
  void initState() {
    super.initState();
    final config = ref.read(gameConfigProvider).valueOrNull;
    if (config != null) {
      _timeLimit = config.quizTimeLimitSeconds.toDouble();
      _passThreshold = config.quizPassThreshold;
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
      final mistakes = state.hanziQuizMistakes;
      _candidateChars =
          allHanzi.where((h) => mistakes.contains(h.character)).toList();
      _totalQuestions = _candidateChars.length.clamp(1, 20);
    } else {
      _candidateChars = getHanziByLevel(widget.level!);
      _totalQuestions = _candidateChars.length;
    }
  }

  void _nextQuestion() {
    if (_questionNum >= _totalQuestions) {
      setState(() => _gameComplete = true);
      _handleCompletion();
      return;
    }

    // 从候选列表中选出当前题目（顺序出题，不重复）
    _currentHanzi = _candidateChars[_questionNum % _candidateChars.length];

    // 生成 4 个选项：1 个正确 + 3 个干扰（同关卡或全库随机）
    final allChars = widget.mistakeMode
        ? allHanzi
        : (getHanziByLevel(widget.level!).length >= 4
            ? getHanziByLevel(widget.level!)
            : allHanzi);

    final wrongChars = allChars
        .where((h) => h.character != _currentHanzi!.character)
        .toList()
      ..shuffle(_random);

    _options = [
      _currentHanzi!.character,
      ...wrongChars.take(3).map((h) => h.character),
    ]..shuffle(_random);

    _selectedAnswer = null;
    _answered = false;
    _timedOut = false;

    setState(() {});

    _questionStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _timerController.reset();
    _timerController.forward();
  }

  void _handleCompletion() {
    if (!widget.mistakeMode && widget.level != null) {
      final scorePercent = (_score / _totalQuestions * 100).round();
      if (scorePercent >= _passThreshold) {
        ref.read(learningNotifierProvider.notifier)
            .markHanziLevelPassed(widget.level!, scorePercent);
      }
    }
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

    ref.read(learningNotifierProvider.notifier)
        .addHanziMistake(_currentHanzi!.character)
        .then((_) {
      if (mounted) setState(() => _mistakesAdded++);
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _questionNum++);
        _nextQuestion();
      }
    });
  }

  void _selectAnswer(String character) {
    if (_answered) return;
    _timerController.stop();

    final elapsed =
        DateTime.now().millisecondsSinceEpoch / 1000.0 - _questionStartTime;
    _responseTimes.add(elapsed.clamp(0, _timeLimit));

    final isCorrect = character == _currentHanzi!.character;
    setState(() {
      _selectedAnswer = character;
      _answered = true;
    });

    final notifier = ref.read(learningNotifierProvider.notifier);
    if (isCorrect) {
      _score++;
      if (widget.mistakeMode) {
        notifier.removeHanziMistake(character).then((_) {
          if (mounted) setState(() => _mistakesCleared++);
        });
      }
    } else {
      notifier.addHanziMistake(_currentHanzi!.character).then((_) {
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
    final title = widget.mistakeMode
        ? '错题重练 🔴'
        : '第${widget.level}关测验 ✏️';

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: CsAppBar(
        title: title,
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
          _buildQuestionCard(),
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
            value: _totalQuestions > 0 ? _questionNum / _totalQuestions : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
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
          const SizedBox(height: 24),
          // 拼音大字（无 emoji 提示）
          Text(
            _currentHanzi!.pinyin,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // 含义文字
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentHanzi!.meaning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '这个字怎么写？',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          if (_timedOut)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '⏰ 时间到！正确答案是「${_currentHanzi!.character}」',
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
        final char = entry.value;
        Color bgColor = Colors.white;
        Color borderColor = Colors.grey.shade200;
        Color textColor = const Color(0xFF333333);

        if (_answered) {
          if (char == _currentHanzi!.character) {
            bgColor = AppTheme.primaryGreen.withOpacity(0.15);
            borderColor = AppTheme.primaryGreen;
            textColor = AppTheme.primaryGreen;
          } else if (_selectedAnswer == char) {
            bgColor = Colors.red.withOpacity(0.08);
            borderColor = Colors.red;
            textColor = Colors.red;
          }
        }

        return GestureDetector(
          onTap: () => _selectAnswer(char),
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
                char,
                style: TextStyle(
                  fontSize: 40,
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
    final percent = _totalQuestions > 0
        ? (_score / _totalQuestions * 100).round()
        : 0;
    final avgTime = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final bool passed = percent >= 70;

    String emoji;
    String message;
    if (percent >= 90) {
      emoji = '🏆';
      message = '太厉害了！';
    } else if (percent >= 70) {
      emoji = '🎉';
      message = '很不错！通关了！';
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
                        fontSize: 30, fontWeight: FontWeight.bold))
                .animate(delay: 200.ms)
                .fadeIn(),
            const SizedBox(height: 8),
            Text('正确率：$percent%',
                    style: const TextStyle(fontSize: 22, color: Colors.grey))
                .animate(delay: 300.ms)
                .fadeIn(),
            Text('$_score / $_totalQuestions 题正确',
                    style: const TextStyle(fontSize: 18, color: Colors.grey))
                .animate(delay: 400.ms)
                .fadeIn(),
            Text('平均用时：${avgTime.toStringAsFixed(1)} 秒',
                    style: const TextStyle(fontSize: 16, color: Colors.grey))
                .animate(delay: 500.ms)
                .fadeIn(),
            const SizedBox(height: 12),
            // 通关提示
            if (!widget.mistakeMode && passed)
              _buildStatChip('🔓 已解锁下一关！', AppTheme.primaryGreen)
            else if (!widget.mistakeMode && !passed)
              _buildStatChip('再接再厉，70% 可通关', Colors.orange),
            // 错题摘要
            if (widget.mistakeMode && _mistakesCleared > 0)
              _buildStatChip('已消灭 $_mistakesCleared 个错题 ✅', AppTheme.primaryGreen)
            else if (_mistakesAdded > 0)
              _buildStatChip('本次新增 $_mistakesAdded 个错题 🔴', Colors.redAccent),
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
                ShadButton.outline(
                  onPressed: () => context.pop(),
                  leading: const Icon(Icons.home),
                  child: const Text('返回'),
                ),
              ],
            ).animate(delay: 600.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
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
    ).animate(delay: 550.ms).fadeIn();
  }
}
