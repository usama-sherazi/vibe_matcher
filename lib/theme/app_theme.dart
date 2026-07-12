import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vibe Connect brand palette — warm coral (connection, warmth)
/// paired with a deep indigo (depth, trust). Kept to a small,
/// disciplined set so the UI reads as designed, not decorated.
class AppColors {
  AppColors._();

  static const coral = Color(0xFFFF6F61);
  static const coralDeep = Color(0xFFE85A4F);
  static const indigo = Color(0xFF5B4FE9);
  static const indigoDeep = Color(0xFF3F35B8);
  static const gold = Color(0xFFFFC15E);

  static const cream = Color(0xFFFFF8F4);
  static const ink = Color(0xFF221D2E);
  static const inkSoft = Color(0xFF6E6579);

  static const surfaceDark = Color(0xFF201C2C);
  static const surfaceDarkElevated = Color(0xFF2A2438);

  static const success = Color(0xFF3FB68B);
  static const warning = Color(0xFFFFB020);

  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, indigo],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, AppColors.ink);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.coral,
        secondary: AppColors.indigo,
        surface: Colors.white,
        error: const Color(0xFFE0564C),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.indigo,
        inactiveTrackColor: AppColors.indigo.withOpacity(0.12),
        thumbColor: Colors.white,
        overlayColor: AppColors.indigo.withOpacity(0.12),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: AppColors.indigo,
        labelStyle: textTheme.labelLarge,
        shape: StadiumBorder(side: BorderSide(color: AppColors.ink.withOpacity(0.08))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.ink.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.ink.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = _textTheme(base.textTheme, Colors.white);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.coral,
        secondary: AppColors.indigo,
        surface: AppColors.surfaceDarkElevated,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      cardColor: AppColors.surfaceDarkElevated,
    );
  }

  static TextTheme _textTheme(TextTheme base, Color color) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displaySmall: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: color),
      headlineMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: color),
      headlineSmall: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: color),
      titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: color, height: 1.4),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: color.withOpacity(0.75), height: 1.4),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
    );
  }
}
