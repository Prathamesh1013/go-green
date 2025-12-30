class ChargingSession {
  final String chargeSessionId;
  final String vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final double? energyKwh;
  final int? chargeLevelStart;
  final int? chargeLevelEnd;
  final String? locationId;
  final String? sessionType; // depot, public_charger, emergency_charge
  final double? cost;
  final DateTime createdDate;

  ChargingSession({
    required this.chargeSessionId,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    this.energyKwh,
    this.chargeLevelStart,
    this.chargeLevelEnd,
    this.locationId,
    this.sessionType,
    this.cost,
    required this.createdDate,
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      chargeSessionId: json['charge_session_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : null,
      energyKwh: json['energy_kwh']?.toDouble(),
      chargeLevelStart: json['charge_level_start'],
      chargeLevelEnd: json['charge_level_end'],
      locationId: json['location_id'],
      sessionType: json['session_type'],
      cost: json['cost']?.toDouble(),
      createdDate: DateTime.parse(json['created_date']),
    );
  }

  Duration? get duration => endTime != null 
      ? endTime!.difference(startTime)
      : null;

  String get displayDuration {
    if (duration == null) return 'In Progress';
    final d = duration!;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  String get displaySessionType {
    switch (sessionType) {
      case 'depot':
        return 'Depot';
      case 'public_charger':
        return 'Public Charger';
      case 'emergency_charge':
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }
}




