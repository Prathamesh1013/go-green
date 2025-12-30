import 'package:flutter/material.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final double? changePercent;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
    this.onTap,
    this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;
    final isPositive = changePercent != null && changePercent! >= 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pastel background colors for both light and dark modes
    Color backgroundColor;
    if (!isDark) {
      // Light mode - bright pastels
      if (cardColor == AppColors.primary || cardColor == AppColors.lightPrimary) {
        backgroundColor = const Color(0xFFDBEAFE); // Light blue
      } else if (cardColor == AppColors.success || cardColor == AppColors.healthy) {
        backgroundColor = const Color(0xFFDCFCE7); // Light green
      } else if (cardColor == AppColors.warning || cardColor == AppColors.attention) {
        backgroundColor = const Color(0xFFFEF9C3); // Light yellow
      } else if (cardColor == AppColors.error || cardColor == AppColors.critical) {
        backgroundColor = const Color(0xFFFEE2E2); // Light red
      } else {
        backgroundColor = const Color(0xFFF3E8FF); // Light purple
      }
    } else {
      // Dark mode - darker pastel variants
      if (cardColor == AppColors.primary || cardColor == AppColors.lightPrimary) {
        backgroundColor = const Color(0xFF1E3A5F); // Dark blue
      } else if (cardColor == AppColors.success || cardColor == AppColors.healthy) {
        backgroundColor = const Color(0xFF1E4D2B); // Dark green
      } else if (cardColor == AppColors.warning || cardColor == AppColors.attention) {
        backgroundColor = const Color(0xFF4D4516); // Dark yellow
      } else if (cardColor == AppColors.error || cardColor == AppColors.critical) {
        backgroundColor = const Color(0xFF4D1F1F); // Dark red
      } else {
        backgroundColor = const Color(0xFF3D2D4D); // Dark purple
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: cardColor, size: 20),
              ),
              if (changePercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${changePercent!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}





