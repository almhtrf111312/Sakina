import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'app_colors.dart';

/// Provides [ThemeData] for Night, Day, and AMOLED modes.
class AppTheme {
  AppTheme._();

  // -------------------------------------------------------------------------
  // Night Theme (default dark)
  // -------------------------------------------------------------------------

  static ThemeData nightTheme() {
    final primary = AppColors.nightPrimary;
    final secondary = AppColors.nightSecondary;
    final background = AppColors.nightBackground;
    final surface = AppColors.nightSurface;
    final elevated = AppColors.nightElevated;
    const textPrimary = AppColors.nightTextPrimary;
    const textSecondary = AppColors.nightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.dark(
        primary: primary,
        surfaceTint: Colors.transparent,
        onPrimary: const Color(0xFF0E1514),
        secondary: secondary,
        onSecondary: const Color(0xFF0E1514),
        surface: surface,
        onSurface: textPrimary,
        background: background,
        onBackground: textPrimary,
        surfaceVariant: elevated,
        onSurfaceVariant: textSecondary,
        outline: textSecondary.withOpacity(0.3),
        outlineVariant: textSecondary.withOpacity(0.15),
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        tertiary: textSecondary,
        onTertiary: background,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: textSecondary,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        iconTheme: const IconThemeData(color: textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0E1514),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      primaryIconTheme: IconThemeData(color: primary),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.6),
          fontFamily: 'Cairo',
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? primary : textSecondary,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primary.withOpacity(0.3)
              : textSecondary.withOpacity(0.2),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.2),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: elevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevated,
        contentTextStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: Color(0x1F5FB59B),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevated,
        labelStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        selectedColor: primary.withOpacity(0.2),
        checkmarkColor: primary,
        side: BorderSide(color: textSecondary.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Day Theme
  // -------------------------------------------------------------------------

  static ThemeData dayTheme() {
    final primary = AppColors.dayPrimary;
    final secondary = AppColors.daySecondary;
    const background = AppColors.dayBackground;
    const surface = AppColors.daySurface;
    const textPrimary = AppColors.dayTextPrimary;
    const textSecondary = AppColors.dayTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.light(
        primary: primary,
        surfaceTint: Colors.transparent,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        background: background,
        onBackground: textPrimary,
        surfaceVariant: const Color(0xFFEBE9E3),
        onSurfaceVariant: textSecondary,
        outline: textSecondary.withOpacity(0.4),
        outlineVariant: textSecondary.withOpacity(0.2),
        error: const Color(0xFFB00020),
        onError: Colors.white,
        tertiary: textSecondary,
        onTertiary: background,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: textSecondary,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      primaryIconTheme: IconThemeData(color: primary),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEBE9E3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.6),
          fontFamily: 'Cairo',
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? primary : textSecondary,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primary.withOpacity(0.3)
              : textSecondary.withOpacity(0.2),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.2),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: Color(0x1F2F7F69),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEBE9E3),
        labelStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        selectedColor: primary.withOpacity(0.15),
        checkmarkColor: primary,
        side: BorderSide(color: textSecondary.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AMOLED Theme
  // -------------------------------------------------------------------------

  static ThemeData amoledTheme() {
    final primary = AppColors.nightPrimary;
    final secondary = AppColors.nightSecondary;
    const background = AppColors.amoledBackground;
    const surface = AppColors.amoledSurface;
    const textPrimary = AppColors.nightTextPrimary;
    const textSecondary = AppColors.nightTextSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Cairo',
      colorScheme: ColorScheme.dark(
        primary: primary,
        surfaceTint: Colors.transparent,
        onPrimary: Colors.black,
        secondary: secondary,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        background: background,
        onBackground: textPrimary,
        surfaceVariant: const Color(0xFF111918),
        onSurfaceVariant: textSecondary,
        outline: textSecondary.withOpacity(0.3),
        outlineVariant: textSecondary.withOpacity(0.1),
        error: const Color(0xFFCF6679),
        onError: Colors.black,
        tertiary: textSecondary,
        onTertiary: background,
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: textSecondary,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      primaryIconTheme: IconThemeData(color: primary),
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary, fontFamily: 'Cairo'),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.6),
          fontFamily: 'Cairo',
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected) ? primary : textSecondary,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? primary.withOpacity(0.3)
              : textSecondary.withOpacity(0.2),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withOpacity(0.2),
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.15),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Cairo',
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: Color(0x1F5FB59B),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: TextStyle(color: textPrimary, fontFamily: 'Cairo'),
        selectedColor: primary.withOpacity(0.2),
        checkmarkColor: primary,
        side: BorderSide(color: textSecondary.withOpacity(0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shared text theme builder
  // -------------------------------------------------------------------------

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Amiri',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primary,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        height: 1.45,
      ),
    );
  }
}
