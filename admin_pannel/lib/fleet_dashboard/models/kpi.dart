class FleetKPIs {
  final ActiveCoreVehicles activeCoreVehicles;
  final JobsInProgress jobsInProgress;
  final AvgCostPerKm avgCostPerKm;
  final AvgJobCompletionTime avgJobCompletionTime;

  FleetKPIs({
    required this.activeCoreVehicles,
    required this.jobsInProgress,
    required this.avgCostPerKm,
    required this.avgJobCompletionTime,
  });
}

class ActiveCoreVehicles {
  final int total;
  final int ev;
  final int ice;
  final double evPercentage;

  ActiveCoreVehicles({
    required this.total,
    required this.ev,
    required this.ice,
    required this.evPercentage,
  });
}

class JobsInProgress {
  final int count;
  final String status; // 'normal' | 'warning' | 'critical'

  JobsInProgress({
    required this.count,
    required this.status,
  });
}

class AvgCostPerKm {
  final double value;
  final double delta;
  final double fleetAvg;

  AvgCostPerKm({
    required this.value,
    required this.delta,
    required this.fleetAvg,
  });
}

class AvgJobCompletionTime {
  final double hours;
  final String trend; // 'up' | 'down' | 'stable'
  final double delta;

  AvgJobCompletionTime({
    required this.hours,
    required this.trend,
    required this.delta,
  });
}

class ServicePipelineData {
  final String name;
  final int value;
  final String color;

  ServicePipelineData({
    required this.name,
    required this.value,
    required this.color,
  });
}

class LogisticsInsights {
  final List<String> peakBreakdownZones;
  final String avgResponseTime;
  final int vehiclesNearServiceDue;

  LogisticsInsights({
    required this.peakBreakdownZones,
    required this.avgResponseTime,
    required this.vehiclesNearServiceDue,
  });
}

class CostTrend {
  final String month;
  final int totalCost;
  final int evCost;
  final int iceCost;

  CostTrend({
    required this.month,
    required this.totalCost,
    required this.evCost,
    required this.iceCost,
  });
}

class CostBreakdown {
  final String category;
  final int ev;
  final int ice;

  CostBreakdown({
    required this.category,
    required this.ev,
    required this.ice,
  });
}

class EnergyVsService {
  final String month;
  final int energyCost;
  final int serviceCost;

  EnergyVsService({
    required this.month,
    required this.energyCost,
    required this.serviceCost,
  });
}

class CostPerKmBenchmark {
  final double current;
  final double fleetAvg;
  final double optimal;
  final String vehicleId;
  final String routeType;
  final double loadFactor;

  CostPerKmBenchmark({
    required this.current,
    required this.fleetAvg,
    required this.optimal,
    required this.vehicleId,
    required this.routeType,
    required this.loadFactor,
  });
}

class ActionRecommendation {
  final int id;
  final String type; // 'warning' | 'info' | 'success'
  final String message;
  final String action;

  ActionRecommendation({
    required this.id,
    required this.type,
    required this.message,
    required this.action,
  });
}
