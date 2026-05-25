import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 宝宝识字横屏设计规范（812×375）。
///
/// 与 [AppOrientation.designSize] 对齐，供 T002+ 各屏统一引用。
/// 数值为逻辑像素，在 UI 中配合 ScreenUtil 的 `.w` / `.h` / `.sp` 使用。
abstract final class HanziDesignSpec {
  // ── 画布 ──────────────────────────────────────────────
  static const double canvasWidth = 812;
  static const double canvasHeight = 375;

  // ── 品牌色（Figma 拼音 Hub 导出）────────────────────
  static const Color headerBlue = Color(0xFF28A2E9);
  static const Color titleInk = Color(0xFF284059);
  static const Color subtitleMuted = Color(0xFF8D8C89);
  static const Color cardShadowBlue = Color(0xFF2F9DE0);

  static const Color accentLearn = Color(0xFF3EC9A7);
  static const Color accentQuiz = Color(0xFFFF7A5C);
  static const Color accentMistake = Color(0xFFFF6A88);

  // ── 表面色 ────────────────────────────────────────────
  static const Color surfaceWarm = Color(0xFFFFF9F0);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfacePeach = Color(0xFFFFF3E0);

  // ── 间距（横屏）──────────────────────────────────────
  static const double pagePaddingH = 20;
  static const double pagePaddingV = 8;
  static const double sectionGap = 12;
  static const double cardGap = 10;
  static const double cardPadding = 16;

  // ── 形状 ──────────────────────────────────────────────
  static const double cardRadius = 20;
  static const double chipRadius = 12;
  static const double buttonRadius = 20;

  // ── 阴影 ──────────────────────────────────────────────
  static List<BoxShadow> cardShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? cardShadowBlue).withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── 横屏字号 ──────────────────────────────────────────
  static TextStyle get hubTitleStyle => GoogleFonts.notoSansSc(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: titleInk,
        height: 1.2,
      );

  static TextStyle get hubSubtitleStyle => GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: subtitleMuted,
        height: 1.3,
      );

  static TextStyle get cardTitleStyle => GoogleFonts.notoSansSc(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: titleInk,
        height: 1.2,
      );

  static TextStyle get cardBodyStyle => GoogleFonts.notoSansSc(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: subtitleMuted,
        height: 1.4,
      );

  static TextStyle get chipLabelStyle => GoogleFonts.notoSansSc(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: surfaceCard,
        height: 1.1,
      );

  /// 所有 token 是否已定义（供 Playground / 单测断言）
  static bool get tokensDefined =>
      canvasWidth > canvasHeight &&
      headerBlue.a > 0 &&
      pagePaddingH > 0 &&
      cardRadius > 0 &&
      hubTitleStyle.fontSize != null;
}
