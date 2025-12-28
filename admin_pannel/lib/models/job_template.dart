class JobTemplate {
  final String id;
  final String name;
  final List<TemplatePart> parts;
  final List<TemplateLabor> labor;
  final List<TemplateOther> other;

  JobTemplate({
    required this.id,
    required this.name,
    required this.parts,
    required this.labor,
    required this.other,
  });

  factory JobTemplate.fromJson(Map<String, dynamic> json) {
    return JobTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parts: (json['parts'] as List? ?? [])
          .map((p) => TemplatePart.fromJson(p))
          .toList(),
      labor: (json['labor'] as List? ?? [])
          .map((l) => TemplateLabor.fromJson(l))
          .toList(),
      other: (json['other'] as List? ?? [])
          .map((o) => TemplateOther.fromJson(o))
          .toList(),
    );
  }
}

class TemplatePart {
  final String name;
  final int defaultQuantity;
  final double defaultPrice;

  TemplatePart({
    required this.name,
    this.defaultQuantity = 1,
    this.defaultPrice = 0.0,
  });

  factory TemplatePart.fromJson(Map<String, dynamic> json) {
    return TemplatePart(
      name: json['name'] ?? '',
      defaultQuantity: json['quantity'] ?? 1,
      defaultPrice: (json['price'] ?? 0).toDouble(),
    );
  }
}

class TemplateLabor {
  final String name;
  final double defaultPrice;

  TemplateLabor({
    required this.name,
    this.defaultPrice = 0.0,
  });

  factory TemplateLabor.fromJson(Map<String, dynamic> json) {
    return TemplateLabor(
      name: json['name'] ?? '',
      defaultPrice: (json['price'] ?? 0).toDouble(),
    );
  }
}

class TemplateOther {
  final String name;
  final double defaultPrice;

  TemplateOther({
    required this.name,
    this.defaultPrice = 0.0,
  });

  factory TemplateOther.fromJson(Map<String, dynamic> json) {
    return TemplateOther(
      name: json['name'] ?? '',
      defaultPrice: (json['price'] ?? 0).toDouble(),
    );
  }
}

// Predefined job templates
class JobTemplates {
  static List<JobTemplate> getTemplates() {
    return [
      JobTemplate(
        id: 'periodic_service',
        name: 'Periodic Service',
        parts: [
          TemplatePart(name: 'Engine oil(3.5L Bosch)', defaultQuantity: 1, defaultPrice: 1700),
          TemplatePart(name: 'Air filter', defaultQuantity: 1, defaultPrice: 290),
          TemplatePart(name: 'Ac filter', defaultQuantity: 1, defaultPrice: 305),
          TemplatePart(name: 'Spark plugs', defaultQuantity: 3, defaultPrice: 172),
          TemplatePart(name: 'Brake pads', defaultQuantity: 1, defaultPrice: 562),
          TemplatePart(name: 'Oil filter', defaultQuantity: 1, defaultPrice: 99),
        ],
        labor: [
          TemplateLabor(name: 'Periodic Service', defaultPrice: 1200),
          TemplateLabor(name: 'Wash', defaultPrice: 400),
          TemplateLabor(name: 'Wheel alignment balancing', defaultPrice: 750),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'clutch_overhaul',
        name: 'Clutch Overhaul',
        parts: [
          TemplatePart(name: 'Clutch assembly(Amt)', defaultQuantity: 1, defaultPrice: 2255),
          TemplatePart(name: 'Release Bearing', defaultQuantity: 1, defaultPrice: 507),
          TemplatePart(name: 'Gear Oil', defaultQuantity: 1, defaultPrice: 1100),
        ],
        labor: [
          TemplateLabor(name: 'Clutch Overhaul Labor', defaultPrice: 1500),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'suspension_overhaul',
        name: 'Suspension Overhaul',
        parts: [
          TemplatePart(name: 'Shock Absorber (Front)', defaultQuantity: 2, defaultPrice: 2500),
          TemplatePart(name: 'Shock Absorber (Rear)', defaultQuantity: 2, defaultPrice: 2000),
          TemplatePart(name: 'Strut Mount', defaultQuantity: 2, defaultPrice: 800),
        ],
        labor: [
          TemplateLabor(name: 'Suspension Overhaul Labor', defaultPrice: 2000),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'ac_service',
        name: 'AC Service',
        parts: [
          TemplatePart(name: 'AC Filter', defaultQuantity: 1, defaultPrice: 305),
          TemplatePart(name: 'AC Gas Refill', defaultQuantity: 1, defaultPrice: 1200),
        ],
        labor: [
          TemplateLabor(name: 'AC Service Labor', defaultPrice: 800),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'tyre_changes',
        name: 'Tyre Changes',
        parts: [
          TemplatePart(name: 'Tyre (Front)', defaultQuantity: 2, defaultPrice: 3500),
          TemplatePart(name: 'Tyre (Rear)', defaultQuantity: 2, defaultPrice: 3000),
        ],
        labor: [
          TemplateLabor(name: 'Tyre Fitting', defaultPrice: 500),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'wheel_alignment_balance',
        name: 'Wheel Alignment and Balance',
        parts: [],
        labor: [
          TemplateLabor(name: 'Wheel Alignment', defaultPrice: 400),
          TemplateLabor(name: 'Wheel Balancing', defaultPrice: 350),
        ],
        other: [],
      ),
      JobTemplate(
        id: 'general',
        name: 'General',
        parts: [],
        labor: [],
        other: [],
      ),
      JobTemplate(
        id: 'custom_job',
        name: 'Custom Job',
        parts: [],
        labor: [],
        other: [],
      ),
    ];
  }
}



