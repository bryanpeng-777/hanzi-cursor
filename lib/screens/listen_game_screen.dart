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
        ref.read(learningNotifierProvider.notifier).addStars(_currentHanzi.character, 1);
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
      backgroundColor: AppTheme.backgroundPeach,
      appBar: CsAppBar(
        title: '听音选字',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('$_score/$_totalQuestions',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _gameComplete ? _buildCompletionScreen() : _buildGameBody(),
    );
  }

  Widget _buildGameBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProgressBar(),
          const SizedBox(height: 30),
          _buildPinyinCard(),
          const SizedBox(height: 40),
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

  Widget _buildPinyinCard() {
    return GestureDetector(
      onTap: _playSound,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ECDC4).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_isPlaying ? 0.5 : 0.2),
                shape: BoxShape.circle,
              ),
              child: CsImage(
                configKey: _isPlaying ? 'img_icon_playing' : 'img_icon_listen',
                description: _isPlaying ? '播放中' : '点击播放',
                width: 50, height: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentHanzi.pinyin,
              style: const TextStyle(
                fontSize: 52,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击喇叭听读音，选出正确的汉字',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildOptions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: _options.asMap().entries.map((entry) {
        final hanzi = entry.value;
        Color bgColor = Colors.white;
        Color borderColor = Colors.grey.shade200;
        if (_answered && _selectedAnswer == hanzi.character) {
          if (hanzi.character == _currentHanzi.character) {
            bgColor = AppTheme.primaryGreen.withOpacity(0.2);
            borderColor = AppTheme.primaryGreen;
          } else {
            bgColor = Colors.red.withOpacity(0.1);
            borderColor = Colors.red;
          }
        } else if (_answered && hanzi.character == _currentHanzi.character) {
          bgColor = AppTheme.primaryGreen.withOpacity(0.2);
          borderColor = AppTheme.primaryGreen;
        }

        return GestureDetector(
          onTap: () => _selectAnswer(hanzi.character),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CsImage(configKey: 'hanzi_icon_${hanzi.character}', description: hanzi.iconHint, width: 28, height: 28),
                const SizedBox(height: 6),
                Text(
                  hanzi.character,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (entry.key * 100).ms).fadeIn().scale(
              begin: const Offset(0.8, 0.8),
            );
      }).toList(),
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
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsImage(configKey: resultKey, description: message, width: 80, height: 80)
                .animate()
                .scale(curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold))
                .animate(delay: 300.ms)
                .fadeIn(),
            const SizedBox(height: 12),
            Text(
              '正确率: $percent%',
              style: const TextStyle(fontSize: 24, color: Colors.grey),
            ).animate(delay: 500.ms).fadeIn(),
            Text(
              '$_score / $_totalQuestions 题正确',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ).animate(delay: 600.ms).fadeIn(),
            const SizedBox(height: 30),
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
                  leading: CsImage(configKey: 'img_icon_refresh', description: '重来', width: 20, height: 20),
                  child: const Text('再来一次'),
                ),
                const SizedBox(width: 16),
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
}
