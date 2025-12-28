class Interaction {
  final String interactionId;
  final String vehicleId;
  final String interactionNumber;
  final String interactionStatus;
  final int currentOdometerReading;
  final DateTime pickupDateTime;
  final String vendorName;
  final String primaryJob;
  final String customerNote;
  final double purchasePrice;
  final double sellPrice;
  final double? profit;
  final String customerPaymentStatus;
  final String vendorPaymentStatus;
  final double totalAmount;
  final DateTime deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Interaction({
    required this.interactionId,
    required this.vehicleId,
    required this.interactionNumber,
    required this.interactionStatus,
    required this.currentOdometerReading,
    required this.pickupDateTime,
    required this.vendorName,
    required this.primaryJob,
    required this.customerNote,
    required this.purchasePrice,
    required this.sellPrice,
    this.profit,
    required this.customerPaymentStatus,
    required this.vendorPaymentStatus,
    required this.totalAmount,
    required this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      interactionId: json['interaction_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      interactionNumber: json['interaction_number'] ?? '',
      interactionStatus: json['interaction_status'] ?? '',
      currentOdometerReading: json['current_odometer_reading'] ?? 0,
      pickupDateTime: DateTime.parse(json['pickup_date_time']),
      vendorName: json['vendor_name'] ?? '',
      primaryJob: json['primary_job'] ?? '',
      customerNote: json['customer_note'] ?? '',
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellPrice: (json['sell_price'] ?? 0).toDouble(),
      profit: json['profit']?.toDouble(),
      customerPaymentStatus: json['customer_payment_status'] ?? '',
      vendorPaymentStatus: json['vendor_payment_status'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      deliveryDate: DateTime.parse(json['delivery_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interaction_id': interactionId,
      'vehicle_id': vehicleId,
      'interaction_number': interactionNumber,
      'interaction_status': interactionStatus,
      'current_odometer_reading': currentOdometerReading,
      'pickup_date_time': pickupDateTime.toIso8601String(),
      'vendor_name': vendorName,
      'primary_job': primaryJob,
      'customer_note': customerNote,
      'purchase_price': purchasePrice,
      'sell_price': sellPrice,
      'profit': profit,
      'customer_payment_status': customerPaymentStatus,
      'vendor_payment_status': vendorPaymentStatus,
      'total_amount': totalAmount,
      'delivery_date': deliveryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Interaction copyWith({
    String? interactionId,
    String? vehicleId,
    String? interactionNumber,
    String? interactionStatus,
    int? currentOdometerReading,
    DateTime? pickupDateTime,
    String? vendorName,
    String? primaryJob,
    String? customerNote,
    double? purchasePrice,
    double? sellPrice,
    double? profit,
    String? customerPaymentStatus,
    String? vendorPaymentStatus,
    double? totalAmount,
    DateTime? deliveryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interaction(
      interactionId: interactionId ?? this.interactionId,
      vehicleId: vehicleId ?? this.vehicleId,
      interactionNumber: interactionNumber ?? this.interactionNumber,
      interactionStatus: interactionStatus ?? this.interactionStatus,
      currentOdometerReading: currentOdometerReading ?? this.currentOdometerReading,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      vendorName: vendorName ?? this.vendorName,
      primaryJob: primaryJob ?? this.primaryJob,
      customerNote: customerNote ?? this.customerNote,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      profit: profit ?? this.profit,
      customerPaymentStatus: customerPaymentStatus ?? this.customerPaymentStatus,
      vendorPaymentStatus: vendorPaymentStatus ?? this.vendorPaymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}



