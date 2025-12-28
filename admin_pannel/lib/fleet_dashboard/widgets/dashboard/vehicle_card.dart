import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../models/alert.dart';
import '../../theme/app_colors.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final bool isSelected;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FleetColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? FleetColors.blue500 : FleetColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: FleetColors.blue500.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vehicle.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FleetColors.gray900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: vehicle.type == VehicleType.EV ? FleetColors.green50 : FleetColors.blue50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehicle.type.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: vehicle.type == VehicleType.EV ? FleetColors.green600 : FleetColors.blue600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.model,
                      style: const TextStyle(fontSize: 13, color: FleetColors.gray500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(vehicle.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vehicle.status.name.substring(0, 1).toUpperCase() + vehicle.status.name.substring(1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusTextColor(vehicle.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Battery/Fuel Level
            if (vehicle.batteryLevel != null)
              _buildLevelIndicator(
                'Battery',
                vehicle.batteryLevel!,
                Icons.battery_full,
                FleetColors.green500,
              )
            else if (vehicle.fuelLevel != null)
              _buildLevelIndicator(
                'Fuel',
                vehicle.fuelLevel!,
                Icons.local_gas_station,
                FleetColors.blue500,
              ),
            
            const SizedBox(height: 12),
            
            // Location & Driver
            _buildInfoRow(Icons.location_on, vehicle.location.address),
            const SizedBox(height: 6),
            if (vehicle.driver != null)
              _buildInfoRow(Icons.person, vehicle.driver!.name),
            
            // Current Job
            if (vehicle.currentJob != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FleetColors.blue50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${vehicle.currentJob!.type} - ${vehicle.currentJob!.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: FleetColors.blue700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'ETA: ${vehicle.currentJob!.eta}',
                          style: const TextStyle(fontSize: 11, color: FleetColors.blue600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: vehicle.currentJob!.progress / 100,
                        backgroundColor: FleetColors.blue200,
                        valueColor: const AlwaysStoppedAnimation(FleetColors.blue600),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Metrics Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(
                  'Health',
                  '${vehicle.healthScore}%',
                  Icons.speed,
                  _getHealthScoreColor(vehicle.healthScore),
                ),
                _buildMetric(
                  'Cost/km',
                  '\$${vehicle.costPerKm}',
                  Icons.trending_up,
                  FleetColors.gray900,
                ),
                _buildMetric(
                  'Service',
                  '${_formatNumber(vehicle.kmToMaintenance)} km',
                  Icons.build,
                  FleetColors.gray900,
                ),
              ],
            ),
            
            // Alerts
            if (vehicle.alerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...vehicle.alerts.take(1).map((alert) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FleetColors.blue50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 14, color: FleetColors.blue600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.message,
                        style: const TextStyle(fontSize: 11, color: FleetColors.blue700, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: FleetColors.gray400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: FleetColors.gray600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelIndicator(String label, double level, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: FleetColors.gray600)),
            const Spacer(),
            Text(
              '${level.toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FleetColors.gray900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: level / 100,
            backgroundColor: FleetColors.gray200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color valueColor) {
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Color _getStatusBgColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return const Color(0xFFDCFCE7); // green-100
      case VehicleStatus.idle: return const Color(0xFFF3F4F6); // gray-100
      case VehicleStatus.charging: return const Color(0xFFDBEAFE); // blue-100
      case VehicleStatus.maintenance: return const Color(0xFFFFEDD5); // orange-100
    }
  }

  Color _getStatusTextColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return const Color(0xFF15803D); // green-700
      case VehicleStatus.idle: return const Color(0xFF374151); // gray-700
      case VehicleStatus.charging: return const Color(0xFF1D4ED8); // blue-700
      case VehicleStatus.maintenance: return const Color(0xFFC2410C); // orange-700
    }
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 90) return FleetColors.green600;
    if (score >= 75) return FleetColors.yellow600;
    return FleetColors.red600;
  }
}
