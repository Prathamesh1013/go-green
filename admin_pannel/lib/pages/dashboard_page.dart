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
      context.read<VehicleProvider>().loadVehicles();
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
        body: Consumer<VehicleProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return _buildLoadingState();
            }

            return Column(
              children: [
                // Kanban Board - Takes remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
    return const Center(
      child: CircularProgressIndicator(),
    );
  }



  Widget _buildKanbanBoard() {
    return const DashboardKanbanBoard();
  }

  void _showAddInteractionDialog(BuildContext context, InteractionProvider interactionProvider) {
    Vehicle? selectedVehicle;
    final jobController = TextEditingController();
    final vehicleSearchController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final vehicles = context.read<VehicleProvider>().vehicles;
          
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
                  // Vehicle Selection with Autocomplete
                  Autocomplete<Vehicle>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Vehicle>.empty();
                      }
                      return vehicles.where((vehicle) =>
                        vehicle.vehicleNumber
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        (vehicle.make?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false) ||
                        (vehicle.model?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false)
                      );
                    },
                    displayStringForOption: (Vehicle vehicle) => 
                        '${vehicle.vehicleNumber} - ${vehicle.make ?? ''} ${vehicle.model ?? ''}',
                    onSelected: (Vehicle vehicle) {
                      setState(() {
                        selectedVehicle = vehicle;
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
                          labelText: 'Vehicle Number',
                          hintText: 'Type to search...',
                          prefixIcon: const Icon(Icons.directions_car),
                          suffixIcon: selectedVehicle != null
                              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        onChanged: (value) {
                          vehicleSearchController.text = value;
                          setState(() {
                            if (value.isEmpty) {
                              selectedVehicle = null;
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
                onPressed: (selectedVehicle == null || jobController.text.isEmpty)
                    ? null
                    : () async {
                        try {
                          // Generate interaction number
                          final interactionNumber = 'INT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          
                          final interactionData = {
                            'vehicle_id': selectedVehicle!.vehicleId,
                            'interaction_number': interactionNumber,
                            'interaction_status': 'pending',
                            'current_odometer_reading': selectedVehicle!.odometerCurrent ?? 0,
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

