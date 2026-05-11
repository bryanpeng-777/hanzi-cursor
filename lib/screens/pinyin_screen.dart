import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../providers/learning_provider.dart';

/// 拼音 Hub：大卡入口 + 提示 + 底部轻装饰（对齐设计稿色板与布局）
class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

  /// 与设计稿接近的标题蓝（略偏 #3498db）
  static const Color _headerBlue = Color(0xFF3498DB);

  /// 极轻字影，避免压过扁平渐变色带
  static const List<Shadow> _cardTitleShadows = [
    Shadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<Shadow> _cardSubtitleShadows = [
    Shadow(color: Color(0x12000000), offset: Offset(0, 1), blurRadius: 1),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount =
        ref.watch(learningNotifierProvider).pinyinMistakes.length;
    return Container(
      decoration: const BoxDecoration(
        // 设计稿：近纯色暖米底 #FFFBF5
        color: Color(0xFFFFFBF5),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 22),
                    _buildLearnCard(context),
                    const SizedBox(height: 16),
                    _buildExerciseCard(context),
                    const SizedBox(height: 16),
                    _buildMistakeCard(context, mistakeCount),
                    const SizedBox(height: 20),
                    _buildTip(),
                    const SizedBox(height: 14),
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
                color: _headerBlue,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        const SizedBox(height: 6),
        Text(
          '学好拼音，读好汉字！',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF9E9E9E),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w400,
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
        colors: [Color(0xFF48B1BF), Color(0xFF06BEB6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadowColor: const Color(0xFF48B1BF),
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
        colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadowColor: const Color(0xFFFF9966),
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
              colors: [Color(0xFFEE0979), Color(0xFFFF6A00)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade300],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
      shadowColor: hasmistakes ? const Color(0xFFEE0979) : Colors.grey,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE082).withValues(alpha: 0.95),
          width: 1,
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
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }

  Widget _buildBottomFiller(BuildContext context) {
    const muted = Color(0xFFBDBDBD);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                    color: Color(0xFFFFD54F).withValues(alpha: 0.55 + i * 0.05),
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
                fontWeight: FontWeight.w500,
                color: muted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 450.ms);
  }
}

/// 设计稿：白底圆标 + 红字（多位数时用横胶囊）
class _MistakeBadge extends StatelessWidget {
  final String label;

  const _MistakeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final oneDigit = label.length == 1;
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.14),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
    return Container(
      constraints: BoxConstraints(
        minWidth: oneDigit ? 28 : 32,
        minHeight: 28,
      ),
      padding: EdgeInsets.symmetric(horizontal: oneDigit ? 0 : 8),
      alignment: Alignment.center,
      decoration: oneDigit
          ? BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: shadow,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: shadow,
            ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
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
              constraints: const BoxConstraints(minHeight: 108),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 20),
                  CsImage(
                      configKey: iconKey,
                      description: iconDesc,
                      width: 48,
                      height: 48),
                  const SizedBox(width: 16),
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
                            fontWeight: FontWeight.w800,
                            shadows: titleShadows,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.28,
                            fontWeight: FontWeight.w400,
                            shadows: subtitleShadows,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.88),
                        size: 16,
                        shadows: subtitleShadows,
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 12,
                child: _MistakeBadge(label: badge!),
              ),
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.94, 0.94));
  }
}
