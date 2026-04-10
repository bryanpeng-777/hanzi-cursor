import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/hanzi_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_detail_screen.dart';

class HanziLearnGridScreen extends StatefulWidget {
  const HanziLearnGridScreen({super.key});

  @override
  State<HanziLearnGridScreen> createState() => _HanziLearnGridScreenState();
}

class _HanziLearnGridScreenState extends State<HanziLearnGridScreen> {
  int _selectedLevel = 1;

  int get _maxLevel =>
      allHanzi.map((h) => h.level).reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '识字学习 📖',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryOrange,
                fontSize: 22,
              ),
        ),
      ),
      body: Column(
        children: [
          _buildLevelSelector(),
          Expanded(child: _buildHanziGrid()),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _maxLevel,
        itemBuilder: (context, index) {
          final level = index + 1;
          final isSelected = _selectedLevel == level;
          final color = AppColors.getLevelColor(level);
          return GestureDetector(
            onTap: () => setState(() => _selectedLevel = level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                '第$level关',
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHanziGrid() {
    final characters = getHanziByLevel(_selectedLevel);
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final hanzi = characters[index];
            final isLearned = provider.isLearned(hanzi.character);
            final isFavorite = provider.isFavorite(hanzi.character);
            return _HanziCard(
              hanzi: hanzi,
              isLearned: isLearned,
              isFavorite: isFavorite,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _HanziCard extends StatelessWidget {
  final HanziCharacter hanzi;
  final bool isLearned;
  final bool isFavorite;
  final int index;

  const _HanziCard({
    required this.hanzi,
    required this.isLearned,
    required this.isFavorite,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HanziDetailScreen(hanzi: hanzi),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isLearned
              ? Border.all(color: AppTheme.primaryGreen, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(hanzi.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    hanzi.character,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hanzi.pinyin,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryBlue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isLearned)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            if (isFavorite)
              const Positioned(
                top: 6,
                left: 6,
                child: Text('⭐', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().scale(
            begin: const Offset(0.8, 0.8),
          ),
    );
  }
}
