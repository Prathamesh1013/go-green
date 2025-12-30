class ServiceItem {
  final String id;
  final String name;
  final int quantity;
  final double partsCost;
  final double labourCost;
  final bool isICESpecific; // For EV-first logic
  final String itemType; // 'periodic' or 'bodyshop'

  ServiceItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.partsCost = 0.0,
    this.labourCost = 0.0,
    this.isICESpecific = false,
    required this.itemType,
  });

  double get totalCost => partsCost + labourCost;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      partsCost: (json['parts_cost'] ?? 0).toDouble(),
      labourCost: (json['labour_cost'] ?? 0).toDouble(),
      isICESpecific: json['is_ice_specific'] ?? false,
      itemType: json['item_type'] ?? 'periodic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'parts_cost': partsCost,
      'labour_cost': labourCost,
      'is_ice_specific': isICESpecific,
      'item_type': itemType,
    };
  }

  ServiceItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? partsCost,
    double? labourCost,
    bool? isICESpecific,
    String? itemType,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      partsCost: partsCost ?? this.partsCost,
      labourCost: labourCost ?? this.labourCost,
      isICESpecific: isICESpecific ?? this.isICESpecific,
      itemType: itemType ?? this.itemType,
    );
  }

  // Factory methods for creating default items
  static ServiceItem engineOil() => ServiceItem(
    id: 'engine_oil',
    name: 'Engine Oil',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: true,
    itemType: 'periodic',
  );

  static ServiceItem oilFilter() => ServiceItem(
    id: 'oil_filter',
    name: 'Oil Filter',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: true,
    itemType: 'periodic',
  );

  static ServiceItem airFilter() => ServiceItem(
    id: 'air_filter',
    name: 'Air Filter',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: true,
    itemType: 'periodic',
  );

  static ServiceItem acFilter() => ServiceItem(
    id: 'ac_filter',
    name: 'AC Filter',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem frontBrakePads() => ServiceItem(
    id: 'front_brake_pads',
    name: 'Front brake pads',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem rearBrakeLiners() => ServiceItem(
    id: 'rear_brake_liners',
    name: 'Rear brake liners',
    quantity: 1,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem periodicService() => ServiceItem(
    id: 'periodic_service',
    name: 'Periodic Service',
    quantity: 0,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem serviceLabour() => ServiceItem(
    id: 'service_labour',
    name: 'Service Labour',
    quantity: 800,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem wash() => ServiceItem(
    id: 'wash',
    name: 'Wash',
    quantity: 0,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );

  static ServiceItem wheelAlignment() => ServiceItem(
    id: 'wheel_alignment',
    name: 'Wheel Alignment & Balancing',
    quantity: 1000,
    partsCost: 0,
    labourCost: 0,
    isICESpecific: false,
    itemType: 'periodic',
  );
}
