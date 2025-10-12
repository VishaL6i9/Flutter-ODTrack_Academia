import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odtrack_academia/core/theme/app_theme.dart';

/// Utility class for theme-aware analytics components
class AnalyticsThemeUtils {
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get card background color based on theme
  static Color getCardBackgroundColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Theme.of(context).cardColor : Colors.white;
  }

  /// Get secondary background color (for nested containers) based on theme
  static Color getSecondaryBackgroundColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade800 : Colors.grey.shade50;
  }

  /// Get card shadow based on theme
  static List<BoxShadow> getCardShadow(BuildContext context) {
    final isDark = isDarkMode(context);
    return [
      BoxShadow(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: isDark ? 6 : 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Get text color for secondary text based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade400 : Colors.grey;
  }

  /// Get text color for primary text based on theme
  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  /// Get grid line color for charts based on theme
  static Color getGridLineColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade700 : Colors.grey.shade200;
  }

  /// Get chart axis text color based on theme
  static Color getAxisTextColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.grey.shade400 : Colors.grey;
  }

  /// Get container background color with opacity based on theme
  static Color getContainerBackgroundColor(BuildContext context, Color baseColor, {double opacity = 0.1}) {
    final isDark = isDarkMode(context);
    if (isDark) {
      // In dark mode, use a more subtle approach
      return baseColor.withValues(alpha: opacity * 0.7);
    }
    return baseColor.withValues(alpha: opacity);
  }

  /// Get border color based on theme
  static Color getBorderColor(BuildContext context, Color baseColor, {double opacity = 0.3}) {
    final isDark = isDarkMode(context);
    if (isDark) {
      return baseColor.withValues(alpha: opacity * 0.8);
    }
    return baseColor.withValues(alpha: opacity);
  }

  /// Get alert colors based on severity and theme
  static Color getAlertColor(String severity, BuildContext context) {
    final isDark = isDarkMode(context);
    
    switch (severity.toLowerCase()) {
      case 'high':
        return isDark ? Colors.red.shade300 : Colors.red;
      case 'medium':
        return isDark ? Colors.orange.shade300 : Colors.orange;
      case 'low':
        return isDark ? Colors.blue.shade300 : Colors.blue;
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey;
    }
  }

  /// Get success color based on theme
  static Color getSuccessColor(BuildContext context) {
    final isDark = isDarkMode(context);
    return isDark ? Colors.green.shade300 : Colors.green.shade600;
  }

  /// Get chart colors that work well in both light and dark themes
  static List<Color> getChartColors(BuildContext context) {
    final isDark = isDarkMode(context);
    
    if (isDark) {
      return [
        AppTheme.primaryColor.withValues(alpha: 0.8),
        AppTheme.accentColor.withValues(alpha: 0.8),
        Colors.orange.shade300,
        Colors.green.shade300,
        Colors.purple.shade300,
        Colors.red.shade300,
        Colors.teal.shade300,
        Colors.pink.shade300,
        Colors.indigo.shade300,
      ];
    } else {
      return [
        AppTheme.primaryColor,
        AppTheme.accentColor,
        Colors.orange,
        Colors.green,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.pink,
        Colors.indigo,
      ];
    }
  }

  /// Get FlLine for chart grids that adapts to theme
  static FlLine getChartGridLine(BuildContext context, double value) {
    return FlLine(
      color: getGridLineColor(context),
      strokeWidth: 1,
    );
  }

  /// Get chart dot painter that adapts to theme
  static FlDotPainter getChartDotPainter(BuildContext context, Color color) {
    final isDark = isDarkMode(context);
    return FlDotCirclePainter(
      radius: 4,
      color: color,
      strokeWidth: 2,
      strokeColor: isDark ? Colors.grey.shade800 : Colors.white,
    );
  }

  /// Get efficiency color based on value and theme
  static Color getEfficiencyColor(BuildContext context, double value) {
    final isDark = isDarkMode(context);
    
    if (value >= 0.8) {
      return isDark ? Colors.green.shade300 : Colors.green;
    } else if (value >= 0.6) {
      return isDark ? Colors.orange.shade300 : Colors.orange;
    } else {
      return isDark ? Colors.red.shade300 : Colors.red;
    }
  }

  /// Get trend color based on trend type and theme
  static Color getTrendColor(BuildContext context, dynamic trend) {
    final isDark = isDarkMode(context);
    final trendString = trend.toString().toLowerCase();
    
    if (trendString.contains('increasing')) {
      return isDark ? Colors.orange.shade300 : Colors.orange;
    } else if (trendString.contains('decreasing')) {
      return isDark ? Colors.red.shade300 : Colors.red;
    } else {
      return isDark ? Colors.green.shade300 : Colors.green;
    }
  }

  /// Get grade colors that work in both themes
  static List<Color> getGradeColors(BuildContext context) {
    final isDark = isDarkMode(context);
    
    if (isDark) {
      return [
        Colors.red.shade300, Colors.pink.shade300, Colors.purple.shade300, 
        Colors.deepPurple.shade300, Colors.indigo.shade300, Colors.blue.shade300, 
        Colors.lightBlue.shade300, Colors.cyan.shade300, Colors.teal.shade300, 
        Colors.green.shade300, Colors.lightGreen.shade300, Colors.lime.shade300,
        Colors.orange.shade300,
      ];
    } else {
      return [
        Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
        Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
        Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
        Colors.orange,
      ];
    }
  }

  /// Get subject type colors that work in both themes
  static Color getSubjectTypeColor(BuildContext context, dynamic subjectType) {
    final isDark = isDarkMode(context);
    final typeString = subjectType.toString().toLowerCase();
    
    if (typeString.contains('theory')) {
      return isDark ? AppTheme.primaryColor.withValues(alpha: 0.8) : AppTheme.primaryColor;
    } else if (typeString.contains('practical')) {
      return isDark ? Colors.orange.shade300 : Colors.orange;
    } else if (typeString.contains('lab')) {
      return isDark ? Colors.red.shade300 : Colors.red;
    } else if (typeString.contains('project')) {
      return isDark ? Colors.purple.shade300 : Colors.purple;
    } else if (typeString.contains('seminar')) {
      return isDark ? Colors.teal.shade300 : Colors.teal;
    } else {
      return isDark ? Colors.grey.shade400 : Colors.grey;
    }
  }
}