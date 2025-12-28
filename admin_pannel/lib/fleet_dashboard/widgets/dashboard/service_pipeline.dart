import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ui/custom_card.dart';
import '../../models/kpi.dart';
import '../../theme/app_colors.dart';

class ServicePipeline extends StatelessWidget {
  final List<ServicePipelineData> data;

  const ServicePipeline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, item) => sum + item.value);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(title: 'Service Pipeline'),
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sections: data.map((item) {
                      return PieChartSectionData(
                        value: item.value.toDouble(),
                        color: _parseColor(item.color),
                        radius: 25, // Thicker ring
                        showTitle: false,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 90,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: FleetColors.gray900,
                        ),
                      ),
                      const Text(
                        'Total Jobs',
                        style: TextStyle(
                          color: FleetColors.gray600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(context, data[0]), // In Progress
                    const SizedBox(height: 12),
                    _buildLegendItem(context, data[2]), // Completed (Assuming index matches design order preference, though data order matters)
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(context, data[1]), // Pending Diagnosis
                    const SizedBox(height: 12),
                    _buildLegendItem(context, data[3]), // On-Hold
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, ServicePipelineData item) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _parseColor(item.color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.name,
          style: const TextStyle(
            color: FleetColors.gray600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          '${item.value}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: FleetColors.gray900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }


  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
  }
}
