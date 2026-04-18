import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';

class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount = ref.watch(learningNotifierProvider).pinyinMistakes.length;
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
                _buildExerciseCard(context),
                const SizedBox(height: 16),
                _buildMistakeCard(context, mistakeCount),
                const SizedBox(height: 24),
                _buildTip(),
              ],
            ),
          ),
        );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '拼音学习 🔤',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 28,
              ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(height: 4),
        Text(
          '学好拼音，读好汉字！',
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
      title: '拼音学习',
      subtitle: '认识声母·韵母·四声',
      gradient: const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFF4ECDC4),
      badge: null,
      onTap: () => context.push('/pinyin-learn'),
      delay: 0,
    );
  }

  Widget _buildExerciseCard(BuildContext context) {
    return _EntryCard(
      emoji: '✏️',
      title: '拼音测验',
      subtitle: '声母识别·10 题挑战',
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: AppTheme.primaryOrange,
      badge: null,
      onTap: () => context.push('/pinyin-exercise'),
      delay: 100,
    );
  }

  Widget _buildMistakeCard(BuildContext context, int mistakeCount) {
    final hasmistakes = mistakeCount > 0;
    return _EntryCard(
      emoji: hasmistakes ? '🔴' : '✅',
      title: '错题重练',
      subtitle: hasmistakes ? '共 $mistakeCount 个声母需要复习' : '太棒了！暂无错题',
      gradient: hasmistakes
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
      shadowColor: hasmistakes ? Colors.redAccent : Colors.grey,
      badge: hasmistakes ? '$mistakeCount' : null,
      onTap: hasmistakes
          ? () => context.push('/pinyin-exercise', extra: {'mistakeMode': true})
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
              '先学习声母和韵母，再做测验！答错的声母会自动加入错题集。',
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
            // 错题数量角标
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
