import 'package:flutter/material.dart';

class AppColors {
  // ============================
  // LIGHT MODE COLORS (Analytics Dashboard Style)
  // ============================
  static const Color lightBg = Color(0xFFF9FAFB); // gray-50 background
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white surface
  static const Color lightPrimary = Color(0xFF030213); // Dark primary
  static const Color lightSecondary = Color(0xFF1E3A8A); // blue-900
  static const Color lightAccent = Color(0xFF10B981); // green-500
  static const Color lightText = Color(0xFF111827); // gray-900
  static const Color lightTextSecondary = Color(0xFF4B5563); // gray-600
  static const Color lightBorder = Color(0xFFE5E7EB); // gray-200

  // Status Colors - Light Mode
  static const Color lightHealthy = Color(0xFF16A34A); // green-600
  static const Color lightAttention = Color(0xFFEAB308); // yellow-500
  static const Color lightCritical = Color(0xFFEF4444); // red-500

  // ============================
  // DARK MODE COLORS (Analytics Dashboard Style)
  // ============================
  static const Color darkBg = Color(0xFF0D1117); // Dark background
  static const Color darkSurface = Color(0xFF161B22); // Dark surface
  static const Color darkPrimary = Color(0xFF3B82F6); // blue-500
  static const Color darkSecondary = Color(0xFF60A5FA); // blue-400
  static const Color darkAccent = Color(0xFF10B981); // green-500
  static const Color darkText = Color(0xFFF9FAFB); // gray-50
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // gray-400
  static const Color darkBorder = Color(0xFF374151); // gray-700

  // Status Colors - Dark Mode
  static const Color darkHealthy = Color(0xFF22C55E); // green-500
  static const Color darkAttention = Color(0xFFFBBF24); // yellow-400
  static const Color darkCritical = Color(0xFFF87171); // red-400

  // Helper methods to get colors based on theme
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPrimary
        : lightPrimary;
  }

  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSecondary
        : lightSecondary;
  }

  static Color getHealthy(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkHealthy
        : lightHealthy;
  }

  static Color getAttention(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAttention
        : lightAttention;
  }

  static Color getCritical(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCritical
        : lightCritical;
  }

  // ============================
  // CHART COLORS (Analytics Dashboard)
  // ============================
  static const Color chartBlue = Color(0xFF3B82F6); // blue-500
  static const Color chartGreen = Color(0xFF10B981); // green-500
  static const Color chartOrange = Color(0xFFF97316); // orange-500
  static const Color chartRed = Color(0xFFEF4444); // red-500
  static const Color chartPurple = Color(0xFF8B5CF6); // purple-500
  static const Color chartGray = Color(0xFF6B7280); // gray-500

  // ============================
  // STATUS COLOR SCALES (Tailwind-inspired)
  // ============================
  // Green scale
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);

  // Yellow scale
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow500 = Color(0xFFEAB308);
  static const Color yellow600 = Color(0xFFCA8A04);

  // Red scale
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);

  // Blue scale
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue900 = Color(0xFF1E3A8A);

  // Orange scale
  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange200 = Color(0xFFFED7AA);
  static const Color orange500 = Color(0xFFF97316);
  static const Color orange600 = Color(0xFFEA580C);
  static const Color orange700 = Color(0xFFC2410C);

  // Purple scale
  static const Color purple100 = Color(0xFFF3E8FF);
  static const Color purple500 = Color(0xFFA855F7);
  static const Color purple600 = Color(0xFF9333EA);

  // Gray scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Gradient Colors
  static LinearGradient primaryGradient(BuildContext context) {
    return LinearGradient(
      colors: [
        getPrimary(context),
        getSecondary(context),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient successGradient(BuildContext context) {
    return LinearGradient(
      colors: [
        getHealthy(context),
        getSecondary(context),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient warningGradient(BuildContext context) {
    return LinearGradient(
      colors: [
        getAttention(context),
        const Color(0xFFFF8C00),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Legacy support (for backward compatibility)
  static const Color primary = lightPrimary;
  static const Color success = lightHealthy;
  static const Color warning = lightAttention;
  static const Color error = lightCritical;
  static const Color backgroundLight = lightBg;
  static const Color backgroundDark = darkBg;
  static const Color surfaceLight = lightSurface;
  static const Color surfaceDark = darkSurface;
  static const Color textPrimary = lightText;
  static const Color textSecondary = lightTextSecondary;
  static const Color textPrimaryDark = darkText;
  static const Color textSecondaryDark = darkTextSecondary;
  static const Color healthy = lightHealthy;
  static const Color attention = lightAttention;
  static const Color critical = lightCritical;

  // Glassmorphism Colors (kept for backward compatibility)
  static Color glassBackgroundLight = Colors.white.withOpacity(0.25);
  static Color glassBackgroundDark =
      const Color.fromARGB(161, 255, 255, 255).withOpacity(0.08);
  static Color glassBorderLight = Colors.white.withOpacity(0.4);
  static Color glassBorderDark = Colors.white.withOpacity(0.15);

  // Status color helpers
  static Color getStatusColor(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status.toLowerCase()) {
      case 'completed':
        return isDark ? darkHealthy : lightHealthy;
      case 'in_progress':
        return isDark ? darkPrimary : lightPrimary;
      case 'pending_diagnosis':
        return isDark ? darkAttention : lightAttention;
      case 'on_hold':
        return isDark ? darkAttention : lightAttention;
      case 'cancelled':
        return isDark ? darkCritical : lightCritical;
      default:
        return isDark ? darkTextSecondary : lightTextSecondary;
    }
  }

  static Color getVehicleStatusColor(String status, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status.toLowerCase()) {
      case 'active':
        return isDark ? darkHealthy : lightHealthy;
      case 'inactive':
        return isDark ? darkTextSecondary : lightTextSecondary;
      case 'scrapped':
        return isDark ? darkCritical : lightCritical;
      case 'trial':
        return isDark ? darkAttention : lightAttention;
      default:
        return isDark ? darkTextSecondary : lightTextSecondary;
    }
  }
}
