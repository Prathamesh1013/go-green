import 'package:flutter/foundation.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class CoreVehicleProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<CoreVehicle> _coreVehicles = [];
  CoreVehicle? _selectedCoreVehicle;
  bool _isLoading = false;
  String? _error;

  List<CoreVehicle> get coreVehicles => _coreVehicles;
  CoreVehicle? get selectedCoreVehicle => _selectedCoreVehicle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter states
  String? _statusFilter;
  String? _healthStateFilter;
  String? _hubFilter;
  String _searchQuery = '';

  String? get statusFilter => _statusFilter;
  String? get healthStateFilter => _healthStateFilter;
  String? get hubFilter => _hubFilter;
  String get searchQuery => _searchQuery;

  List<CoreVehicle> get filteredCoreVehicles {
    var filtered = _coreVehicles;

    if (_statusFilter != null) {
      filtered = filtered.where((v) => v.status == _statusFilter).toList();
    }

    if (_healthStateFilter != null) {
      filtered =
          filtered.where((v) => v.healthState == _healthStateFilter).toList();
    }

    if (_hubFilter != null) {
      filtered = filtered.where((v) => v.primaryHubId == _hubFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((v) =>
              v.vehicleNumber.toLowerCase().contains(query) ||
              (v.make?.toLowerCase().contains(query) ?? false) ||
              (v.model?.toLowerCase().contains(query) ?? false) ||
              v.franchiseName.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  Future<void> loadCoreVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coreVehicles = await _supabaseService.getCoreVehicles(
        status: _statusFilter,
        healthState: _healthStateFilter,
        hubId: _hubFilter,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _coreVehicles = [];
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCoreVehicle(CoreVehicle vehicle) {
    _selectedCoreVehicle = vehicle;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setHealthStateFilter(String? healthState) {
    _healthStateFilter = healthState;
    notifyListeners();
  }

  void setHubFilter(String? hubId) {
    _hubFilter = hubId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _healthStateFilter = null;
    _hubFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> createCoreVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicle = await _supabaseService.createCoreVehicle(data);
      _coreVehicles.add(vehicle);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCoreVehicle(
      String vehicleId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicle = await _supabaseService.updateCoreVehicle(vehicleId, data);
      final index = _coreVehicles.indexWhere((v) => v.vehicleId == vehicleId);
      if (index != -1) {
        _coreVehicles[index] = vehicle;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
