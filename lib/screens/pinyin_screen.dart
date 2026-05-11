import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';

/// 拼音 Hub：大卡入口 + 提示 + 底部轻装饰（填充 Tab 以上留白）
class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

  static const List<Shadow> _cardTitleShadows = [
    Shadow(color: Color(0x48000000), offset: Offset(0, 1), blurRadius: 4),
  ];

  static const List<Shadow> _cardSubtitleShadows = [
    Shadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount =
        ref.watch(learningNotifierProvider).pinyinMistakes.length;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8F0),
            Color(0xFFFFFBF5),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildLearnCard(context),
                    const SizedBox(height: 14),
                    _buildExerciseCard(context),
                    const SizedBox(height: 14),
                    _buildMistakeCard(context, mistakeCount),
                    const SizedBox(height: 22),
                    _buildTip(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildBottomFiller(context),
            ),
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
          '拼音学习',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(height: 4),
        Text(
          '学好拼音，读好汉字！',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF7D6B5C),
                height: 1.35,
              ),
        ).animate(delay: 200.ms).fadeIn(),
      ],
    );
  }

  Widget _buildLearnCard(BuildContext context) {
    return _EntryCard(
      iconKey: 'img_card_pinyin_learn',
      iconDesc: '拼音学习',
      title: '拼音学习',
      subtitle: '认识声母·韵母·四声',
      titleShadows: _cardTitleShadows,
      subtitleShadows: _cardSubtitleShadows,
      gradient: const LinearGradient(
        colors: [Color(0xFF45C4BB), Color(0xFF3D8F78)],
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
      iconKey: 'img_card_pinyin_quiz',
      iconDesc: '拼音测验',
      title: '拼音测验',
      subtitle: '声母识别·10 题挑战',
      titleShadows: _cardTitleShadows,
      subtitleShadows: _cardSubtitleShadows,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF672F), Color(0xFFFF9A52)],
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
      iconKey: hasmistakes
          ? 'img_card_pinyin_mistakes_active'
          : 'img_card_pinyin_mistakes_empty',
      iconDesc: hasmistakes ? '有错题' : '无错题',
      title: '错题重练',
      subtitle: hasmistakes
          ? '共 $mistakeCount 个声母需要复习'
          : '太棒了！暂无错题',
      titleShadows: _cardTitleShadows,
      subtitleShadows: _cardSubtitleShadows,
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
          ? () =>
              context.push('/pinyin-exercise', extra: {'mistakeMode': true})
          : null,
      delay: 200,
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryYellow.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CsImage(
              configKey: 'img_icon_tip',
              description: '提示',
              width: 24,
              height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '先学习声母和韵母，再做测验！答错的声母会自动加入错题集。',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildBottomFiller(BuildContext context) {
    const muted = Color(0xFF8D7B6C);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppTheme.primaryYellow.withValues(alpha: 0.32 + i * 0.02),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '每天练习一点点，拼音更简单！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted.withValues(alpha: 0.55),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 450.ms);
  }
}

class _EntryCard extends StatelessWidget {
  final String iconKey;
  final String iconDesc;
  final String title;
  final String subtitle;
  final List<Shadow> titleShadows;
  final List<Shadow> subtitleShadows;
  final Gradient gradient;
  final Color shadowColor;
  final String? badge;
  final VoidCallback? onTap;
  final int delay;

  const _EntryCard({
    required this.iconKey,
    required this.iconDesc,
    required this.title,
    required this.subtitle,
    required this.titleShadows,
    required this.subtitleShadows,
    required this.gradient,
    required this.shadowColor,
    required this.badge,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 94),
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 22),
                  CsImage(
                      configKey: iconKey,
                      description: iconDesc,
                      width: 44,
                      height: 44),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: titleShadows,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            height: 1.25,
                            shadows: subtitleShadows,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 18,
                        shadows: subtitleShadows,
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 10,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
