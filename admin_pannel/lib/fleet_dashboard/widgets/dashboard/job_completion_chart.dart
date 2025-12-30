import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ui/custom_card.dart';
import '../../models/job.dart';
import '../../theme/app_colors.dart';

class JobCompletionChart extends StatelessWidget {
  final List<JobCompletionTime> evData;

  const JobCompletionChart({
    super.key,
    required this.evData,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job Completion Time by Category (EV Only)',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < evData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              evData[index].category,
                              style: const TextStyle(fontSize: 12, color: FleetColors.gray600),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12, color: FleetColors.gray600),
                        );
                      },
                    ),
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Hours', style: TextStyle(fontSize: 12, color: FleetColors.gray600)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  verticalInterval: 1,
                  getDrawingVerticalLine: (value) {
                     return const FlLine(
                      color: FleetColors.gray100,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: FleetColors.gray200,
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: FleetColors.gray300),
                    bottom: BorderSide(color: FleetColors.gray300),
                  ),
                ),
                barGroups: _getBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    return List.generate(evData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: evData[index].time,
            color: FleetColors.green600,
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }
}
