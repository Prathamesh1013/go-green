import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../models/vehicle.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load vehicles when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (provider.vehicles.isEmpty && !provider.isLoadingVehicles) {
        provider.loadVehicles();
      }
    });
  }

  Future<void> _onRefresh() async {
    await context.read<AppProvider>().refreshVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vehicles = provider.vehicles;
    final isLoading = provider.isLoadingVehicles;
    final error = provider.vehiclesError;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            color: AppTheme.primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Vehicles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  vehicles.isEmpty && !isLoading 
                      ? 'No vehicles assigned' 
                      : 'Manage your daily tasks',
                  style: const TextStyle(fontSize: 14, color: Color(0xFFDBEAFE)),
                ),
              ],
            ),
          ),
          Expanded(
            child: error != null
                ? _ErrorView(error: error, onRetry: _onRefresh)
                : isLoading && vehicles.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : vehicles.isEmpty
                        ? _EmptyView(onRefresh: _onRefresh)
                        : RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: vehicles.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _VehicleCard(vehicle: vehicles[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.car, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No vehicles assigned', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.pending: return Colors.orange;
      case VehicleStatus.inProgress: return Colors.blue;
      case VehicleStatus.completed: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/vehicle/${vehicle.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: const Icon(LucideIcons.car, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.vehicleNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(vehicle.customerName, style: const TextStyle(fontSize: 14, color: AppTheme.textLight)),
                    const SizedBox(height: 2),
                    Text(vehicle.serviceType, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(vehicle.status).withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(vehicle.status).withAlpha(50)),
                      ),
                      child: Text(vehicle.statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(vehicle.status))),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
