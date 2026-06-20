import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/pinyin_learn_ui_assets.dart';
import 'figma_ui_image.dart';

/// Figma node 9-2 底部进度条（星星 + 里程碑 + 鼓励语）
class PinyinLearnStatsBar extends StatelessWidget {
  const PinyinLearnStatsBar({
    super.key,
    required this.starCount,
    required this.learnedCount,
    required this.totalCount,
  });

  final int starCount;
  final int learnedCount;
  final int totalCount;

  static const _milestones = [20, 30, 40, 50];
  static const _milestoneBtnKeys = [
    PinyinLearnUiAssets.gridMilestone20,
    PinyinLearnUiAssets.gridMilestone30,
    PinyinLearnUiAssets.gridMilestone40,
    PinyinLearnUiAssets.gridMilestone50,
  ];
  static const _milestoneDotKeys = [
    PinyinLearnUiAssets.gridMilestoneDot1,
    PinyinLearnUiAssets.gridMilestoneDot2,
    PinyinLearnUiAssets.gridMilestoneDot3,
    PinyinLearnUiAssets.gridMilestoneDot4,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: FigmaUiImage(
            configKey: PinyinLearnUiAssets.gridStatsBar,
            description: '底部统计条',
            fit: BoxFit.fill,
          ),
        ),
        // 鼓励语气泡
        Positioned(
          left: 140,
          top: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FigmaUiImage(
                configKey: PinyinLearnUiAssets.gridEncourageBubble,
                description: '鼓励语气泡',
                width: 377,
                height: 84,
                fit: BoxFit.fill,
              ),
              Positioned(
                left: 56,
                top: 24,
                child: Text(
                  '小朋友，继续加油哦!',
                  style: GoogleFonts.notoSansSc(
                    fontSize: 27,
                    color: const Color(0xFF4B6C9F),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 24,
                child: FigmaUiImage(
                  configKey: PinyinLearnUiAssets.gridEncourageIcon,
                  description: '鼓励图标',
                  width: 45,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        // 里程碑 20 → 50
        for (var i = 0; i < _milestones.length; i++) ...[
          Positioned(
            right: 180 + (3 - i) * 104,
            top: 42,
            child: _MilestoneBadge(
              value: _milestones[i],
              reached: learnedCount >= _milestones[i],
              btnKey: _milestoneBtnKeys[i],
              dotKey: _milestoneDotKeys[i],
            ),
          ),
        ],
        // 星星 + 当前进度
        Positioned(
          right: 562,
          top: 37,
          child: Stack(
            alignment: Alignment.center,
            children: [
              FigmaUiImage(
                configKey: PinyinLearnUiAssets.gridStarBadge,
                description: '星星进度',
                width: 82,
                height: 82,
                fit: BoxFit.contain,
              ),
              Text(
                '$starCount',
                style: GoogleFonts.notoSansSc(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF5F6F7),
                ),
              ),
            ],
          ),
        ),
        // 礼物盒
        Positioned(
          right: 44,
          top: 41,
          child: FigmaUiImage(
            configKey: PinyinLearnUiAssets.gridGiftBox,
            description: '奖励礼盒',
            width: 71,
            height: 74,
            fit: BoxFit.contain,
          ),
        ),
        // 掌握数量（设计稿右侧文字区）
        Positioned(
          right: 680,
          top: 48,
          child: Text(
            '掌握拼音 $learnedCount/$totalCount',
            style: GoogleFonts.notoSansSc(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5F869D),
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.value,
    required this.reached,
    required this.btnKey,
    required this.dotKey,
  });

  final int value;
  final bool reached;
  final String btnKey;
  final String dotKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FigmaUiImage(
          configKey: dotKey,
          description: '里程碑连线',
          height: 12,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            FigmaUiImage(
              configKey: btnKey,
              description: '里程碑$value',
              width: 59,
              height: 64,
              fit: BoxFit.contain,
            ),
            Text(
              '$value',
              style: GoogleFonts.notoSansSc(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: reached
                    ? const Color(0xFFF4F6F7)
                    : const Color(0xFFF4F6F7).withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
