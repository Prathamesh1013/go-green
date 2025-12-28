import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/status_badge.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/providers/job_provider.dart';
import 'package:gogreen_admin/models/compliance.dart';
import 'package:gogreen_admin/models/charging_session.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:intl/intl.dart';

class CoreVehicleDetailPage extends StatefulWidget {
  final String vehicleId;

  const CoreVehicleDetailPage({
    super.key,
    required this.vehicleId,
  });

  @override
  State<CoreVehicleDetailPage> createState() => _CoreVehicleDetailPageState();
}

class _CoreVehicleDetailPageState extends State<CoreVehicleDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  List<ChargingSession> _chargingSessions = [];
  bool _loadingCharging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoreVehicleProvider>().loadCoreVehicles();
      context.read<JobProvider>().loadJobs(vehicleId: widget.vehicleId);
      _loadChargingSessions();
    });
  }

  Future<void> _loadChargingSessions() async {
    setState(() => _loadingCharging = true);
    try {
      final data = await _supabaseService.getChargingSessions(widget.vehicleId, limit: 10);
      setState(() {
        _chargingSessions = data.map((json) => ChargingSession.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Error loading charging sessions: $e');
    } finally {
      setState(() => _loadingCharging = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/coreVehicles',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/coreVehicles'),
          ),
          title: Consumer<CoreVehicleProvider>(
            builder: (context, provider, _) {
              if (provider.coreVehicles.isEmpty) {
                return const Text('CoreVehicle Details');
              }
              final vehicle = provider.coreVehicles.firstWhere(
                (v) => v.vehicleId == widget.vehicleId,
                orElse: () => provider.coreVehicles.first,
              );
              return Text(vehicle.vehicleNumber);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.go('/coreVehicles/${widget.vehicleId}/edit');
              },
              tooltip: 'Edit CoreVehicle',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Charging'),
              Tab(text: 'Jobs'),
              Tab(text: 'Compliance'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Consumer<CoreVehicleProvider>(
          builder: (context, vehicleProvider, _) {
            if (vehicleProvider.isLoading || vehicleProvider.coreVehicles.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicle = vehicleProvider.coreVehicles.firstWhere(
              (v) => v.vehicleId == widget.vehicleId,
              orElse: () => vehicleProvider.coreVehicles.first,
            );

            return TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(vehicle: vehicle),
                _ChargingTab(
                  vehicleId: widget.vehicleId,
                  vehicle: vehicle,
                  sessions: _chargingSessions,
                  loading: _loadingCharging,
                ),
                _JobsTab(vehicleId: widget.vehicleId),
                _ComplianceTab(vehicleId: widget.vehicleId),
                _HistoryTab(vehicleId: widget.vehicleId),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final dynamic vehicle;

  const _OverviewTab({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1000;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildCoreVehicleHeader(context),
                          const SizedBox(height: 20),
                          _buildKeyMetrics(context),
                          const SizedBox(height: 20),
                          _buildHubInfo(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildCoreVehicleDetails(context),
                          const SizedBox(height: 20),
                          _buildUsageStats(context),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildCoreVehicleHeader(context),
                    const SizedBox(height: 20),
                    _buildKeyMetrics(context),
                    const SizedBox(height: 20),
                    _buildCoreVehicleDetails(context),
                    const SizedBox(height: 20),
                    _buildUsageStats(context),
                    const SizedBox(height: 20),
                    _buildHubInfo(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCoreVehicleHeader(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getPrimary(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: AppColors.getPrimary(context),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.vehicleNumber,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (vehicle.displayName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  vehicle.displayName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: vehicle.status),
                  if (vehicle.healthState != null) ...[
                    const SizedBox(height: 8),
                    StatusBadge(
                      status: vehicle.healthState!,
                      isHealthState: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _MetricTile(
                icon: Icons.speed,
                label: 'Odometer',
                value: vehicle.odometerCurrent != null
                    ? '${NumberFormat('#,###').format(vehicle.odometerCurrent)} km'
                    : 'N/A',
                color: AppColors.getPrimary(context),
              ),
              _MetricTile(
                icon: Icons.trending_up,
                label: 'Avg KM/Day',
                value: vehicle.avgKmPerDay != null
                    ? '${vehicle.avgKmPerDay!.toStringAsFixed(1)}'
                    : 'N/A',
                color: AppColors.getHealthy(context),
              ),
              _MetricTile(
                icon: Icons.access_time,
                label: 'Downtime',
                value: vehicle.totalDowntimeDays != null && vehicle.totalDowntimeDays! > 0
                    ? '${vehicle.totalDowntimeDays} days'
                    : '0 days',
                color: vehicle.totalDowntimeDays != null && vehicle.totalDowntimeDays! > 0
                    ? AppColors.getAttention(context)
                    : AppColors.getHealthy(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoreVehicleDetails(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CoreVehicle Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _DetailItem(
                icon: Icons.local_gas_station,
                label: 'Fuel Type',
                value: vehicle.fuelType ?? 'N/A',
              ),
              _DetailItem(
                icon: Icons.calendar_today,
                label: 'Year',
                value: vehicle.yearOfManufacture?.toString() ?? 'N/A',
              ),
              _DetailItem(
                icon: Icons.business,
                label: 'Owner Type',
                value: vehicle.ownerType?.replaceAll('_', ' ').toUpperCase() ?? 'N/A',
              ),
              _DetailItem(
                icon: Icons.satellite_alt,
                label: 'Telematics ID',
                value: vehicle.telematicsId ?? 'N/A',
              ),
              if (vehicle.variant != null)
                _DetailItem(
                  icon: Icons.category,
                  label: 'Variant',
                  value: vehicle.variant!,
                ),
              _DetailItem(
                icon: Icons.date_range,
                label: 'Last Active',
                value: vehicle.lastActiveDate != null
                    ? DateFormat('MMM dd, yyyy').format(vehicle.lastActiveDate!)
                    : 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Usage Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_car,
                  label: 'Avg Trips/Day',
                  value: vehicle.avgTripsPerDay != null
                      ? vehicle.avgTripsPerDay!.toStringAsFixed(1)
                      : 'N/A',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Last Trip',
                  value: vehicle.lastTripDate != null
                      ? DateFormat('MMM dd').format(vehicle.lastTripDate!)
                      : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHubInfo(BuildContext context) {
    if (vehicle.hub == null) return const SizedBox.shrink();
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Primary Hub',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getPrimary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store,
                  color: AppColors.getPrimary(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.hub!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (vehicle.hub!.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicle.hub!.location,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.getPrimary(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.getPrimary(context), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChargingTab extends StatelessWidget {
  final String vehicleId;
  final dynamic vehicle;
  final List<ChargingSession> sessions;
  final bool loading;

  const _ChargingTab({
    required this.vehicleId,
    required this.vehicle,
    required this.sessions,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicle.fuelType != 'EV') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electric_car,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'This vehicle is not an EV',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Charging data is only available for electric coreVehicles',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChargingStats(context),
          const SizedBox(height: 20),
          _buildChargingHistory(context),
        ],
      ),
    );
  }

  Widget _buildChargingStats(BuildContext context) {
    if (sessions.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.battery_charging_full,
                size: 48,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No charging data available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final totalEnergy = sessions
        .where((s) => s.energyKwh != null)
        .fold<double>(0, (sum, s) => sum + (s.energyKwh ?? 0));
    final totalCost = sessions
        .where((s) => s.cost != null)
        .fold<double>(0, (sum, s) => sum + (s.cost ?? 0));
    final recentSession = sessions.isNotEmpty ? sessions.first : null;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.battery_charging_full,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Charging Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _MetricTile(
                icon: Icons.flash_on,
                label: 'Total Energy',
                value: '${totalEnergy.toStringAsFixed(1)} kWh',
                color: AppColors.getPrimary(context),
              ),
              _MetricTile(
                icon: Icons.attach_money,
                label: 'Total Cost',
                value: totalCost > 0 ? '₹${totalCost.toStringAsFixed(0)}' : 'N/A',
                color: AppColors.getHealthy(context),
              ),
              _MetricTile(
                icon: Icons.electric_car,
                label: 'Sessions',
                value: '${sessions.length}',
                color: AppColors.getAttention(context),
              ),
            ],
          ),
          if (recentSession != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.getPrimary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Charge',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM dd, yyyy • HH:mm').format(recentSession.startTime)} • ${recentSession.displayDuration}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChargingHistory(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.getPrimary(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Charging Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sessions.take(10).map((session) => _ChargingSessionItem(session: session)),
        ],
      ),
    );
  }
}

class _ChargingSessionItem extends StatelessWidget {
  final ChargingSession session;

  const _ChargingSessionItem({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.getPrimary(context).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.battery_charging_full,
              color: AppColors.getPrimary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(session.startTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (session.energyKwh != null) ...[
                      Icon(Icons.flash_on, size: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${session.energyKwh!.toStringAsFixed(1)} kWh',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Icons.access_time, size: 14, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      session.displayDuration,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (session.sessionType != null) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.getPrimary(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.displaySessionType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.getPrimary(context),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (session.chargeLevelStart != null && session.chargeLevelEnd != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.chargeLevelStart}% → ${session.chargeLevelEnd}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Battery',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  final String vehicleId;

  const _JobsTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = provider.jobs.where((j) => j.vehicleId == vehicleId).toList();

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 64, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No maintenance jobs',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Create Job'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.getStatusColor(job.status, context).withOpacity(0.1),
                  child: Icon(
                    Icons.build,
                    color: AppColors.getStatusColor(job.status, context),
                  ),
                ),
                title: Text(job.displayJobType),
                subtitle: Text(
                  '${job.jobCategory} • ${DateFormat('MMM dd, yyyy').format(job.diagnosisDate)}',
                ),
                trailing: StatusBadge(status: job.status, isJobStatus: true),
                onTap: () {
                  context.go('/jobs/${job.jobId}');
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ComplianceTab extends StatelessWidget {
  final String vehicleId;

  const _ComplianceTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ComplianceDocument>>(
      future: SupabaseService().getComplianceDocuments(vehicleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final complianceDocs = snapshot.data ?? [];

        if (complianceDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No compliance documents',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complianceDocs.length,
          itemBuilder: (context, index) {
            final doc = complianceDocs[index];
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: doc.status == 'expired'
                      ? AppColors.getCritical(context).withOpacity(0.1)
                      : doc.status == 'expiring_soon'
                          ? AppColors.getAttention(context).withOpacity(0.1)
                          : AppColors.getHealthy(context).withOpacity(0.1),
                  child: Icon(
                    Icons.description,
                    color: doc.status == 'expired'
                        ? AppColors.getCritical(context)
                        : doc.status == 'expiring_soon'
                            ? AppColors.getAttention(context)
                            : AppColors.getHealthy(context),
                  ),
                ),
                title: Text(doc.displayDocType),
                subtitle: Text(
                  doc.expiryDate != null
                      ? 'Expires: ${DateFormat('MMM dd, yyyy').format(doc.expiryDate!)}'
                      : 'No expiry date',
                ),
                trailing: StatusBadge(status: doc.status),
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String vehicleId;

  const _HistoryTab({required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
          const SizedBox(height: 16),
          Text(
            'History Timeline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
