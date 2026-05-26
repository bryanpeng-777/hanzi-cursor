import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cs_ui/cs_ui.dart';

import 'hanzi_design_spec.dart';

/// 横屏页面脚手架：统一背景与安全区内边距。
class HanziLandscapeScaffold extends StatelessWidget {
  const HanziLandscapeScaffold({
    super.key,
    required this.body,
    this.backgroundColor = HanziDesignSpec.surfaceWarm,
    this.padding,
    this.appBar,
  });

  final Widget body;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: HanziDesignSpec.pagePaddingH.w,
                vertical: HanziDesignSpec.pagePaddingV.h,
              ),
          child: body,
        ),
      ),
    );
  }
}

/// 白底圆角卡片，带可选强调色阴影。
class HanziSurfaceCard extends StatelessWidget {
  const HanziSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.shadowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(HanziDesignSpec.cardPadding.w),
      decoration: BoxDecoration(
        color: HanziDesignSpec.surfaceCard,
        borderRadius:
            BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        boxShadow: HanziDesignSpec.cardShadow(color: shadowColor),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(HanziDesignSpec.cardRadius.r),
        child: card,
      ),
    );
  }
}

/// 区块标题 + 副标题。
class HanziSectionHeader extends StatelessWidget {
  const HanziSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: HanziDesignSpec.hubTitleStyle),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(subtitle!, style: HanziDesignSpec.hubSubtitleStyle),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 强调色角标/标签（如 Hub 卡片右上角）。
class HanziAccentChip extends StatelessWidget {
  const HanziAccentChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(HanziDesignSpec.chipRadius.r),
      ),
      child: Text(label, style: HanziDesignSpec.chipLabelStyle),
    );
  }
}

class HanziBottomNavItem {
  const HanziBottomNavItem({
    required this.iconKey,
    required this.iconDesc,
    required this.label,
  });

  final String iconKey;
  final String iconDesc;
  final String label;
}

class HanziBottomNavBar extends StatelessWidget {
  const HanziBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const defaultItems = <HanziBottomNavItem>[
    HanziBottomNavItem(
      iconKey: 'img_nav_pinyin',
      iconDesc: '拼音',
      label: '拼音',
    ),
    HanziBottomNavItem(
      iconKey: 'img_nav_learn',
      iconDesc: '识字',
      label: '识字',
    ),
    HanziBottomNavItem(
      iconKey: 'img_nav_game',
      iconDesc: '游戏',
      label: '游戏',
    ),
    HanziBottomNavItem(
      iconKey: 'img_nav_vocab',
      iconDesc: '我的学习',
      label: '我的学习',
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HanziBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HanziDesignSpec.surfaceCard,
        border: Border(
          top: BorderSide(
            color: HanziDesignSpec.subtitleMuted.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: HanziDesignSpec.navBarPaddingV,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _HanziBottomNavTile(
                    item: items[i],
                    index: i,
                    isSelected: i == currentIndex,
                    onTap: onTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HanziBottomNavTile extends StatelessWidget {
  const _HanziBottomNavTile({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final HanziBottomNavItem item;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = isSelected
        ? HanziDesignSpec.navIconSelected
        : HanziDesignSpec.navIconDefault;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? HanziDesignSpec.navSelectedBackground
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(HanziDesignSpec.buttonRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CsImage(
              configKey: item.iconKey,
              description: item.iconDesc,
              width: iconSize,
              height: iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: isSelected
                  ? HanziDesignSpec.navLabelSelectedStyle
                  : HanziDesignSpec.navLabelStyle,
            ),
          ],
        ),
      ),
    );
  }
}
