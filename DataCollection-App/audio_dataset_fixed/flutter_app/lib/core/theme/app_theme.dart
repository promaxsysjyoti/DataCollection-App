import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary        = Color(0xFF6C63FF);
  static const Color primaryDark    = Color(0xFF4A43D4);
  static const Color primaryLight   = Color(0xFF9D97FF);
  static const Color secondary      = Color(0xFF00D4AA);
  static const Color accent         = Color(0xFFFF6B9D);
  static const Color success        = Color(0xFF00C896);
  static const Color warning        = Color(0xFFFFB020);
  static const Color error          = Color(0xFFFF4D6A);
  static const Color info           = Color(0xFF3DBEFF);
  static const Color background     = Color(0xFF0F0F1A);
  static const Color surface        = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF252540);
  static const Color surfaceElevated= Color(0xFF2D2D50);
  static const Color cardBg         = Color(0xFF1E1E35);
  static const Color textPrimary    = Color(0xFFF0F0FF);
  static const Color textSecondary  = Color(0xFF9B9BC0);
  static const Color textMuted      = Color(0xFF6B6B90);
  static const Color border         = Color(0xFF2E2E50);
  static const Color borderLight    = Color(0xFF3A3A60);

  static const List<Color> primaryGradient = [Color(0xFF6C63FF), Color(0xFF9D97FF)];
  static const List<Color> adminGradient   = [Color(0xFF6C63FF), Color(0xFFB44FFF)];
  static const List<Color> level1Gradient  = [Color(0xFF3DBEFF), Color(0xFF6C63FF)];
  static const List<Color> walletGradient  = [Color(0xFFFF6B9D), Color(0xFF6C63FF)];
  static const List<Color> successGradient = [Color(0xFF00C896), Color(0xFF3DBEFF)];
  static const List<Color> warningGradient = [Color(0xFFFFB020), Color(0xFFFF6B9D)];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
