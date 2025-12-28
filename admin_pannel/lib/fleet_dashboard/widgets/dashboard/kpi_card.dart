import 'package:flutter/material.dart';
import '../ui/custom_card.dart';
import '../../theme/app_colors.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtext;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final Map<String, dynamic>? trend;
  final String? status;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    this.subtext,
    required this.icon,
    this.iconBgColor = FleetColors.blue100,
    this.iconColor = FleetColors.blue600,
    this.trend,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconBgColor, // Full card background in pastel color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FleetColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FleetColors.gray600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: FleetColors.gray900,
                          ),
                        ),
                        if (trend != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${trend!['direction'] == 'down' ? '↓' : '↑'} ${trend!['value'].abs()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: trend!['direction'] == 'down'
                                  ? FleetColors.green600
                                  : FleetColors.red600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtext != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtext!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: FleetColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(status!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: FleetColors.gray600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'normal':
        return FleetColors.green500;
      case 'warning':
        return FleetColors.yellow500;
      case 'critical':
        return FleetColors.red500;
      default:
        return FleetColors.gray500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'normal':
        return 'Operating normally';
      case 'warning':
        return 'Needs attention';
      case 'critical':
        return 'Critical';
      default:
        return '';
    }
  }
}
