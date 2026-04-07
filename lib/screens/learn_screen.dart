import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/hanzi_data.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _selectedLevel = 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildLevelSelector(),
          Expanded(child: _buildHanziGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            '识字卡片 📖',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontSize: 26,
                ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [1, 2, 3].map((level) {
          final isSelected = _selectedLevel == level;
          final color = AppColors.getLevelColor(level);
          final labels = ['第一关', '第二关', '第三关'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    labels[level - 1],
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
                    style: TextStyle(
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
              Positioned(
                top: 6,
                left: 6,
                child: const Text('⭐', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().scale(
            begin: const Offset(0.8, 0.8),
          ),
    );
  }
}
