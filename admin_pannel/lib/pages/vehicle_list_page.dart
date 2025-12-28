import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/status_badge.dart';
import 'package:gogreen_admin/widgets/loading_skeleton.dart';
import 'package:gogreen_admin/widgets/empty_state.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:intl/intl.dart';

class CoreVehicleListPage extends StatefulWidget {
  const CoreVehicleListPage({super.key});

  @override
  State<CoreVehicleListPage> createState() => _CoreVehicleListPageState();
}

class _CoreVehicleListPageState extends State<CoreVehicleListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoreVehicleProvider>().loadCoreVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/coreVehicles',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CoreVehicle Fleet'),
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.go('/coreVehicles/new');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filters
            _buildSearchAndFilters(),
            
            // CoreVehicle List/Table
            Expanded(
              child: Consumer<CoreVehicleProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingState();
                  }

                  final coreVehicles = provider.filteredCoreVehicles;

                  if (coreVehicles.isEmpty) {
                    return EmptyState(
                      icon: Icons.directions_car,
                      title: 'No coreVehicles found',
                      message: provider.searchQuery.isNotEmpty
                          ? 'Try adjusting your search or filters'
                          : 'Add your first vehicle to get started',
                      action: ElevatedButton.icon(
                        onPressed: () {
                          context.go('/coreVehicles/new');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add CoreVehicle'),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 1024) {
                        return _buildDataTable(coreVehicles);
                      } else {
                        return _buildCardList(coreVehicles);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<CoreVehicleProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by vehicle number, make, or model...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  provider.setSearchQuery(value);
                },
              ),
              
              // Filters
              if (_showFilters) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FilterChip(
                      label: 'Status',
                      value: provider.statusFilter,
                      options: const ['active', 'inactive', 'scrapped', 'trial'],
                      onSelected: (value) {
                        provider.setStatusFilter(value);
                      },
                    ),
                    _FilterChip(
                      label: 'Health',
                      value: provider.healthStateFilter,
                      options: const ['healthy', 'attention', 'critical'],
                      onSelected: (value) {
                        provider.setHealthStateFilter(value);
                      },
                    ),
                    if (provider.statusFilter != null ||
                        provider.healthStateFilter != null ||
                        provider.hubFilter != null)
                      ActionChip(
                        label: const Text('Clear Filters'),
                        onPressed: () {
                          provider.clearFilters();
                        },
                        avatar: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingSkeleton(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(List<CoreVehicle> coreVehicles) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text('CoreVehicle Number')),
            DataColumn(label: Text('Make/Model')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Health')),
            DataColumn(label: Text('Odometer')),
            DataColumn(label: Text('Actions')),
          ],
          rows: coreVehicles.map((vehicle) {
            return DataRow(
              cells: [
                DataCell(Text(vehicle.vehicleNumber)),
                DataCell(Text(vehicle.displayName)),
                DataCell(StatusBadge(status: vehicle.status)),
                DataCell(
                  vehicle.healthState != null
                      ? StatusBadge(
                          status: vehicle.healthState!,
                          isHealthState: true,
                        )
                      : const Text('-'),
                ),
                DataCell(
                  Text(
                    vehicle.odometerCurrent != null
                        ? '${NumberFormat('#,###').format(vehicle.odometerCurrent)} km'
                        : '-',
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      context.go('/coreVehicles/${vehicle.vehicleId}');
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardList(List<CoreVehicle> coreVehicles) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coreVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = coreVehicles[index];
        return _CoreVehicleCard(vehicle: vehicle);
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final Function(String?) onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: value != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value != null
                ? AppColors.primary
                : AppColors.gray300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${value ?? 'All'}',
              style: TextStyle(
                color: value != null ? AppColors.primary : null,
                fontWeight: value != null ? FontWeight.w600 : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: value != null ? AppColors.primary : null,
            ),
          ],
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('All $label'),
        ),
        ...options.map((option) => PopupMenuItem(
              value: option,
              child: Text(option.split('_').map((word) =>
                word[0].toUpperCase() + word.substring(1)
              ).join(' ')),
            )),
      ],
    );
  }
}

class _CoreVehicleCard extends StatelessWidget {
  final CoreVehicle vehicle;

  const _CoreVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.go('/coreVehicles/${vehicle.vehicleId}');
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text(
                          vehicle.vehicleNumber,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        if (vehicle.displayName.isNotEmpty)
                          Text(
                            vehicle.displayName,
                            style: Theme.of(context).textTheme.bodyMedium,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  if (vehicle.odometerCurrent != null)
                    _InfoChip(
                      icon: Icons.speed,
                      label: '${NumberFormat('#,###').format(vehicle.odometerCurrent)} km',
                    ),
                  if (vehicle.avgKmPerDay != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.trending_up,
                      label: '${vehicle.avgKmPerDay!.toStringAsFixed(1)} km/day',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

