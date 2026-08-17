import 'package:flutter/material.dart';

/// Vibe Connect brand palette — warm coral (connection, warmth)
/// paired with a deep indigo (depth, trust).
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

  static const surfaceDark = Color(0xFF16131F);
  static const surfaceDarkElevated = Color(0xFF221C2E);

  static const success = Color(0xFF3FB68B);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFE0564C);

  static const gradientWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, indigo],
  );
}

class AppTheme {
  AppTheme._();

  static const _radius = 20.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.light,
      primary: AppColors.coral,
      secondary: AppColors.indigo,
      surface: Colors.white,
      error: AppColors.error,
    ).copyWith(
      primaryContainer: const Color(0xFFFFE4DF),
      secondaryContainer: const Color(0xFFE4E0FF),
    );
    return _build(scheme, AppColors.cream, AppColors.ink);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.dark,
      primary: AppColors.coral,
      secondary: AppColors.indigo,
      surface: AppColors.surfaceDarkElevated,
      error: AppColors.error,
    );
    return _build(scheme, AppColors.surfaceDark, Colors.white);
  }

  static ThemeData _build(ColorScheme scheme, Color scaffold, Color ink) {
    final textTheme = _textTheme(ink);
    final radius = BorderRadius.circular(_radius);
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: BorderSide(color: ink.withValues(alpha: 0.12)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.coral.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.coral : ink.withValues(alpha: 0.55),
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.indigo,
        inactiveTrackColor: AppColors.indigo.withValues(alpha: 0.12),
        thumbColor: Colors.white,
        overlayColor: AppColors.indigo.withValues(alpha: 0.12),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: AppColors.indigo,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        shape: StadiumBorder(side: BorderSide(color: ink.withValues(alpha: 0.08))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: ink.withValues(alpha: 0.08)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    TextStyle style(double size, FontWeight weight, {double height = 1.25, Color? fg}) {
      return TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        color: fg ?? color,
        height: height,
      );
    }

    return TextTheme(
      displaySmall: style(32, FontWeight.w700),
      headlineMedium: style(26, FontWeight.w700),
      headlineSmall: style(22, FontWeight.w600),
      titleLarge: style(18, FontWeight.w600),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w600),
      bodyLarge: style(16, FontWeight.w400, height: 1.4),
      bodyMedium: style(14, FontWeight.w400, height: 1.4, fg: color.withValues(alpha: 0.75)),
      bodySmall: style(12, FontWeight.w400, height: 1.4, fg: color.withValues(alpha: 0.65)),
      labelLarge: style(13, FontWeight.w600),
      labelMedium: style(12, FontWeight.w600),
      labelSmall: style(11, FontWeight.w600),
    );
  }
}
