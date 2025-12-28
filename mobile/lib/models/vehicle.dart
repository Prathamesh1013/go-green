enum VehicleStatus { pending, inProgress, completed }

class ReportedIssue {
  final String id;
  final String vehicleId;
  final String type;
  final String description;
  final DateTime timestamp;
  final String? photoPath;
  final String? videoPath;

  ReportedIssue({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.photoPath,
    this.videoPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'type': type,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'photoPath': photoPath,
    'videoPath': videoPath,
  };

  factory ReportedIssue.fromJson(Map<String, dynamic> json) => ReportedIssue(
    id: json['id'],
    vehicleId: json['vehicleId'],
    type: json['type'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    photoPath: json['photoPath'],
    videoPath: json['videoPath'],
  );
}

class InspectionResult {
  final String vehicleId;
  final Map<String, String> checks;
  final DateTime timestamp;

  InspectionResult({
    required this.vehicleId,
    required this.checks,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'vehicleId': vehicleId,
    'checks': checks,
    'timestamp': timestamp.toIso8601String(),
  };

  factory InspectionResult.fromJson(Map<String, dynamic> json) => InspectionResult(
    vehicleId: json['vehicleId'],
    checks: Map<String, String>.from(json['checks']),
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class Vehicle {
  final String id;
  final String vehicleNumber;
  final String customerName;
  final String serviceType;
  final VehicleStatus status;
  
  // New Field Ops Data
  bool isVehicleIn; // IN/OUT status
  DateTime? lastServiceDate;
  String? lastServiceType;
  bool serviceAttention; // OK / Attention
  
  double batteryLevel;
  String lastChargeType; // AC / DC
  String chargingHealth;
  
  List<String> toDos;
  Map<String, bool> dailyChecks;
  int inventoryPhotoCount;
  
  DateTime? lastInventoryTime;

  // Database fields from crm_vehicles
  final String? registrationNumber;
  final String? make;
  final String? model;
  final String? variant;
  final String? primaryHubId;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.customerName,
    required this.serviceType,
    required this.status,
    this.isVehicleIn = true,
    this.lastServiceDate,
    this.lastServiceType,
    this.serviceAttention = false,
    this.batteryLevel = 85.0,
    this.lastChargeType = 'AC',
    this.chargingHealth = 'Good',
    this.toDos = const [],
    this.dailyChecks = const {},
    this.inventoryPhotoCount = 0,
    this.lastInventoryTime,
    this.registrationNumber,
    this.make,
    this.model,
    this.variant,
    this.primaryHubId,
    this.createdAt,
  });

  String get statusText {
    switch (status) {
      case VehicleStatus.pending:
        return 'Pending';
      case VehicleStatus.inProgress:
        return 'In Progress';
      case VehicleStatus.completed:
        return 'Completed';
    }
  }

  // Create Vehicle from Supabase JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['vehicle_id'] ?? json['id'] ?? '',
      vehicleNumber: json['registration_number'] ?? json['vehicleNumber'] ?? 'N/A',
      customerName: json['customer_name'] ?? json['customerName'] ?? 'Unknown',
      serviceType: json['service_type'] ?? json['serviceType'] ?? 'General',
      status: _parseStatus(json['status']),
      isVehicleIn: json['is_vehicle_in'] ?? json['isVehicleIn'] ?? true,
      lastServiceDate: json['last_service_date'] != null 
          ? DateTime.parse(json['last_service_date']) 
          : null,
      lastServiceType: json['last_service_type'] ?? json['lastServiceType'],
      serviceAttention: json['service_attention'] ?? json['serviceAttention'] ?? false,
      batteryLevel: (json['battery_level'] ?? json['batteryLevel'] ?? 85.0).toDouble(),
      lastChargeType: json['last_charge_type'] ?? json['lastChargeType'] ?? 'AC',
      chargingHealth: json['charging_health'] ?? json['chargingHealth'] ?? 'Good',
      toDos: json['to_dos'] != null 
          ? List<String>.from(json['to_dos']) 
          : (json['toDos'] != null ? List<String>.from(json['toDos']) : []),
      dailyChecks: json['daily_checks'] != null
          ? Map<String, bool>.from(json['daily_checks'])
          : (json['dailyChecks'] != null ? Map<String, bool>.from(json['dailyChecks']) : {}),
      inventoryPhotoCount: json['inventory_photo_count'] ?? json['inventoryPhotoCount'] ?? 0,
      lastInventoryTime: json['last_inventory_time'] != null 
          ? DateTime.parse(json['last_inventory_time']) 
          : null,
      registrationNumber: json['registration_number'],
      make: json['make'],
      model: json['model'],
      variant: json['variant'],
      primaryHubId: json['primary_hub_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  // Convert Vehicle to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_number': vehicleNumber,
      'customer_name': customerName,
      'service_type': serviceType,
      'status': status.name,
      'is_vehicle_in': isVehicleIn,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'last_service_type': lastServiceType,
      'service_attention': serviceAttention,
      'battery_level': batteryLevel,
      'last_charge_type': lastChargeType,
      'charging_health': chargingHealth,
      'to_dos': toDos,
      'daily_checks': dailyChecks,
      'inventory_photo_count': inventoryPhotoCount,
      'last_inventory_time': lastInventoryTime?.toIso8601String(),
      'make': make,
      'model': model,
      'variant': variant,
      'primary_hub_id': primaryHubId,
    };
  }

  static VehicleStatus _parseStatus(dynamic status) {
    if (status == null) return VehicleStatus.pending;
    
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('progress') || statusStr == 'inprogress') {
      return VehicleStatus.inProgress;
    } else if (statusStr.contains('complete')) {
      return VehicleStatus.completed;
    }
    return VehicleStatus.pending;
  }

  // Copy with method for updates
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? customerName,
    String? serviceType,
    VehicleStatus? status,
    bool? isVehicleIn,
    DateTime? lastServiceDate,
    String? lastServiceType,
    bool? serviceAttention,
    double? batteryLevel,
    String? lastChargeType,
    String? chargingHealth,
    List<String>? toDos,
    Map<String, bool>? dailyChecks,
    int? inventoryPhotoCount,
    DateTime? lastInventoryTime,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      customerName: customerName ?? this.customerName,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      isVehicleIn: isVehicleIn ?? this.isVehicleIn,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceType: lastServiceType ?? this.lastServiceType,
      serviceAttention: serviceAttention ?? this.serviceAttention,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastChargeType: lastChargeType ?? this.lastChargeType,
      chargingHealth: chargingHealth ?? this.chargingHealth,
      toDos: toDos ?? this.toDos,
      dailyChecks: dailyChecks ?? this.dailyChecks,
      inventoryPhotoCount: inventoryPhotoCount ?? this.inventoryPhotoCount,
      lastInventoryTime: lastInventoryTime ?? this.lastInventoryTime,
      registrationNumber: this.registrationNumber,
      make: this.make,
      model: this.model,
      variant: this.variant,
      primaryHubId: this.primaryHubId,
      createdAt: this.createdAt,
    );
  }
}
