import 'package:flutter/material.dart';
import '../ui/custom_card.dart';
import '../../models/kpi.dart';
import '../../theme/app_colors.dart';

class CostPerKmGauge extends StatelessWidget {
  final CostPerKmBenchmark benchmark;

  const CostPerKmGauge({super.key, required this.benchmark});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost per KM Benchmark', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '\$${benchmark.current}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FleetColors.gray900),
                ),
                const Text('Current Cost/KM', style: TextStyle(color: FleetColors.gray600)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('Fleet Avg', '\$${benchmark.fleetAvg}', FleetColors.blue600),
                    _buildMetric('Optimal', '\$${benchmark.optimal}', FleetColors.green600),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Vehicle ID', benchmark.vehicleId),
                _buildInfoRow('Route Type', benchmark.routeType),
                _buildInfoRow('Load Factor', '${(benchmark.loadFactor * 100).toInt()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: FleetColors.gray600)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ', style: const TextStyle(color: FleetColors.gray600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: FleetColors.gray900)),
        ],
      ),
    );
  }
}
