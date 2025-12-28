import '../models/kpi.dart';
import '../models/job.dart';
import '../models/vehicle.dart';
import '../models/alert.dart';
import '../models/driver_details.dart';
import '../models/rsa_event.dart';

// Fleet KPIs (SAME)
final fleetKPIs = FleetKPIs(
  activeCoreVehicles: ActiveCoreVehicles(
    total: 248,
    ev: 156,
    ice: 92,
    evPercentage: 62.9,
  ),
  jobsInProgress: JobsInProgress(
    count: 34,
    status: 'normal',
  ),
  avgCostPerKm: AvgCostPerKm(
    value: 2.45,
    delta: -8.2,
    fleetAvg: 2.67,
  ),
  avgJobCompletionTime: AvgJobCompletionTime(
    hours: 4.2,
    trend: 'down',
    delta: -12.5,
  ),
);

// Service Pipeline Data (SAME)
final servicePipelineData = [
  ServicePipelineData(name: 'In Progress', value: 34, color: '#3B82F6'),
  ServicePipelineData(name: 'Pending Diagnosis', value: 18, color: '#F59E0B'),
  ServicePipelineData(name: 'Completed', value: 127, color: '#10B981'),
  ServicePipelineData(name: 'On-Hold', value: 9, color: '#EF4444'),
];

