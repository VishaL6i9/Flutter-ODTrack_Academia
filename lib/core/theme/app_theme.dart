import 'package:flutter/material.dart';
import 'package:odtrack_academia/core/accessibility/accessibility_service.dart';

class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  
  // High Contrast Colors
  static const Color highContrastPrimary = Color(0xFF000000);
  static const Color highContrastOnPrimary = Color(0xFFFFFFFF);
  static const Color highContrastSecondary = Color(0xFF333333);
  static const Color highContrastOnSecondary = Color(0xFFFFFFFF);
  static const Color highContrastSurface = Color(0xFFFFFFFF);
  static const Color highContrastOnSurface = Color(0xFF000000);
  static const Color highContrastError = Color(0xFFCC0000);
  static const Color highContrastOnError = Color(0xFFFFFFFF);
  
  // Light Theme
  static ThemeData get lightTheme {
    final isHighContrast = AccessibilityService.instance.isHighContrastEnabled;
    final isBoldText = AccessibilityService.instance.isBoldTextEnabled;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: isHighContrast ? _getHighContrastLightColorScheme() : ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isHighContrast ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isHighContrast ? const BorderSide(color: highContrastOnSurface, width: 2) : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHighContrast ? const BorderSide(color: highContrastOnSurface, width: 2) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: isHighContrast ? highContrastOnSurface : primaryColor,
            width: isHighContrast ? 2 : 1,
          ),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnSurface : Colors.grey,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnSurface : Colors.grey,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastPrimary : primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      textTheme: _getAccessibleTextTheme(isBoldText, false),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    final isHighContrast = AccessibilityService.instance.isHighContrastEnabled;
    final isBoldText = AccessibilityService.instance.isBoldTextEnabled;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: isHighContrast ? _getHighContrastDarkColorScheme() : ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isHighContrast ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isHighContrast ? const BorderSide(color: highContrastOnPrimary, width: 2) : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isHighContrast ? const BorderSide(color: highContrastOnPrimary, width: 2) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : primaryColor,
            width: isHighContrast ? 2 : 1,
          ),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : Colors.grey,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : Colors.grey,
            width: isHighContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w400,
        ),
        hintStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      textTheme: _getAccessibleTextTheme(isBoldText, true),
    );
  }

  // High contrast color schemes
  static ColorScheme _getHighContrastLightColorScheme() {
    return const ColorScheme.light(
      primary: highContrastPrimary,
      onPrimary: highContrastOnPrimary,
      secondary: highContrastSecondary,
      onSecondary: highContrastOnSecondary,
      surface: highContrastSurface,
      onSurface: highContrastOnSurface,
      error: highContrastError,
      onError: highContrastOnError,
    );
  }

  static ColorScheme _getHighContrastDarkColorScheme() {
    return const ColorScheme.dark(
      primary: highContrastOnPrimary,
      onPrimary: highContrastPrimary,
      secondary: highContrastOnSecondary,
      onSecondary: highContrastSecondary,
      surface: highContrastPrimary,
      onSurface: highContrastOnPrimary,
      error: highContrastError,
      onError: highContrastOnError,
    );
  }

  // Accessible text theme
  static TextTheme _getAccessibleTextTheme(bool isBoldText, bool isDark) {
    final baseTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    
    if (!isBoldText) return baseTheme;
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
      displayMedium: baseTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
      displaySmall: baseTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: baseTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      titleMedium: baseTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      titleSmall: baseTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      bodySmall: baseTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      labelMedium: baseTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
      labelSmall: baseTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
