class CoreVehicle {
  final String vehicleId;
  final String vehicleNumber;
  final String? make;
  final String? model;
  final String? variant;
  final String? fuelType; // ICE, EV, Hybrid, CNG
  final int? yearOfManufacture;
  final String? telematicsId;
  final String status; // active, inactive, scrapped, trial
  final String? ownerType; // client_owned, leased
  final String? primaryHubId;
  final HubInfo? hub; // Hub/docking station information
  final DateTime createdDate;
  final DateTime? updatedDate;
  
  // Current state
  final int? odometerCurrent;
  final double? avgKmPerDay;
  final double? avgTripsPerDay;
  final DateTime? lastTripDate;
  final DateTime? lastActiveDate;
  final String? healthState; // healthy, attention, critical
  final int? totalDowntimeDays;
  
  // Driver Info
  final String? driverName;
  final String? driverPhone;
  final String? driverLicense;
  
  // Mobile App Sync Fields
  final bool? isVehicleIn;
  final List<String>? toDos;
  final DateTime? lastServiceDate;
  final String? lastServiceType;
  final bool? serviceAttention;
  final String? lastChargeType;
  final String? chargingHealth;
  final Map<String, bool>? dailyChecks;
  final Map<String, dynamic>? lastFullScan;
  final int? inventoryPhotoCount;
  final DateTime? lastInventoryTime;

  CoreVehicle({
    required this.vehicleId,
    required this.vehicleNumber,
    this.make,
    this.model,
    this.variant,
    this.fuelType,
    this.yearOfManufacture,
    this.telematicsId,
    required this.status,
    this.ownerType,
    this.primaryHubId,
    this.hub,
    required this.createdDate,
    this.updatedDate,
    this.odometerCurrent,
    this.avgKmPerDay,
    this.avgTripsPerDay,
    this.lastTripDate,
    this.lastActiveDate,
    this.healthState,
    this.totalDowntimeDays,
    this.driverName,
    this.driverPhone,
    this.driverLicense,
    this.isVehicleIn,
    this.toDos,
    this.lastServiceDate,
    this.lastServiceType,
    this.serviceAttention,
    this.lastChargeType,
    this.chargingHealth,
    this.dailyChecks,
    this.lastFullScan,
    this.inventoryPhotoCount,
    this.lastInventoryTime,
  });

  factory CoreVehicle.fromJson(Map<String, dynamic> json) {
    // Handle crm_vehicles table structure
    String? make;
    String? model;
    String? variant;
    int? yearOfManufacture;
    
    // Parse make_model_year if it exists (from crm_vehicles)
    if (json['make_model_year'] != null) {
      final makeModelYear = json['make_model_year'] as String;
      // Try to parse format like "TATA TIGOR XPRESS-T XM" or "TATA XPRESS-T XM+"
      final parts = makeModelYear.split(' ');
      if (parts.isNotEmpty) {
        make = parts[0]; // First part is usually make (e.g., "TATA")
        if (parts.length > 1) {
          // Join remaining parts as model/variant
          model = parts.sublist(1).join(' ');
        }
      }
    } else {
      // Use separate fields if they exist (from vehicle table)
      make = json['make'];
      model = json['model'];
      variant = json['variant'];
    }
    
    // Get year from year_of_registration (crm_vehicles) or year_of_manufacture (vehicle)
    yearOfManufacture = json['year_of_manufacture'] ?? json['year_of_registration'];
    
    // Handle date fields - crm_vehicles uses created_at/updated_at, vehicle uses created_date/updated_date
    DateTime createdDate;
    try {
      createdDate = json['created_date'] != null 
          ? DateTime.parse(json['created_date'])
          : DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String());
    } catch (e) {
      createdDate = DateTime.now();
    }
    
