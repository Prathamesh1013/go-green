import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';

class BatteryChargingCard extends StatelessWidget {
  final Vehicle vehicle;

  const BatteryChargingCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    if (vehicle.type != VehicleType.EV) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Battery & Charging',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: FleetColors.gray900),
              ),
              Row(
                children: [
                  const Icon(Icons.battery_charging_full, size: 16, color: FleetColors.green600),
                  const SizedBox(width: 4),
                  Text(
                    '${vehicle.batteryLevel?.toInt()}%',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FleetColors.green600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetric('Range', '${vehicle.evRange} km', Icons.bolt)),
              Expanded(child: _buildMetric('Efficiency', '${vehicle.efficiency} km/kWh', Icons.trending_up)),
              Expanded(child: _buildMetric('Last Charged', '${vehicle.lastCharged}', Icons.access_time)),
              Expanded(child: _buildMetric('Health', '${vehicle.batteryHealth}%', Icons.show_chart)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 25,
                  verticalInterval: 2,
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 12,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 45),
                      FlSpot(2, 55),
                      FlSpot(4, 70),
                      FlSpot(6, 85),
                      FlSpot(8, 95),
                      FlSpot(10, 80),
                      FlSpot(12, 65),
                    ],
                    isCurved: true,
                    color: FleetColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: FleetColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:00', style: TextStyle(fontSize: 10, color: FleetColors.gray500)),
              Text('06:00', style: TextStyle(fontSize: 10, color: FleetColors.gray500)),
              Text('12:00', style: TextStyle(fontSize: 10, color: FleetColors.gray500)),
              Text('18:00', style: TextStyle(fontSize: 10, color: FleetColors.gray500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: FleetColors.gray400),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: FleetColors.gray500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FleetColors.gray900),
        ),
      ],
    );
  }
}
