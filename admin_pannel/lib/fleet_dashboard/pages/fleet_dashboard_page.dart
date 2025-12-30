import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/top_nav.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/kpi_card.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/service_pipeline.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/job_completion_chart.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/jobs_table.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/cost_trends.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/cost_breakdown.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/energy_vs_service.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/cost_per_km_gauge.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/action_recommendations.dart';
import 'package:gogreen_admin/fleet_dashboard/widgets/dashboard/vehicle_tracking.dart';
import 'package:gogreen_admin/fleet_dashboard/theme/app_colors.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/providers/job_provider.dart';
import 'package:gogreen_admin/providers/analytics_provider.dart';
import 'package:gogreen_admin/models/vehicle.dart' as core_models;
import 'package:gogreen_admin/fleet_dashboard/models/vehicle.dart' as dashboard_models;
import 'package:gogreen_admin/fleet_dashboard/models/driver_details.dart';

class FleetDashboardPage extends StatefulWidget {
  const FleetDashboardPage({super.key});

  @override
  State<FleetDashboardPage> createState() => _FleetDashboardPageState();
}

class _FleetDashboardPageState extends State<FleetDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Initialize data fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
      context.read<JobProvider>().loadJobs();
      context.read<AnalyticsProvider>().loadAnalyticsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: FleetColors.backgroundGray,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              const SliverToBoxAdapter(
                child: TopNav(),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(text: 'Dashboard Overview'),
                      Tab(text: 'Vehicle Tracking'),
                      Tab(text: 'Job Operations'),
                      Tab(text: 'Cost Analytics'),
                      Tab(text: 'Benchmarking'),
                    ],
                    labelColor: FleetColors.textPrimary,
                    unselectedLabelColor: FleetColors.textTertiary,
                    indicatorColor: FleetColors.primary,
                  ),
                ),
              ),
            ];
          },
          body: Consumer3<AnalyticsProvider, VehicleProvider, JobProvider>(
            builder: (context, analytics, vehicleProv, jobProv, child) {
              if (analytics.isLoading || vehicleProv.isLoading || jobProv.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (analytics.error != null) {
                return Center(child: Text('Error: ${analytics.error}'));
              }

              return TabBarView(
                children: [
                  _buildDashboardOverview(analytics),
                  _buildVehicleTracking(vehicleProv),
                  _buildJobOperations(jobProv),
                  _buildCostAnalytics(analytics),
                  _buildBenchmarking(analytics),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(AnalyticsProvider analytics) {
    final kpis = analytics.fleetKPIs;
    if (kpis == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          children: [
            // KPI Cards
            Row(
              children: [
                Expanded(
                  child: KPICard(
                    title: 'Active Vehicles',
                    value: '${kpis.activeVehicles.total}',
                    subtext: '${kpis.activeVehicles.evPercentage.toStringAsFixed(1)}% EV (${kpis.activeVehicles.ev}), ${ (100 - kpis.activeVehicles.evPercentage).toStringAsFixed(1)}% ICE (${kpis.activeVehicles.ice})',
                    icon: Icons.local_shipping,
                    iconBgColor: FleetColors.blue100,
                    iconColor: FleetColors.blue600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Jobs in Progress',
                    value: '${kpis.jobsInProgress.count}',
                    icon: Icons.electric_bolt,
                    iconBgColor: FleetColors.green100,
                    iconColor: FleetColors.green600,
                    status: kpis.jobsInProgress.status,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Avg Cost per KM',
                    value: '\$${kpis.avgCostPerKm.value}',
                    subtext: 'Fleet avg: \$${kpis.avgCostPerKm.fleetAvg}',
                    icon: Icons.attach_money,
                    iconBgColor: FleetColors.purple100,
                    iconColor: FleetColors.purple600,
                    trend: {
                      'value': kpis.avgCostPerKm.delta.abs(),
                      'direction': kpis.avgCostPerKm.delta < 0 ? 'down' : 'up',
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KPICard(
                    title: 'Avg Job Completion Time',
                    value: '${kpis.avgJobCompletionTime.hours}h',
                    icon: Icons.access_time,
                    iconBgColor: FleetColors.orange100,
                    iconColor: FleetColors.orange600,
                    trend: {
                      'value': kpis.avgJobCompletionTime.delta.abs(),
                      'direction': kpis.avgJobCompletionTime.trend == 'down' ? 'down' : 'up',
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Service Pipeline & Job Completion
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: ServicePipeline(data: analytics.servicePipeline),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 7,
                  child: JobCompletionChart(
                    evData: analytics.jobCompletionTimes['ev'] ?? [],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTracking(VehicleProvider provider) {
    // Map Vehicle to Dashboard Vehicle
    final mappedVehicles = provider.vehicles.map((v) {
      final coreV = v;
      return dashboard_models.Vehicle(
        id: coreV.vehicleNumber,
        databaseId: coreV.vehicleId,
        type: coreV.fuelType?.toUpperCase() == 'EV' 
            ? dashboard_models.VehicleType.EV 
            : dashboard_models.VehicleType.ICE,
        model: coreV.model ?? 'Unknown',
        status: _mapStatus(coreV.status),
        location: dashboard_models.Location(lat: 0, lng: 0, address: coreV.hubName), // Dummy location
        odometer: coreV.odometerCurrent ?? 0,
        nextMaintenanceKm: 50000, // Placeholder
        healthScore: coreV.healthState == 'healthy' ? 95 : 70,
        alerts: [],
        costPerKm: 2.45,
        avgSpeed: 45,
        idleTime: 12,
        rsaEvents: [],
        driver: coreV.driverName != null ? DriverDetails(
          name: coreV.driverName!,
          phone: coreV.driverPhone ?? '',
          licenseNumber: coreV.driverLicense ?? '',
          rating: 4.5,
          totalTrips: 120,
          imageUrl: 'https://i.pravatar.cc/150?u=${coreV.vehicleId}',
          drivingScore: 88,
          currentMonthTrips: 15,
          drivingHours: 160,
        ) : null,
        // Map Mobile App Sync Fields
        isVehicleIn: coreV.isVehicleIn,
        toDos: coreV.toDos,
        lastServiceDate: coreV.lastServiceDate,
        lastServiceType: coreV.lastServiceType,
        serviceAttention: coreV.serviceAttention,
        lastChargeType: coreV.lastChargeType,
        chargingHealth: coreV.chargingHealth,
        dailyChecks: coreV.dailyChecks,
        inventoryPhotoCount: coreV.inventoryPhotoCount,
        lastInventoryTime: coreV.lastInventoryTime,
        lastFullScan: coreV.lastFullScan,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: VehicleTracking(vehicles: mappedVehicles),
    );
  }

  dashboard_models.VehicleStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active': return dashboard_models.VehicleStatus.active;
      case 'charging': return dashboard_models.VehicleStatus.charging;
      case 'maintenance': return dashboard_models.VehicleStatus.maintenance;
      case 'idle': return dashboard_models.VehicleStatus.idle;
      default: return dashboard_models.VehicleStatus.active;
    }
  }

  Widget _buildJobOperations(JobProvider provider) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              children: [
                JobsTable(jobs: analytics.jobsByCategory),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCostAnalytics(AnalyticsProvider analytics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          children: [
            CostTrends(data: analytics.costTrends),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CostBreakdownChart(data: analytics.costBreakdown)),
                const SizedBox(width: 24),
                Expanded(child: EnergyVsServiceChart(data: analytics.energyVsService)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchmarking(AnalyticsProvider analytics) {
    if (analytics.costBenchmark == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: CostPerKmGauge(benchmark: analytics.costBenchmark!)),
            const SizedBox(width: 24),
            Expanded(child: ActionRecommendations(recommendations: analytics.recommendations)),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: FleetColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
