import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CustomAvatar extends StatelessWidget {
  final Widget? child;
  final double size;

  const CustomAvatar({
    super.key,
    this.child,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FleetColors.gray100,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: child,
      ),
    );
  }
}
