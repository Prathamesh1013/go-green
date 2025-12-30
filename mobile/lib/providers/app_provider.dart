import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';

class AppProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? _lastRoute;
  String? get lastRoute => _lastRoute;

  // Vehicles from Supabase
  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;
  bool _isLoadingVehicles = false;
  bool get isLoadingVehicles => _isLoadingVehicles;
  String? _vehiclesError;
  String? get vehiclesError => _vehiclesError;

  // Local data for offline support
  final List<ReportedIssue> _reportedIssues = [];
  final List<InspectionResult> _inspectionResults = [];
  final Map<String, Map<String, String>> _inventoryPhotos = {}; // vehicleId -> category -> path

  // Pending operations queue for offline support
  final List<Map<String, dynamic>> _pendingOperations = [];

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _lastRoute = prefs.getString('lastRoute');
      
      // Load Issues (kept for offline support)
      final issuesJson = prefs.getString('reportedIssues');
      if (issuesJson != null) {
        final List<dynamic> decoded = jsonDecode(issuesJson);
        _reportedIssues.clear();
        _reportedIssues.addAll(decoded.map((i) => ReportedIssue.fromJson(i)));
      }

      // Load Inspections (kept for offline support)
      final inspectionsJson = prefs.getString('inspectionResults');
      if (inspectionsJson != null) {
        final List<dynamic> decoded = jsonDecode(inspectionsJson);
        _inspectionResults.clear();
        _inspectionResults.addAll(decoded.map((i) => InspectionResult.fromJson(i)));
      }

      // Load Inventory Photos (kept for offline support)
      final photosJson = prefs.getString('inventoryPhotos');
      if (photosJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(photosJson);
        _inventoryPhotos.clear();
        decoded.forEach((vId, categories) {
          _inventoryPhotos[vId] = Map<String, String>.from(categories);
        });
      }

      // Load pending operations
      final pendingJson = prefs.getString('pendingOperations');
      if (pendingJson != null) {
        final List<dynamic> decoded = jsonDecode(pendingJson);
        _pendingOperations.clear();
        _pendingOperations.addAll(decoded.map((op) => Map<String, dynamic>.from(op)));
      }

      debugPrint('AppProvider: INITIALIZED. isLoggedIn=$_isLoggedIn, issues=${_reportedIssues.length}, photos=${_inventoryPhotos.length}');
      
      // Load vehicles from Supabase if logged in
      if (_isLoggedIn) {
        await loadVehicles();
        await _syncPendingOperations();
      }
    } catch (e) {
      debugPrint('AppProvider: Error loading settings: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ==================== VEHICLE MANAGEMENT ====================

  /// Load vehicles from Supabase
  Future<void> loadVehicles() async {
    _isLoadingVehicles = true;
    _vehiclesError = null;
    notifyListeners();

    try {
      _vehicles = await _supabaseService.getVehicles();
      debugPrint('AppProvider: Loaded ${_vehicles.length} vehicles from Supabase');
    } catch (e) {
      _vehiclesError = e.toString();
      debugPrint('AppProvider: Error loading vehicles: $e');
    } finally {
      _isLoadingVehicles = false;
      notifyListeners();
    }
  }

  /// Refresh vehicles (pull-to-refresh)
  Future<void> refreshVehicles() async {
    await loadVehicles();
  }

  /// Get vehicle by ID (from cache or fetch)
  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update vehicle status
  Future<void> updateVehicleStatus(String vehicleId, VehicleStatus status) async {
    try {
      await _supabaseService.updateVehicle(vehicleId, {'status': status.name});
      await loadVehicles(); // Refresh to get updated data
      debugPrint('AppProvider: Updated vehicle $vehicleId status to ${status.name}');
    } catch (e) {
      debugPrint('AppProvider: Error updating vehicle status: $e');
      // Queue for offline sync
      await _queueOperation({
        'type': 'update_vehicle',
        'vehicleId': vehicleId,
        'data': {'status': status.name},
      });
    }
  }

  // ==================== ISSUE MANAGEMENT ====================

  /// Add a reported issue (save to Supabase)
  Future<void> addIssue(ReportedIssue issue) async {
    debugPrint('AppProvider: Adding issue for vehicle ${issue.vehicleId}: ${issue.type}');
    
    try {
      // Upload photos/videos to Supabase Storage if they exist
      String? photoUrl;
      String? videoUrl;

      if (issue.photoPath != null) {
        // In a real implementation, you'd read the file and upload it
        // For now, we'll just store the path
        photoUrl = issue.photoPath;
      }

      if (issue.videoPath != null) {
        videoUrl = issue.videoPath;
      }

      // Create maintenance job in Supabase
      await _supabaseService.createMaintenanceJob({
        'vehicle_id': issue.vehicleId,
        'job_category': 'issue',
        'issue_type': issue.type,
        'description': issue.description,
        'diagnosis_date': issue.timestamp.toIso8601String(),
        'status': 'pending_diagnosis',
        'photo_url': photoUrl,
        'video_url': videoUrl,
      });

      debugPrint('AppProvider: Issue saved to Supabase');
      
      // Also keep in local cache
      _reportedIssues.add(issue);
      await _persistIssues();
      
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error saving issue to Supabase: $e');
      
      // Save locally and queue for sync
      _reportedIssues.add(issue);
      await _persistIssues();
      
      await _queueOperation({
        'type': 'create_issue',
        'issue': issue.toJson(),
      });
      
      notifyListeners();
    }
  }

  /// Get issues for a vehicle (from Supabase)
  Future<List<Map<String, dynamic>>> getIssuesForVehicle(String vehicleId) async {
    try {
      return await _supabaseService.getMaintenanceJobs(vehicleId);
    } catch (e) {
      debugPrint('AppProvider: Error fetching issues: $e');
      // Fallback to local cache
      return _reportedIssues
          .where((i) => i.vehicleId == vehicleId)
          .map((i) => i.toJson())
          .toList();
    }
  }

  /// Remove an issue
  Future<void> removeIssue(String issueId) async {
    debugPrint('AppProvider: Removing issue $issueId');
    
    try {
      await _supabaseService.deleteMaintenanceJob(issueId);
      _reportedIssues.removeWhere((i) => i.id == issueId);
      await _persistIssues();
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error removing issue: $e');
      
      // Queue for offline sync
      await _queueOperation({
        'type': 'delete_issue',
        'issueId': issueId,
      });
    }
  }

  // ==================== INSPECTION MANAGEMENT ====================

  /// Save inspection result
  Future<void> saveInspection(InspectionResult result) async {
    try {
      // Save to Supabase
      await _supabaseService.createDailyInventory({
        'vehicle_id': result.vehicleId,
        'check_date': result.timestamp.toIso8601String(),
        'status': 'completed',
        'notes': jsonEncode(result.checks),
      });

      // Update summary data on crm_vehicles for admin panel
      await _supabaseService.updateVehicle(result.vehicleId, {
        'last_full_scan': result.checks,
        'last_inventory_time': result.timestamp.toIso8601String(),
      });

      debugPrint('AppProvider: Full Scan saved to Supabase and summary updated');
      
      // Also keep in local cache
      _inspectionResults.removeWhere((r) => r.vehicleId == result.vehicleId);
      _inspectionResults.add(result);
      await _persistInspections();
      
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error saving inspection: $e');
      
      // Save locally and queue for sync
      _inspectionResults.removeWhere((r) => r.vehicleId == result.vehicleId);
      _inspectionResults.add(result);
      await _persistInspections();
      
      await _queueOperation({
        'type': 'create_inspection',
        'inspection': result.toJson(),
      });
      
      notifyListeners();
    }
  }

  Future<void> updateVehicleSummary(String vehicleId, Map<String, dynamic> data) async {
    try {
      await _supabaseService.updateVehicle(vehicleId, data);
      
      // Update local vehicle state to reflect changes immediately
      final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (vehicleIndex != -1) {
        final existing = _vehicles[vehicleIndex];
        // We'd need to update the model, but since it's immutable, we'd use copyWith if it had it.
        // Let's just notify and refetch if needed, but for now just logging.
        debugPrint('AppProvider: Summary updated locally and on Supabase for $vehicleId');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('AppProvider: Error updating vehicle summary: $e');
      rethrow;
    }
  }

  Future<void> saveDailyChecks(String vehicleId, Map<String, bool?> checks) async {
    try {
      final Map<String, bool> cleanedChecks = {};
      checks.forEach((key, value) {
        if (value != null) cleanedChecks[key] = value;
      });

      await updateVehicleSummary(vehicleId, {
        'daily_checks': cleanedChecks,
        'last_inventory_time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('AppProvider: Error saving daily checks: $e');
      rethrow;
    }
  }

  InspectionResult? getInspectionForVehicle(String vehicleId) {
    try {
      return _inspectionResults.firstWhere((r) => r.vehicleId == vehicleId);
    } catch (e) {
      return null;
    }
  }

  // ==================== INVENTORY PHOTOS ====================

  Future<void> setInventoryPhoto(String vehicleId, String category, String path) async {
    if (!_inventoryPhotos.containsKey(vehicleId)) {
      _inventoryPhotos[vehicleId] = {};
    }
    _inventoryPhotos[vehicleId]![category] = path;
    await _persistPhotos();
    
    try {
      // 1. Read bytes from photo path
      final XFile file = XFile(path);
      final Uint8List bytes = await file.readAsBytes();
      
      // 2. Upload to Supabase Storage
      final String fileName = 'inventory/${vehicleId}/${category}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String photoUrl = await _supabaseService.uploadFile(fileName, bytes, 'image/jpeg');
      
      // 3. Save photo record to mobile_inventory_photos table
      await _supabaseService.saveInventoryPhoto(
        vehicleId: vehicleId,
        category: category,
        photoUrl: photoUrl,
      );

      // 4. Update the summary count on crm_vehicles
      final photoCount = _inventoryPhotos[vehicleId]?.length ?? 0;
      await _supabaseService.updateVehicle(vehicleId, {
        'inventory_photo_count': photoCount,
        'last_inventory_time': DateTime.now().toIso8601String(),
      });
      
      debugPrint('AppProvider: Inventory photo uploaded and count updated for $vehicleId: $photoCount');
    } catch (e) {
      debugPrint('AppProvider: Error during photo upload/sync: $e');
      rethrow; // Rethrow to allow UI to handle
    }
    
    notifyListeners();
  }

  Map<String, String> getInventoryPhotos(String vehicleId) {
    return _inventoryPhotos[vehicleId] ?? {};
  }

  Future<void> removeInventoryPhoto(String vehicleId, String category) async {
    if (_inventoryPhotos.containsKey(vehicleId)) {
      _inventoryPhotos[vehicleId]!.remove(category);
      await _persistPhotos();
      notifyListeners();
    }
  }

  Future<void> clearInventoryPhotos(String vehicleId) async {
    _inventoryPhotos.remove(vehicleId);
    await _persistPhotos();
    notifyListeners();
  }

  // ==================== OFFLINE SUPPORT ====================

  Future<void> _queueOperation(Map<String, dynamic> operation) async {
    _pendingOperations.add({
      ...operation,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingOperations', jsonEncode(_pendingOperations));
    
    debugPrint('AppProvider: Queued operation for offline sync: ${operation['type']}');
  }

  Future<void> _syncPendingOperations() async {
    if (_pendingOperations.isEmpty) return;
    
    debugPrint('AppProvider: Syncing ${_pendingOperations.length} pending operations');
    
    final List<Map<String, dynamic>> failedOps = [];
    
    for (final op in _pendingOperations) {
      try {
        switch (op['type']) {
          case 'update_vehicle':
            await _supabaseService.updateVehicle(op['vehicleId'], op['data']);
            break;
          case 'create_issue':
            final issue = ReportedIssue.fromJson(op['issue']);
            await _supabaseService.createMaintenanceJob({
              'vehicle_id': issue.vehicleId,
              'job_category': 'issue',
              'issue_type': issue.type,
              'description': issue.description,
              'diagnosis_date': issue.timestamp.toIso8601String(),
              'status': 'pending_diagnosis',
            });
            break;
          case 'delete_issue':
            await _supabaseService.deleteMaintenanceJob(op['issueId']);
            break;
          case 'create_inspection':
            final inspection = InspectionResult.fromJson(op['inspection']);
            await _supabaseService.createDailyInventory({
              'vehicle_id': inspection.vehicleId,
              'check_date': inspection.timestamp.toIso8601String(),
              'status': 'completed',
              'notes': jsonEncode(inspection.checks),
            });
            
            // Also update crm_vehicles summary
            final Map<String, bool> dailyChecks = {};
            inspection.checks.forEach((key, value) {
              dailyChecks[key] = value == 'ok' || value == 'yes' || value == 'true';
            });

            await _supabaseService.updateVehicle(inspection.vehicleId, {
              'daily_checks': dailyChecks,
              'last_inventory_time': inspection.timestamp.toIso8601String(),
            });
            break;
        }
        debugPrint('AppProvider: Synced operation: ${op['type']}');
      } catch (e) {
        debugPrint('AppProvider: Failed to sync operation: ${op['type']}, error: $e');
        failedOps.add(op);
      }
    }
    
    _pendingOperations.clear();
    _pendingOperations.addAll(failedOps);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingOperations', jsonEncode(_pendingOperations));
    
    if (failedOps.isEmpty) {
      debugPrint('AppProvider: All pending operations synced successfully');
    } else {
      debugPrint('AppProvider: ${failedOps.length} operations failed to sync');
    }
  }

  // ==================== PERSISTENCE ====================

  Future<void> _persistIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_reportedIssues.map((i) => i.toJson()).toList());
    await prefs.setString('reportedIssues', json);
  }

  Future<void> _persistInspections() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_inspectionResults.map((i) => i.toJson()).toList());
    await prefs.setString('inspectionResults', json);
  }

  Future<void> _persistPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inventoryPhotos', jsonEncode(_inventoryPhotos));
  }

  // ==================== ROUTE MANAGEMENT ====================

  Future<void> setLastRoute(String route) async {
    if (_lastRoute == route) return;
    if (route == '/login') return;
    
    debugPrint('AppProvider: SAVING ROUTE: $route');
    _lastRoute = route;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRoute', route);
  }

  Future<void> clearLastRoute() async {
    debugPrint('AppProvider: CLEARING ROUTE');
    _lastRoute = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastRoute');
  }

  // ==================== AUTH ====================

  Future<void> login() async {
    debugPrint('AppProvider: LOGIN ACTION TRIGGERED');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    _isLoggedIn = true;
    debugPrint('AppProvider: isLoggedIn set to true and PERSISTED. Notifying listeners...');
    
    // Load vehicles after login
    await loadVehicles();
    await _syncPendingOperations();
    
    notifyListeners();
  }

  Future<void> logout() async {
    debugPrint('AppProvider: LOGOUT ACTION TRIGGERED');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _isLoggedIn = false;
    
    // Clear data on logout
    _vehicles.clear();
    _reportedIssues.clear();
    _inspectionResults.clear();
    _inventoryPhotos.clear();
    _pendingOperations.clear();
    
    await prefs.remove('reportedIssues');
    await prefs.remove('inspectionResults');
    await prefs.remove('inventoryPhotos');
    await prefs.remove('pendingOperations');
    await prefs.remove('lastRoute');
    _lastRoute = null;
    
    debugPrint('AppProvider: isLoggedIn set to false and PERSISTED. Notifying listeners...');
    notifyListeners();
  }

  // ==================== CONSTANTS ====================

  static const List<String> issueTypes = [
    'Battery Drain',
    'Charging Failure',
    'Motor Noise',
    'Brake Squeal',
    'Tire Pressure',
    'Coolant Leak',
    'AC Not Cooling',
    '12V Battery Low'
  ];
}
