import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/pinyin_data.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_detail_screen.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider),
                const SizedBox(height: 24),
                _buildPinyinSection(context, provider),
                const SizedBox(height: 20),
                _buildHanziSection(context, provider),
                const SizedBox(height: 20),
                _buildFavoritesSection(context, provider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LearningProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '我的学习 🎓',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryOrange,
                fontSize: 26,
              ),
        ).animate().fadeIn(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppTheme.primaryYellow.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '${provider.totalStars}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryYellow.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  // ─── 拼音学习进度 ────────────────────────────────────────────────────────────

  Widget _buildPinyinSection(BuildContext context, LearningProvider provider) {
    final totalInitials = allInitials.length; // 23
    final mistakeCount = provider.pinyinMistakes.length;
    final masteredCount = totalInitials - mistakeCount;
    final progress = masteredCount / totalInitials;

    return _SectionCard(
      title: '🔤 拼音学习进度',
      accentColor: const Color(0xFF4ECDC4),
      delay: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(
            context,
            label: '声母掌握',
            progress: progress,
            current: masteredCount,
            total: totalInitials,
            color: const Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                  label: '已掌握',
                  value: '$masteredCount',
                  color: const Color(0xFF4ECDC4)),
              const SizedBox(width: 10),
              _StatChip(
                  label: '错题',
                  value: '$mistakeCount',
                  color: mistakeCount > 0 ? Colors.redAccent : Colors.grey),
            ],
          ),
          const SizedBox(height: 14),
          _buildInitialsGrid(provider),
          const SizedBox(height: 14),
          _buildJumpButton(
            context,
            label: '去拼音学习',
            color: const Color(0xFF4ECDC4),
            tabIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsGrid(LearningProvider provider) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allInitials.map((item) {
        final isMistake = provider.pinyinMistakes.contains(item.symbol);
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isMistake
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFF4ECDC4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMistake
                  ? Colors.redAccent.withOpacity(0.6)
                  : const Color(0xFF4ECDC4).withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              item.symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isMistake ? Colors.redAccent : const Color(0xFF2A9D8F),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 识字学习进度 ────────────────────────────────────────────────────────────

  Widget _buildHanziSection(BuildContext context, LearningProvider provider) {
    final passedCount =
        List.generate(10, (i) => i + 1).where(provider.isHanziLevelPassed).length;

    return _SectionCard(
      title: '📖 识字学习进度',
      accentColor: AppTheme.primaryOrange,
      delay: 100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(
            context,
            label: '已学汉字',
            progress: provider.overallProgress,
            current: provider.learnedCount,
            total: provider.totalCount,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                  label: '已学会',
                  value: '${provider.learnedCount}',
                  color: AppTheme.primaryOrange),
              const SizedBox(width: 10),
              _StatChip(
                  label: '已通关',
                  value: '$passedCount 关',
                  color: AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 14),
          _buildLevelList(provider),
          const SizedBox(height: 14),
          _buildJumpButton(
            context,
            label: '去识字学习',
            color: AppTheme.primaryOrange,
            tabIndex: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLevelList(LearningProvider provider) {
    const levelNames = [
      '数字&基础', '大小&五行', '天地&日常', '动物', '颜色',
      '食物', '身体', '家庭', '方位', '自然',
    ];
    return Column(
      children: List.generate(10, (i) {
        final level = i + 1;
        final unlocked = provider.isHanziLevelUnlocked(level);
        final passed = provider.isHanziLevelPassed(level);
        final bestScore = provider.getHanziQuizBestScore(level);
        final name = levelNames[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: passed
                ? AppTheme.primaryGreen.withOpacity(0.07)
                : unlocked
                    ? Colors.white
                    : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: passed
                  ? AppTheme.primaryGreen.withOpacity(0.3)
                  : unlocked
                      ? Colors.grey.shade200
                      : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Text(
                passed ? '✅' : unlocked ? '🔓' : '🔒',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level  $name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: unlocked ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    if (passed)
                      Text(
                        '最高 $bestScore%',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    if (!passed && unlocked)
                      Text(
                        '已解锁，去挑战测验',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    if (!unlocked)
                      Text(
                        '通过上一关解锁',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── 我的收藏 ────────────────────────────────────────────────────────────────

  Widget _buildFavoritesSection(
      BuildContext context, LearningProvider provider) {
    final favorites = provider.favoriteCharacters;

    return _SectionCard(
      title: '❤️ 我的收藏',
      accentColor: AppTheme.primaryPink,
      delay: 200,
      child: favorites.isEmpty
          ? _buildEmptyFavorites()
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final hanzi = favorites[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HanziDetailScreen(hanzi: hanzi)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primaryPink.withOpacity(0.3),
                          width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(hanzi.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(
                          hanzi.character,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          hanzi.pinyin,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (index * 40).ms).fadeIn().scale(
                        begin: const Offset(0.85, 0.85),
                      ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            const Text('❤️', style: TextStyle(fontSize: 40))
                .animate()
                .scale(curve: Curves.elasticOut),
            const SizedBox(height: 10),
            const Text('还没有收藏汉字',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '在汉字详情页点击 ❤️ 收藏',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 共用组件 ─────────────────────────────────────────────────────────────────

  Widget _buildProgressBar(
    BuildContext context, {
    required String label,
    required double progress,
    required int current,
    required int total,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            Text(
              '$current / $total',
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildJumpButton(
    BuildContext context, {
    required String label,
    required Color color,
    required int tabIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
        ],
      ),
    );
  }
}

// ─── _SectionCard ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget child;
  final int delay;

  const _SectionCard({
    required this.title,
    required this.accentColor,
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ).animate(delay: delay.ms).fadeIn().slideY(begin: 0.05);
  }
}

// ─── _StatChip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 13, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}
