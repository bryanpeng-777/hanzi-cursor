import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cs_framework/cs_framework.dart';
import '../data/hanzi_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';

class MatchGameScreen extends StatefulWidget {
  const MatchGameScreen({super.key});

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  late List<HanziCharacter> _gameCharacters;
  late List<_MatchItem> _leftItems;  // emoji cards
  late List<_MatchItem> _rightItems; // character cards
  String? _selectedLeft;
  String? _selectedRight;
  Set<String> _matchedPairs = {};
  int _score = 0;
  int _errors = 0;
  bool _gameComplete = false;
  int _wordCount = 5;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initGame();
  }

  Future<void> _loadConfig() async {
    final count = await ConfigManager.getInt('match_game_word_count') ?? 5;
    if (mounted) setState(() => _wordCount = count);
  }

  void _initGame() {
    final allChars = allHanzi.toList()..shuffle();
    _gameCharacters = allChars.take(_wordCount).toList();
    _leftItems = _gameCharacters
        .map((h) => _MatchItem(id: h.character, display: h.emoji, isEmoji: true))
        .toList()
      ..shuffle();
    _rightItems = _gameCharacters
        .map((h) => _MatchItem(id: h.character, display: h.character, isEmoji: false))
        .toList()
      ..shuffle();
    _selectedLeft = null;
    _selectedRight = null;
    _matchedPairs = {};
    _score = 0;
    _errors = 0;
    _gameComplete = false;
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
    if (_selectedLeft != null && _selectedRight != null) {
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
        _errors++;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _selectedLeft = null;
              _selectedRight = null;
            });
          }
        });
      }
    }
  }

  Future<void> _saveProgress() async {
    final provider = context.read<LearningProvider>();
    for (final hanzi in _gameCharacters) {
      await provider.addStars(hanzi.character, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('图字配对 🔗',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('⭐ $_score',
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('进度: ${_matchedPairs.length}/${_gameCharacters.length}',
                  style: const TextStyle(fontSize: 16)),
              Text('错误: $_errors',
                  style: const TextStyle(fontSize: 16, color: Colors.red)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _leftItems.map((item) {
                      final isMatched = _matchedPairs.contains(item.id);
                      final isSelected = _selectedLeft == item.id;
                      return _buildCard(
                        item.display,
                        isMatched: isMatched,
                        isSelected: isSelected,
                        fontSize: 40,
                        onTap: () => _onSelectLeft(item.id),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _rightItems.map((item) {
                      final isMatched = _matchedPairs.contains(item.id);
                      final isSelected = _selectedRight == item.id;
                      return _buildCard(
                        item.display,
                        isMatched: isMatched,
                        isSelected: isSelected,
                        fontSize: 36,
                        onTap: () => _onSelectRight(item.id),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    String text, {
    required bool isMatched,
    required bool isSelected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    if (isMatched) {
      bgColor = AppTheme.primaryGreen.withOpacity(0.15);
      borderColor = AppTheme.primaryGreen;
    } else if (isSelected) {
      bgColor = AppTheme.primaryOrange.withOpacity(0.15);
      borderColor = AppTheme.primaryOrange;
    }

    return GestureDetector(
      onTap: isMatched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 80))
              .animate()
              .scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 16),
          const Text(
            '配对完成！',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            '得分: $_score | 错误: $_errors',
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ).animate(delay: 500.ms).fadeIn(),
          const SizedBox(height: 30),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() => _initGame()),
                icon: const Text('🔄'),
                label: const Text('再来一次'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('返回'),
              ),
            ],
          ).animate(delay: 700.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _MatchItem {
  final String id;
  final String display;
  final bool isEmoji;

  _MatchItem({required this.id, required this.display, required this.isEmoji});
}
