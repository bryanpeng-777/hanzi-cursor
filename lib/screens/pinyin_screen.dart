import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cs_ui/cs_ui.dart';
import '../constants/pinyin_figma_assets.dart';
import '../design/hanzi_design_spec.dart';
import '../providers/learning_provider.dart';

/// 拼音 Hub：绘本风衬底 +「一大两小」白卡入口 + 提示 + 底部轻装饰
class PinyinScreen extends ConsumerWidget {
  const PinyinScreen({super.key});

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
      key: const Key('hanzi-pinyin-hub-landscape'),
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            PinyinFigmaAssetPaths.canvasBackdrop,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  HanziDesignSpec.pagePaddingH.w,
                  HanziDesignSpec.pagePaddingV.h,
                  HanziDesignSpec.pagePaddingH.w,
                  0,
                ),
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
                          SizedBox(height: HanziDesignSpec.sectionGap.h + 8),
                          _buildHeroLearnCard(context),
                          SizedBox(height: HanziDesignSpec.cardGap.h + 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildQuizHalfCard(context),
                              ),
                              SizedBox(width: HanziDesignSpec.cardGap.w + 2),
                              Expanded(
                                child: _buildMistakeHalfCard(
                                  context,
                                  mistakeCount,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: HanziDesignSpec.sectionGap.h + 8),
                          _buildTip(),
                          SizedBox(height: 14.h),
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
          key: const Key('hanzi-pinyin-hub-header-chip'),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: HanziDesignSpec.headerBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '拼音学习',
            style: HanziDesignSpec.hubTitleStyle.copyWith(
              color: HanziDesignSpec.headerBlue,
              fontSize: 26.sp,
              height: 1.15,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.96, 0.96)),
        SizedBox(height: 10.h),
        Text(
          '学好拼音，读好汉字！',
          textAlign: TextAlign.center,
          style: HanziDesignSpec.hubSubtitleStyle.copyWith(fontSize: 16.sp),
        ).animate(delay: 120.ms).fadeIn(),
      ],
    );
  }

  Widget _buildHeroLearnCard(BuildContext context) {
    return _PictureBookCard(
      accentColor: HanziDesignSpec.accentLearn,
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
      accentColor: HanziDesignSpec.accentQuiz,
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
      accentColor:
          hasMistakes ? HanziDesignSpec.accentMistake : Colors.grey.shade500,
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
      padding: EdgeInsets.all(HanziDesignSpec.cardPadding.w - 2),
      decoration: BoxDecoration(
        color: HanziDesignSpec.surfacePeach,
        borderRadius: BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        border: Border.all(
          color: const Color(0xFFFCF0D8),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CsImage(
            configKey: 'img_icon_tip',
            description: '提示',
            width: 28.w,
            height: 28.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '小提示：先学习拼音知识，再进行测验巩固；发现错题及时重练，加深记忆效果更好哦！',
              style: HanziDesignSpec.cardBodyStyle.copyWith(
                color: Colors.grey[800],
                height: 1.45,
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
                    color: HanziDesignSpec.cardShadowBlue.withValues(alpha: 0.12),
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
                      padding: EdgeInsets.fromLTRB(4.w, verticalPad, 12.w, verticalPad),
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
                                    color: HanziDesignSpec.titleInk,
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
                                    color: HanziDesignSpec.subtitleMuted,
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
                              color: HanziDesignSpec.subtitleMuted
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
