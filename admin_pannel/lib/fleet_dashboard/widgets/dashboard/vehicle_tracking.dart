import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import 'vehicle_card.dart';
import 'vehicle_details.dart';

class VehicleTracking extends StatefulWidget {
  final List<Vehicle> vehicles;

  const VehicleTracking({super.key, required this.vehicles});

  @override
  State<VehicleTracking> createState() => _VehicleTrackingState();
}

class _VehicleTrackingState extends State<VehicleTracking> {
  Vehicle? _selectedVehicle;
  String _searchQuery = '';
  String _filterType = 'all';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = widget.vehicles.where((vehicle) {
      final matchesSearch = vehicle.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vehicle.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (vehicle.driver?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesType = _filterType == 'all' || vehicle.type.name == _filterType;
      final matchesStatus = _filterStatus == 'all' || vehicle.status.name == _filterStatus;
      
      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    final activeCount = widget.vehicles.where((v) => v.status == VehicleStatus.active).length;
    final chargingCount = widget.vehicles.where((v) => v.status == VehicleStatus.charging).length;
    final idleCount = widget.vehicles.where((v) => v.status == VehicleStatus.idle).length;
    final alertCount = widget.vehicles.fold<int>(0, (sum, v) => sum + v.alerts.length);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Stats
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Vehicles', '${widget.vehicles.length}', FleetColors.gray900)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Active', '$activeCount', FleetColors.green600)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Charging/Idle', '${chargingCount + idleCount}', FleetColors.blue600)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Alerts', '$alertCount', FleetColors.orange600)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search & Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FleetColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FleetColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search by vehicle ID, model, or driver...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.filter_list, size: 20, color: FleetColors.gray500),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterType,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Types')),
                        DropdownMenuItem(value: 'EV', child: Text('EV Only')),
                        DropdownMenuItem(value: 'ICE', child: Text('ICE Only')),
                      ],
                      onChanged: (value) => setState(() => _filterType = value!),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'idle', child: Text('Idle')),
                        DropdownMenuItem(value: 'charging', child: Text('Charging')),
                        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                      ],
                      onChanged: (value) => setState(() => _filterStatus = value!),
                    ),
                  ],
                ),
                if (_searchQuery.isNotEmpty || _filterType != 'all' || _filterStatus != 'all') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Showing ${filteredVehicles.length} of ${widget.vehicles.length} vehicles',
                        style: const TextStyle(fontSize: 14, color: FleetColors.gray600),
                      ),
                      const SizedBox(width: 16),
                      if (_filterType != 'all' || _filterStatus != 'all')
                        TextButton(
                          onPressed: () => setState(() {
                            _filterType = 'all';
                            _filterStatus = 'all';
                            _searchQuery = '';
                          }),
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Vehicle List & Details
          SizedBox(
            height: 800,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Cards List
                Expanded(
                  flex: 4,
                  child: Container(
                    height: double.infinity,
                    child: filteredVehicles.isNotEmpty
                        ? ListView.builder(
                            itemCount: filteredVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = filteredVehicles[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: VehicleCard(
                                  vehicle: vehicle,
                                  onTap: () => setState(() => _selectedVehicle = vehicle),
                                  isSelected: _selectedVehicle?.id == vehicle.id,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: FleetColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: FleetColors.border),
                              ),
                              child: const Text(
                                'No vehicles found matching your filters',
                                style: TextStyle(color: FleetColors.gray500),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Vehicle Details Panel
                Expanded(
                  flex: 8,
                  child: _selectedVehicle != null
                      ? VehicleDetails(vehicle: _selectedVehicle!)
                      : Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: FleetColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: FleetColors.border),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 48, color: FleetColors.gray400),
                                SizedBox(height: 16),
                                Text(
                                  'Select a vehicle to view details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: FleetColors.gray900,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Click on any vehicle card to see comprehensive tracking information',
                                  style: TextStyle(fontSize: 14, color: FleetColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FleetColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FleetColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: FleetColors.gray600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
