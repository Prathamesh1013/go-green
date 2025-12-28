import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final String currentRoute;

  const BottomNav({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard,
                label: 'Dashboard',
                route: '/dashboard',
                isActive: currentRoute == '/dashboard',
              ),
              _NavItem(
                icon: Icons.directions_car,
                label: 'CoreVehicles',
                route: '/coreVehicles',
                isActive: currentRoute == '/coreVehicles' || currentRoute.startsWith('/coreVehicles/'),
              ),
              _NavItem(
                icon: Icons.build,
                label: 'Jobs',
                route: '/jobs',
                isActive: currentRoute == '/jobs' || currentRoute.startsWith('/jobs/'),
              ),
              _NavItem(
                icon: Icons.analytics,
                label: 'Analytics',
                route: '/analytics',
                isActive: currentRoute == '/analytics' || currentRoute.startsWith('/analytics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





