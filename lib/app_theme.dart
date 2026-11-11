import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =============================================
// APP THEME - Quản lý Theme tập trung (Bài 4)
// Dùng font hệ thống hỗ trợ tiếng Việt, màu sắc đồng nhất.
// =============================================

class AppTheme {
  // Màu sắc chính theo chuẩn giao diện FitPlan
  static const Color primaryColor = Color(0xFF00796B); // Teal đậm #00796B
  static const Color secondaryColor = Color(0xFF00897B);
  static const Color amberAccentColor = Color(
    0xFFF4B544,
  ); // Vàng hổ phách #F4B544
  static const Color amberSoftBackground = Color(0xFFFFF4DC);
  static const Color amberOnColor = Color(0xFF1F2933); // Chữ tối trên nền vàng
  static const Color accentCaloriesColor = Color(
    0xFFE65100,
  ); // Cam đậm cho kcal
  static const Color errorColor = Color(0xFFD32F2F); // Đỏ cho xóa/lỗi
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFF57C00);

  // Màu nền & bề mặt giảm diện tích trắng đơn điệu
  static const Color backgroundColor = Color(
    0xFFEAF3F2,
  ); // Xanh xám nhạt #EAF3F2
  static const Color mintSurfaceColor = Color(
    0xFFD8EEEA,
  ); // Xanh mint nhạt #D8EEEA
  static const Color cardBackground = Colors.white;
  static const Color surfaceTint = mintSurfaceColor;
  static const Color completedCardBackground = mintSurfaceColor;

  // Gradient teal nhẹ cho vùng chào / nhận diện
  static const LinearGradient headerTealGradient = LinearGradient(
    colors: [Color(0xFF00796B), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Màu chữ đảm bảo tương phản rõ
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF4B5563);

  // Cấu hình thanh trạng thái hệ thống (Status Bar & Navigation Bar)
  /// Dùng cho màn hình có nền sáng (#EAF3F2): biểu tượng giờ/pin/mạng tối
  static const SystemUiOverlayStyle lightStatusBarStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Dùng cho màn hình có AppBar / vùng đỉnh màu teal (#00796B): biểu tượng sáng
  static const SystemUiOverlayStyle tealHeaderStatusBarStyle =
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );

  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;

  // ThemeData chính
  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: amberAccentColor,
      error: errorColor,
      surface: cardBackground,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: tealHeaderStatusBarStyle,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFFB2DFDB),
        indicatorColor: amberAccentColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 1.5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: Color(0xFFD5E4E2), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: textSecondary),
        errorMaxLines: 5,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Color(0xFFCBD2D9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Color(0xFFCBD2D9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: errorColor, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingSmall + 4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: paddingLarge,
            vertical: paddingSmall + 4,
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: paddingMedium,
            vertical: paddingSmall + 4,
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        return const Color(0xFF1565C0);
      case 'Cardio':
        return const Color(0xFFE65100);
      case 'Thể lực':
        return const Color(0xFF6A1B9A);
      default:
        return primaryColor;
    }
  }
}
