import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

enum InspectionStatus { auto, ok, attention }

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Vehicle _vehicle; // In simple app, we might check provider, but let's assume we fetch it
  
  // Field Ops State
  bool _isVehicleIn = true;
  final TextEditingController _todoController = TextEditingController();
  List<String> _localTodos = [];
  
  // Daily Inventory State
  final Map<String, bool?> _dailyChecks = {
    'Battery Level': null,
    'Charging Cable': null,
    'Tyre Condition': null,
    'Visible Damage': null,
  }; // null = unset, true = OK, false = Issue

  // Inspection Data State (Existing)
  final Map<String, InspectionStatus> _checks = {
    'SoH OK': InspectionStatus.auto,
    'No HV warnings': InspectionStatus.auto,
    'AC charging OK': InspectionStatus.auto,
    'DC charging OK': InspectionStatus.auto,
    'No abnormal noise': InspectionStatus.auto,
    'Power delivery normal': InspectionStatus.auto,
    'Coolant level OK': InspectionStatus.auto,
    'Fans / pump working': InspectionStatus.auto,
    '12V battery OK': InspectionStatus.auto,
    'Brakes OK': InspectionStatus.auto,
    'Tire condition OK': InspectionStatus.auto,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load vehicle data
    final provider = context.read<AppProvider>();
    final v = provider.getVehicleById(widget.vehicleId);
    if (v != null) {
      _vehicle = v;
      _isVehicleIn = v.isVehicleIn;
      _localTodos.addAll(v.toDos);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  void _toggleStatus(String key) {
    setState(() {
      if (_checks[key] == InspectionStatus.auto || _checks[key] == InspectionStatus.attention) {
        _checks[key] = InspectionStatus.ok;
      } else {
        _checks[key] = InspectionStatus.attention;
      }
    });
  }
  
  void _completeInspection() {
     final Map<String, String> results = _checks.map((key, value) {
      if (value == InspectionStatus.ok) return MapEntry(key, 'ok');
      if (value == InspectionStatus.attention) return MapEntry(key, 'attention');
      return MapEntry(key, 'auto');
    });

    context.read<AppProvider>().saveInspection(InspectionResult(
          vehicleId: widget.vehicleId,
          checks: results,
          timestamp: DateTime.now(),
        ));

    context.pushReplacement('/vehicle-summary/${widget.vehicleId}');
  }

  bool get _hasAttention => _checks.values.any((s) => s == InspectionStatus.attention);

  @override
  Widget build(BuildContext context) {
    if (context.read<AppProvider>().getVehicleById(widget.vehicleId) == null) {
       return const Scaffold(body: Center(child: Text('Vehicle Not Found')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Vehicle Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryBlue,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Daily Check'),
            Tab(text: 'Full Scan'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildInOutHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDailyCheckTab(),
                _buildFullScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. IN / OUT Feature
  Widget _buildInOutHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.car, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_vehicle.vehicleNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_vehicle.serviceType, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          InkWell(
            onTap: () async {
              try {
                final newValue = !_isVehicleIn;
                await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                  'is_vehicle_in': newValue,
                });
                setState(() => _isVehicleIn = newValue);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Vehicle marked as ${newValue ? "IN" : "OUT"}'),
                    duration: const Duration(seconds: 1),
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating status: $e')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isVehicleIn ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _isVehicleIn ? const Color(0xFF166534) : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(_isVehicleIn ? LucideIcons.logIn : LucideIcons.logOut, size: 16, color: _isVehicleIn ? const Color(0xFF166534) : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _isVehicleIn ? 'IN GARAGE' : 'OUT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _isVehicleIn ? const Color(0xFF166534) : Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: Overview (To-Do, Charging, Service)
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 4. To-Do Feature
          _buildTodoSection(),
          const SizedBox(height: 20),
          // 3. Charging Cycle Feature
          _buildChargingSection(),
          const SizedBox(height: 20),
          // 2. Servicing Feature
          _buildServiceSection(),
        ],
      ),
    );
  }

  Widget _buildTodoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tasks (To-Do)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${_localTodos.length}/3', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ..._localTodos.map((todo) => CheckboxListTile(
            title: Text(todo, style: const TextStyle(fontSize: 14)),
            value: false, // In real app, track completion
            onChanged: (val) async {
              try {
                final List<String> updatedTodos = List.from(_localTodos)..remove(todo);
                await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                  'to_dos': updatedTodos,
                });
                setState(() => _localTodos = updatedTodos);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing task: $e')),
                  );
                }
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
          if (_localTodos.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _todoController,
                        decoration: const InputDecoration(
                          hintText: 'Add new task...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (val) async {
                          if (val.isNotEmpty) {
                            try {
                              final List<String> updatedTodos = List.from(_localTodos)..add(val);
                              await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                                'to_dos': updatedTodos,
                              });
                              setState(() {
                                _localTodos = updatedTodos;
                                _todoController.clear();
                              });
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error adding task: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: AppTheme.primaryBlue),
                    onPressed: () async {
                      final val = _todoController.text;
                      if (val.isNotEmpty) {
                        try {
                          final List<String> updatedTodos = List.from(_localTodos)..add(val);
                          await context.read<AppProvider>().updateVehicleSummary(widget.vehicleId, {
                            'to_dos': updatedTodos,
                          });
                          setState(() {
                            _localTodos = updatedTodos;
                            _todoController.clear();
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error adding task: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChargingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Charging Cycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Last: ${_vehicle.lastChargeType}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoStat('Battery', '${_vehicle.batteryLevel.toInt()}%', LucideIcons.battery),
              _infoStat('Health', _vehicle.chargingHealth, LucideIcons.heartPulse),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('Log Charging'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Servicing Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Text('Last Service: ${_vehicle.lastServiceDate != null ? DateFormat('d MMM y').format(_vehicle.lastServiceDate!) : 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text('Type: ${_vehicle.lastServiceType ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statusButton('Service OK', true, true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statusButton('Attention', false, false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: Daily Check
  Widget _buildDailyCheckTab() {
    final photos = context.watch<AppProvider>().getInventoryPhotos(widget.vehicleId);
    final int photoCount = photos.length;
    final int requiredCount = 9; // Total categories in InventoryPhotosScreen
    final bool allPhotosCaptured = photoCount >= requiredCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Inventory / Visual Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Tap to toggle status', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                ..._dailyChecks.keys.map((key) => _dailyCheckItem(key)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Structured Photos Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange.shade200, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (allPhotosCaptured ? AppTheme.successGreen : Colors.orange).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allPhotosCaptured ? LucideIcons.checkCheck : LucideIcons.camera, 
                        color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange, 
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Required Inventory Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            allPhotosCaptured ? 'All photos captured' : 'Capture all angles & details',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$photoCount/$requiredCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: allPhotosCaptured ? AppTheme.successGreen : Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/inventory-photos/${widget.vehicleId}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      allPhotosCaptured ? 'Review Photos' : 'Capture Photos Now',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/add-issue/${widget.vehicleId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: AppTheme.dangerRed,
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Color(0xFFFEE2E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 20),
                const SizedBox(width: 12),
                const Text('Add Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: allPhotosCaptured ? () async {
                 // Save the daily checks to Supabase
                 await context.read<AppProvider>().saveDailyChecks(widget.vehicleId, _dailyChecks);
                 
                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory Logged Successfully')));
                   _tabController.animateTo(2); // Switch to "Full Scan" section
                 }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                allPhotosCaptured 
                  ? 'Complete & Submit Inventory' 
                  : 'Capture All Photos to Submit', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyCheckItem(String label) {
    bool? status = _dailyChecks[label];
    Color color = Colors.grey.shade100;
    IconData icon = LucideIcons.circle;
    Color iconColor = Colors.grey;
    
    if (status == true) {
      color = const Color(0xFFDCFCE7);
      icon = LucideIcons.checkCircle;
      iconColor = const Color(0xFF166534);
    } else if (status == false) {
      color = const Color(0xFFFEF2F2);
      icon = LucideIcons.alertTriangle;
      iconColor = AppTheme.dangerRed;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (status == null) _dailyChecks[label] = true;
          else if (status == true) _dailyChecks[label] = false;
          else _dailyChecks[label] = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  // TAB 3: Full Scan (Original Quick Inspection)
  Widget _buildFullScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           // Top Summary Bar (Integrated into tab)
          _buildSummaryBar(),
          const SizedBox(height: 16),
          // Sections
          _buildSection('Battery & HV System', ['SoH OK', 'No HV warnings'], LucideIcons.battery),
          _buildSection('Charging', ['AC charging OK', 'DC charging OK'], LucideIcons.zap),
          _buildSection('Motor & Drive', ['No abnormal noise', 'Power delivery normal'], LucideIcons.activity),
          _buildSection('Cooling', ['Coolant level OK', 'Fans / pump working'], LucideIcons.thermometer),
          _buildSection('12V System', ['12V battery OK'], LucideIcons.batteryMedium),
          _buildSection('Brakes & Tires', ['Brakes OK', 'Tire condition OK'], LucideIcons.disc),
          
          const SizedBox(height: 24),
          _buildBottomActions(),
        ],
      ),
    );
  }

  // Helpers from previous step...
  Widget _infoStat(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _statusButton(String label, bool isOk, bool isPrimary) {
    // Determine visuals based on state logic if needed, simplify for now
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOk ? const Color(0xFF166534) : AppTheme.dangerRed)
      ),
      child: Center(
        child: Text(label, style: TextStyle(
          color: isOk ? const Color(0xFF166534) : AppTheme.dangerRed,
          fontWeight: FontWeight.bold,
        )),
      ),
    );
  }

  // REUSED: Summary Bar
  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: _hasAttention ? AppTheme.dangerRed.withOpacity(0.1) : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Vehicle | VIN', '${_vehicle.vehicleNumber} | ...8241'),
          _summaryItem('Battery SoH', '94%', highlight: true),
          _summaryItem('Faults', _hasAttention ? 'YES' : 'NO', 
            color: _hasAttention ? AppTheme.dangerRed : Colors.green),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color, bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppTheme.textDark)),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildCheckCard(item)),
        ],
      ),
    );
  }

  Widget _buildCheckCard(String label) {
    final status = _checks[label]!;
    Color cardColor = Colors.white;
    Color textColor = AppTheme.textDark;
    Color iconColor = Colors.grey;
    IconData icon = LucideIcons.circle;

    if (status == InspectionStatus.ok) {
      cardColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF166534);
      iconColor = const Color(0xFF166534);
      icon = LucideIcons.checkCircle;
    } else if (status == InspectionStatus.attention) {
      cardColor = const Color(0xFFFEF9C3);
      textColor = const Color(0xFF854D0E);
      iconColor = const Color(0xFF854D0E);
      icon = LucideIcons.alertCircle;
    } else if (status == InspectionStatus.auto) {
      cardColor = const Color(0xFFF3F4F6);
      icon = LucideIcons.cpu;
    }

    return GestureDetector(
      onTap: () => _toggleStatus(label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == InspectionStatus.attention ? AppTheme.dangerRed : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            Row(
              children: [
                if (status == InspectionStatus.auto)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('AUTO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                Icon(icon, color: iconColor, size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
          ElevatedButton(
            onPressed: () => context.push('/add-issue/${widget.vehicleId}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEF2F2),
              foregroundColor: AppTheme.dangerRed,
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: Color(0xFFFEE2E2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertCircle, size: 20),
                SizedBox(width: 12),
                Text('Add Issue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _completeInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasAttention ? AppTheme.dangerRed : AppTheme.successGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: (_hasAttention ? AppTheme.dangerRed : AppTheme.successGreen).withOpacity(0.3),
            ),
            child: const Text('Complete Inspection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
