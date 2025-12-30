import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/pages/dashboard_page.dart';
import 'package:gogreen_admin/pages/analytics_page.dart';
import 'package:gogreen_admin/pages/vehicle_list_page_v2.dart';
import 'package:gogreen_admin/pages/vehicle_detail_page.dart';
import 'package:gogreen_admin/pages/vehicle_form_page.dart';
import 'package:gogreen_admin/pages/job_management_page.dart';
import 'package:gogreen_admin/pages/interaction_detail_page.dart';
import 'package:gogreen_admin/pages/compliance_dashboard_page.dart';
import 'package:gogreen_admin/pages/hub_performance_page.dart';
import 'package:gogreen_admin/pages/service_details_page.dart';

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
        path: '/coreVehicles',
        name: 'vehicles',
        builder: (context, state) => const CoreVehicleListPageV2(), // Using new design
      ),
      GoRoute(
        path: '/coreVehicles/new',
        name: 'vehicle-new',
        builder: (context, state) => const CoreVehicleFormPage(),
      ),
      GoRoute(
        path: '/coreVehicles/:id',
        name: 'vehicle-detail',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return CoreVehicleDetailPage(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/coreVehicles/:id/edit',
        name: 'vehicle-edit',
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return CoreVehicleFormPage(vehicleId: vehicleId);
        },
      ),
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        builder: (context, state) => const JobManagementPage(),
      ),
      GoRoute(
        path: '/jobs/:id',
        name: 'job-detail',
        builder: (context, state) {
          final jobId = state.pathParameters['id']!;
          return JobManagementPage(jobId: jobId);
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
    ],
  );
}

