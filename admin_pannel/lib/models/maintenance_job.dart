class MaintenanceJob {
  final String jobId;
  final String vehicleId;
  final String jobType; // brake_pads, suspension, AC, battery, tyres, etc.
  final String jobCategory; // scheduled, breakdown, warranty, RSA, PDI
  final DateTime diagnosisDate;
  final String? serviceCenterId;
  final String? assignedTo; // technician_id
  final String status; // pending_diagnosis, in_progress, completed, on_hold, cancelled
  final DateTime? dueDate;
  final DateTime? completionDate;
  
  // Costs
  final double? totalCost;
  final double? partsCost;
  final double? labourCost;
  final bool warrantyFlag;
  final double? warrantyClaimAmount;
  
  // Notes
  final String? diagnosisNotes;
  final String? repairNotes;
  final String? customerNotes;
  
  final bool repeatFlag;
  final int repeatCount;
  final DateTime createdDate;
  final DateTime? updatedDate;

  MaintenanceJob({
    required this.jobId,
    required this.vehicleId,
    required this.jobType,
    required this.jobCategory,
    required this.diagnosisDate,
    this.serviceCenterId,
    this.assignedTo,
    required this.status,
    this.dueDate,
    this.completionDate,
    this.totalCost,
    this.partsCost,
    this.labourCost,
    this.warrantyFlag = false,
    this.warrantyClaimAmount,
    this.diagnosisNotes,
    this.repairNotes,
    this.customerNotes,
    this.repeatFlag = false,
    this.repeatCount = 0,
    required this.createdDate,
    this.updatedDate,
  });

  factory MaintenanceJob.fromJson(Map<String, dynamic> json) {
    return MaintenanceJob(
      jobId: json['job_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      jobType: json['job_type'] ?? '',
      jobCategory: json['job_category'] ?? '',
      diagnosisDate: DateTime.parse(json['diagnosis_date']),
      serviceCenterId: json['service_center_id'],
      assignedTo: json['assigned_to'],
      status: json['status'] ?? 'pending_diagnosis',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completionDate: json['completion_date'] != null 
          ? DateTime.parse(json['completion_date']) 
          : null,
      totalCost: json['total_cost']?.toDouble(),
      partsCost: json['parts_cost']?.toDouble(),
      labourCost: json['labour_cost']?.toDouble(),
      warrantyFlag: json['warranty_flag'] ?? false,
      warrantyClaimAmount: json['warranty_claim_amount']?.toDouble(),
      diagnosisNotes: json['diagnosis_notes'],
      repairNotes: json['repair_notes'],
      customerNotes: json['customer_notes'],
      repeatFlag: json['repeat_flag'] ?? false,
      repeatCount: json['repeat_count'] ?? 0,
      createdDate: DateTime.parse(json['created_date']),
      updatedDate: json['updated_date'] != null 
          ? DateTime.parse(json['updated_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'vehicle_id': vehicleId,
      'job_type': jobType,
      'job_category': jobCategory,
      'diagnosis_date': diagnosisDate.toIso8601String(),
      'service_center_id': serviceCenterId,
      'assigned_to': assignedTo,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'total_cost': totalCost,
      'parts_cost': partsCost,
      'labour_cost': labourCost,
      'warranty_flag': warrantyFlag,
      'warranty_claim_amount': warrantyClaimAmount,
      'diagnosis_notes': diagnosisNotes,
      'repair_notes': repairNotes,
      'customer_notes': customerNotes,
      'repeat_flag': repeatFlag,
      'repeat_count': repeatCount,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate?.toIso8601String(),
    };
  }

  String get displayJobType {
    return jobType.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}





