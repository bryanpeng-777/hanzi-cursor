import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_learn_grid_screen.dart';
import 'hanzi_quiz_level_screen.dart';
import 'hanzi_quiz_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, _) {
        final mistakeCount = provider.hanziQuizMistakes.length;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 28),
                _buildLearnCard(context),
                const SizedBox(height: 16),
                _buildQuizCard(context),
                const SizedBox(height: 16),
                _buildMistakeCard(context, mistakeCount),
                const SizedBox(height: 24),
                _buildTip(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '识字 📖',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryOrange,
                fontSize: 28,
              ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(height: 4),
        Text(
          '学汉字，认汉字，练汉字！',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[600]),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildLearnCard(BuildContext context) {
    return _EntryCard(
      emoji: '📚',
      title: '识字学习',
      subtitle: '图文并貌·分关卡认字',
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: AppTheme.primaryGreen,
      badge: null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HanziLearnGridScreen()),
      ),
      delay: 0,
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return _EntryCard(
      emoji: '✏️',
      title: '识字测验',
      subtitle: '纯文字考验·逐关解锁',
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: AppTheme.primaryOrange,
      badge: null,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HanziQuizLevelScreen()),
      ),
      delay: 100,
    );
  }

  Widget _buildMistakeCard(BuildContext context, int mistakeCount) {
    final hasMistakes = mistakeCount > 0;
    return _EntryCard(
      emoji: hasMistakes ? '🔴' : '✅',
      title: '错题重练',
      subtitle: hasMistakes ? '共 $mistakeCount 个汉字需要复习' : '太棒了！暂无错题',
      gradient: hasMistakes
          ? const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFEF9A9A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      shadowColor: hasMistakes ? Colors.redAccent : Colors.grey,
      badge: hasMistakes ? '$mistakeCount' : null,
      onTap: hasMistakes
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HanziQuizScreen(mistakeMode: true),
                ),
              )
          : null,
      delay: 200,
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryYellow.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '先用学习模式认识汉字，再做测验！通过第一关可以解锁下一关，答错的字会进入错题集。',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}

class _EntryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color shadowColor;
  final String? badge;
  final VoidCallback? onTap;
  final int delay;

  const _EntryCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.shadowColor,
    required this.badge,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  Text(emoji, style: const TextStyle(fontSize: 44)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white70, size: 18),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -8,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                      )
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.94, 0.94));
  }
}
