import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/game_config_provider.dart';
import '../utils/app_theme.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(gameConfigProvider);
    final spellGameEnabled = configAsync.valueOrNull?.spellGameEnabled ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '趣味游戏 🎮',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontSize: 26,
                  ),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(
              '边玩边学，快乐识字！',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            _GameCard(
              emoji: '🔗',
              title: '图字配对',
              description: '把汉字和图片配对，考验你的记忆力！',
              color: const Color(0xFFFF6B6B),
              gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              difficulty: '简单',
              stars: 3,
              onTap: () => context.push('/match-game'),
            ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.2),
            const SizedBox(height: 16),
            _GameCard(
              emoji: '👂',
              title: '听音选字',
              description: '听拼音找出正确的汉字，锻炼听力！',
              color: const Color(0xFF4ECDC4),
              gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              difficulty: '中等',
              stars: 2,
              onTap: () => context.push('/listen-game'),
            ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.2),
            const SizedBox(height: 16),
            _GameCard(
              emoji: '🧩',
              title: '拼字游戏',
              description: '将笔画拼成完整的汉字！',
              color: const Color(0xFF667EEA),
              gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
              difficulty: '困难',
              stars: 1,
              isComingSoon: !spellGameEnabled,
              onTap: spellGameEnabled ? () {} : () {},
            ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.2),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradient;
  final String difficulty;
  final int stars;
  final bool isComingSoon;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
    required this.difficulty,
    required this.stars,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '即将推出',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          difficulty,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(
                        stars,
                        (i) => const Text('⭐',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isComingSoon)
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