// Job Completion Time Data (SAME)
final jobCompletionTimeData = {
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

// Jobs by Category (SAME)
final jobsByCategory = [
  JobCategory(
    category: 'Scheduled Maintenance',
    total: 89,
    completed: 76,
    pending: 13,
    slaStatus: 'on-track',
  ),
  JobCategory(
    category: 'Breakdown',
    total: 45,
    completed: 32,
    pending: 13,
    slaStatus: 'at-risk',
  ),
  JobCategory(
    category: 'Warranty',
    total: 28,
    completed: 24,
    pending: 4,
    slaStatus: 'on-track',
  ),
  JobCategory(
    category: 'RSA (Roadside Assistance)',
    total: 26,
    completed: 19,
    pending: 7,
    slaStatus: 'critical',
  ),
];

// Logistics Insights (SAME)
final logisticsInsights = LogisticsInsights(
  peakBreakdownZones: [
    'Zone A (Downtown)',
    'Zone C (Industrial)',
    'Zone E (Highway-12)',
  ],
  avgResponseTime: '18 mins',
  vehiclesNearServiceDue: 42,
);

// Cost Trends Data (SAME)
final costTrendsData = [
  CostTrend(month: 'Jul', totalCost: 245000, evCost: 142000, iceCost: 103000),
  CostTrend(month: 'Aug', totalCost: 238000, evCost: 148000, iceCost: 90000),
  CostTrend(month: 'Sep', totalCost: 252000, evCost: 155000, iceCost: 97000),
  CostTrend(month: 'Oct', totalCost: 241000, evCost: 151000, iceCost: 90000),
  CostTrend(month: 'Nov', totalCost: 235000, evCost: 147000, iceCost: 88000),
  CostTrend(month: 'Dec', totalCost: 229000, evCost: 144000, iceCost: 85000),
];

// Cost Breakdown Data (SAME)
final costBreakdownData = [
  CostBreakdown(category: 'Tyres', ev: 42000, ice: 38000),
  CostBreakdown(category: 'Brakes', ev: 31000, ice: 29000),
  CostBreakdown(category: 'AC', ev: 18000, ice: 22000),
  CostBreakdown(category: 'Suspension', ev: 15000, ice: 28000),
  CostBreakdown(category: 'Battery/Engine', ev: 38000, ice: 52000),
];

// Energy vs Service Cost (SAME)
final energyVsServiceCost = [
  EnergyVsService(month: 'Jul', energyCost: 85000, serviceCost: 57000),
  EnergyVsService(month: 'Aug', energyCost: 88000, serviceCost: 60000),
  EnergyVsService(month: 'Sep', energyCost: 91000, serviceCost: 64000),
  EnergyVsService(month: 'Oct', energyCost: 87000, serviceCost: 64000),
  EnergyVsService(month: 'Nov', energyCost: 84000, serviceCost: 63000),
  EnergyVsService(month: 'Dec', energyCost: 82000, serviceCost: 62000),
];

// Cost Per Km Benchmark (SAME)
final costPerKmBenchmark = CostPerKmBenchmark(
  current: 2.45,
  fleetAvg: 2.67,
  optimal: 2.1,
  vehicleId: 'EV-1247',
  routeType: 'Urban',
  loadFactor: 0.72,
);

// Action Recommendations (SAME)
final actionRecommendations = [
  ActionRecommendation(
    id: 1,
    type: 'warning',
    message: 'High brake wear detected on 8 vehicles',
    action: 'Schedule preventive inspection',
  ),
  ActionRecommendation(
    id: 2,
    type: 'info',
    message: 'Battery health affecting cost/km on EV-1247, EV-1288',
    action: 'Run battery diagnostics',
  ),
  ActionRecommendation(
    id: 3,
    type: 'success',
    message: 'Fleet cost/km trending 8.2% below target',
    action: 'Continue current maintenance schedule',
  ),
];

// Individual Vehicles (UPDATED)
final individualVehicles = [
  Vehicle(
    id: 'EV-1247',
    type: VehicleType.EV,
    model: 'Tesla Semi',
    status: VehicleStatus.active,
    batteryLevel: 78,
    fuelLevel: null,
    location: Location(
      lat: 40.7128,
      lng: -74.006,
      address: 'Downtown Hub, Zone A',
    ),
    currentJob: CurrentJob(
      id: 'JOB-8934',
      type: 'Delivery',
      progress: 65,
      eta: '1.2 hrs',
    ),
    driver: DriverDetails(
      name: 'Sarah Johnson',
      phone: '+1 (555) 123-4567',
      licenseNumber: 'DL-98765432',
      rating: 4.8,
      totalTrips: 1243,
      imageUrl: 'https://i.pravatar.cc/150?u=sarah',
      drivingScore: 92,
      currentMonthTrips: 42,
      drivingHours: 156,
    ),
    odometer: 45280,
    nextMaintenanceKm: 50000,
    healthScore: 92,
    alerts: [
      Alert(type: AlertType.info, message: 'Tire pressure check recommended'),
    ],
    costPerKm: 2.15,
    avgSpeed: 58,
    idleTime: 12,
    evRange: 142,
    efficiency: 4.2,
    lastCharged: '6h ago',
    batteryHealth: 96,
    rsaEvents: [
      RSAEvent(type: 'Harsh Braking', severity: 'medium', time: 'Dec 22, 2:45 PM', location: 'Highway 101, Mile 45'),
      RSAEvent(type: 'Speeding', severity: 'low', time: 'Dec 21, 10:30 AM', location: 'Main Street'),
    ],
  ),
  Vehicle(
    id: 'ICE-2891',
    type: VehicleType.ICE,
    model: 'Volvo FH16',
    status: VehicleStatus.active,
    batteryLevel: null,
    fuelLevel: 42,
    location: Location(
      lat: 40.7589,
      lng: -73.9851,
      address: 'Route 12, Zone E',
    ),
    currentJob: CurrentJob(
      id: 'JOB-8947',
      type: 'Long Haul',
      progress: 28,
      eta: '4.5 hrs',
    ),
    driver: DriverDetails(
      name: 'Michael Chen',
      phone: '+1 (555) 345-6789',
      licenseNumber: 'DL-87654321',
      rating: 4.9,
      totalTrips: 850,
      imageUrl: 'https://i.pravatar.cc/150?u=michael',
      drivingScore: 95,
      currentMonthTrips: 38,
      drivingHours: 142,
    ),
    odometer: 128450,
    nextMaintenanceKm: 130000,
    healthScore: 88,
    alerts: [
      Alert(type: AlertType.warning, message: 'Service due in 1,550 km'),
    ],
    costPerKm: 2.89,
    avgSpeed: 72,
    idleTime: 28,
    rsaEvents: [
      RSAEvent(type: 'Rapid Acceleration', severity: 'low', time: 'Dec 20, 3:15 PM', location: 'Industrial Zone'),
    ],
  ),
  Vehicle(
    id: 'EV-1288',
    type: VehicleType.EV,
    model: 'Rivian EDV',
    status: VehicleStatus.charging,
    batteryLevel: 34,
    fuelLevel: null,
    location: Location(
      lat: 40.7282,
      lng: -74.0776,
      address: 'Charging Station 7, Zone B',
    ),
    currentJob: null,
    driver: null,
    odometer: 32150,
    nextMaintenanceKm: 35000,
    healthScore: 85,
    alerts: [
      Alert(type: AlertType.info, message: 'Fast charging in progress - 25 mins remaining'),
      Alert(type: AlertType.warning, message: 'Battery health degradation detected'),
    ],
    costPerKm: 2.42,
    avgSpeed: 0,
    idleTime: 0,
    evRange: 85,
    efficiency: 3.8,
    lastCharged: 'Now',
    batteryHealth: 88,
  ),
  Vehicle(
    id: 'ICE-2456',
    type: VehicleType.ICE,
    model: 'Mercedes Actros',
    status: VehicleStatus.idle,
    batteryLevel: null,
    fuelLevel: 88,
    location: Location(
      lat: 40.6892,
      lng: -74.0445,
      address: 'Warehouse District, Zone C',
    ),
    currentJob: null,
    driver: DriverDetails(
      name: 'David Martinez',
      phone: '+1 (555) 987-6543',
      licenseNumber: 'DL-12345678',
      rating: 4.6,
      totalTrips: 1560,
      imageUrl: 'https://i.pravatar.cc/150?u=david',
      drivingScore: 82,
      currentMonthTrips: 51,
      drivingHours: 168,
    ),
    odometer: 89720,
    nextMaintenanceKm: 95000,
    healthScore: 94,
    alerts: [],
    costPerKm: 2.58,
    avgSpeed: 0,
    idleTime: 45,
    rsaEvents: [
      RSAEvent(type: 'Hard Cornering', severity: 'medium', time: 'Dec 18, 9:00 AM', location: 'Downtown'),
    ],
  ),
  Vehicle(
    id: 'EV-1356',
    type: VehicleType.EV,
    model: 'BYD ETM6',
    status: VehicleStatus.active,
    batteryLevel: 91,
    fuelLevel: null,
    location: Location(
      lat: 40.7489,
      lng: -73.9680,
      address: 'Central District, Zone D',
    ),
    currentJob: CurrentJob(
      id: 'JOB-8956',
      type: 'Pickup',
      progress: 15,
      eta: '0.8 hrs',
    ),
    driver: DriverDetails(
      name: 'Emily Rodriguez',
      phone: '+1 (555) 555-5555',
      licenseNumber: 'DL-00001111',
      rating: 4.9,
      totalTrips: 420,
      imageUrl: 'https://i.pravatar.cc/150?u=emily',
      drivingScore: 98,
      currentMonthTrips: 30,
      drivingHours: 98,
    ),
    odometer: 21890,
    nextMaintenanceKm: 25000,
    healthScore: 96,
    alerts: [],
    costPerKm: 1.98,
    avgSpeed: 45,
    idleTime: 8,
    evRange: 210,
    efficiency: 4.5,
    lastCharged: '2h ago',
    batteryHealth: 99,
  ),
  Vehicle(
    id: 'ICE-2678',
    type: VehicleType.ICE,
    model: 'Scania R500',
    status: VehicleStatus.maintenance,
    batteryLevel: null,
    fuelLevel: 65,
    location: Location(
      lat: 40.7056,
      lng: -74.0134,
      address: 'Service Center 3',
    ),
    currentJob: null,
    driver: null,
    odometer: 156780,
    nextMaintenanceKm: 160000,
    healthScore: 72,
    alerts: [
      Alert(type: AlertType.critical, message: 'Brake system maintenance in progress'),
      Alert(type: AlertType.warning, message: 'Engine diagnostics required'),
    ],
    costPerKm: 3.12,
    avgSpeed: 0,
    idleTime: 0,
  ),
  Vehicle(
    id: 'EV-1189',
    type: VehicleType.EV,
    model: 'Ford E-Transit',
    status: VehicleStatus.active,
    batteryLevel: 56,
    fuelLevel: null,
    location: Location(
      lat: 40.7614,
      lng: -73.9776,
      address: 'Midtown Area, Zone A',
    ),
    currentJob: CurrentJob(
      id: 'JOB-8961',
      type: 'Service',
      progress: 82,
      eta: '0.3 hrs',
    ),
    driver: DriverDetails(
      name: 'James Wilson',
      phone: '+1 (555) 777-8888',
      licenseNumber: 'DL-22223333',
      rating: 4.7,
      totalTrips: 980,
      imageUrl: 'https://i.pravatar.cc/150?u=james',
      drivingScore: 89,
      currentMonthTrips: 45,
      drivingHours: 132,
    ),
    odometer: 18420,
    nextMaintenanceKm: 20000,
    healthScore: 98,
    alerts: [],
    costPerKm: 1.85,
    avgSpeed: 52,
    idleTime: 5,
    evRange: 110,
    efficiency: 4.0,
    lastCharged: '4h ago',
    batteryHealth: 95,
  ),
  Vehicle(
    id: 'ICE-2334',
    type: VehicleType.ICE,
    model: 'MAN TGX',
    status: VehicleStatus.idle,
    batteryLevel: null,
    fuelLevel: 23,
    location: Location(
      lat: 40.7456,
      lng: -73.9889,
      address: 'Depot 5, Zone B',
    ),
    currentJob: null,
    driver: DriverDetails(
      name: 'Lisa Anderson',
      phone: '+1 (555) 444-4444',
      licenseNumber: 'DL-44445555',
      rating: 4.5,
      totalTrips: 2100,
      imageUrl: 'https://i.pravatar.cc/150?u=lisa',
      drivingScore: 85,
      currentMonthTrips: 55,
      drivingHours: 175,
    ),
    odometer: 112340,
    nextMaintenanceKm: 115000,
    healthScore: 81,
    alerts: [
      Alert(type: AlertType.warning, message: 'Low fuel level - refuel recommended'),
    ],
    costPerKm: 2.95,
    avgSpeed: 0,
    idleTime: 67,
  ),
];
