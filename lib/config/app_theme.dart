import 'package:flutter/material.dart';

class AppColors {
  // Primary - vibrant emerald green
  static const Color primary = Color(0xFF00875A);
  static const Color primaryLight = Color(0xFF00C97B);
  static const Color primaryDark = Color(0xFF005C3D);
  static const Color accent = Color(0xFF00E396);

  // Text hierarchy
  static const Color deepSlate = Color(0xFF1A2332);
  static const Color textDark = Color(0xFF1A2332);      // Alias for deepSlate
  static const Color slateGray = Color(0xFF556677);
  static const Color lightSlate = Color(0xFF8899AA);
  static const Color paleSlate = Color(0xFFCBD5E1);

  // Surfaces - WARM tinted, not cold gray!
  static const Color background = Color(0xFFF0F7F4);       // Soft green-tinted
  static const Color backgroundLight = Color(0xFFF8FAF9);  // Lighter background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF0F7F4);       // Main background - green tinted

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Dividers & shimmer
  static const Color divider = Color(0xFFE0EDE8);          // Green-tinted divider
  static const Color border = Color(0xFFE0EDE8);           // Alias for divider
  static const Color shimmer = Color(0xFFD4E8DF);

  // Status colors
  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusCompleted = Color(0xFF3B82F6);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Gradient helpers
  static const List<Color> primaryGradient = [Color(0xFF00875A), Color(0xFF00C97B)];
  static const List<Color> headerGradient = [Color(0xFF006644), Color(0xFF00875A), Color(0xFF00B894)];
  static const List<Color> warmGradient = [Color(0xFF00875A), Color(0xFF00E396)];
  static const List<Color> accentGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.deepSlate,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: 'Roboto',
      // Global text theme with larger fonts for mobile readability
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.deepSlate),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.deepSlate),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.deepSlate, height: 1.5),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.deepSlate, height: 1.5),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.slateGray, height: 1.4),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepSlate),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.slateGray),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightSlate),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          // Android touch target standard: minimum 48dp height
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          // Android touch target standard: minimum 48dp height
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          // Android touch target standard: minimum 48dp height
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          // Android touch target standard: minimum 48dp
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.slateGray, fontSize: 15),
        hintStyle: const TextStyle(color: AppColors.lightSlate, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightSlate,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 13),
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 26),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: AppColors.deepSlate,
        contentTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.deepSlate),
        contentTextStyle: const TextStyle(fontSize: 15, color: AppColors.slateGray, height: 1.5),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.deepSlate),
        subtitleTextStyle: TextStyle(fontSize: 14, color: AppColors.slateGray),
        iconColor: AppColors.primary,
      ),
    );
  }
}
