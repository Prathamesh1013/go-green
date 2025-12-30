import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VehicleListPageV2 extends StatefulWidget {
  const VehicleListPageV2({super.key});

  @override
  State<VehicleListPageV2> createState() => _VehicleListPageV2State();
}

class _VehicleListPageV2State extends State<VehicleListPageV2> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'vehicleNumber';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      currentRoute: '/vehicles',
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBg : AppColors.lightBg,
        body: Column(
          children: [
            // Header with Search
            _buildHeader(),

            // Summary Statistics with Glassmorphism
            _buildSummaryStats(),

            // Vehicle Table with Glassmorphism
            Expanded(
              child: _buildVehicleTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vehicle Plan & Status',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ),
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by plate number, franchise...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.primary),
                          onPressed: () {
                            _searchController.clear();
                            context.read<VehicleProvider>().setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  context.read<VehicleProvider>().setSearchQuery(value);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Theme Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          // Add Button
          ElevatedButton.icon(
            onPressed: () => context.go('/vehicles/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Vehicle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSummaryStats() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, _) {
        final vehicles = provider.filteredVehicles;
        final total = vehicles.length;
        final onRoad = vehicles
            .where((v) => v.status == 'active' && v.healthState == 'healthy')
            .length;
        final onRepair = vehicles
            .where((v) =>
                v.healthState == 'critical' || v.healthState == 'attention')
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Total Car',
                  value: total.toString(),
                  gradient: AppColors.successGradient,
                  icon: Icons.directions_car,
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: 'On Repair',
                  value: onRepair.toString(),
                  gradient: AppColors.warningGradient,
                  icon: Icons.build,
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: 'On Road',
                  value: onRoad.toString(),
                  gradient: AppColors.successGradient,
                  icon: Icons.check_circle,
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleTable() {
    return Consumer<VehicleProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        var vehicles = provider.filteredVehicles;

        // Sort vehicles
        vehicles.sort((a, b) {
          int comparison = 0;
          switch (_sortBy) {
            case 'vehicleNumber':
              comparison = a.vehicleNumber.compareTo(b.vehicleNumber);
              break;
            case 'franchiseName':
              comparison = a.franchiseName.compareTo(b.franchiseName);
              break;
            case 'status':
              comparison = a.status.compareTo(b.status);
              break;
            case 'createdDate':
              comparison = a.createdDate.compareTo(b.createdDate);
              break;
          }
          return _sortAscending ? comparison : -comparison;
        });

        if (vehicles.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'No vehicles found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first vehicle to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/vehicles/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Table Header with Sort
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      _SortableHeader(
                        label: 'Vehicle Number',
                        sortBy: 'vehicleNumber',
                        currentSort: _sortBy,
                        ascending: _sortAscending,
                        onSort: (sortBy, ascending) {
                          setState(() {
                            _sortBy = sortBy;
                            _sortAscending = ascending;
                          });
                        },
                      ),
                      Expanded(
                        child: _SortableHeader(
                          label: 'Franchise Name',
                          sortBy: 'franchiseName',
                          currentSort: _sortBy,
                          ascending: _sortAscending,
                          onSort: (sortBy, ascending) {
                            setState(() {
                              _sortBy = sortBy;
                              _sortAscending = ascending;
                            });
                          },
                        ),
                      ),
                      const Expanded(
                          child: Text('Plate Number',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600))),
                      const Expanded(
                          child: Text('Status',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600))),
                      _SortableHeader(
                        label: 'CarPlan Started',
                        sortBy: 'createdDate',
                        currentSort: _sortBy,
                        ascending: _sortAscending,
                        onSort: (sortBy, ascending) {
                          setState(() {
                            _sortBy = sortBy;
                            _sortAscending = ascending;
                          });
                        },
                      ),
                      const Expanded(
                          child: Text('End of Contract',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                // Table Body
                Expanded(
                  child: ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _VehicleTableRow(
                        vehicle: vehicle,
                        onTap: () =>
                            context.go('/vehicles/${vehicle.vehicleId}'),
                      )
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient Function(BuildContext) gradient;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortableHeader extends StatelessWidget {
  final String label;
  final String sortBy;
  final String currentSort;
  final bool ascending;
  final Function(String, bool) onSort;

  const _SortableHeader({
    required this.label,
    required this.sortBy,
    required this.currentSort,
    required this.ascending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == sortBy;
    return Expanded(
      child: InkWell(
        onTap: () => onSort(sortBy, isActive ? !ascending : true),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isActive
                  ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleTableRow extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const _VehicleTableRow({
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Vehicle No. ${vehicle.vehicleNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                vehicle.franchiseName,
                style: TextStyle(
                   color: Theme.of(context).brightness == Brightness.dark ? AppColors.primary : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(vehicle.vehicleNumber),
            ),
            Expanded(
              child: _buildStatusPill(context),
            ),
            Expanded(
              child: Text(
                DateFormat('dd MMM, yyyy').format(vehicle.createdDate),
              ),
            ),
            Expanded(
              child: Text(
                DateFormat('dd MMM, yyyy').format(
                  vehicle.createdDate.add(const Duration(days: 730)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context) {
    String statusText;
    LinearGradient statusGradient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (vehicle.status == 'active' && vehicle.healthState == 'healthy') {
      statusText = 'On Road';
      statusGradient = AppColors.successGradient(context);
    } else if (vehicle.healthState == 'critical' ||
        vehicle.healthState == 'attention') {
      statusText = 'On Repair';
      statusGradient = AppColors.warningGradient(context);
    } else if (vehicle.status == 'trial') {
      statusText = 'New Driver';
      statusGradient = AppColors.primaryGradient(context);
    } else {
      statusText = vehicle.status
          .split('_')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
      statusGradient = LinearGradient(
        colors: [
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: statusGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusGradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
