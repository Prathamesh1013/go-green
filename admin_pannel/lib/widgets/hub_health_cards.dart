import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';

class HubHealthCards extends StatelessWidget {
  const HubHealthCards({super.key});

  @override
  Widget build(BuildContext context) {
    final hubs = [
      {'name': 'Nashik', 'status': 'Good', 'color': AppColors.success},
      {'name': 'Pune', 'status': 'Attention', 'color': AppColors.warning},
      {'name': 'Mumbai', 'status': 'Critical', 'color': AppColors.error},
    ];

    return Row(
      children: hubs.map((hub) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (hub['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hub['status'] == 'Good'
                          ? Icons.check_circle
                          : hub['status'] == 'Attention'
                              ? Icons.warning
                              : Icons.error,
                      color: hub['color'] as Color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hub['name'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hub['status'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hub['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
