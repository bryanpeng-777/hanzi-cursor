import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../providers/learning_provider.dart';

/// 拼音 Hub：绘本风衬底 +「一大两小」白卡入口 + 提示 + 底部轻装饰
class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

  /// Figma / 设计稿主标题蓝（约 #28A2E9）
  static const Color _headerBlue = Color(0xFF28A2E9);

  static const Color _creamBg = Color(0xFFFFFBF5);
  static const Color _titleInk = Color(0xFF284059);
  static const Color _subtitleMuted = Color(0xFF8D8C89);
  static const Color _cardShadowBlue = Color(0xFF2F9DE0);

  static const Color _accentLearn = Color(0xFF3EC9A7);
  static const Color _accentQuiz = Color(0xFFFF7A5C);
  static const Color _accentMistake = Color(0xFFFF6A88);

  static const List<Widget> _footerDecorDots = <Widget>[
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Icon(Icons.circle, size: 5.5, color: Color(0x73FFD54F)),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Icon(Icons.circle, size: 5.5, color: Color(0x82FFD54F)),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Icon(Icons.circle, size: 5.5, color: Color(0x91FFD54F)),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Icon(Icons.circle, size: 5.5, color: Color(0xA0FFD54F)),
    ),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Icon(Icons.circle, size: 5.5, color: Color(0xB0FFD54F)),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakeCount =
        ref.watch(learningNotifierProvider).pinyinMistakes.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: _creamBg),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: _PinyinHubBackdropPainter()),
        ),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        left: -28,
                        top: 96,
                        child: IgnorePointer(
                          child: _WatermarkLetter('a', Color(0x663EC9A7)),
                        ),
                      ),
                      const Positioned(
                        right: -16,
                        top: 200,
                        child: IgnorePointer(
                          child: _WatermarkLetter('e', Color(0x66FF7A5C)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 20),
                          _buildHeroLearnCard(context),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildQuizHalfCard(context),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMistakeHalfCard(
                                  context,
                                  mistakeCount,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildTip(),
                          const SizedBox(height: 14),
                        ],
                      ),
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
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _headerBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '拼音学习',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _headerBlue,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.96, 0.96)),
        const SizedBox(height: 10),
        Text(
          '学好拼音，读好汉字！',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _subtitleMuted,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
        ).animate(delay: 120.ms).fadeIn(),
      ],
    );
  }

  Widget _buildHeroLearnCard(BuildContext context) {
    return _PictureBookCard(
      accentColor: _accentLearn,
      iconKey: 'img_card_pinyin_learn',
      iconDesc: '拼音学习',
      title: '拼音学习',
      subtitle: '认识声母·韵母·四声',
      badgeLabel: null,
      enabled: true,
      delay: 0,
      onTap: () => context.push('/pinyin-learn'),
    );
  }

  Widget _buildQuizHalfCard(BuildContext context) {
    return _PictureBookCard(
      accentColor: _accentQuiz,
      iconKey: 'img_card_pinyin_quiz',
      iconDesc: '拼音测验',
      title: '拼音测验',
      subtitle: '声母识别·10 题挑战',
      badgeLabel: null,
      enabled: true,
      compact: true,
      delay: 80,
      onTap: () => context.push('/pinyin-exercise'),
    );
  }

  Widget _buildMistakeHalfCard(BuildContext context, int mistakeCount) {
    final hasMistakes = mistakeCount > 0;
    return _PictureBookCard(
      accentColor: hasMistakes ? _accentMistake : Colors.grey.shade500,
      iconKey: hasMistakes
          ? 'img_card_pinyin_mistakes_active'
          : 'img_card_pinyin_mistakes_empty',
      iconDesc: hasMistakes ? '有错题' : '无错题',
      title: '错题重练',
      subtitle: hasMistakes
          ? '共 $mistakeCount 个声母需要复习'
          : '太棒了！暂无错题',
      badgeLabel: hasMistakes ? '$mistakeCount' : null,
      enabled: hasMistakes,
      compact: true,
      delay: 160,
      onTap: hasMistakes
          ? () =>
              context.push('/pinyin-exercise', extra: {'mistakeMode': true})
          : null,
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFCF0D8),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CsImage(
            configKey: 'img_icon_tip',
            description: '提示',
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '小提示：先学习拼音知识，再进行测验巩固；发现错题及时重练，加深记忆效果更好哦！',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 320.ms).fadeIn();
  }

  Widget _buildBottomFiller(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _footerDecorDots,
            ),
            SizedBox(height: 10),
            Text(
              '每天进步一点点，拼音学习更轻松！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF92918F),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 420.ms).fadeIn(duration: 400.ms);
  }
}

class _WatermarkLetter extends StatelessWidget {
  final String letter;
  final Color color;

  const _WatermarkLetter(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: TextStyle(
        fontSize: 120,
        fontWeight: FontWeight.w200,
        color: color,
        height: 1,
      ),
    );
  }
}

/// 轻水彩晕染（不抢内容）
class _PinyinHubBackdropPainter extends CustomPainter {
  const _PinyinHubBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..blendMode = BlendMode.softLight;

    void blob(Color c, Offset center, double radius) {
      final g = RadialGradient(
        colors: [
          c.withValues(alpha: 0.22),
          c.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      );
      paint.shader = g.createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(const Color(0xFF3EC9A7), rect.topLeft + Offset(size.width * 0.08, size.height * 0.18), size.width * 0.42);
    blob(const Color(0xFFFFB4A2), rect.topRight + Offset(-size.width * 0.02, size.height * 0.32), size.width * 0.38);
    blob(const Color(0xFF7EC8FF), rect.bottomCenter + Offset(0, -size.height * 0.12), size.width * 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Figma 风：红底圆角泡 + 白字
class _PictureBookMistakeBadge extends StatelessWidget {
  final String label;

  const _PictureBookMistakeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFE4940),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFD5046), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE4940).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFFF3F1),
          fontWeight: FontWeight.w800,
          fontSize: 18,
          height: 1,
        ),
      ),
    );
  }
}

class _PictureBookCard extends StatelessWidget {
  final Color accentColor;
  final String iconKey;
  final String iconDesc;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final bool enabled;
  final bool compact;
  final int delay;
  final VoidCallback? onTap;

  const _PictureBookCard({
    required this.accentColor,
    required this.iconKey,
    required this.iconDesc,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.enabled,
    this.compact = false,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 17.0 : 20.0;
    final subtitleSize = compact ? 12.5 : 13.0;
    final iconSize = compact ? 44.0 : 52.0;
    final verticalPad = compact ? 14.0 : 18.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.58,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: compact ? 128 : 116),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: PinyinScreen._cardShadowBlue.withValues(alpha: 0.12),
                    blurRadius: 22,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: iconSize + verticalPad * 2,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, verticalPad, 12, verticalPad),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CsImage(
                            configKey: iconKey,
                            description: iconDesc,
                            width: iconSize,
                            height: iconSize,
                          ),
                          const SizedBox(width: 12),
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
                                    color: PinyinScreen._titleInk,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: PinyinScreen._subtitleMuted,
                                    fontSize: subtitleSize,
                                    height: 1.28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: PinyinScreen._subtitleMuted
                                  .withValues(alpha: 0.75),
                              size: compact ? 22 : 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badgeLabel != null)
              Positioned(
                top: -4,
                right: 6,
                child: _PictureBookMistakeBadge(label: badgeLabel!),
              ),
          ],
        ),
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.96, 0.96));
  }
}
