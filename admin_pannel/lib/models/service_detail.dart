import 'package:gogreen_admin/models/customer_info.dart';
import 'package:gogreen_admin/models/vehicle_info.dart';
import 'package:gogreen_admin/models/service_item.dart';

class ServiceDetail {
  final String id;
  final String? kanbanCardId;
  final CustomerInfo customer;
  final VehicleInfo vehicle;
  final List<ServiceItem> periodicServiceItems;
  final List<ServiceItem> bodyshopItems;
  final Map<String, List<ServiceItem>> customJobs; // Map of job name -> items
  final String? customerNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceDetail({
    required this.id,
    this.kanbanCardId,
    required this.customer,
    required this.vehicle,
    List<ServiceItem>? periodicServiceItems,
    List<ServiceItem>? bodyshopItems,
    Map<String, List<ServiceItem>>? customJobs,
    this.customerNotes,
    DateTime? createdAt,
    this.updatedAt,
  })  : periodicServiceItems = periodicServiceItems ?? [],
        bodyshopItems = bodyshopItems ?? [],
        customJobs = customJobs ?? {},
        createdAt = createdAt ?? DateTime.now();

  // Calculated properties for Periodic Service
  double get periodicPartsCost {
    return periodicServiceItems.fold(0.0, (sum, item) => sum + item.partsCost);
  }

  double get periodicLabourCost {
    return periodicServiceItems.fold(0.0, (sum, item) => sum + item.labourCost);
  }

  double get periodicTotal => periodicPartsCost + periodicLabourCost;

  // Calculated properties for Bodyshop
  double get bodyshopPartsCost {
    return bodyshopItems.fold(0.0, (sum, item) => sum + item.partsCost);
  }

  double get bodyshopLabourCost {
    return bodyshopItems.fold(0.0, (sum, item) => sum + item.labourCost);
  }

  double get bodyshopTotal => bodyshopPartsCost + bodyshopLabourCost;

  // Calculated properties for Custom Jobs
  Map<String, double> get customJobsPartsCost {
    return customJobs.map((jobName, items) => MapEntry(
      jobName,
      items.fold(0.0, (sum, item) => sum + item.partsCost),
    ));
  }

  Map<String, double> get customJobsLabourCost {
    return customJobs.map((jobName, items) => MapEntry(
      jobName,
      items.fold(0.0, (sum, item) => sum + item.labourCost),
    ));
  }

  Map<String, double> get customJobsTotal {
    return customJobs.map((jobName, items) => MapEntry(
      jobName,
      items.fold(0.0, (sum, item) => sum + item.partsCost + item.labourCost),
    ));
  }

  // Grand total (includes all custom jobs)
  double get grandTotal {
    final customJobsSum = customJobsTotal.values.fold(0.0, (sum, total) => sum + total);
    return periodicTotal + bodyshopTotal + customJobsSum;
  }

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    return ServiceDetail(
      id: json['id'] ?? '',
      kanbanCardId: json['kanban_card_id'],
      customer: CustomerInfo.fromJson(json),
      vehicle: VehicleInfo.fromJson(json),
      periodicServiceItems: (json['periodic_items'] as List<dynamic>?)
              ?.map((item) => ServiceItem.fromJson(item))
              .toList() ??
          [],
      bodyshopItems: (json['bodyshop_items'] as List<dynamic>?)
              ?.map((item) => ServiceItem.fromJson(item))
              .toList() ??
          [],
      customJobs: (json['custom_jobs'] as Map<String, dynamic>?)
              ?.map((jobName, items) => MapEntry(
                jobName,
                (items as List<dynamic>)
                    .map((item) => ServiceItem.fromJson(item))
                    .toList(),
              )) ??
          {},
      customerNotes: json['customer_notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kanban_card_id': kanbanCardId,
      ...customer.toJson(),
      ...vehicle.toJson(),
      'periodic_items': periodicServiceItems.map((item) => item.toJson()).toList(),
      'bodyshop_items': bodyshopItems.map((item) => item.toJson()).toList(),
      'custom_jobs': customJobs.map((jobName, items) => MapEntry(
        jobName,
        items.map((item) => item.toJson()).toList(),
      )),
      'customer_notes': customerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ServiceDetail copyWith({
    String? id,
    String? kanbanCardId,
    CustomerInfo? customer,
    VehicleInfo? vehicle,
    List<ServiceItem>? periodicServiceItems,
    List<ServiceItem>? bodyshopItems,
    Map<String, List<ServiceItem>>? customJobs,
    String? customerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceDetail(
      id: id ?? this.id,
      kanbanCardId: kanbanCardId ?? this.kanbanCardId,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      periodicServiceItems: periodicServiceItems ?? this.periodicServiceItems,
      bodyshopItems: bodyshopItems ?? this.bodyshopItems,
      customJobs: customJobs ?? this.customJobs,
      customerNotes: customerNotes ?? this.customerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get default periodic items based on fuel type
  static List<ServiceItem> getDefaultPeriodicItems(String fuelType) {
    if (fuelType.toUpperCase() == 'EV') {
      // For EV, only include non-ICE-specific items
      return [
        ServiceItem.acFilter(),
        ServiceItem.frontBrakePads(),
        ServiceItem.rearBrakeLiners(),
        ServiceItem.periodicService(),
        ServiceItem.serviceLabour(),
        ServiceItem.wash(),
        ServiceItem.wheelAlignment(),
      ];
    }

    // For ICE, include all items
    return [
      ServiceItem.engineOil(),
      ServiceItem.oilFilter(),
      ServiceItem.airFilter(),
      ServiceItem.acFilter(),
      ServiceItem.frontBrakePads(),
      ServiceItem.rearBrakeLiners(),
      ServiceItem.periodicService(),
      ServiceItem.serviceLabour(),
      ServiceItem.wash(),
      ServiceItem.wheelAlignment(),
    ];
  }
}
