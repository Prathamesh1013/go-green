import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../theme/app_colors.dart';
import '../../../services/supabase_service.dart';
import 'driver_summary_card.dart';
import 'battery_charging_card.dart';
import 'rsa_events_card.dart';

class VehicleDetails extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetails({super.key, required this.vehicle});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _inventoryPhotos = [];
  List<Map<String, dynamic>> _dailyInventoryLogs = [];
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadDetailedData();
  }

  @override
  void didUpdateWidget(VehicleDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicle.id != widget.vehicle.id) {
      _loadDetailedData();
    }
  }

  Future<void> _loadDetailedData() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final photos = await _supabaseService.getInventoryPhotosByVehicleId(widget.vehicle.databaseId);
      final logs = await _supabaseService.getDailyInventoryByVehicleId(widget.vehicle.databaseId);
      
      if (mounted) {
        setState(() {
          _inventoryPhotos = photos;
          _dailyInventoryLogs = logs;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading detailed mobile data: $e');
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final bool isSyncing = (vehicle.inventoryPhotoCount ?? 0) > _inventoryPhotos.length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section (Transparent background)
          _buildHeader(),
          const SizedBox(height: 20),
          
          // Metrics Grid (Row of 4 cards)
          _buildMetricsRow(),
          const SizedBox(height: 20),
          
          // Location and Job Row
          _buildLocationCard(),
          const SizedBox(height: 20),
          
          // Maintenance Information (Full width card)
          _buildMaintenanceCard(),
          const SizedBox(height: 20),
          
          // Mobile App Data Sections
          if (vehicle.isVehicleIn != null || vehicle.toDos != null || 
              vehicle.lastServiceDate != null || vehicle.dailyChecks != null) ...[
            const Text(
              'Mobile Technician Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            _buildMobileAppDataSection(),
            const SizedBox(height: 24),
            
            // Photo Gallery (New)
            if (_inventoryPhotos.isNotEmpty || isSyncing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vehicle Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FleetColors.gray900,
                    ),
                  ),
                  if (isSyncing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FleetColors.orange50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: FleetColors.orange600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(vehicle.inventoryPhotoCount ?? 0) - _inventoryPhotos.length} still syncing...',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FleetColors.orange600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_inventoryPhotos.isNotEmpty) 
                _buildPhotoGallery()
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FleetColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FleetColors.border, style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Text('Photos uploaded but records not yet visible...', style: TextStyle(color: FleetColors.gray500, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            // Detailed History (New)
            if (_dailyInventoryLogs.isNotEmpty) ...[
              const Text(
                'Inventory History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FleetColors.gray900,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailedHistoryView(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final vehicle = widget.vehicle;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Vehicle ID, Type, Status
        Row(
          children: [
            Text(
              vehicle.id,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: vehicle.type == VehicleType.EV ? FleetColors.green50 : FleetColors.blue50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vehicle.type.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: vehicle.type == VehicleType.EV ? FleetColors.green600 : FleetColors.blue600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusBgColor(vehicle.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(vehicle.status),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusTextColor(vehicle.status),
                ),
              ),
            ),
          ],
        ),
        // Right side - Health Score
        Row(
          children: [
            const Icon(Icons.speed, size: 18, color: FleetColors.gray500),
            const SizedBox(width: 8),
            const Text(
              'Health Score',
              style: TextStyle(fontSize: 14, color: FleetColors.gray600),
            ),
            const SizedBox(width: 12),
            Text(
              '${vehicle.healthScore}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getHealthScoreColor(vehicle.healthScore),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    final vehicle = widget.vehicle;
    return Row(
      children: [
        if (vehicle.batteryLevel != null)
          Expanded(child: _buildMetricCard(
            'Battery Level',
            '${vehicle.batteryLevel!.toInt()}%',
            Icons.battery_full,
            FleetColors.green500,
            showProgress: true,
            progressValue: vehicle.batteryLevel! / 100,
            progressColor: _getLevelColor(vehicle.batteryLevel!),
          ))
        else if (vehicle.fuelLevel != null)
          Expanded(child: _buildMetricCard(
            'Fuel Level',
            '${vehicle.fuelLevel!.toInt()}%',
            Icons.local_gas_station,
            FleetColors.blue500,
            showProgress: true,
            progressValue: vehicle.fuelLevel! / 100,
            progressColor: _getLevelColor(vehicle.fuelLevel!),
          )),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(
          'Avg Speed',
          '${vehicle.avgSpeed.toInt()} km/h',
          Icons.bolt, 
          FleetColors.purple500,
          subtext: 'Last 24 hours',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(
          'Idle Time',
          '${vehicle.idleTime} min',
          Icons.access_time,
          FleetColors.orange500,
          subtext: 'Today',
        )),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(
          'Cost per KM',
          '\$${vehicle.costPerKm}',
          Icons.attach_money,
          FleetColors.blue500,
          subtext: '8% below avg', 
          subtextColor: FleetColors.green600,
        )),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color iconColor, {
    String? subtext,
    Color? subtextColor,
    bool showProgress = false,
    double? progressValue,
    Color? progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: FleetColors.gray500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FleetColors.gray900,
            ),
          ),
          if (showProgress && progressValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: FleetColors.gray200,
                valueColor: AlwaysStoppedAnimation(progressColor ?? FleetColors.green500),
                minHeight: 6,
              ),
            ),
          ],
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 12,
                color: subtextColor ?? FleetColors.gray500,
                fontWeight: subtextColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final vehicle = widget.vehicle;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FleetColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FleetColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, size: 20, color: FleetColors.blue600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.location.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FleetColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.location.lat.toStringAsFixed(4)}, ${vehicle.location.lng.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: FleetColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vehicle.driver != null || vehicle.type == VehicleType.EV) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vehicle.driver != null)
                  Expanded(
                    child: DriverSummaryCard(driver: vehicle.driver!),
                  ),
                if (vehicle.driver != null && vehicle.type == VehicleType.EV)
                  const SizedBox(width: 24),
                if (vehicle.type == VehicleType.EV)
                  Expanded(
                    child: BatteryChargingCard(vehicle: vehicle),
                  ),
              ],
            ),
          ],
            
          if (vehicle.rsaEvents.isNotEmpty) ...[
            const SizedBox(height: 24),
            RSAEventsCard(events: vehicle.rsaEvents),
          ],
        ],
      ),
    );
  }



  Widget _buildMaintenanceCard() {
    final vehicle = widget.vehicle;
    final kmToService = vehicle.kmToMaintenance;
    // Cap progress at 1.0 for UI even if overdue
    final serviceProgress = (vehicle.odometer / vehicle.nextMaintenanceKm).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Maintenance Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FleetColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMaintenanceMetric(
                  'Odometer',
                  '${_formatNumber(vehicle.odometer)} km',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildMaintenanceMetric(
                  'Next Service',
                  '${_formatNumber(vehicle.nextMaintenanceKm)} km',
                  Icons.build,
                ),
              ),
              Expanded(
                child: _buildMaintenanceMetric(
                  'Distance to Service',
                  '${_formatNumber(kmToService)} km',
                  Icons.trending_up,
                  valueColor: kmToService < 2000 ? FleetColors.orange600 : FleetColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service interval progress',
                style: TextStyle(fontSize: 12, color: FleetColors.gray500),
              ),
              Text(
                '${(serviceProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FleetColors.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: serviceProgress,
              backgroundColor: FleetColors.gray200,
              valueColor: AlwaysStoppedAnimation(
                serviceProgress > 0.9 ? FleetColors.red500 : (serviceProgress > 0.75 ? FleetColors.orange500 : FleetColors.red500), 
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceMetric(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: FleetColors.gray400),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: FleetColors.gray500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? FleetColors.gray900,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Color _getStatusBgColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return const Color(0xFFDCFCE7);
      case VehicleStatus.idle: return const Color(0xFFF3F4F6);
      case VehicleStatus.charging: return const Color(0xFFDBEAFE);
      case VehicleStatus.maintenance: return const Color(0xFFFFEDD5);
    }
  }

  Color _getStatusTextColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return const Color(0xFF15803D);
      case VehicleStatus.idle: return const Color(0xFF374151);
      case VehicleStatus.charging: return const Color(0xFF1D4ED8);
      case VehicleStatus.maintenance: return const Color(0xFFC2410C);
    }
  }

  String _getStatusText(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active: return 'Active';
      case VehicleStatus.idle: return 'Idle';
      case VehicleStatus.charging: return 'Charging';
      case VehicleStatus.maintenance: return 'Maintenance';
    }
  }

  Color _getLevelColor(double level) {
    if (level > 60) return FleetColors.green500;
    if (level > 30) return FleetColors.yellow500;
    return FleetColors.red500;
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 90) return FleetColors.green600;
    if (score >= 75) return FleetColors.yellow600;
    return FleetColors.red600;
  }
  
  // Mobile App Data Section
  Widget _buildMobileAppDataSection() {
    final vehicle = widget.vehicle;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IN/OUT Status
          if (vehicle.isVehicleIn != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: vehicle.isVehicleIn! ? FleetColors.green50 : FleetColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    vehicle.isVehicleIn! ? Icons.garage : Icons.directions_car,
                    size: 20,
                    color: vehicle.isVehicleIn! ? FleetColors.green600 : FleetColors.gray600,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Garage Status',
                      style: TextStyle(fontSize: 13, color: FleetColors.gray500),
                    ),
                    Text(
                      vehicle.isVehicleIn! ? 'IN GARAGE' : 'OUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: vehicle.isVehicleIn! ? FleetColors.green600 : FleetColors.gray900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // To-Do Tasks
          if (vehicle.toDos != null && vehicle.toDos!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'To-Do Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FleetColors.gray900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FleetColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${vehicle.toDos!.length} tasks',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: FleetColors.blue600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...vehicle.toDos!.map((todo) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: FleetColors.gray400),
                  const SizedBox(width: 8),
                  Text(todo, style: const TextStyle(fontSize: 14, color: FleetColors.gray700)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // Servicing Status
          if (vehicle.lastServiceDate != null || vehicle.lastServiceType != null) ...[
            const Text(
              'Last Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(fontSize: 12, color: FleetColors.gray500)),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.lastServiceDate != null 
                            ? '${vehicle.lastServiceDate!.day}/${vehicle.lastServiceDate!.month}/${vehicle.lastServiceDate!.year}'
                            : 'N/A',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type', style: TextStyle(fontSize: 12, color: FleetColors.gray500)),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.lastServiceType ?? 'N/A',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (vehicle.serviceAttention != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: vehicle.serviceAttention! ? FleetColors.orange50 : FleetColors.green50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vehicle.serviceAttention! ? 'Attention' : 'OK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: vehicle.serviceAttention! ? FleetColors.orange600 : FleetColors.green600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // Charging Info (Mobile App)
          if (vehicle.lastChargeType != null || vehicle.chargingHealth != null) ...[
            const Text(
              'Charging Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (vehicle.lastChargeType != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last Charge Type', style: TextStyle(fontSize: 12, color: FleetColors.gray500)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FleetColors.blue50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.lastChargeType!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: FleetColors.blue600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (vehicle.chargingHealth != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Charging Health', style: TextStyle(fontSize: 12, color: FleetColors.gray500)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: vehicle.chargingHealth == 'Good' ? FleetColors.green50 : FleetColors.orange50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vehicle.chargingHealth!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: vehicle.chargingHealth == 'Good' ? FleetColors.green600 : FleetColors.orange600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // Daily Checks
          if (vehicle.dailyChecks != null && vehicle.dailyChecks!.isNotEmpty) ...[
            const Text(
              'Daily Inventory Checks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            ...vehicle.dailyChecks!.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14, color: FleetColors.gray700)),
                  Icon(
                    entry.value ? Icons.check_circle : Icons.cancel,
                    size: 20,
                    color: entry.value ? FleetColors.green600 : FleetColors.red600,
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // Full Scan (Detailed Inspection)
          if (vehicle.lastFullScan != null && vehicle.lastFullScan!.isNotEmpty) ...[
            const Text(
              'Full System Scan Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: FleetColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FleetColors.blue50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: vehicle.lastFullScan!.entries.map((entry) {
                  final status = entry.value.toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 13, color: FleetColors.gray700)),
                        Row(
                          children: [
                            if (status == 'auto')
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Text('AUTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FleetColors.gray500)),
                              ),
                            Icon(
                              status == 'ok' || status == 'auto' ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: status == 'ok' || status == 'auto' ? FleetColors.green600 : FleetColors.orange600,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
          ],
          
          // Inventory Photos
          if (vehicle.inventoryPhotoCount != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inventory Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: FleetColors.gray900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: vehicle.inventoryPhotoCount! >= 9 ? FleetColors.green50 : FleetColors.orange50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_camera,
                        size: 16,
                        color: vehicle.inventoryPhotoCount! >= 9 ? FleetColors.green600 : FleetColors.orange600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vehicle.inventoryPhotoCount}/9',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: vehicle.inventoryPhotoCount! >= 9 ? FleetColors.green600 : FleetColors.orange600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_inventoryPhotos.isNotEmpty) 
              _buildPhotoGallery()
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: FleetColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FleetColors.border, style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.photo_library_outlined, color: FleetColors.gray400, size: 32),
                    SizedBox(height: 8),
                    Text('No inventory photos captured yet', style: TextStyle(color: FleetColors.gray500, fontSize: 13)),
                  ],
                ),
              ),
            if (vehicle.lastInventoryTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${vehicle.lastInventoryTime!.day}/${vehicle.lastInventoryTime!.month}/${vehicle.lastInventoryTime!.year} at ${vehicle.lastInventoryTime!.hour}:${vehicle.lastInventoryTime!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: FleetColors.gray500),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Photo Gallery Widget
  Widget _buildPhotoGallery() {
    return Container(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _inventoryPhotos.length,
        itemBuilder: (context, index) {
          final photo = _inventoryPhotos[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FleetColors.border),
              image: DecorationImage(
                image: NetworkImage(photo['photo_url']),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  debugPrint('Failed to load image: ${photo['photo_url']}');
                },
              ),
            ),
            child: Stack(
              children: [
                // Error indicator if image fails to load (using opaque background)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photo['photo_url'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: FleetColors.gray100,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: FleetColors.gray400, size: 32),
                              SizedBox(height: 4),
                              Text('Failed to load', style: TextStyle(color: FleetColors.gray500, fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      photo['category']?.toUpperCase() ?? 'PHOTO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Detailed History View Widget
  Widget _buildDetailedHistoryView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FleetColors.border),
      ),
      child: Column(
        children: _dailyInventoryLogs.map((log) {
          final DateTime checkDate = DateTime.parse(log['check_date']);
          final String status = log['status'] ?? 'unknown';
          Map<String, dynamic> notes = {};
          try {
            if (log['notes'] != null) {
              notes = jsonDecode(log['notes'] as String) as Map<String, dynamic>;
            }
          } catch (e) {
            debugPrint('Error parsing inventory notes: $e');
          }

          return ExpansionTile(
            title: Text(
              'Check on ${checkDate.day}/${checkDate.month}/${checkDate.year}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Status: ${status.toUpperCase()}',
              style: TextStyle(
                fontSize: 12,
                color: status == 'completed' ? FleetColors.green600 : FleetColors.orange600,
              ),
            ),
            leading: Icon(
              Icons.assignment_turned_in,
              color: status == 'completed' ? FleetColors.green600 : FleetColors.orange600,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (log['technician_id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('Technician: ${log['technician_id']}', style: const TextStyle(fontSize: 12, color: FleetColors.gray600)),
                      ),
                    const Divider(),
                    const Text('Checklist Results:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    // If notes contains the checklist items
                    ...notes.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 12)),
                          Icon(
                            entry.value == 'ok' || entry.value == true ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: entry.value == 'ok' || entry.value == true ? FleetColors.green600 : FleetColors.red600,
                          ),
                        ],
                      ),
                    )).toList(),
                    if (notes.isEmpty)
                      const Text('No detailed checklist data available', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
