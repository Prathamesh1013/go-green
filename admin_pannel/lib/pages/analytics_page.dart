import 'package:flutter/material.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import '../fleet_dashboard/pages/fleet_dashboard_page.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      currentRoute: '/analytics',
      child: FleetDashboardPage(),
    );
  }
}
