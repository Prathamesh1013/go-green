import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:gogreen_admin/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.glassBackgroundDark,
                        AppColors.darkPrimary.withOpacity(0.15),
                        AppColors.glassBackgroundDark.withOpacity(0.5),
                      ]
                    : [
                        AppColors.glassBackgroundLight,
                        AppColors.lightPrimary.withOpacity(0.2),
                        AppColors.glassBackgroundLight.withOpacity(0.7),
                      ],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: isDark 
                    ? AppColors.darkPrimary.withOpacity(0.3)
                    : AppColors.lightPrimary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: borderRadius ?? BorderRadius.circular(20),
                    child: child,
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

