import 'package:flutter/foundation.dart';
import 'package:gogreen_admin/models/maintenance_job.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class JobProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<MaintenanceJob> _jobs = [];
  MaintenanceJob? _selectedJob;
  bool _isLoading = false;
  String? _error;

  List<MaintenanceJob> get jobs => _jobs;
  MaintenanceJob? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadJobs({String? vehicleId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _supabaseService.getJobs(vehicleId: vehicleId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectJob(MaintenanceJob job) {
    _selectedJob = job;
    notifyListeners();
  }

  Future<void> createJob(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final job = await _supabaseService.createMaintenanceJob(data);
      _jobs.add(job);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final job = await _supabaseService.updateMaintenanceJob(jobId, data);
      final index = _jobs.indexWhere((j) => j.jobId == jobId);
      if (index != -1) {
        _jobs[index] = job;
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





