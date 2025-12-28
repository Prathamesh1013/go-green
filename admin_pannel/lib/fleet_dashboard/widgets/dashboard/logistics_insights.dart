import 'package:flutter/material.dart';
import '../ui/custom_card.dart';
import '../../models/kpi.dart';
import '../../theme/app_colors.dart';

class LogisticsInsights extends StatelessWidget {
  final List<String> peakZones;
  final String avgResponseTime;
  final int vehiclesNearServiceDue;

  const LogisticsInsights({
    super.key,
    required this.peakZones,
    required this.avgResponseTime,
    required this.vehiclesNearServiceDue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logistics Insights',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          _buildInsightRow(
            context,
            Icons.location_on,
            'Peak Breakdown Zones',
            peakZones.join(', '),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            context,
            Icons.access_time,
            'Avg Response Time',
            avgResponseTime,
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            context,
            Icons.build,
            'Vehicles Near Service Due',
            '$vehiclesNearServiceDue vehicles',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FleetColors.blue100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: FleetColors.blue600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: FleetColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: FleetColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
