import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/pages/dashboard_page.dart';
import 'package:gogreen_admin/pages/analytics_page.dart';
import 'package:gogreen_admin/pages/vehicle_list_page_v2.dart';
import 'package:gogreen_admin/pages/vehicle_detail_page.dart';
import 'package:gogreen_admin/pages/vehicle_form_page.dart';
import 'package:gogreen_admin/pages/interaction_detail_page.dart';
import 'package:gogreen_admin/pages/compliance_dashboard_page.dart';
import 'package:gogreen_admin/pages/hub_performance_page.dart';
import 'package:gogreen_admin/pages/service_details_page.dart';
import 'package:gogreen_admin/pages/settings_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/vehicles',
        name: 'vehicles',
        builder: (context, state) => const VehicleListPageV2(), // Using new design
      ),
      GoRoute(
        path: '/vehicles/new',
        name: 'vehicle-new',
        builder: (context, state) => const VehicleFormPage(),
      ),
      GoRoute(
        path: '/vehicles/:id',
        name: 'vehicle-detail',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return VehicleDetailPage(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        name: 'vehicle-edit',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return VehicleFormPage(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(), // Empty analytics page
      ),
      GoRoute(
        path: '/compliance',
        name: 'compliance',
        builder: (context, state) => const ComplianceDashboardPage(), // Compliance content moved here
      ),
      GoRoute(
        path: '/hub-performance',
        name: 'hub-performance',
        builder: (context, state) => const HubPerformancePage(),
      ),
      GoRoute(
        path: '/interactions/:id',
        name: 'interaction-detail',
        builder: (context, state) {
          final interactionId = state.pathParameters['id']!;
          return InteractionDetailPage(interactionId: interactionId);
        },
      ),
      GoRoute(
        path: '/service-details/:id',
        name: 'service-detail',
        builder: (context, state) {
          final serviceId = state.pathParameters['id']!;
          return ServiceDetailsPage(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

