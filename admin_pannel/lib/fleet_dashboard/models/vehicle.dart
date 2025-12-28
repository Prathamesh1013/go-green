import 'alert.dart';
import 'job.dart';
import 'driver_details.dart';
import 'rsa_event.dart';

enum VehicleType { EV, ICE }

enum VehicleStatus { active, idle, charging, maintenance }

class Location {
  // ... (unchanged)
  final double lat;
  final double lng;
  final String address;

  Location({
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String,
    );
  }
}

class Vehicle {
  final String id; // Registration Number for display
  final String databaseId; // UUID for database queries
  final VehicleType type;
  final String model;
  final VehicleStatus status;
  final double? batteryLevel;
  final double? fuelLevel;
  final Location location;
  final CurrentJob? currentJob;
  final DriverDetails? driver;
  final int odometer;
  final int nextMaintenanceKm;
  final int healthScore;
  final List<Alert> alerts;
  final double costPerKm;
  final double avgSpeed;
  final int idleTime;
  
  // New EV/RSA Fields
  final int? evRange; // km
  final double? efficiency; // km/kWh
  final String? lastCharged; // e.g. "6h ago"
  final int? batteryHealth; // %
  final List<RSAEvent> rsaEvents;
  
  // Mobile App Fields (synced from mobile technician app)
  final bool? isVehicleIn; // IN/OUT garage status
  final List<String>? toDos; // Task list
  final DateTime? lastServiceDate;
  final String? lastServiceType;
  final bool? serviceAttention; // Service needs attention
  final String? lastChargeType; // AC/DC
  final String? chargingHealth; // Good/Action Req
  final Map<String, bool>? dailyChecks; // Battery, cables, tires, damage
  final Map<String, dynamic>? lastFullScan; // Detailed technician scan
  final int? inventoryPhotoCount; // Number of photos captured
  final DateTime? lastInventoryTime;

  Vehicle({
    required this.id,
    required this.databaseId,
    required this.type,
    required this.model,
    required this.status,
    this.batteryLevel,
    this.fuelLevel,
    required this.location,
    this.currentJob,
    this.driver,
    required this.odometer,
    required this.nextMaintenanceKm,
    required this.healthScore,
    required this.alerts,
    required this.costPerKm,
    required this.avgSpeed,
    required this.idleTime,
    this.evRange,
    this.efficiency,
    this.lastCharged,
    this.batteryHealth,
    this.rsaEvents = const [],
    // Mobile App Fields
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

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      databaseId: json['databaseId'] as String? ?? json['id'] as String, // Fallback if not provided
      type: VehicleType.values.firstWhere((e) => e.name == json['type']),
      model: json['model'] as String,
      status: VehicleStatus.values.firstWhere((e) => e.name == json['status']),
      batteryLevel: json['batteryLevel'] != null 
          ? (json['batteryLevel'] as num).toDouble() 
          : null,
      fuelLevel: json['fuelLevel'] != null 
          ? (json['fuelLevel'] as num).toDouble() 
          : null,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      currentJob: json['currentJob'] != null
          ? CurrentJob.fromJson(json['currentJob'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null 
          ? DriverDetails.fromJson(json['driver'] as Map<String, dynamic>) 
          : null,
      odometer: json['odometer'] as int,
      nextMaintenanceKm: json['nextMaintenanceKm'] as int,
      healthScore: json['healthScore'] as int,
      alerts: (json['alerts'] as List)
          .map((e) => Alert.fromJson(e as Map<String, dynamic>))
          .toList(),
      costPerKm: (json['costPerKm'] as num).toDouble(),
      avgSpeed: (json['avgSpeed'] as num).toDouble(),
      idleTime: json['idleTime'] as int,
      evRange: json['evRange'] as int?,
      efficiency: json['efficiency'] != null ? (json['efficiency'] as num).toDouble() : null,
      lastCharged: json['lastCharged'] as String?,
      batteryHealth: json['batteryHealth'] as int?,
      rsaEvents: (json['rsaEvents'] as List?)
          ?.map((e) => RSAEvent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      // Mobile App Fields
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

  int get kmToMaintenance => nextMaintenanceKm - odometer;
}
