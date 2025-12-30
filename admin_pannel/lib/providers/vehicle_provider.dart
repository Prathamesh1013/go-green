import 'package:flutter/foundation.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class VehicleProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
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

  List<Vehicle> get filteredVehicles {
    var filtered = _vehicles;

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

  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicles = await _supabaseService.getVehicles(
        status: _statusFilter,
        healthState: _healthStateFilter,
        hubId: _hubFilter,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _vehicles = [];
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
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

  Future<void> createVehicle(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicle = await _supabaseService.createVehicle(data);
      _vehicles.add(vehicle);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateVehicle(
      String vehicleId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final vehicle = await _supabaseService.updateVehicle(vehicleId, data);
      final index = _vehicles.indexWhere((v) => v.vehicleId == vehicleId);
      if (index != -1) {
        _vehicles[index] = vehicle;
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
