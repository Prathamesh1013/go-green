class CoreVehicleData {
  // Available vehicle makes
  static const List<String> makes = [
    'Tata',
    'BYD',
    'MG',
  ];

  // Vehicle models by make
  static const Map<String, List<String>> modelsByMake = {
    'Tata': [
      'XPRES-T XM',
      'XPRES-T XM+',
      'Nexon EV',
      'Tigor EV',
      'Tiago EV',
      'Punch EV',
    ],
    'BYD': [
      'E6',
      'E6 Plus',
      'Atto 3',
      'Seal',
      'Dolphin',
    ],
    'MG': [
      'ZS EV',
      'ZS EV Excite',
      'ZS EV Exclusive',
      'Comet EV',
      'Air EV',
    ],
  };

  // Get models for a specific make
  static List<String> getModelsForMake(String? make) {
    if (make == null || make.isEmpty) {
      return [];
    }
    return modelsByMake[make] ?? [];
  }

  // Get all models
  static List<String> getAllModels() {
    return modelsByMake.values.expand((models) => models).toList();
  }
}




