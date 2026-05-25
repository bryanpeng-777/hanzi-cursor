import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
