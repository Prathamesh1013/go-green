import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum ButtonVariant { defaultVariant, outline, ghost }
enum ButtonSize { sm, md, icon }

class CustomButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;

  const CustomButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.defaultVariant,
    this.size = ButtonSize.md,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry padding = switch (size) {
      ButtonSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ButtonSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ButtonSize.icon => const EdgeInsets.all(8),
    };

    final double fontSize = switch (size) {
      ButtonSize.sm => 14,
      ButtonSize.md => 16,
      ButtonSize.icon => 16,
    };

    Widget buttonChild = child ?? (text != null ? Text(text!) : const SizedBox());
    
    if (icon != null && text != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text!),
        ],
      );
    } else if (icon != null) {
      buttonChild = icon!;
    }

    switch (variant) {
      case ButtonVariant.defaultVariant:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: FleetColors.primary,
            foregroundColor: FleetColors.primaryForeground,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: buttonChild,
        );
      
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: FleetColors.textPrimary,
            padding: padding,
            side: const BorderSide(color: FleetColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: buttonChild,
        );
      
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: FleetColors.textPrimary,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: buttonChild,
        );
    }
  }
}
