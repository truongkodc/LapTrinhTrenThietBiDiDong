import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================
// APP THEME - Quản lý Theme tập trung (Bài 4)
// =============================================

class AppTheme {
  // Màu sắc chính
  static const Color primaryColor = Colors.teal;
  static const Color secondaryColor = Color(0xFF00897B);
  static const Color errorColor = Colors.red;
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);

  // Màu nền
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color surfaceTint = Color(0xFFE0F2F1);

  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // ThemeData chính
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingSmall + 4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingSmall + 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }

  // Icon theo category
  static IconData categoryIcon(String category) {
    switch (category) {
      case 'Tăng cơ':
        return Icons.fitness_center;
      case 'Cardio':
        return Icons.directions_run;
      case 'Thể lực':
        return Icons.bolt;
      default:
        return Icons.sports;
    }
  }

  // Màu theo category
  static Color categoryColor(String category) {
    switch (category) {
      case 'Tăng cơ':
        return Colors.blue;
      case 'Cardio':
        return Colors.orange;
      case 'Thể lực':
        return Colors.purple;
      default:
        return primaryColor;
    }
  }
}
