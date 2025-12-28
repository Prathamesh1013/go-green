import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/widgets/glass_card.dart';
import 'package:gogreen_admin/widgets/autocomplete_field.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/data/vehicle_data.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class CoreVehicleFormPage extends StatefulWidget {
  final String? vehicleId;

  const CoreVehicleFormPage({
    super.key,
    this.vehicleId,
  });

  @override
  State<CoreVehicleFormPage> createState() => _CoreVehicleFormPageState();
}

class _CoreVehicleFormPageState extends State<CoreVehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _variantController = TextEditingController();
  final _telematicsIdController = TextEditingController();
  final _odometerController = TextEditingController();
  final _yearController = TextEditingController();
  final _mechanicalIssuesController = TextEditingController();
  final _bodyShopIssuesController = TextEditingController();
  final _electricalIssuesController = TextEditingController();
  final _warrantyNotesController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  String? _fuelType = 'EV'; // Default to EV
  String? _status;
  String? _ownerType;
  String? _healthState;
  String? _warrantyStatus;
  String? _selectedHubId;
  DateTime? _insuranceExpiryDate;
  XFile? _insuranceDocument;
  bool _hasChalan = false;
  DateTime? _lastServiceDate;
  List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleId != null) {
      _loadCoreVehicleData();
    } else {
      _status = 'active';
      _ownerType = 'client_owned';
      _warrantyStatus = 'active';
      _hasChalan = false;
    }
  }

  void _loadCoreVehicleData() {
    final provider = context.read<CoreVehicleProvider>();
    if (provider.coreVehicles.isEmpty) return;
    final vehicle = provider.coreVehicles.firstWhere(
      (v) => v.vehicleId == widget.vehicleId,
      orElse: () => provider.coreVehicles.first,
    );

    _vehicleNumberController.text = vehicle.vehicleNumber;
    _makeController.text = vehicle.make ?? '';
    _modelController.text = vehicle.model ?? '';
    _variantController.text = vehicle.variant ?? '';
    _telematicsIdController.text = vehicle.telematicsId ?? '';
    _odometerController.text = vehicle.odometerCurrent?.toString() ?? '';
    _yearController.text = vehicle.yearOfManufacture?.toString() ?? '';
    _fuelType = vehicle.fuelType ?? 'EV';
    _status = vehicle.status;
    _ownerType = vehicle.ownerType;
    _healthState = vehicle.healthState;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _telematicsIdController.dispose();
    _odometerController.dispose();
    _yearController.dispose();
    _mechanicalIssuesController.dispose();
    _bodyShopIssuesController.dispose();
    _electricalIssuesController.dispose();
    _warrantyNotesController.dispose();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _pickInsuranceDocument() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _insuranceDocument = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _selectInsuranceDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _insuranceExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != _insuranceExpiryDate) {
      setState(() {
        _insuranceExpiryDate = picked;
      });
    }
  }

  Future<Uint8List> _getImageBytes(XFile file) async {
    if (kIsWeb) {
      return await file.readAsBytes();
    } else {
      return await File(file.path).readAsBytes();
    }
  }

  Future<String?> _uploadImageToSupabase(
      XFile image, String vehicleId, String type) async {
    try {
      final bytes = await _getImageBytes(image);
      final extension = image.path.split('.').last;
      final fileName =
          '${vehicleId}_${type}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'vehicles/$vehicleId/$fileName';

      await _supabaseService.uploadFile(
          path, bytes, image.mimeType ?? 'image/jpeg');
      return _supabaseService.getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      // Show user-friendly error message
      if (mounted) {
        String errorMessage = 'Failed to upload image';
        if (e.toString().contains('Bucket not found') ||
            e.toString().contains('404')) {
          errorMessage =
              'Storage bucket not configured. Please create "vehicle-documents" bucket in Supabase.';
        } else if (e.toString().contains('row-level security') ||
            e.toString().contains('403') ||
            e.toString().contains('Unauthorized')) {
          errorMessage =
              'Upload denied: Storage RLS policy not configured. Please set up Storage policies in Supabase (see SUPABASE_SETUP.md).';
        } else {
          errorMessage = 'Failed to upload image: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.getAttention(context),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _lastServiceDate) {
      setState(() {
        _lastServiceDate = picked;
      });
    }
  }

  Future<void> _saveCoreVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicleData = {
        if (widget.vehicleId == null) 'vehicle_id': const Uuid().v4(),
        'vehicle_number': _vehicleNumberController.text.trim(),
        'make': _makeController.text.trim().isEmpty
            ? null
            : _makeController.text.trim(),
        'model': _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        'variant': _variantController.text.trim().isEmpty
            ? null
            : _variantController.text.trim(),
        'fuel_type': _fuelType ?? 'EV',
        'year_of_manufacture': _yearController.text.trim().isEmpty
            ? null
            : int.tryParse(_yearController.text.trim()),
        'telematics_id': _telematicsIdController.text.trim().isEmpty
            ? null
            : _telematicsIdController.text.trim(),
        'status': _status ?? 'active',
        'owner_type': _ownerType,
        'health_state': _healthState,
        'odometer_current': _odometerController.text.trim().isEmpty
            ? null
            : int.tryParse(_odometerController.text.trim()),
        'primary_hub_id': (_selectedHubId == null || _selectedHubId!.isEmpty)
            ? null
            : _selectedHubId,
        'driver_name': _driverNameController.text.trim().isEmpty ? null : _driverNameController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim().isEmpty ? null : _driverPhoneController.text.trim(),
        'driver_license': _driverLicenseController.text.trim().isEmpty ? null : _driverLicenseController.text.trim(),
      };

      CoreVehicle vehicle;
      if (widget.vehicleId != null) {
        await context.read<CoreVehicleProvider>().updateCoreVehicle(
              widget.vehicleId!,
              vehicleData,
            );
        vehicle = await _supabaseService.getCoreVehicleById(widget.vehicleId!);
      } else {
        vehicle = await _supabaseService.createCoreVehicle(vehicleData);
        await context.read<CoreVehicleProvider>().loadCoreVehicles();
      }

      // Upload vehicle photos
      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          await _uploadImageToSupabase(
              _selectedImages[i], vehicle.vehicleId, 'photo_$i');
        }
      }

      // Create insurance compliance document
      if (_insuranceExpiryDate != null || _insuranceDocument != null) {
        String? scanUrl;
        if (_insuranceDocument != null) {
          scanUrl = await _uploadImageToSupabase(
              _insuranceDocument!, vehicle.vehicleId, 'insurance');
        }

        final daysUntilExpiry = _insuranceExpiryDate != null
            ? _insuranceExpiryDate!.difference(DateTime.now()).inDays
            : null;

        String status = 'valid';
        if (daysUntilExpiry != null) {
          if (daysUntilExpiry <= 0) {
            status = 'expired';
          } else if (daysUntilExpiry <= 30) {
            status = 'expiring_soon';
          }
        }

        await _supabaseService.createComplianceDocument({
          'vehicle_id': vehicle.vehicleId,
          'doc_type': 'insurance',
          'expiry_date': _insuranceExpiryDate?.toIso8601String().split('T')[0],
          'scan_url': scanUrl,
          'status': status,
          'days_until_expiry': daysUntilExpiry,
        });
      }

      // Create warranty compliance document if warranty status is set
      if (_warrantyStatus != null && _warrantyStatus != 'void') {
        await _supabaseService.createComplianceDocument({
          'vehicle_id': vehicle.vehicleId,
          'doc_type': 'warranty',
          'status': _warrantyStatus == 'active' ? 'valid' : 'expired',
        });
      }

      // TODO: Create maintenance job records for issues if any
      if (_mechanicalIssuesController.text.trim().isNotEmpty ||
          _bodyShopIssuesController.text.trim().isNotEmpty ||
          _electricalIssuesController.text.trim().isNotEmpty) {
        // TODO: Create maintenance job records
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicleId != null
                  ? 'CoreVehicle updated successfully'
                  : 'CoreVehicle added successfully',
            ),
            backgroundColor: AppColors.getHealthy(context),
          ),
        );
        context.go('/coreVehicles');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred while saving the vehicle';

        // Check for PostgrestException (Supabase errors)
        if (e is PostgrestException) {
          // 409 Conflict usually means unique constraint violation
          if (e.code == '23505' ||
              e.message.contains('duplicate') ||
              e.message.contains('unique')) {
            errorMessage =
                'A vehicle with this number already exists. Please use a different vehicle number.';
            // Highlight the vehicle number field
            _formKey.currentState?.validate();
          } else if (e.code == 'PGRST116' || e.message.contains('not found')) {
            errorMessage = 'CoreVehicle not found. Please refresh and try again.';
          } else {
            errorMessage = 'Database error: ${e.message}';
          }
        } else if (e.toString().contains('409') ||
            e.toString().contains('Conflict')) {
          errorMessage =
              'A vehicle with this number already exists. Please use a different vehicle number.';
          _formKey.currentState?.validate();
        } else if (e.toString().contains('vehicle_number') &&
            e.toString().contains('unique')) {
          errorMessage =
              'A vehicle with this number already exists. Please use a different vehicle number.';
          _formKey.currentState?.validate();
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.getCritical(context),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/coreVehicles',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/coreVehicles'),
          ),
          title:
              Text(widget.vehicleId != null ? 'Edit CoreVehicle' : 'Add CoreVehicle'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton.icon(
                onPressed: _saveCoreVehicle,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 1200;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isWideScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Basic Information
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.info_outline,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Basic Information',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          // CoreVehicle Number - Full Width
                                          TextFormField(
                                            controller:
                                                _vehicleNumberController,
                                            inputFormatters: [
                                              UpperCaseTextFormatter(),
                                            ],
                                            decoration: const InputDecoration(
                                              labelText: 'CoreVehicle Number *',
                                              hintText: 'e.g., MH15JC0050',
                                              prefixIcon: Icon(
                                                  Icons.confirmation_number),
                                              isDense: true,
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'CoreVehicle number is required';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          // Make and Model in Row
                                          Row(
                                            children: [
                                              Expanded(
                                                child: AutocompleteField(
                                                  controller: _makeController,
                                                  label: 'Make',
                                                  hint:
                                                      'Select or type (Tata, BYD, MG)',
                                                  icon:
                                                      Icons.branding_watermark,
                                                  options: CoreVehicleData.makes,
                                                  onSelected: (value) {
                                                    setState(() {
                                                      _modelController.clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Builder(
                                                  builder: (context) {
                                                    final models = CoreVehicleData
                                                        .getModelsForMake(
                                                            _makeController
                                                                .text);
                                                    return AutocompleteField(
                                                      controller:
                                                          _modelController,
                                                      label: 'Model',
                                                      hint: models.isEmpty
                                                          ? 'Select make first'
                                                          : 'Select model',
                                                      icon:
                                                          Icons.directions_car,
                                                      options: models.isEmpty
                                                          ? CoreVehicleData
                                                              .getAllModels()
                                                          : models,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // Variant, Year, Fuel Type in Row
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller:
                                                      _variantController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Variant',
                                                    hintText: 'e.g., XZ+',
                                                    prefixIcon:
                                                        Icon(Icons.category),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: _yearController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Year',
                                                    hintText: '2023',
                                                    prefixIcon: Icon(
                                                        Icons.calendar_today),
                                                    isDense: true,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 3,
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _fuelType,
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Fuel Type *',
                                                    prefixIcon: Icon(Icons
                                                        .local_gas_station),
                                                    isDense: true,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                        value: 'EV',
                                                        child: Text('EV')),
                                                    DropdownMenuItem(
                                                        value: 'ICE',
                                                        child: Text('ICE')),
                                                    DropdownMenuItem(
                                                        value: 'Hybrid',
                                                        child: Text('Hybrid')),
                                                    DropdownMenuItem(
                                                        value: 'CNG',
                                                        child: Text('CNG')),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _fuelType = value;
                                                    });
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Required';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // CoreVehicle Details - Compact Layout
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.speed,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'CoreVehicle Details',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _telematicsIdController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Telematics ID',
                                                    hintText: 'Device ID',
                                                    prefixIcon: Icon(
                                                        Icons.satellite_alt),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _odometerController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Current Odometer (km) *',
                                                    hintText: '15000',
                                                    prefixIcon:
                                                        Icon(Icons.speed),
                                                    isDense: true,
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.trim().isEmpty) {
                                                      return 'Required';
                                                    }
                                                    if (int.tryParse(
                                                            value.trim()) ==
                                                        null) {
                                                      return 'Invalid';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () =>
                                                      _selectDate(context),
                                                  child: InputDecorator(
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Last Service',
                                                      prefixIcon: Icon(
                                                          Icons.build_circle),
                                                      isDense: true,
                                                    ),
                                                    child: Text(
                                                      _lastServiceDate != null
                                                          ? DateFormat(
                                                                  'dd MMM, yyyy')
                                                              .format(
                                                                  _lastServiceDate!)
                                                          : 'Select date',
                                                      style: TextStyle(
                                                        color:
                                                            _lastServiceDate !=
                                                                    null
                                                                ? null
                                                                : Theme.of(
                                                                        context)
                                                                    .hintColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Driver Information Section
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(context).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.person_outline,
                                                  color: AppColors.getPrimary(context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Driver Information',
                                                style: Theme.of(context).textTheme.headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: _driverNameController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Driver Name',
                                                    hintText: 'e.g., John Doe',
                                                    prefixIcon: Icon(Icons.person),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: _driverPhoneController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'Phone Number',
                                                    hintText: 'e.g., 9876543210',
                                                    prefixIcon: Icon(Icons.phone),
                                                    isDense: true,
                                                  ),
                                                  keyboardType: TextInputType.phone,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: _driverLicenseController,
                                                  decoration: const InputDecoration(
                                                    labelText: 'License Number',
                                                    hintText: 'e.g., DL12345678',
                                                    prefixIcon: Icon(Icons.badge),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Status & Ownership - Compact
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.info_outline,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Status & Ownership',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _status,
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Status *',
                                                    prefixIcon:
                                                        Icon(Icons.info),
                                                    isDense: true,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                        value: 'active',
                                                        child: Text('Active')),
                                                    DropdownMenuItem(
                                                        value: 'inactive',
                                                        child:
                                                            Text('Inactive')),
                                                    DropdownMenuItem(
                                                        value: 'scrapped',
                                                        child:
                                                            Text('Scrapped')),
                                                    DropdownMenuItem(
                                                        value: 'trial',
                                                        child: Text('Trial')),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _status = value;
                                                    });
                                                  },
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Required';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _ownerType,
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Owner Type',
                                                    prefixIcon:
                                                        Icon(Icons.business),
                                                    isDense: true,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'client_owned',
                                                      child:
                                                          Text('Client Owned'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'leased',
                                                      child: Text('Leased'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _ownerType = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  value: _healthState,
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Health State',
                                                    prefixIcon:
                                                        Icon(Icons.favorite),
                                                    isDense: true,
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                        value: 'healthy',
                                                        child: Text('Healthy')),
                                                    DropdownMenuItem(
                                                        value: 'attention',
                                                        child:
                                                            Text('Attention')),
                                                    DropdownMenuItem(
                                                        value: 'critical',
                                                        child:
                                                            Text('Critical')),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _healthState = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Issues & Problems - Compact Grid
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Issues & Problems',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _mechanicalIssuesController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Mechanical Issues',
                                                    hintText:
                                                        'Describe problems...',
                                                    prefixIcon:
                                                        Icon(Icons.build),
                                                    isDense: true,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _bodyShopIssuesController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Body Shop Issues',
                                                    hintText:
                                                        'Describe damage...',
                                                    prefixIcon:
                                                        Icon(Icons.car_repair),
                                                    isDense: true,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _electricalIssuesController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Electrical Issues',
                                                    hintText:
                                                        'Describe problems...',
                                                    prefixIcon: Icon(Icons
                                                        .electrical_services),
                                                    isDense: true,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Compliance & Documents - 2 Column Layout
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.description,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Compliance & Documents',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          // 2 Column Layout
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Left Column
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    // Insurance Section
                                                    Text(
                                                      'Insurance',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    InkWell(
                                                      onTap: () =>
                                                          _selectInsuranceDate(
                                                              context),
                                                      child: InputDecorator(
                                                        decoration:
                                                            const InputDecoration(
                                                          labelText:
                                                              'Insurance Expiry Date',
                                                          prefixIcon: Icon(Icons
                                                              .calendar_today),
                                                          isDense: true,
                                                        ),
                                                        child: Text(
                                                          _insuranceExpiryDate !=
                                                                  null
                                                              ? DateFormat(
                                                                      'dd MMM, yyyy')
                                                                  .format(
                                                                      _insuranceExpiryDate!)
                                                              : 'Select expiry date',
                                                          style: TextStyle(
                                                            color: _insuranceExpiryDate !=
                                                                    null
                                                                ? null
                                                                : Theme.of(
                                                                        context)
                                                                    .hintColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    OutlinedButton.icon(
                                                      onPressed:
                                                          _pickInsuranceDocument,
                                                      icon: Icon(
                                                        _insuranceDocument !=
                                                                null
                                                            ? Icons.check_circle
                                                            : Icons.upload_file,
                                                        size: 18,
                                                      ),
                                                      label: Text(
                                                        _insuranceDocument !=
                                                                null
                                                            ? 'Document Uploaded'
                                                            : 'Upload Insurance Document',
                                                      ),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                    if (_insuranceDocument !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 8),
                                                        child: Text(
                                                          _insuranceDocument!
                                                              .name,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    const SizedBox(height: 24),
                                                    // Chalan Section
                                                    Text(
                                                      'Chalan',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    SwitchListTile(
                                                      title: const Text(
                                                          'Has Chalan'),
                                                      subtitle: Text(_hasChalan
                                                          ? 'CoreVehicle has chalan'
                                                          : 'No chalan'),
                                                      value: _hasChalan,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _hasChalan = value;
                                                        });
                                                      },
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 24),
                                              // Right Column
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    // Warranty Section
                                                    Text(
                                                      'Warranty',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    DropdownButtonFormField<
                                                        String>(
                                                      value: _warrantyStatus,
                                                      isExpanded: true,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Warranty Status',
                                                        prefixIcon: Icon(
                                                            Icons.verified),
                                                        isDense: true,
                                                      ),
                                                      items: const [
                                                        DropdownMenuItem(
                                                            value: 'active',
                                                            child:
                                                                Text('Active')),
                                                        DropdownMenuItem(
                                                            value: 'expired',
                                                            child: Text(
                                                                'Expired')),
                                                        DropdownMenuItem(
                                                            value: 'void',
                                                            child:
                                                                Text('Void')),
                                                      ],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _warrantyStatus =
                                                              value;
                                                        });
                                                      },
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextFormField(
                                                      controller:
                                                          _warrantyNotesController,
                                                      decoration:
                                                          const InputDecoration(
                                                        labelText:
                                                            'Warranty Notes',
                                                        hintText:
                                                            'Additional warranty information...',
                                                        prefixIcon:
                                                            Icon(Icons.note),
                                                        isDense: true,
                                                      ),
                                                      maxLines: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Photo Upload - Compact
                                    GlassCard(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                                .getPrimary(
                                                                    context)
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.photo_library,
                                                        color: AppColors
                                                            .getPrimary(
                                                                context),
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Flexible(
                                                      child: Text(
                                                        'CoreVehicle Photos',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headlineMedium,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Wrap(
                                                spacing: 8,
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: _pickImages,
                                                    icon: const Icon(
                                                        Icons.photo_library,
                                                        size: 18),
                                                    label:
                                                        const Text('Gallery'),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                  ),
                                                  OutlinedButton.icon(
                                                    onPressed: _takePhoto,
                                                    icon: const Icon(
                                                        Icons.camera_alt,
                                                        size: 18),
                                                    label: const Text('Camera'),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          if (_selectedImages.isEmpty)
                                            Container(
                                              height: 100,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.3),
                                                  style: BorderStyle.solid,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: AppColors.getPrimary(
                                                        context)
                                                    .withOpacity(0.05),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_photo_alternate,
                                                      size: 36,
                                                      color:
                                                          AppColors.getPrimary(
                                                                  context)
                                                              .withOpacity(0.6),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'No photos selected',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: AppColors
                                                                    .getPrimary(
                                                                        context)
                                                                .withOpacity(
                                                                    0.7),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 4,
                                                crossAxisSpacing: 8,
                                                mainAxisSpacing: 8,
                                                childAspectRatio: 1,
                                              ),
                                              itemCount: _selectedImages.length,
                                              itemBuilder: (context, index) {
                                                return FutureBuilder<Uint8List>(
                                                  future: _getImageBytes(
                                                      _selectedImages[index]),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }
                                                    if (snapshot.hasError ||
                                                        !snapshot.hasData) {
                                                      return const Center(
                                                          child: Icon(
                                                              Icons.error));
                                                    }
                                                    return Stack(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          child: Image.memory(
                                                            snapshot.data!,
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 4,
                                                          right: 4,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black87,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                  Icons.close,
                                                                  size: 16),
                                                              color:
                                                                  Colors.white,
                                                              onPressed: () =>
                                                                  _removeImage(
                                                                      index),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              constraints:
                                                                  const BoxConstraints(
                                                                minWidth: 28,
                                                                minHeight: 28,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Basic Information
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            color:
                                                AppColors.getPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Basic Information',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _vehicleNumberController,
                                      inputFormatters: [
                                        UpperCaseTextFormatter(),
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'CoreVehicle Number *',
                                        hintText: 'e.g., MH15JC0050',
                                        prefixIcon:
                                            Icon(Icons.confirmation_number),
                                        isDense: true,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'CoreVehicle number is required';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AutocompleteField(
                                            controller: _makeController,
                                            label: 'Make',
                                            hint:
                                                'Select or type (Tata, BYD, MG)',
                                            icon: Icons.branding_watermark,
                                            options: CoreVehicleData.makes,
                                            onSelected: (value) {
                                              setState(() {
                                                _modelController.clear();
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final models =
                                                  CoreVehicleData.getModelsForMake(
                                                      _makeController.text);
                                              return AutocompleteField(
                                                controller: _modelController,
                                                label: 'Model',
                                                hint: models.isEmpty
                                                    ? 'Select make first'
                                                    : 'Select model',
                                                icon: Icons.directions_car,
                                                options: models.isEmpty
                                                    ? CoreVehicleData.getAllModels()
                                                    : models,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: _variantController,
                                            decoration: const InputDecoration(
                                              labelText: 'Variant',
                                              hintText: 'e.g., XZ+',
                                              prefixIcon: Icon(Icons.category),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: _yearController,
                                            decoration: const InputDecoration(
                                              labelText: 'Year',
                                              hintText: '2023',
                                              prefixIcon:
                                                  Icon(Icons.calendar_today),
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 3,
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _fuelType,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Fuel Type *',
                                              prefixIcon:
                                                  Icon(Icons.local_gas_station),
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'EV',
                                                  child: Text('EV')),
                                              DropdownMenuItem(
                                                  value: 'ICE',
                                                  child: Text('ICE')),
                                              DropdownMenuItem(
                                                  value: 'Hybrid',
                                                  child: Text('Hybrid')),
                                              DropdownMenuItem(
                                                  value: 'CNG',
                                                  child: Text('CNG')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _fuelType = value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // CoreVehicle Details
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.speed,
                                            color:
                                                AppColors.getPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'CoreVehicle Details',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _telematicsIdController,
                                            decoration: const InputDecoration(
                                              labelText: 'Telematics ID',
                                              hintText: 'Device ID',
                                              prefixIcon:
                                                  Icon(Icons.satellite_alt),
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _odometerController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Current Odometer (km) *',
                                              hintText: '15000',
                                              prefixIcon: Icon(Icons.speed),
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Required';
                                              }
                                              if (int.tryParse(value.trim()) ==
                                                  null) {
                                                return 'Invalid';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _selectDate(context),
                                            child: InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText: 'Last Service',
                                                prefixIcon:
                                                    Icon(Icons.build_circle),
                                                isDense: true,
                                              ),
                                              child: Text(
                                                _lastServiceDate != null
                                                    ? DateFormat('dd MMM, yyyy')
                                                        .format(
                                                            _lastServiceDate!)
                                                    : 'Select date',
                                                style: TextStyle(
                                                  color:
                                                      _lastServiceDate != null
                                                          ? null
                                                          : Theme.of(context)
                                                              .hintColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Status & Ownership
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.info_outline,
                                            color:
                                                AppColors.getPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Status & Ownership',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _status,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Status *',
                                              prefixIcon: Icon(Icons.info),
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'active',
                                                  child: Text('Active')),
                                              DropdownMenuItem(
                                                  value: 'inactive',
                                                  child: Text('Inactive')),
                                              DropdownMenuItem(
                                                  value: 'scrapped',
                                                  child: Text('Scrapped')),
                                              DropdownMenuItem(
                                                  value: 'trial',
                                                  child: Text('Trial')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _status = value;
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _ownerType,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Owner Type',
                                              prefixIcon: Icon(Icons.business),
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'client_owned',
                                                child: Text('Client Owned'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'leased',
                                                child: Text('Leased'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _ownerType = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _healthState,
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Health State',
                                              prefixIcon: Icon(Icons.favorite),
                                              isDense: true,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'healthy',
                                                  child: Text('Healthy')),
                                              DropdownMenuItem(
                                                  value: 'attention',
                                                  child: Text('Attention')),
                                              DropdownMenuItem(
                                                  value: 'critical',
                                                  child: Text('Critical')),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _healthState = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Issues & Problems
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            color:
                                                AppColors.getPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Issues & Problems',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _mechanicalIssuesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Mechanical Issues',
                                              hintText: 'Describe problems...',
                                              prefixIcon: Icon(Icons.build),
                                              isDense: true,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _bodyShopIssuesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Body Shop Issues',
                                              hintText: 'Describe damage...',
                                              prefixIcon:
                                                  Icon(Icons.car_repair),
                                              isDense: true,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _electricalIssuesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Electrical Issues',
                                              hintText: 'Describe problems...',
                                              prefixIcon: Icon(
                                                  Icons.electrical_services),
                                              isDense: true,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Compliance & Documents
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.description,
                                            color:
                                                AppColors.getPrimary(context),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Compliance & Documents',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Insurance',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              InkWell(
                                                onTap: () =>
                                                    _selectInsuranceDate(
                                                        context),
                                                child: InputDecorator(
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Insurance Expiry Date',
                                                    prefixIcon: Icon(
                                                        Icons.calendar_today),
                                                    isDense: true,
                                                  ),
                                                  child: Text(
                                                    _insuranceExpiryDate != null
                                                        ? DateFormat(
                                                                'dd MMM, yyyy')
                                                            .format(
                                                                _insuranceExpiryDate!)
                                                        : 'Select expiry date',
                                                    style: TextStyle(
                                                      color:
                                                          _insuranceExpiryDate !=
                                                                  null
                                                              ? null
                                                              : Theme.of(
                                                                      context)
                                                                  .hintColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              OutlinedButton.icon(
                                                onPressed:
                                                    _pickInsuranceDocument,
                                                icon: Icon(
                                                  _insuranceDocument != null
                                                      ? Icons.check_circle
                                                      : Icons.upload_file,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  _insuranceDocument != null
                                                      ? 'Document Uploaded'
                                                      : 'Upload Insurance Document',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 12),
                                                ),
                                              ),
                                              if (_insuranceDocument != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8),
                                                  child: Text(
                                                    _insuranceDocument!.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              const SizedBox(height: 24),
                                              Text(
                                                'Chalan',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              SwitchListTile(
                                                title: const Text('Has Chalan'),
                                                subtitle: Text(_hasChalan
                                                    ? 'CoreVehicle has chalan'
                                                    : 'No chalan'),
                                                value: _hasChalan,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _hasChalan = value;
                                                  });
                                                },
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Warranty',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 12),
                                              DropdownButtonFormField<String>(
                                                value: _warrantyStatus,
                                                isExpanded: true,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Warranty Status',
                                                  prefixIcon:
                                                      Icon(Icons.verified),
                                                  isDense: true,
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 'active',
                                                      child: Text('Active')),
                                                  DropdownMenuItem(
                                                      value: 'expired',
                                                      child: Text('Expired')),
                                                  DropdownMenuItem(
                                                      value: 'void',
                                                      child: Text('Void')),
                                                ],
                                                onChanged: (value) {
                                                  setState(() {
                                                    _warrantyStatus = value;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              TextFormField(
                                                controller:
                                                    _warrantyNotesController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Warranty Notes',
                                                  hintText:
                                                      'Additional warranty information...',
                                                  prefixIcon: Icon(Icons.note),
                                                  isDense: true,
                                                ),
                                                maxLines: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // CoreVehicle Photos
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppColors.getPrimary(
                                                          context)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.photo_library,
                                                  color: AppColors.getPrimary(
                                                      context),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Flexible(
                                                child: Text(
                                                  'CoreVehicle Photos',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: _pickImages,
                                              icon: const Icon(
                                                  Icons.photo_library,
                                                  size: 18),
                                              label: const Text('Gallery'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: _takePhoto,
                                              icon: const Icon(Icons.camera_alt,
                                                  size: 18),
                                              label: const Text('Camera'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_selectedImages.isEmpty)
                                      Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.getPrimary(context)
                                                .withOpacity(0.3),
                                            style: BorderStyle.solid,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: AppColors.getPrimary(context)
                                              .withOpacity(0.05),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 36,
                                                color: AppColors.getPrimary(
                                                        context)
                                                    .withOpacity(0.6),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'No photos selected',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.getPrimary(
                                                                  context)
                                                              .withOpacity(0.7),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                          childAspectRatio: 1,
                                        ),
                                        itemCount: _selectedImages.length,
                                        itemBuilder: (context, index) {
                                          return FutureBuilder<Uint8List>(
                                            future: _getImageBytes(
                                                _selectedImages[index]),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              }
                                              if (snapshot.hasError ||
                                                  !snapshot.hasData) {
                                                return const Center(
                                                    child: Icon(Icons.error));
                                              }
                                              return Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.memory(
                                                      snapshot.data!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black87,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                            Icons.close,
                                                            size: 16),
                                                        color: Colors.white,
                                                        onPressed: () =>
                                                            _removeImage(index),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    // Action Buttons - Fixed at bottom
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/coreVehicles'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveCoreVehicle,
                              icon: const Icon(Icons.save, size: 18),
                              label: Text(widget.vehicleId != null
                                  ? 'Update'
                                  : 'Create'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getPrimary(context),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
