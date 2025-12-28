class Task {
  final String taskId;
  final String interactionId;
  final String category; // 'Part', 'Labor', 'Other'
  final String taskType; // Job name like 'Periodic Service', 'Clutch Overhaul'
  final int quantity;
  final String description;
  final bool isCompleted;
  final String? vendorName;
  final double purchasePrice;
  final double sellPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.taskId,
    required this.interactionId,
    required this.category,
    required this.taskType,
    required this.quantity,
    required this.description,
    required this.isCompleted,
    this.vendorName,
    required this.purchasePrice,
    required this.sellPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['task_id'] ?? '',
      interactionId: json['interaction_id'] ?? '',
      category: json['category'] ?? 'Other',
      taskType: json['task_type'] ?? '',
      quantity: json['quantity'] ?? 1,
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      vendorName: json['vendor_name'],
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      sellPrice: (json['sell_price'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'interaction_id': interactionId,
      'category': category,
      'task_type': taskType,
      'quantity': quantity,
      'description': description,
      'is_completed': isCompleted,
      'vendor_name': vendorName,
      'purchase_price': purchasePrice,
      'sell_price': sellPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}



