import 'package:flutter/material.dart';
import '../../models/driver_details.dart';
import '../../theme/app_colors.dart';

class DriverSummaryCard extends StatelessWidget {
  final DriverDetails driver;

  const DriverSummaryCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Driver Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: FleetColors.gray900),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(driver.imageUrl),
                backgroundColor: FleetColors.primary,
                child: driver.imageUrl.isEmpty ? Text(driver.name[0], style: const TextStyle(color: Colors.white)) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FleetColors.gray900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${driver.licenseNumber} • Rating: ${driver.rating} ★',
                      style: const TextStyle(fontSize: 13, color: FleetColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Driver Score', style: TextStyle(fontSize: 14, color: FleetColors.gray600)),
              Text(
                '${driver.drivingScore}/100',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FleetColors.green600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: driver.drivingScore / 100,
              backgroundColor: FleetColors.gray200,
              valueColor: const AlwaysStoppedAnimation(FleetColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(Icons.map, 'This Month', '${driver.currentMonthTrips} trips'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniStat(Icons.access_time, 'Driving Hours', '${driver.drivingHours}h'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FleetColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: FleetColors.gray500),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: FleetColors.gray500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FleetColors.gray900),
          ),
        ],
      ),
    );
  }
}
