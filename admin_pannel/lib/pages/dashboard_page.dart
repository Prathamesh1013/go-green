import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/providers/theme_provider.dart';
import 'package:gogreen_admin/widgets/loading_skeleton.dart';
import 'package:gogreen_admin/providers/vehicle_provider.dart';
import 'package:gogreen_admin/providers/interaction_provider.dart';
import 'package:gogreen_admin/widgets/dashboard_kanban_board.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/theme/app_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoreVehicleProvider>().loadCoreVehicles();
      context.read<InteractionProvider>().loadInteractions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      currentRoute: '/dashboard',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                  tooltip: themeProvider.themeMode == ThemeMode.dark
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {},
            ),
          ],
        ),
        body: Consumer<CoreVehicleProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _buildLoadingState();
            }

            final coreVehicles = provider.coreVehicles;
            final healthy = coreVehicles.where((v) => v.healthState == 'healthy').length;
            final attention = coreVehicles.where((v) => v.healthState == 'attention').length;
            final critical = coreVehicles.where((v) => v.healthState == 'critical').length;
            final active = coreVehicles.where((v) => v.status == 'active').length;

            return Column(
              children: [
                // KPI Cards - Small and in one line
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildKPIGrid(
                    totalCoreVehicles: coreVehicles.length,
                    activeCoreVehicles: active,
                    healthyCoreVehicles: healthy,
                    attentionCoreVehicles: attention,
                    criticalCoreVehicles: critical,
                  ),
                ),
                
                // Kanban Board - Takes remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: _buildKanbanBoard(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const KPICardSkeleton(),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIGrid({
    required int totalCoreVehicles,
    required int activeCoreVehicles,
    required int healthyCoreVehicles,
    required int attentionCoreVehicles,
    required int criticalCoreVehicles,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSmallKPICard(
            title: 'Total',
            value: totalCoreVehicles.toString(),
            icon: Icons.directions_car,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildSmallKPICard(
            title: 'Active',
            value: activeCoreVehicles.toString(),
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          _buildSmallKPICard(
            title: 'Healthy',
            value: healthyCoreVehicles.toString(),
            icon: Icons.favorite,
            color: AppColors.healthy,
          ),
          const SizedBox(width: 12),
          _buildSmallKPICard(
            title: 'Attention',
            value: attentionCoreVehicles.toString(),
            icon: Icons.warning,
            color: AppColors.attention,
          ),
          const SizedBox(width: 12),
          _buildSmallKPICard(
            title: 'Critical',
            value: criticalCoreVehicles.toString(),
            icon: Icons.error,
            color: AppColors.critical,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Pastel background colors for both light and dark modes
    Color backgroundColor;
    if (!isDark) {
      // Light mode - bright pastels
      if (color == AppColors.primary || color == AppColors.lightPrimary) {
        backgroundColor = const Color(0xFFDBEAFE); // Light blue
      } else if (color == AppColors.success || color == AppColors.healthy) {
        backgroundColor = const Color(0xFFDCFCE7); // Light green
      } else if (color == AppColors.warning || color == AppColors.attention) {
        backgroundColor = const Color(0xFFFEF9C3); // Light yellow
      } else if (color == AppColors.error || color == AppColors.critical) {
        backgroundColor = const Color(0xFFFEE2E2); // Light red
      } else {
        backgroundColor = const Color(0xFFF3E8FF); // Light purple
      }
    } else {
      // Dark mode - darker pastel variants
      if (color == AppColors.primary || color == AppColors.lightPrimary) {
        backgroundColor = const Color(0xFF1E3A5F); // Dark blue
      } else if (color == AppColors.success || color == AppColors.healthy) {
        backgroundColor = const Color(0xFF1E4D2B); // Dark green
      } else if (color == AppColors.warning || color == AppColors.attention) {
        backgroundColor = const Color(0xFF4D4516); // Dark yellow
      } else if (color == AppColors.error || color == AppColors.critical) {
        backgroundColor = const Color(0xFF4D1F1F); // Dark red
      } else {
        backgroundColor = const Color(0xFF3D2D4D); // Dark purple
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    return const DashboardKanbanBoard();
  }

  void _showAddInteractionDialog(BuildContext context, InteractionProvider interactionProvider) {
    CoreVehicle? selectedCoreVehicle;
    final jobController = TextEditingController();
    final vehicleSearchController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final coreVehicles = context.read<CoreVehicleProvider>().coreVehicles;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              'New Interaction',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CoreVehicle Selection with Autocomplete
                  Autocomplete<CoreVehicle>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<CoreVehicle>.empty();
                      }
                      return coreVehicles.where((vehicle) =>
                        vehicle.vehicleNumber
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        (vehicle.make?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false) ||
                        (vehicle.model?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false)
                      );
                    },
                    displayStringForOption: (CoreVehicle vehicle) => 
                        '${vehicle.vehicleNumber} - ${vehicle.make ?? ''} ${vehicle.model ?? ''}',
                    onSelected: (CoreVehicle vehicle) {
                      setState(() {
                        selectedCoreVehicle = vehicle;
                        vehicleSearchController.text = vehicle.vehicleNumber;
                      });
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      // Sync with external controller
                      if (fieldTextEditingController.text != vehicleSearchController.text) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          fieldTextEditingController.text = vehicleSearchController.text;
                        });
                      }
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          labelText: 'CoreVehicle Number',
                          hintText: 'Type to search...',
                          prefixIcon: const Icon(Icons.directions_car),
                          suffixIcon: selectedCoreVehicle != null
                              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        onChanged: (value) {
                          vehicleSearchController.text = value;
                          setState(() {
                            if (value.isEmpty) {
                              selectedCoreVehicle = null;
                            }
                          });
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      if (options.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).cardColor,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 400,
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: options.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              itemBuilder: (context, index) {
                                final vehicle = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(vehicle),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          vehicle.vehicleNumber,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (vehicle.make != null || vehicle.model != null)
                                          Text(
                                            '${vehicle.make ?? ''} ${vehicle.model ?? ''}'.trim(),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Job Field
                  TextField(
                    controller: jobController,
                    decoration: const InputDecoration(
                      labelText: 'Job',
                      hintText: 'e.g., Oil Change, Brake Repair...',
                      prefixIcon: Icon(Icons.build),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Date and Time Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date & Time',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} '
                        '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedCoreVehicle == null || jobController.text.isEmpty)
                    ? null
                    : () async {
                        try {
                          // Generate interaction number
                          final interactionNumber = 'INT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          
                          final interactionData = {
                            'vehicle_id': selectedCoreVehicle!.vehicleId,
                            'interaction_number': interactionNumber,
                            'interaction_status': 'pending',
                            'current_odometer_reading': selectedCoreVehicle!.odometerCurrent ?? 0,
                            'pickup_date_time': selectedDateTime.toIso8601String(),
                            'vendor_name': '',
                            'primary_job': jobController.text,
                            'customer_note': '',
                            'purchase_price': 0.0,
                            'sell_price': 0.0,
                            'profit': 0.0,
                            'customer_payment_status': 'pending',
                            'vendor_payment_status': 'pending',
                            'total_amount': 0.0,
                            'delivery_date': selectedDateTime.add(const Duration(days: 7)).toIso8601String().split('T')[0],
                          };

                          await interactionProvider.createInteraction(interactionData);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Interaction created successfully'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

