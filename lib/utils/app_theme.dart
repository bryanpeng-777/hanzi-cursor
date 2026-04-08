import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryYellow = Color(0xFFFFD23F);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryPink = Color(0xFFE91E8C);
  static const Color backgroundPeach = Color(0xFFFFF3E0);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static const List<Color> levelColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
  ];

  static ThemeData get theme {
    final notoSansSc = GoogleFonts.notoSansSc();
    final fontFamily = notoSansSc.fontFamily;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: backgroundPeach,
      cardTheme: const CardThemeData(
        color: cardWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily),
        ),
      ),
      textTheme: GoogleFonts.notoSansScTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
          bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF555555)),
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ),
    );
  }
}

class AppColors {
  static Color getLevelColor(int level) =>
      AppTheme.levelColors[(level - 1).clamp(0, AppTheme.levelColors.length - 1)];
}
