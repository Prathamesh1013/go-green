class CustomerInfo {
  final String name;
  final String phone;
  final String email;
  final DateTime date;
  final String? gstNumber; // Optional

  CustomerInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.date,
    this.gstNumber,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['customer_name'] ?? '',
      phone: json['customer_phone'] ?? '',
      email: json['customer_email'] ?? '',
      date: json['service_date'] != null 
          ? DateTime.parse(json['service_date']) 
          : DateTime.now(),
      gstNumber: json['gst_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_name': name,
      'customer_phone': phone,
      'customer_email': email,
      'service_date': date.toIso8601String(),
      'gst_number': gstNumber,
    };
  }

  CustomerInfo copyWith({
    String? name,
    String? phone,
    String? email,
    DateTime? date,
    String? gstNumber,
  }) {
    return CustomerInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      date: date ?? this.date,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }
}
