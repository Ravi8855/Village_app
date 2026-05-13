import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Naganoor village palette: warm earth, monsoon green, dawn cream.
class AppColors {
  static const forest = Color(0xFF1B5E20);
  static const leaf = Color(0xFF2E7D32);
  static const clay = Color(0xFFC97D60);
  static const sand = Color(0xFFF5F0E8);
  static const soil = Color(0xFF3E2723);
  static const sky = Color(0xFF4A6FA5);
  static const rice = Color(0xFFE8F5E9);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.leaf,
        brightness: Brightness.light,
        primary: AppColors.leaf,
        secondary: AppColors.clay,
        surface: AppColors.sand,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.sand,
      textTheme: GoogleFonts.notoSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.soil,
        displayColor: AppColors.soil,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.sand.withValues(alpha: 0.92),
        foregroundColor: AppColors.soil,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.soil,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: AppColors.rice,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
