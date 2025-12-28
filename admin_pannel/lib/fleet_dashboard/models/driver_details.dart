class DriverDetails {
  final String name;
  final String phone;
  final String licenseNumber;
  final double rating;
  final int totalTrips;
  final String imageUrl;
  final int drivingScore;
  final int currentMonthTrips;
  final int drivingHours;

  DriverDetails({
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.rating,
    required this.totalTrips,
    required this.imageUrl,
    required this.drivingScore,
    required this.currentMonthTrips,
    required this.drivingHours,
  });

  factory DriverDetails.fromJson(Map<String, dynamic> json) {
    return DriverDetails(
      name: json['name'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['licenseNumber'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalTrips: json['totalTrips'] as int,
      imageUrl: json['imageUrl'] as String,
      drivingScore: json['drivingScore'] as int,
      currentMonthTrips: json['currentMonthTrips'] as int,
      drivingHours: json['drivingHours'] as int,
    );
  }
}
