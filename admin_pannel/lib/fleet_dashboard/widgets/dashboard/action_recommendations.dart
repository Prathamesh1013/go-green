import 'package:flutter/material.dart';
import '../ui/custom_card.dart';
import '../../models/kpi.dart';
import '../../theme/app_colors.dart';

class ActionRecommendations extends StatelessWidget {
  final List<ActionRecommendation> recommendations;

  const ActionRecommendations({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Recommendations',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(rec.type),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getBorderColor(rec.type)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getIndicatorColor(rec.type),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: FleetColors.gray900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rec.action,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FleetColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getBackgroundColor(String type) {
    switch (type) {
      case 'warning':
        return FleetColors.orange50;
      case 'info':
        return FleetColors.blue50;
      case 'success':
        return FleetColors.green50;
      default:
        return FleetColors.gray50;
    }
  }

  Color _getBorderColor(String type) {
    switch (type) {
      case 'warning':
        return FleetColors.orange200;
      case 'info':
        return FleetColors.blue200;
      case 'success':
        return FleetColors.green200;
      default:
        return FleetColors.gray200;
    }
  }

  Color _getIndicatorColor(String type) {
    switch (type) {
      case 'warning':
        return FleetColors.orange600;
      case 'info':
        return FleetColors.blue600;
      case 'success':
        return FleetColors.green600;
      default:
        return FleetColors.gray600;
    }
  }
}
