class ComplianceDocument {
  final String documentId;
  final String vehicleId;
  final String docType; // insurance, registration, PUC, permit, fitness, warranty, roadtax
  final String? issuer;
  final String? policyNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final int? daysUntilExpiry;
  final double? renewalCost;
  final String? scanUrl;
  final String status; // valid, expiring_soon, expired
  final DateTime createdDate;

  ComplianceDocument({
    required this.documentId,
    required this.vehicleId,
    required this.docType,
    this.issuer,
    this.policyNumber,
    this.issueDate,
    this.expiryDate,
    this.daysUntilExpiry,
    this.renewalCost,
    this.scanUrl,
    required this.status,
    required this.createdDate,
  });

  factory ComplianceDocument.fromJson(Map<String, dynamic> json) {
    return ComplianceDocument(
      documentId: json['document_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      docType: json['doc_type'] ?? '',
      issuer: json['issuer'],
      policyNumber: json['policy_number'],
      issueDate: json['issue_date'] != null 
          ? DateTime.parse(json['issue_date']) 
          : null,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      daysUntilExpiry: json['days_until_expiry'],
      renewalCost: json['renewal_cost']?.toDouble(),
      scanUrl: json['scan_url'],
      status: json['status'] ?? 'valid',
      createdDate: DateTime.parse(json['created_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'vehicle_id': vehicleId,
      'doc_type': docType,
      'issuer': issuer,
      'policy_number': policyNumber,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'days_until_expiry': daysUntilExpiry,
      'renewal_cost': renewalCost,
      'scan_url': scanUrl,
      'status': status,
      'created_date': createdDate.toIso8601String(),
    };
  }

  String get displayDocType {
    return docType.toUpperCase();
  }

  bool get isExpiringSoon => daysUntilExpiry != null && daysUntilExpiry! <= 30 && daysUntilExpiry! > 0;
  bool get isExpired => daysUntilExpiry != null && daysUntilExpiry! <= 0;
}





