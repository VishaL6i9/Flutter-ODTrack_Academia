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
        clipBehavior: Clip.antiAlias,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
      colorScheme: isHighContrast
          ? _getHighContrastDarkColorScheme()
          : ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isHighContrast ? 4 : 2,
        color: const Color(0xFF2C2C2C),
        clipBehavior: Clip.antiAlias,
        shadowColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isHighContrast 
              ? const BorderSide(color: highContrastOnPrimary, width: 2) 
              : const BorderSide(color: Color(0xFF404040), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: const Color(0xFF121212),
          disabledBackgroundColor: const Color(0xFF424242),
          disabledForegroundColor: const Color(0xFF616161),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF90CAF9),
          disabledForegroundColor: const Color(0xFF616161),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : const Color(0xFF90CAF9),
            width: isHighContrast ? 2 : 1.5,
          ),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF90CAF9),
          disabledForegroundColor: const Color(0xFF616161),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontWeight: isBoldText ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : const Color(0xFF404040),
            width: isHighContrast ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : const Color(0xFF404040),
            width: isHighContrast ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isHighContrast ? highContrastOnPrimary : const Color(0xFF90CAF9),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: errorColor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: errorColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.bold : FontWeight.w400,
          color: Colors.grey[400],
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontWeight: isBoldText ? FontWeight.w500 : FontWeight.w400,
          color: Colors.grey[500],
          fontSize: 14,
        ),
        helperStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: 12,
        ),
      ),
      textTheme: _getAccessibleTextTheme(isBoldText, true),
      dividerColor: const Color(0xFF404040),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 0.5,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF3C3C3C),
        labelStyle: TextStyle(color: Colors.white),
        side: BorderSide(color: Color(0xFF404040)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white70,
        tileColor: Color(0xFF2C2C2C),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1E1E1E),
        textStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF90CAF9),
        linearTrackColor: Color(0xFF404040),
        circularTrackColor: Color(0xFF404040),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF90CAF9),
        foregroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF90CAF9),
        unselectedLabelColor: Colors.white70,
        indicatorColor: Color(0xFF90CAF9),
        dividerColor: Color(0xFF404040),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF90CAF9);
          }
          return Colors.grey[600];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF90CAF9).withValues(alpha: 0.5);
          }
          return const Color(0xFF404040);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF90CAF9);
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: Color(0xFF404040)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF90CAF9);
          }
          return const Color(0xFF404040);
        }),
      ),
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
