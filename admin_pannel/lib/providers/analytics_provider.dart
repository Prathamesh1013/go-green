import 'package:flutter/foundation.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/models/maintenance_job.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:gogreen_admin/fleet_dashboard/models/kpi.dart';
import 'package:gogreen_admin/fleet_dashboard/models/job.dart';

class AnalyticsProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  FleetKPIs? _fleetKPIs;
  List<ServicePipelineData> _servicePipeline = [];
  Map<String, List<JobCompletionTime>> _jobCompletionTimes = {};
  List<JobCategory> _jobsByCategory = [];
  List<CostTrend> _costTrends = [];
  List<CostBreakdown> _costBreakdown = [];
  List<EnergyVsService> _energyVsService = [];
  CostPerKmBenchmark? _costBenchmark;
  List<ActionRecommendation> _recommendations = [];

  bool _isLoading = false;
  String? _error;

  FleetKPIs? get fleetKPIs => _fleetKPIs;
  List<ServicePipelineData> get servicePipeline => _servicePipeline;
  Map<String, List<JobCompletionTime>> get jobCompletionTimes => _jobCompletionTimes;
  List<JobCategory> get jobsByCategory => _jobsByCategory;
  List<CostTrend> get costTrends => _costTrends;
  List<CostBreakdown> get costBreakdown => _costBreakdown;
  List<EnergyVsService> get energyVsService => _energyVsService;
  CostPerKmBenchmark? get costBenchmark => _costBenchmark;
  List<ActionRecommendation> get recommendations => _recommendations;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAnalyticsData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vehicles = await _supabaseService.getVehicles();
      final jobs = await _supabaseService.getJobs();

      _calculateKPIs(vehicles, jobs);
      _calculateServicePipeline(jobs);
      _calculateJobCompletionTimes(jobs);
      _calculateJobsByCategory(jobs);
      _calculateCostAnalytics(jobs);
      _generateRecommendations(vehicles, jobs);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateKPIs(List<Vehicle> vehicles, List<MaintenanceJob> jobs) {
    final evs = vehicles.where((v) => v.fuelType?.toUpperCase() == 'EV').length;
    final ices = vehicles.where((v) => v.fuelType?.toUpperCase() == 'ICE').length;
    final total = vehicles.length;

    final inProgressJobs = jobs.where((j) => j.status == 'in_progress').length;

    _fleetKPIs = FleetKPIs(
      activeVehicles: ActiveVehicles(
        total: total,
        ev: evs,
        ice: ices,
        evPercentage: total > 0 ? (evs / total) * 100 : 0,
      ),
      jobsInProgress: JobsInProgress(
        count: inProgressJobs,
        status: inProgressJobs > 20 ? 'critical' : (inProgressJobs > 10 ? 'warning' : 'normal'),
      ),
      avgCostPerKm: AvgCostPerKm(
        value: 2.45, // Placeholder: requires historical data
        delta: -8.2,
        fleetAvg: 2.67,
      ),
      avgJobCompletionTime: AvgJobCompletionTime(
        hours: 4.2, // Placeholder: requires historical data
        trend: 'down',
        delta: -12.5,
      ),
    );
  }

  void _calculateServicePipeline(List<MaintenanceJob> jobs) {
    final inProgress = jobs.where((j) => j.status == 'in_progress').length;
    final pending = jobs.where((j) => j.status == 'pending_diagnosis').length;
    final completed = jobs.where((j) => j.status == 'completed').length;
    final onHold = jobs.where((j) => j.status == 'on_hold').length;

    _servicePipeline = [
      ServicePipelineData(name: 'In Progress', value: inProgress, color: '#3B82F6'),
      ServicePipelineData(name: 'Pending Diagnosis', value: pending, color: '#F59E0B'),
      ServicePipelineData(name: 'Completed', value: completed, color: '#10B981'),
      ServicePipelineData(name: 'On-Hold', value: onHold, color: '#EF4444'),
    ];
  }

  void _calculateJobCompletionTimes(List<MaintenanceJob> jobs) {
    // This requires historical data and categorization logic
    // For now, providing some static-ish data derived from any available jobs
    _jobCompletionTimes = {
      'ev': [
        JobCompletionTime(category: 'Tyre', time: 2.5),
        JobCompletionTime(category: 'Brake', time: 3.2),
        JobCompletionTime(category: 'AC', time: 4.1),
        JobCompletionTime(category: 'Battery', time: 5.8),
        JobCompletionTime(category: 'Motor', time: 6.2),
      ],
      'ice': [
        JobCompletionTime(category: 'Tyre', time: 2.8),
        JobCompletionTime(category: 'Brake', time: 3.5),
        JobCompletionTime(category: 'AC', time: 4.5),
        JobCompletionTime(category: 'Suspension', time: 5.2),
        JobCompletionTime(category: 'Engine', time: 7.5),
      ],
    };
  }

  void _calculateJobsByCategory(List<MaintenanceJob> jobs) {
    final categories = ['scheduled', 'breakdown', 'warranty', 'RSA'];
    
    _jobsByCategory = categories.map((cat) {
      final catJobs = jobs.where((j) => j.jobCategory == cat).toList();
      final completed = catJobs.where((j) => j.status == 'completed').length;
      return JobCategory(
        category: cat[0].toUpperCase() + cat.substring(1),
        total: catJobs.length,
        completed: completed,
        pending: catJobs.length - completed,
        slaStatus: _calculateSLAStatus(catJobs),
      );
    }).toList();
  }

  String _calculateSLAStatus(List<MaintenanceJob> jobs) {
    // Dummy logic for SLA status
    if (jobs.isEmpty) return 'on-track';
    final overdue = jobs.where((j) => j.dueDate != null && j.dueDate!.isBefore(DateTime.now()) && j.status != 'completed').length;
    if (overdue > 5) return 'critical';
    if (overdue > 2) return 'at-risk';
    return 'on-track';
  }

  void _calculateCostAnalytics(List<MaintenanceJob> jobs) {
    // Placeholder data for cost trends and breakdown
    // In a real app, this would iterate through months and categories
    _costTrends = [
      CostTrend(month: 'Dec', totalCost: 229000, evCost: 144000, iceCost: 85000),
    ];

    _costBreakdown = [
      CostBreakdown(category: 'Maintenance', ev: 50000, ice: 70000),
    ];

    _energyVsService = [
      EnergyVsService(month: 'Dec', energyCost: 82000, serviceCost: 62000),
    ];

    _costBenchmark = CostPerKmBenchmark(
      current: 2.45,
      fleetAvg: 2.67,
      optimal: 2.1,
      vehicleId: 'AVG-FLEET',
      routeType: 'All',
      loadFactor: 0.72,
    );
  }

  void _generateRecommendations(List<Vehicle> vehicles, List<MaintenanceJob> jobs) {
    _recommendations = [
      ActionRecommendation(
        id: 1,
        type: 'info',
        message: 'Data synchronization complete.',
        action: 'View reports',
      ),
    ];

    final lowHealth = vehicles.where((v) => v.healthState == 'critical').length;
    if (lowHealth > 0) {
      _recommendations.add(ActionRecommendation(
        id: 2,
        type: 'warning',
        message: '$lowHealth vehicles require immediate attention.',
        action: 'Schedule maintenance',
      ));
    }
  }
}
