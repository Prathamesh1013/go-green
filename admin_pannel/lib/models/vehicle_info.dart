class VehicleInfo {
  final String registrationNumber;
  final String makeAndModel;
  final int year;
  final String fuelType; // 'EV' or 'ICE'

  VehicleInfo({
    required this.registrationNumber,
    required this.makeAndModel,
    required this.year,
    required this.fuelType,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      registrationNumber: json['vehicle_reg_number'] ?? '',
      makeAndModel: json['vehicle_make_model'] ?? '',
      year: json['vehicle_year'] ?? DateTime.now().year,
      fuelType: json['vehicle_fuel_type'] ?? 'EV',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_reg_number': registrationNumber,
      'vehicle_make_model': makeAndModel,
      'vehicle_year': year,
      'vehicle_fuel_type': fuelType,
    };
  }

  bool get isEV => fuelType.toUpperCase() == 'EV';
  bool get isICE => fuelType.toUpperCase() == 'ICE';

  VehicleInfo copyWith({
    String? registrationNumber,
    String? makeAndModel,
    int? year,
    String? fuelType,
  }) {
    return VehicleInfo(
      registrationNumber: registrationNumber ?? this.registrationNumber,
      makeAndModel: makeAndModel ?? this.makeAndModel,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
    );
  }
}
