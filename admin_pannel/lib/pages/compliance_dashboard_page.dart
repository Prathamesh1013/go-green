import 'dart:math';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/models/compliance.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';

class ComplianceDashboardPage extends StatefulWidget {
  const ComplianceDashboardPage({super.key});

  @override
  State<ComplianceDashboardPage> createState() => _ComplianceDashboardPageState();
}

class _ComplianceDashboardPageState extends State<ComplianceDashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<_ComplianceData> _future;

  static const List<String> _requiredDocs = [
    'insurance',
    'registration', // RC
    'fitness',
    'roadtax',
    'warranty',
  ];

  static const List<String> _warrantyCategories = [
    'Battery Warranty',
    'Electric Motor & Powertrain Warranty',
    'Bumper-to-Bumper Warranty',
    'Charging Equipment Warranty',
    'Extended Warranty',
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_ComplianceData> _loadData() async {
    final vehicles = await _supabaseService.getVehicles();
    final docs = await _supabaseService.getComplianceDocumentsForFleet(
      vehicleIds: vehicles.map((v) => v.vehicleId).toList(),
    );
    return _ComplianceData(vehicles: vehicles, documents: docs);
  }

  String _normalizeDocType(String docType) => docType.toLowerCase();

  String _displayDocType(String docType) {
    switch (_normalizeDocType(docType)) {
      case 'registration':
        return 'RC';
      case 'puc':
        return 'PUC';
      case 'roadtax':
        return 'Road Tax';
      default:
        return docType[0].toUpperCase() + docType.substring(1);
    }
  }

  String _docStatus(ComplianceDocument? doc) {
    if (doc == null || doc.expiryDate == null) return 'missing';
    final days = doc.expiryDate!.difference(DateTime.now()).inDays;
    if (days < 0) return 'expired';
    if (days <= 30) return 'expiring';
    return 'valid';
  }

  int _daysLeft(ComplianceDocument? doc) {
    if (doc == null || doc.expiryDate == null) return -1;
    return doc.expiryDate!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/compliance',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Â· Compliance & Documents'),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                  tooltip: themeProvider.themeMode == ThemeMode.dark
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                );
              },
            ),
          ],
        ),
        body: FutureBuilder<_ComplianceData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load compliance data: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = _loadData();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final analytics = _buildAnalytics(data);



            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildComplianceScoreCard(context, analytics),
                  const SizedBox(height: 16),
                  _buildExpirySummary(context, analytics),
                  const SizedBox(height: 16),
              _buildCharts(context, analytics),
              const SizedBox(height: 16),
              _buildVehicleDocumentList(context, data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _ComplianceAnalytics _buildAnalytics(_ComplianceData data) {
    final docsByVehicle = <String, List<ComplianceDocument>>{};
    for (final doc in data.documents) {
      docsByVehicle.putIfAbsent(doc.vehicleId, () => []).add(doc);
    }

    int compliantVehicles = 0;
    for (final vehicle in data.vehicles) {
      final vehicleDocs = docsByVehicle[vehicle.vehicleId] ?? [];
      final docMap = <String, ComplianceDocument>{};
      for (final d in vehicleDocs) {
        docMap[_normalizeDocType(d.docType)] = d;
      }

      final allDocsValid = _requiredDocs.every((req) {
        final doc = docMap[req];
        if (doc == null) return false;
        return _docStatus(doc) == 'valid';
      });

      if (allDocsValid) {
        compliantVehicles += 1;
      }
    }

    final summary = <String, _DocSummary>{};
    final attentionRows = <_AttentionRow>[];
    double totalBudget = 0;
    double usedBudget = 0;
    final now = DateTime.now();

    for (final doc in data.documents) {
      final normalizedType = _normalizeDocType(doc.docType);
      final status = _docStatus(doc);
      final summaryItem = summary.putIfAbsent(normalizedType, () => _DocSummary());
      summaryItem.increment(status);

      final cost = doc.renewalCost ?? 0;
      totalBudget += cost;

      if (status != 'valid') {
        usedBudget += cost;
        final vehicle = data.vehicleIndex[doc.vehicleId];
        if (vehicle != null) {
          attentionRows.add(_AttentionRow(
            vehicle: vehicle,
            document: doc,
            status: status,
            daysLeft: _daysLeft(doc),
          ));
        }
      }
    }

    // Mark missing required documents per vehicle
    for (final vehicle in data.vehicles) {
      final vehicleDocs = docsByVehicle[vehicle.vehicleId] ?? [];
      final docMap = <String, ComplianceDocument>{};
      for (final d in vehicleDocs) {
        docMap[_normalizeDocType(d.docType)] = d;
      }

      for (final req in _requiredDocs) {
        final doc = docMap[req];
        final status = _docStatus(doc);
        if (status == 'missing') {
          final summaryItem = summary.putIfAbsent(req, () => _DocSummary());
          summaryItem.increment('missing');
          attentionRows.add(
            _AttentionRow(
              vehicle: vehicle,
              document: doc,
              status: 'missing',
              daysLeft: -1,
              docTypeOverride: req,
            ),
          );
        }
      }
    }

    final forecastBuckets = _bucketRenewalForecast(data.documents, now);

    final remainingBudget = max<double>(0.0, totalBudget - usedBudget);

    return _ComplianceAnalytics(
      compliantVehicles: compliantVehicles,
      totalVehicles: data.vehicles.length,
      summary: summary,
      attentionRows: attentionRows,
      forecastBuckets: forecastBuckets,
      totalBudget: totalBudget,
      usedBudget: usedBudget,
      remainingBudget: remainingBudget,
    );
  }

  Map<String, double> _bucketRenewalForecast(
    List<ComplianceDocument> docs,
    DateTime now,
  ) {
    double bucket0to30 = 0;
    double bucket31to60 = 0;
    double bucket61to90 = 0;

    for (final doc in docs) {
      if (doc.expiryDate == null || doc.renewalCost == null) continue;
      final days = doc.expiryDate!.difference(now).inDays;
      if (days > 90) continue;

      final clamped = days < 0 ? 0 : days;
      if (clamped <= 30) {
        bucket0to30 += doc.renewalCost!;
      } else if (clamped <= 60) {
        bucket31to60 += doc.renewalCost!;
      } else {
        bucket61to90 += doc.renewalCost!;
      }
    }

    return {
      '0-30': bucket0to30,
      '31-60': bucket31to60,
      '61-90': bucket61to90,
    };
  }

  Widget _buildComplianceScoreCard(BuildContext context, _ComplianceAnalytics analytics) {
    final compliant = analytics.compliantVehicles;
    final total = analytics.totalVehicles;
    final ratio = total == 0 ? 0.0 : compliant / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white, // Clean white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 10,
                    backgroundColor: AppColors.lightBorder.withValues(alpha: 0.4),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(ratio * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$compliant / $total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Score',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A vehicle is marked compliant only when all required documents '
                  '(Insurance, RC, PUC, Fitness, Road Tax, Warranty) are valid with more than 30 days left.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _SummaryChip(
                      label: 'Fully Compliant',
                      value: compliant.toString(),
                      color: AppColors.success,
                    ),
                    _SummaryChip(
                      label: 'Needs Attention',
                      value: (total - compliant).toString(),
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirySummary(BuildContext context, _ComplianceAnalytics analytics) {
    final entries = analytics.summary.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white, // Clean white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Expiry Status',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Valid > 30 days · Expiring ≤ 30 days · Expired < today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 1000 ? constraints.maxWidth / 3 - 12 : constraints.maxWidth / 2 - 12;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: entries.map((entry) {
                  final summary = entry.value;
                  return SizedBox(
                    width: itemWidth,
                    child: _ExpirySummaryCard(
                      title: _displayDocType(entry.key),
                      valid: summary.valid,
                      expiring: summary.expiring,
                      expired: summary.expired,
                      missing: summary.missing,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildCharts(BuildContext context, _ComplianceAnalytics analytics) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _RenewalForecastChart(buckets: analytics.forecastBuckets),
        ),
        const SizedBox(width: 12), // Reduced from 16 to fix overflow
        Expanded(
          flex: 1,
          child: _BudgetCard(
            total: analytics.totalBudget,
            used: analytics.usedBudget,
            remaining: analytics.remainingBudget,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDocumentList(BuildContext context, _ComplianceData data) {
    final docsByVehicle = <String, List<ComplianceDocument>>{};
    for (final doc in data.documents) {
      docsByVehicle.putIfAbsent(doc.vehicleId, () => []).add(doc);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicles & Documents',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Click on a vehicle to view all compliance documents and their expiry dates.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...data.vehicles.map((vehicle) {
            final vehicleDocs = docsByVehicle[vehicle.vehicleId] ?? [];
            final docMap = <String, ComplianceDocument>{};
            for (final d in vehicleDocs) {
              docMap[_normalizeDocType(d.docType)] = d;
            }

            // Calculate compliance status and get attention documents
            int needsAttention = 0;
            bool isCompliant = true;
            final attentionDocs = <Map<String, dynamic>>[];
            
            for (final req in _requiredDocs) {
              final doc = docMap[req];
              final status = _docStatus(doc);
              if (status != 'valid') {
                needsAttention++;
                isCompliant = false;
                
                // Add to attention docs
                final daysLeft = _daysLeft(doc);
                final expiry = doc?.expiryDate != null
                    ? '${doc!.expiryDate!.year}-${doc.expiryDate!.month.toString().padLeft(2, '0')}-${doc.expiryDate!.day.toString().padLeft(2, '0')}'
                    : 'N/A';
                
                attentionDocs.add({
                  'label': _displayDocType(req),
                  'expiry': expiry,
                  'daysLeft': daysLeft,
                  'status': status,
                });
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VehicleExpandableCard(
                vehicle: vehicle,
                isCompliant: isCompliant,
                needsAttentionCount: needsAttention,
                attentionDocs: attentionDocs,
                onViewAll: () => _showVehicleDocumentsDialog(context, vehicle, docMap),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showVehicleDocumentsDialog(
    BuildContext context,
    Vehicle vehicle,
    Map<String, ComplianceDocument> docMap,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.vehicleNumber,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (vehicle.displayName.isNotEmpty)
                            Text(
                              vehicle.displayName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Document list
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compliance Documents',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ..._buildDocumentItems(context, docMap, vehicle),
                      const SizedBox(height: 16),
                      Text(
                        'Warranty Categories',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildWarrantySection(context, docMap, vehicle),
                    ],
                  ),
                ),
              ),
              // Footer with action button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/vehicles/${vehicle.vehicleId}');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Vehicle'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDocumentItems(BuildContext context, Map<String, ComplianceDocument> docMap, Vehicle vehicle) {
    return _requiredDocs.map((req) {
      final doc = docMap[req];
      final status = _docStatus(doc);
      final expiry = doc?.expiryDate != null
          ? '${doc!.expiryDate!.year}-${doc.expiryDate!.month.toString().padLeft(2, '0')}-${doc.expiryDate!.day.toString().padLeft(2, '0')}'
          : 'Not available';
      final daysLeft = _daysLeft(doc);
      final daysLabel = daysLeft >= 0 ? '$daysLeft days left' : 'Missing';

      return _DocumentListItem(
        label: _displayDocType(req),
        expiry: expiry,
        daysLabel: daysLabel,
        status: status,
        document: doc,
        docType: req,
        vehicle: vehicle,
        onUpload: () => _showUploadDocumentDialog(context, vehicle, req),
        onRefresh: () => setState(() => _future = _loadData()),
      );
    }).toList();
  }

  Widget _buildWarrantySection(BuildContext context, Map<String, ComplianceDocument> docMap, Vehicle vehicle) {
    // Get all warranty documents for this vehicle (doc_type starts with 'warranty_')
    final warranties = docMap.entries
        .where((entry) => entry.key.startsWith('warranty_'))
        .map((entry) => entry.value)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Warranty Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddWarrantyDialog(context, vehicle),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Warranty'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (warranties.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'No warranties added yet. Click "Add Warranty" to add one.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          )
        else
          ...warranties.map((warranty) {
            final warrantyName = warranty.docType?.replaceFirst('warranty_', '').replaceAll('_', ' ') ?? 'Unknown';
            final status = _docStatus(warranty);
            final expiry = warranty.expiryDate != null
                ? '${warranty.expiryDate!.year}-${warranty.expiryDate!.month.toString().padLeft(2, '0')}-${warranty.expiryDate!.day.toString().padLeft(2, '0')}'
                : 'Not available';
            final daysLeft = _daysLeft(warranty);
            final daysLabel = daysLeft >= 0 ? '$daysLeft days left' : 'Missing';
            final hasDocument = warranty.scanUrl != null && warranty.scanUrl!.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warrantyName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expiry: $expiry',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          daysLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  // Upload button
                  ElevatedButton.icon(
                    onPressed: () => _showUploadDocumentDialog(context, vehicle, warranty.docType!),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View button if document exists
                  if (hasDocument) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        if (warranty.scanUrl != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening: ${warranty.scanUrl}')),
                          );
                        }
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _ComplianceBadge(status: status),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }


  // Upload document dialog
  void _showUploadDocumentDialog(BuildContext context, Vehicle vehicle, [String? preselectedDocType]) {
    String? selectedDocType = preselectedDocType;
    DateTime? selectedExpiryDate;
    PlatformFile? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Upload Document for ${vehicle.vehicleNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Document Type Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDocType,
                    decoration: const InputDecoration(
                      labelText: 'Document Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                      DropdownMenuItem(value: 'registration', child: Text('RC (Registration)')),
                      DropdownMenuItem(value: 'fitness', child: Text('Fitness Certificate')),
                      DropdownMenuItem(value: 'roadtax', child: Text('Road Tax')),
                      DropdownMenuItem(value: 'warranty', child: Text('Warranty')),
                    ],
                    onChanged: (value) => setState(() => selectedDocType = value),
                  ),
                  const SizedBox(height: 16),
                  // Expiry Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedExpiryDate == null
                        ? 'Select Expiry Date *'
                        : 'Expiry: ${selectedExpiryDate!.year}-${selectedExpiryDate!.month}-${selectedExpiryDate!.day}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) setState(() => selectedExpiryDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  // File Picker
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final file = result.files.first;
                        if (file.size > 10 * 1024 * 1024) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File size must be less than 10MB')),
                          );
                        } else {
                          setState(() => selectedFile = file);
                        }
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile == null ? 'Choose File (PDF, JPG)' : selectedFile!.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // Blue color
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Size: ${(selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (isUploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedDocType == null || selectedExpiryDate == null || selectedFile == null || isUploading)
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          // Upload file to Supabase Storage
                          final fileName = '${vehicle.vehicleId}/${selectedDocType}_${DateTime.now().millisecondsSinceEpoch}.${selectedFile!.extension}';
                          await _supabaseService.uploadFile(
                            fileName,
                            selectedFile!.bytes!,
                            selectedFile!.extension == 'pdf' ? 'application/pdf' : 'image/jpeg',
                          );
                          final fileUrl = _supabaseService.getPublicUrl(fileName);

                          // Create database record
                          await _supabaseService.createComplianceDocument({
                            'vehicle_id': vehicle.vehicleId,
                            'doc_type': selectedDocType,
                            'expiry_date': selectedExpiryDate!.toIso8601String(),
                            'scan_url': fileUrl,
                            'status': 'valid',
                          });

                          Navigator.of(dialogContext).pop();
                          
                          // Show success notification
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Document uploaded successfully! ${_displayDocType(selectedDocType!)} has been saved.',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 4),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
                                dismissDirection: DismissDirection.up,
                                elevation: 1000,
                              ),
                            );
                          }
                          
                          // Refresh data
                          this.setState(() => _future = _loadData());
                        } catch (e) {
                          // Show error notification
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Upload failed: ${e.toString()}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.error,
                                duration: Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
                                dismissDirection: DismissDirection.up,
                                elevation: 1000,
                              ),
                            );
                          }
                        } finally {
                          setState(() => isUploading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success, // Green color
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Upload'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Add warranty dialog
  Future<void> _showAddWarrantyDialog(BuildContext context, Vehicle vehicle) async {
    String warrantyName = '';
    DateTime? selectedExpiryDate;
    PlatformFile? selectedFile;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Warranty for ${vehicle.vehicleNumber}'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warranty Name Input
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Warranty Name *',
                          hintText: 'e.g., Battery Warranty, Tyre Warranty',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => warrantyName = value,
                      ),
                      const SizedBox(height: 16),
                      
                      // Expiry Date Picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() => selectedExpiryDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Select Expiry Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            selectedExpiryDate != null
                                ? '${selectedExpiryDate!.year}-${selectedExpiryDate!.month.toString().padLeft(2, '0')}-${selectedExpiryDate!.day.toString().padLeft(2, '0')}'
                                : 'Tap to select date',
                            style: TextStyle(
                              color: selectedExpiryDate != null ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // File Picker Button
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setState(() => selectedFile = result.files.first);
                          }
                        },
                        icon: const Icon(Icons.attach_file),
                        label: Text(selectedFile != null ? selectedFile!.name : 'Choose File (Optional)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      
                      if (selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Size: ${(selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      
                      if (isUploading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Adding warranty...'),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (warrantyName.trim().isNotEmpty && selectedExpiryDate != null && !isUploading)
                      ? () async {
                          setState(() => isUploading = true);
                          
                          try {
                            String? fileUrl;
                            
                            // Upload file if selected
                            if (selectedFile != null) {
                              final fileName = '${vehicle.vehicleId}/warranty_${warrantyName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.${selectedFile!.extension}';
                              await _supabaseService.uploadFile(
                                fileName,
                                selectedFile!.bytes!,
                                selectedFile!.extension == 'pdf' ? 'application/pdf' : 'image/${selectedFile!.extension}',
                              );
                              fileUrl = _supabaseService.getPublicUrl(fileName);
                            }
                            
                            // Save warranty metadata to database
                            await _supabaseService.createComplianceDocument({
                              'vehicle_id': vehicle.vehicleId,
                              'doc_type': 'warranty_${warrantyName.toLowerCase().replaceAll(' ', '_')}',
                              'expiry_date': selectedExpiryDate!.toIso8601String(),
                              'scan_url': fileUrl,
                              'created_at': DateTime.now().toIso8601String(),
                              'updated_at': DateTime.now().toIso8601String(),
                            });
                            
                            // Close dialog
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            
                            // Show success message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Warranty "$warrantyName" added successfully!',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(top: 50, left: 20, right: 20, bottom: MediaQuery.of(context).size.height - 150),
                                  dismissDirection: DismissDirection.up,
                                  elevation: 1000,
                                ),
                              );
                              
                              // Refresh data
                              this.setState(() => _future = _loadData());
                            }
                          } catch (e) {
                            setState(() => isUploading = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add warranty: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Warranty'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}


class _ComplianceData {
  final List<Vehicle> vehicles;
  final List<ComplianceDocument> documents;
  late final Map<String, Vehicle> vehicleIndex;

  _ComplianceData({required this.vehicles, required this.documents}) {
    vehicleIndex = {for (final v in vehicles) v.vehicleId: v};
  }
}

class _ComplianceAnalytics {
  final int compliantVehicles;
  final int totalVehicles;
  final Map<String, _DocSummary> summary;
  final List<_AttentionRow> attentionRows;
  final Map<String, double> forecastBuckets;
  final double totalBudget;
  final double usedBudget;
  final double remainingBudget;

  _ComplianceAnalytics({
    required this.compliantVehicles,
    required this.totalVehicles,
    required this.summary,
    required this.attentionRows,
    required this.forecastBuckets,
    required this.totalBudget,
    required this.usedBudget,
    required this.remainingBudget,
  });
}

class _DocSummary {
  int valid = 0;
  int expiring = 0;
  int expired = 0;
  int missing = 0;

  void increment(String status) {
    switch (status) {
      case 'valid':
        valid += 1;
        break;
      case 'expiring':
        expiring += 1;
        break;
      case 'missing':
        missing += 1;
        break;
      default:
        expired += 1;
    }
  }
}

class _AttentionRow {
  final Vehicle vehicle;
  final ComplianceDocument? document;
  final String status;
  final int daysLeft;
  final String? docTypeOverride;

  _AttentionRow({
    required this.vehicle,
    required this.document,
    required this.status,
    required this.daysLeft,
    this.docTypeOverride,
  });
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


class _ExpirySummaryCard extends StatelessWidget {
  final String title;
  final int valid;
  final int expiring;
  final int expired;
  final int missing;

  const _ExpirySummaryCard({
    required this.title,
    required this.valid,
    required this.expiring,
    required this.expired,
    required this.missing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _StatusRow(label: 'Valid', value: valid, color: AppColors.success),
          _StatusRow(label: 'Expiring (≤30d)', value: expiring, color: AppColors.warning),
          _StatusRow(label: 'Expired', value: expired, color: AppColors.error),
          _StatusRow(label: 'Missing', value: missing, color: AppColors.attention),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ComplianceBadge extends StatelessWidget {
  final String status;

  const _ComplianceBadge({required this.status});

  Color _color() {
    switch (status) {
      case 'valid':
        return AppColors.success;
      case 'expiring':
        return AppColors.warning;
      case 'missing':
        return AppColors.attention;
      default:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final label = status.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalForecastChart extends StatelessWidget {
  final Map<String, double> buckets;

  const _RenewalForecastChart({required this.buckets});

  @override
  Widget build(BuildContext context) {
    final hasData = buckets.values.any((v) => v > 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Renewal Cost Forecast (Next 90 Days)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No upcoming renewal costs found.'),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['0-30', '31-60', '61-90'];
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Text(labels[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: buckets['0-30'] ?? 0,
                          color: AppColors.error,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: buckets['31-60'] ?? 0,
                          color: AppColors.warning,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: buckets['61-90'] ?? 0,
                          color: AppColors.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double total;
  final double used;
  final double remaining;

  const _BudgetCard({
    required this.total,
    required this.used,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Utilization',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text('Total budget is derived from renewal_cost fields in compliance documents.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.lightBorder.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 12),
          _BudgetRow(label: 'Total Budget', value: total),
          _BudgetRow(label: 'Used', value: used),
          _BudgetRow(label: 'Remaining', value: remaining),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final double value;

  const _BudgetRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// New expandable vehicle card widget
class _VehicleExpandableCard extends StatefulWidget {
  final Vehicle vehicle;
  final bool isCompliant;
  final int needsAttentionCount;
  final List<Map<String, dynamic>> attentionDocs;
  final VoidCallback onViewAll;

  const _VehicleExpandableCard({
    required this.vehicle,
    required this.isCompliant,
    required this.needsAttentionCount,
    required this.attentionDocs,
    required this.onViewAll,
  });

  @override
  State<_VehicleExpandableCard> createState() => _VehicleExpandableCardState();
}

class _VehicleExpandableCardState extends State<_VehicleExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Vehicle icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isCompliant
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.electric_car,
                      color: widget.isCompliant ? AppColors.success : AppColors.warning,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Vehicle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicle.vehicleNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (widget.vehicle.displayName.isNotEmpty)
                          Text(
                            widget.vehicle.displayName,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        const SizedBox(height: 4),
                        if (widget.isCompliant)
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'All documents valid',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.needsAttentionCount} document${widget.needsAttentionCount > 1 ? 's' : ''} need${widget.needsAttentionCount == 1 ? 's' : ''} attention',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 24,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (_isExpanded && widget.attentionDocs.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Documents Needing Attention',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: widget.onViewAll,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.attentionDocs.map((doc) {
                    final daysLeft = doc['daysLeft'] as int;
                    final daysLabel = daysLeft >= 0 ? '${daysLeft}d left' : 'Overdue';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              doc['label'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Expiry: ${doc['expiry']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              daysLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: daysLeft < 0
                                        ? AppColors.error
                                        : daysLeft <= 30
                                            ? AppColors.warning
                                            : AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          _ComplianceBadge(status: doc['status'] as String),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// New widget for document list item in modal
class _DocumentListItem extends StatelessWidget {
  final String label;
  final String expiry;
  final String daysLabel;
  final String status;
  final ComplianceDocument? document;
  final String docType;
  final Vehicle vehicle;
  final VoidCallback onUpload;
  final VoidCallback onRefresh;

  const _DocumentListItem({
    required this.label,
    required this.expiry,
    required this.daysLabel,
    required this.status,
    required this.document,
    required this.docType,
    required this.vehicle,
    required this.onUpload,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocument = document != null && document!.scanUrl != null && document!.scanUrl!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expiry: $expiry',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  daysLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Always show Upload button on the left of status badge
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
          // Show View button if document exists
          if (hasDocument) ...[
            ElevatedButton.icon(
              onPressed: () {
                // Open document URL in new tab
                if (document!.scanUrl != null) {
                  // Use url_launcher or open in browser
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening: ${document!.scanUrl}')),
                  );
                }
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _ComplianceBadge(status: status),
        ],
      ),
    );
  }
}
// Warranty dropdown widget
class _WarrantyDropdown extends StatefulWidget {
  final List<String> warrantyCategories;
  final ComplianceDocument? warrantyDoc;
  final String Function(ComplianceDocument?) onStatusCheck;
  final int Function(ComplianceDocument?) onDaysLeft;

  const _WarrantyDropdown({
    required this.warrantyCategories,
    required this.warrantyDoc,
    required this.onStatusCheck,
    required this.onDaysLeft,
  });

  @override
  State<_WarrantyDropdown> createState() => _WarrantyDropdownState();
}

class _WarrantyDropdownState extends State<_WarrantyDropdown> {
  String? _selectedWarranty;

  @override
  void initState() {
    super.initState();
    if (widget.warrantyCategories.isNotEmpty) {
      _selectedWarranty = widget.warrantyCategories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.onStatusCheck(widget.warrantyDoc);
    final expiry = widget.warrantyDoc?.expiryDate != null
        ? '${widget.warrantyDoc!.expiryDate!.year}-${widget.warrantyDoc!.expiryDate!.month.toString().padLeft(2, '0')}-${widget.warrantyDoc!.expiryDate!.day.toString().padLeft(2, '0')}'
        : 'Not available';
    final daysLeft = widget.onDaysLeft(widget.warrantyDoc);
    final daysLabel = daysLeft >= 0 ? '$daysLeft days left' : 'Missing';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedWarranty,
            decoration: InputDecoration(
              labelText: 'Select Warranty Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: widget.warrantyCategories.map((warranty) {
              return DropdownMenuItem<String>(value: warranty, child: Text(warranty));
            }).toList(),
            onChanged: (value) => setState(() => _selectedWarranty = value),
          ),
          const SizedBox(height: 12),
          if (_selectedWarranty != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expiry Date', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(expiry, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Days Left', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(daysLabel, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: daysLeft < 0 ? AppColors.error : daysLeft <= 30 ? AppColors.warning : AppColors.success,
                      )),
                    ],
                  ),
                ),
                _ComplianceBadge(status: status),
              ],
            ),
        ],
      ),
    );
  }
}
