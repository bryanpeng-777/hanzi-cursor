import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/hanzi_model.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/stroke_animation_widget.dart';
import '../widgets/star_reward_widget.dart';

class HanziDetailScreen extends StatefulWidget {
  final HanziCharacter hanzi;

  const HanziDetailScreen({super.key, required this.hanzi});

  @override
  State<HanziDetailScreen> createState() => _HanziDetailScreenState();
}

class _HanziDetailScreenState extends State<HanziDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  bool _showReward = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

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
        actions: [
          Consumer<LearningProvider>(
            builder: (context, provider, child) {
              final isFav = provider.isFavorite(widget.hanzi.character);
              return IconButton(
                icon: Text(isFav ? '⭐' : '☆',
                    style: const TextStyle(fontSize: 24)),
                onPressed: () => provider.toggleFavorite(widget.hanzi.character),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMainCard(),
                const SizedBox(height: 20),
                _buildStrokeSection(),
                const SizedBox(height: 20),
                _buildExampleWords(),
                const SizedBox(height: 20),
                _buildLearnButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_showReward)
            StarRewardWidget(
              onComplete: () => setState(() => _showReward = false),
            ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getLevelColor(widget.hanzi.level),
            AppColors.getLevelColor(widget.hanzi.level).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.getLevelColor(widget.hanzi.level).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.hanzi.emoji,
            style: const TextStyle(fontSize: 60),
          ).animate().scale(
                begin: const Offset(0, 0),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceController.value * 4 - 2),
                child: child,
              );
            },
            child: Text(
              widget.hanzi.character,
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.hanzi.pinyin,
              style: const TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.hanzi.meaning,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✏️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '笔画 ${widget.hanzi.strokeCount}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: StrokeAnimationWidget(character: widget.hanzi.character),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildExampleWords() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '例词',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.hanzi.exampleWords.asMap().entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.getLevelColor(widget.hanzi.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.getLevelColor(widget.hanzi.level).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.getLevelColor(widget.hanzi.level),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate(delay: (entry.key * 100 + 300).ms).fadeIn().scale();
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildLearnButton() {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        final isLearned = provider.isLearned(widget.hanzi.character);
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLearned
                ? null
                : () async {
                    await provider.markAsLearned(widget.hanzi.character, starsEarned: 3);
                    setState(() => _showReward = true);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLearned ? AppTheme.primaryGreen : AppTheme.primaryOrange,
              disabledBackgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              isLearned ? '✅ 已学会！' : '🌟 我学会了！',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3);
  }
}