    DateTime? updatedDate;
    try {
      updatedDate = json['updated_date'] != null 
          ? (json['updated_date'] is String ? DateTime.parse(json['updated_date']) : null)
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null);
    } catch (e) {
      updatedDate = null;
    }
    
    // Convert avg_monthly_run to avg_km_per_day (divide by ~30)
    double? avgKmPerDay;
    if (json['avg_km_per_day'] != null) {
      avgKmPerDay = json['avg_km_per_day']?.toDouble();
    } else if (json['avg_monthly_run'] != null) {
      avgKmPerDay = (json['avg_monthly_run'] as int) / 30.0;
    }
    
    return CoreVehicle(
      vehicleId: json['vehicle_id'] ?? json['id'] ?? '',
      vehicleNumber: json['vehicle_number'] ?? json['registration_number'] ?? '',
      make: make,
      model: model,
      variant: variant,
      fuelType: json['fuel_type'],
      yearOfManufacture: yearOfManufacture,
      telematicsId: json['telematics_id'],
      status: json['status'] ?? 'active',
      ownerType: json['owner_type'],
      primaryHubId: json['primary_hub_id'],
      hub: json['hub'] != null ? HubInfo.fromJson(json['hub']) : null,
      createdDate: createdDate,
      updatedDate: updatedDate,
      odometerCurrent: json['odometer_current'] ?? json['latest_odometer_reading'],
      avgKmPerDay: avgKmPerDay,
      avgTripsPerDay: json['avg_trips_per_day']?.toDouble(),
      lastTripDate: json['last_trip_date'] != null 
          ? DateTime.parse(json['last_trip_date']) 
          : null,
      lastActiveDate: json['last_active_date'] != null 
          ? DateTime.parse(json['last_active_date']) 
          : null,
      healthState: json['health_state'],
      totalDowntimeDays: json['total_downtime_days'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverLicense: json['driver_license'],
      isVehicleIn: json['is_vehicle_in'] as bool?,
      toDos: (json['to_dos'] as List?)?.map((e) => e as String).toList(),
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date'] as String)
          : null,
      lastServiceType: json['last_service_type'] as String?,
      serviceAttention: json['service_attention'] as bool?,
      lastChargeType: json['last_charge_type'] as String?,
      chargingHealth: json['charging_health'] as String?,
      dailyChecks: json['daily_checks'] != null
          ? Map<String, bool>.from(json['daily_checks'] as Map)
          : null,
      lastFullScan: json['last_full_scan'] != null
          ? Map<String, dynamic>.from(json['last_full_scan'] as Map)
          : null,
      inventoryPhotoCount: json['inventory_photo_count'] as int?,
      lastInventoryTime: json['last_inventory_time'] != null
          ? DateTime.parse(json['last_inventory_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'vehicle_number': vehicleNumber,
      'make': make,
      'model': model,
      'variant': variant,
      'fuel_type': fuelType,
      'year_of_manufacture': yearOfManufacture,
      'telematics_id': telematicsId,
      'status': status,
      'owner_type': ownerType,
      'primary_hub_id': primaryHubId,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
      'odometer_current': odometerCurrent,
      'avg_km_per_day': avgKmPerDay,
      'avg_trips_per_day': avgTripsPerDay,
      'last_trip_date': lastTripDate?.toIso8601String(),
      'last_active_date': lastActiveDate?.toIso8601String(),
      'health_state': healthState,
      'total_downtime_days': totalDowntimeDays,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_license': driverLicense,
      'is_vehicle_in': isVehicleIn,
      'to_dos': toDos,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'last_service_type': lastServiceType,
      'service_attention': serviceAttention,
      'last_charge_type': lastChargeType,
      'charging_health': chargingHealth,
      'daily_checks': dailyChecks,
      'last_full_scan': lastFullScan,
      'inventory_photo_count': inventoryPhotoCount,
      'last_inventory_time': lastInventoryTime?.toIso8601String(),
    };
  }

  String get displayName => '$make $model ${variant ?? ''}'.trim();
  String get fullIdentifier => '$vehicleNumber${yearOfManufacture != null ? ' ($yearOfManufacture)' : ''}';
  String get hubName => hub?.name ?? 'No Hub';
  String get franchiseName => hub?.name ?? 'Unassigned';

  CoreVehicle copyWith({
    String? vehicleId,
    String? vehicleNumber,
    String? make,
    String? model,
    String? variant,
    String? fuelType,
    int? yearOfManufacture,
    String? telematicsId,
    String? status,
    String? ownerType,
    String? primaryHubId,
    HubInfo? hub,
    DateTime? createdDate,
    DateTime? updatedDate,
    int? odometerCurrent,
    double? avgKmPerDay,
    double? avgTripsPerDay,
    DateTime? lastTripDate,
    DateTime? lastActiveDate,
    String? healthState,
    int? totalDowntimeDays,
    String? driverName,
    String? driverPhone,
    String? driverLicense,
    bool? isVehicleIn,
    List<String>? toDos,
    DateTime? lastServiceDate,
    String? lastServiceType,
    bool? serviceAttention,
    String? lastChargeType,
    String? chargingHealth,
    Map<String, bool>? dailyChecks,
    int? inventoryPhotoCount,
    DateTime? lastInventoryTime,
  }) {
    return CoreVehicle(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      fuelType: fuelType ?? this.fuelType,
      yearOfManufacture: yearOfManufacture ?? this.yearOfManufacture,
      telematicsId: telematicsId ?? this.telematicsId,
      status: status ?? this.status,
      ownerType: ownerType ?? this.ownerType,
      primaryHubId: primaryHubId ?? this.primaryHubId,
      hub: hub ?? this.hub,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      odometerCurrent: odometerCurrent ?? this.odometerCurrent,
      avgKmPerDay: avgKmPerDay ?? this.avgKmPerDay,
      avgTripsPerDay: avgTripsPerDay ?? this.avgTripsPerDay,
      lastTripDate: lastTripDate ?? this.lastTripDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      healthState: healthState ?? this.healthState,
      totalDowntimeDays: totalDowntimeDays ?? this.totalDowntimeDays,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLicense: driverLicense ?? this.driverLicense,
      isVehicleIn: isVehicleIn ?? this.isVehicleIn,
      toDos: toDos ?? this.toDos,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceType: lastServiceType ?? this.lastServiceType,
      serviceAttention: serviceAttention ?? this.serviceAttention,
      lastChargeType: lastChargeType ?? this.lastChargeType,
      chargingHealth: chargingHealth ?? this.chargingHealth,
      dailyChecks: dailyChecks ?? this.dailyChecks,
      inventoryPhotoCount: inventoryPhotoCount ?? this.inventoryPhotoCount,
      lastInventoryTime: lastInventoryTime ?? this.lastInventoryTime,
    );
  }
}

class HubInfo {
  final String hubId;
  final String name;
  final String? city;
  final String? state;

  HubInfo({
    required this.hubId,
    required this.name,
    this.city,
    this.state,
  });

  factory HubInfo.fromJson(Map<String, dynamic> json) {
    return HubInfo(
      hubId: json['hub_id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'],
      state: json['state'],
    );
  }

  String get displayName => name;
  String get location => [city, state].where((e) => e != null).join(', ');
}

