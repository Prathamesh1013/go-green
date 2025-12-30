import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isHealthState;
  final bool isJobStatus;

  const StatusBadge({
    super.key,
    required this.status,
    this.isHealthState = false,
    this.isJobStatus = false,
  });

  Color _getStatusColor(BuildContext context) {
    if (isHealthState) {
      switch (status.toLowerCase()) {
        case 'healthy':
          return AppColors.getHealthy(context);
        case 'attention':
          return AppColors.getAttention(context);
        case 'critical':
          return AppColors.getCritical(context);
        default:
          return Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary;
      }
    } else if (isJobStatus) {
      return AppColors.getStatusColor(status, context);
    } else {
      return AppColors.getVehicleStatusColor(status, context);
    }
  }

  String _getDisplayText() {
    return status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getDisplayText(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


