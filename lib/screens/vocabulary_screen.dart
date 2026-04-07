import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';
import 'hanzi_detail_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          _buildStatsRow(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLearnedList(context),
                _buildFavoriteList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            '生字本 ⭐',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.primaryOrange,
                  fontSize: 26,
                ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '已学会',
                  value: '${provider.learnedCount}',
                  emoji: '✅',
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '总星星',
                  value: '${provider.totalStars}',
                  emoji: '⭐',
                  color: AppTheme.primaryYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '收藏',
                  value: '${provider.favoriteCharacters.length}',
                  emoji: '❤️',
                  color: AppTheme.primaryPink,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        tabs: const [
          Tab(text: '已学汉字'),
          Tab(text: '我的收藏'),
        ],
      ),
    );
  }

  Widget _buildLearnedList(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        final learned = provider.learnedCharacters;
        if (learned.isEmpty) {
          return _buildEmptyState('还没有学会任何汉字', '去识字卡片学习吧！', '📖');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: learned.length,
          itemBuilder: (context, index) {
            final hanzi = learned[index];
            final stars = provider.getStars(hanzi.character);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => HanziDetailScreen(hanzi: hanzi)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(hanzi.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      hanzi.character,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hanzi.pinyin,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐' * stars.clamp(0, 5),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ).animate(delay: (index * 50).ms).fadeIn().scale(
                    begin: const Offset(0.8, 0.8),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteList(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, provider, child) {
        final favorites = provider.favoriteCharacters;
        if (favorites.isEmpty) {
          return _buildEmptyState('还没有收藏汉字', '在识字卡片页点击星星收藏！', '⭐');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(hanzi.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                hanzi.character,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                hanzi.pinyin,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.primaryBlue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            hanzi.meaning,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Text('❤️', style: TextStyle(fontSize: 20)),
                      onPressed: () => provider.toggleFavorite(hanzi.character),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.2),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, String emoji) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 60))
              .animate()
              .scale(curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
