import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import '../data/hanzi_data.dart';
import 'learn_screen.dart';
import 'game_screen.dart';
import 'vocabulary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomePage(),
    const LearnScreen(),
    const GameScreen(),
    const VocabularyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: '🏠', label: '首页', index: 0, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: '📖', label: '识字', index: 1, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: '🎮', label: '游戏', index: 2, current: _currentIndex, onTap: _onTap),
                _NavItem(icon: '⭐', label: '生字本', index: 3, current: _currentIndex, onTap: _onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) => setState(() => _currentIndex = index);
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: TextStyle(fontSize: isSelected ? 28 : 24)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryOrange : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, provider),
                const SizedBox(height: 24),
                _buildProgressCard(context, provider),
                const SizedBox(height: 24),
                _buildFeatureCards(context),
                const SizedBox(height: 24),
                _buildDailyChallenge(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, LearningProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '宝宝识字 📚',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontSize: 28,
                    ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
              const SizedBox(height: 4),
              Text(
                '今天学了几个字？',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ).animate(delay: 200.ms).fadeIn(),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryYellow, AppTheme.primaryOrange],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryOrange.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 24)),
              Text(
                '${provider.totalStars}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn().scale(),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, LearningProvider provider) {
    final progress = provider.overallProgress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学习进度',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${provider.learnedCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${provider.totalCount} 字',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% 完成',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildFeatureCards(BuildContext context) {
    final features = [
      {
        'emoji': '📖',
        'title': '识字卡片',
        'subtitle': '学习新汉字',
        'color': const Color(0xFF4CAF50),
        'screen': 1,
      },
      {
        'emoji': '🎮',
        'title': '趣味游戏',
        'subtitle': '边玩边学',
        'color': const Color(0xFF2196F3),
        'screen': 2,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '开始学习',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: features.asMap().entries.map((entry) {
            final feature = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: entry.key == 0 ? 0 : 8,
                  right: entry.key == features.length - 1 ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._onTap(feature['screen'] as int);
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: feature['color'] as Color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (feature['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(feature['emoji'] as String,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          feature['subtitle'] as String,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (200 + entry.key * 100).ms).fadeIn().scale(
                      begin: const Offset(0.9, 0.9),
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    final todayChar = allHanzi[DateTime.now().day % allHanzi.length];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '每日一字',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '今天 ${DateTime.now().month}月${DateTime.now().day}日',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      todayChar.character,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayChar.pinyin,
                      style: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayChar.meaning,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          todayChar.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          todayChar.strokeCount,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: todayChar.exampleWords.take(2).map((word) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            word,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2);
  }
}
