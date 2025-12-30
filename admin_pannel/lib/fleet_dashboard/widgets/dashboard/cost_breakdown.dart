import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ui/custom_card.dart';
import '../../models/kpi.dart';
import '../../theme/app_colors.dart';

class CostBreakdownChart extends StatelessWidget {
  final List<CostBreakdown> data;

  const CostBreakdownChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost Breakdown (EV vs ICE)', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(toY: entry.value.ev.toDouble(), color: FleetColors.green600, width: 16),
                      BarChartRodData(toY: entry.value.ice.toDouble(), color: FleetColors.gray600, width: 16),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(data[index].category, style: const TextStyle(fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
