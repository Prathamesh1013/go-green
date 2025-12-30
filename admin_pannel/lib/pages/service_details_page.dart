import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/models/service_detail.dart';
import 'package:gogreen_admin/models/customer_info.dart';
import 'package:gogreen_admin/models/vehicle_info.dart';
import 'package:gogreen_admin/models/service_item.dart';
import 'package:gogreen_admin/models/job_template.dart';
import 'package:gogreen_admin/widgets/responsive_layout.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String serviceId;

  const ServiceDetailsPage({
    super.key,
    required this.serviceId,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  late ServiceDetail _serviceDetail;
  bool _isLoading = true;
  String _customerNotes = '';
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadServiceDetail();
  }

  Future<void> _loadServiceDetail() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from Supabase
      final data = await _supabaseService.getServiceDetailByCardId(widget.serviceId);
      
      if (data == null) {
        // If no data found, create default mock data
        setState(() {
          _serviceDetail = ServiceDetail(
            id: widget.serviceId,
            kanbanCardId: widget.serviceId,
            customer: CustomerInfo(
              name: 'GG Protech',
              phone: '0000000000',
              email: 'fleet@example.com',
              date: DateTime.now(),
              gstNumber: null,
            ),
            vehicle: VehicleInfo(
              registrationNumber: 'MH15JC0060',
              makeAndModel: 'TATA TIGOR XPRESS-T XM',
              year: 2020,
              fuelType: 'EV',
            ),
            periodicServiceItems: ServiceDetail.getDefaultPeriodicItems('EV'),
            bodyshopItems: [],
            customerNotes: '',
          );
          _isLoading = false;
        });
        return;
      }

      // Parse data from database
      final serviceItems = (data['service_items'] as List? ?? [])
          .map((item) => ServiceItem.fromJson(item))
          .toList();

      final periodicItems = serviceItems.where((item) => item.itemType == 'periodic').toList();
      final bodyshopItems = serviceItems.where((item) => item.itemType == 'bodyshop').toList();

      // Parse custom jobs from database
      // Custom jobs are items with item_type not in ['periodic', 'bodyshop']
      final customJobsFromDb = <String, List<ServiceItem>>{};
      for (var item in serviceItems) {
        if (item.itemType != 'periodic' && item.itemType != 'bodyshop') {
          final jobName = item.itemType; // job name is stored as item_type
          if (!customJobsFromDb.containsKey(jobName)) {
            customJobsFromDb[jobName] = [];
          }
          customJobsFromDb[jobName]!.add(item);
        }
      }

      final fuelType = data['vehicle_fuel_type'] ?? 'EV';
      
      // If periodic items exist in DB, use them. Otherwise, use defaults.
      // Default items will be persisted to DB when first edited
      final finalPeriodicItems = periodicItems.isEmpty 
          ? ServiceDetail.getDefaultPeriodicItems(fuelType)
          : periodicItems;

      setState(() {
        _serviceDetail = ServiceDetail(
          id: widget.serviceId,
          kanbanCardId: widget.serviceId,
          customer: CustomerInfo(
            name: data['customer_name'] ?? 'Unknown',
            phone: data['customer_phone'] ?? '',
            email: data['customer_email'] ?? '',
            date: data['due_date'] != null ? DateTime.parse(data['due_date']) : DateTime.now(),
            gstNumber: data['gst_number'],
          ),
          vehicle: VehicleInfo(
            registrationNumber: data['vehicle_reg_number'] ?? data['title'] ?? '',
            makeAndModel: data['vehicle_make_model'] ?? '',
            year: data['vehicle_year'] ?? DateTime.now().year,
            fuelType: fuelType,
          ),
          periodicServiceItems: finalPeriodicItems,
          bodyshopItems: bodyshopItems,
          customJobs: customJobsFromDb,
          customerNotes: data['description'] ?? '',
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading service detail: $e');
      setState(() => _isLoading = false);
    }
  }

  void _editCustomer() {
    showDialog(
      context: context,
      builder: (context) => _EditCustomerDialog(
        customer: _serviceDetail.customer,
        onSave: (updatedCustomer) async {
          setState(() {
            _serviceDetail = _serviceDetail.copyWith(customer: updatedCustomer);
          });
          
          // Save to database
          try {
            await _supabaseService.updateServiceDetail(widget.serviceId, {
              'customer_name': updatedCustomer.name,
              'customer_phone': updatedCustomer.phone,
              'customer_email': updatedCustomer.email,
              'gst_number': updatedCustomer.gstNumber,
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer information updated')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _editVehicle() {
    showDialog(
      context: context,
      builder: (context) => _EditVehicleDialog(
        vehicle: _serviceDetail.vehicle,
        onSave: (updatedVehicle) async {
          setState(() {
            _serviceDetail = _serviceDetail.copyWith(vehicle: updatedVehicle);
            // Update periodic items based on new fuel type
            if (updatedVehicle.fuelType != _serviceDetail.vehicle.fuelType) {
              _serviceDetail = _serviceDetail.copyWith(
                periodicServiceItems: ServiceDetail.getDefaultPeriodicItems(updatedVehicle.fuelType),
              );
            }
          });
          
          // Save to database
          try {
            await _supabaseService.updateServiceDetail(widget.serviceId, {
              'vehicle_reg_number': updatedVehicle.registrationNumber,
              'vehicle_make_model': updatedVehicle.makeAndModel,
              'vehicle_year': updatedVehicle.year,
              'vehicle_fuel_type': updatedVehicle.fuelType,
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle information updated')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error saving: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _generateEstimate() {
    // Show estimate preview dialog
    showDialog(
      context: context,
      builder: (context) => _EstimatePreviewDialog(
        serviceDetail: _serviceDetail,
      ),
    );
  }

  void _generateReceipt() {
    // Show receipt preview dialog
    showDialog(
      context: context,
      builder: (context) => _ReceiptPreviewDialog(
        serviceDetail: _serviceDetail,
      ),
    );
  }

  void _openInventoryMaker() {
    // Show inventory maker dialog
    showDialog(
      context: context,
      builder: (context) => _InventoryMakerDialog(
        serviceDetail: _serviceDetail,
      ),
    );
  }

  void _processPayment() {
    // Show payment processing dialog
    showDialog(
      context: context,
      builder: (context) => _PaymentDialog(
        totalAmount: _serviceDetail.grandTotal,
        onPaymentComplete: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment processed successfully')),
          );
        },
      ),
    );
  }

  void _deleteInteraction() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interaction'),
        content: const Text('Are you sure you want to delete this service interaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete from database
              context.go('/dashboard');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service interaction deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addPeriodicItem() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'periodic',
        itemCategory: 'other', // Default to 'other' for Add Other button
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          periodicServiceItems: [..._serviceDetail.periodicServiceItems, result],
        );
      });
      
      // Save to database
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.periodicServiceItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            periodicServiceItems: _serviceDetail.periodicServiceItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addBodyshopItem() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'bodyshop',
        itemCategory: 'other', // Default to 'other' for Add Other button
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          bodyshopItems: [..._serviceDetail.bodyshopItems, result],
        );
      });
      
      // Save to database
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.periodicServiceItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            periodicServiceItems: _serviceDetail.periodicServiceItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addPeriodicPart() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'periodic',
        itemCategory: 'part',
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          periodicServiceItems: [..._serviceDetail.periodicServiceItems, result],
        );
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.periodicServiceItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            periodicServiceItems: _serviceDetail.periodicServiceItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addPeriodicLabor() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'periodic',
        itemCategory: 'labor',
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          periodicServiceItems: [..._serviceDetail.periodicServiceItems, result],
        );
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.periodicServiceItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            periodicServiceItems: _serviceDetail.periodicServiceItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addBodyshopPart() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'bodyshop',
        itemCategory: 'part',
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          bodyshopItems: [..._serviceDetail.bodyshopItems, result],
        );
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.bodyshopItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(bodyshopItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            bodyshopItems: _serviceDetail.bodyshopItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addBodyshopLabor() async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: 'bodyshop',
        itemCategory: 'labor',
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(
          bodyshopItems: [..._serviceDetail.bodyshopItems, result],
        );
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        // Update the item with the database-generated ID
        final updatedItem = ServiceItem.fromJson(createdItem);
        setState(() {
          final items = _serviceDetail.bodyshopItems.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          _serviceDetail = _serviceDetail.copyWith(bodyshopItems: items);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service item added successfully')),
          );
        }
      } catch (e) {
        print('Error saving item: $e');
        // Remove item from UI if save failed
        setState(() {
          _serviceDetail = _serviceDetail.copyWith(
            bodyshopItems: _serviceDetail.bodyshopItems
                .where((item) => item.id != result.id)
                .toList(),
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _removePeriodicItem(String itemId) async {
    setState(() {
      _serviceDetail = _serviceDetail.copyWith(
        periodicServiceItems: _serviceDetail.periodicServiceItems
            .where((item) => item.id != itemId)
            .toList(),
      );
    });
    
    // Delete from database
    try {
      await _supabaseService.deleteServiceItem(itemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _removeBodyshopItem(String itemId) async {
    setState(() {
      _serviceDetail = _serviceDetail.copyWith(
        bodyshopItems: _serviceDetail.bodyshopItems
            .where((item) => item.id != itemId)
            .toList(),
      );
    });
    
    // Delete from database
    try {
      await _supabaseService.deleteServiceItem(itemId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _updatePeriodicItem(ServiceItem updatedItem) async {
    setState(() {
      final items = _serviceDetail.periodicServiceItems.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();
      _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
    });
    
    // Check if this is a default item that hasn't been persisted yet
    // Default items have static IDs like 'ac_filter', 'engine_oil', etc.
    final isDefaultItem = updatedItem.id.contains('_') && 
        !updatedItem.id.contains(DateTime.now().millisecondsSinceEpoch.toString());
    
    try {
      // Try to update first. If it fails (item doesn't exist in DB), create it.
      try {
        await _supabaseService.updateServiceItem(updatedItem.id, updatedItem.toJson());
      } catch (e) {
        // If update fails, it might be a default item not yet in DB, so create it
        if (isDefaultItem || e.toString().contains('not found') || e.toString().contains('does not exist')) {
          final createdItem = await _supabaseService.addServiceItem(widget.serviceId, updatedItem.toJson());
          // Update the item with the database-generated ID
          final dbItem = ServiceItem.fromJson(createdItem);
          setState(() {
            final items = _serviceDetail.periodicServiceItems.map((item) {
              return item.id == updatedItem.id ? dbItem : item;
            }).toList();
            _serviceDetail = _serviceDetail.copyWith(periodicServiceItems: items);
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Error updating item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    }
  }

  void _updateBodyshopItem(ServiceItem updatedItem) async {
    setState(() {
      final items = _serviceDetail.bodyshopItems.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();
      _serviceDetail = _serviceDetail.copyWith(bodyshopItems: items);
    });
    
    // Check if this is a default item that hasn't been persisted yet
    try {
      // Try to update first. If it fails (item doesn't exist in DB), create it.
      try {
        await _supabaseService.updateServiceItem(updatedItem.id, updatedItem.toJson());
      } catch (e) {
        // If update fails, it might be a default item not yet in DB, so create it
        if (e.toString().contains('not found') || e.toString().contains('does not exist')) {
          final createdItem = await _supabaseService.addServiceItem(widget.serviceId, updatedItem.toJson());
          // Update the item with the database-generated ID
          final dbItem = ServiceItem.fromJson(createdItem);
          setState(() {
            final items = _serviceDetail.bodyshopItems.map((item) {
              return item.id == updatedItem.id ? dbItem : item;
            }).toList();
            _serviceDetail = _serviceDetail.copyWith(bodyshopItems: items);
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('Error updating item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    }
  }

  // ==================== CUSTOM JOB METHODS ====================

  void _addJobFromTemplate(String jobName) async {
    if (!mounted) return;
    
    // Check if job already exists
    if (_serviceDetail.customJobs.containsKey(jobName)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job "$jobName" already exists')),
        );
      }
      return;
    }

    // Get template
    final templates = JobTemplates.getTemplates();
    final template = templates.firstWhere(
      (t) => t.name == jobName,
      orElse: () => JobTemplate(
        id: jobName.toLowerCase().replaceAll(' ', '_'),
        name: jobName,
        parts: [],
        labor: [],
        other: [],
      ),
    );

    // Create service items from template
    final List<ServiceItem> items = [];
    
    // Add parts
    for (var part in template.parts) {
      final item = ServiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + part.name.toLowerCase().replaceAll(' ', '_'),
        name: part.name,
        quantity: part.defaultQuantity,
        partsCost: part.defaultPrice,
        labourCost: 0,
        itemType: jobName, // Use job name as item type
      );
      items.add(item);
    }
    
    // Add labor
    for (var labor in template.labor) {
      final item = ServiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + labor.name.toLowerCase().replaceAll(' ', '_'),
        name: labor.name,
        quantity: 1,
        partsCost: 0,
        labourCost: labor.defaultPrice,
        itemType: jobName,
      );
      items.add(item);
    }

    // Update state
    final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
    updatedCustomJobs[jobName] = items;
    
    setState(() {
      _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
    });

    // Save all items to database
    for (var item in items) {
      try {
        await _supabaseService.addServiceItem(widget.serviceId, item.toJson());
      } catch (e) {
        print('Error saving custom job item: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job "$jobName" added successfully')),
      );
    }
  }

  void _addCustomJobPart(String jobName) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: jobName,
        itemCategory: 'part',
      ),
    );
    
    if (result != null && mounted) {
      final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
      updatedCustomJobs[jobName] = [...updatedCustomJobs[jobName]!, result];
      
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        if (mounted) {
          final updatedItem = ServiceItem.fromJson(createdItem);
          final updatedItems = updatedCustomJobs[jobName]!.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          updatedCustomJobs[jobName] = updatedItems;
          setState(() {
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
        }
      } catch (e) {
        print('Error saving item: $e');
        if (mounted) {
          setState(() {
            final updatedItems = updatedCustomJobs[jobName]!
                .where((item) => item.id != result.id)
                .toList();
            updatedCustomJobs[jobName] = updatedItems;
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addCustomJobLabor(String jobName) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: jobName,
        itemCategory: 'labor',
      ),
    );
    
    if (result != null && mounted) {
      final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
      updatedCustomJobs[jobName] = [...updatedCustomJobs[jobName]!, result];
      
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        if (mounted) {
          final updatedItem = ServiceItem.fromJson(createdItem);
          final updatedItems = updatedCustomJobs[jobName]!.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          updatedCustomJobs[jobName] = updatedItems;
          setState(() {
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
        }
      } catch (e) {
        print('Error saving item: $e');
        if (mounted) {
          setState(() {
            final updatedItems = updatedCustomJobs[jobName]!
                .where((item) => item.id != result.id)
                .toList();
            updatedCustomJobs[jobName] = updatedItems;
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _addCustomJobOther(String jobName) async {
    final result = await showDialog<ServiceItem>(
      context: context,
      builder: (context) => _AddServiceItemDialog(
        onAdd: (item) => Navigator.pop(context, item),
        itemType: jobName,
        itemCategory: 'other',
      ),
    );
    
    if (result != null && mounted) {
      final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
      updatedCustomJobs[jobName] = [...updatedCustomJobs[jobName]!, result];
      
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
      });
      
      try {
        final createdItem = await _supabaseService.addServiceItem(widget.serviceId, result.toJson());
        if (mounted) {
          final updatedItem = ServiceItem.fromJson(createdItem);
          final updatedItems = updatedCustomJobs[jobName]!.map((item) {
            return item.id == result.id ? updatedItem : item;
          }).toList();
          updatedCustomJobs[jobName] = updatedItems;
          setState(() {
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
        }
      } catch (e) {
        print('Error saving item: $e');
        if (mounted) {
          setState(() {
            final updatedItems = updatedCustomJobs[jobName]!
                .where((item) => item.id != result.id)
                .toList();
            updatedCustomJobs[jobName] = updatedItems;
            _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: $e')),
          );
        }
      }
    }
  }

  void _removeCustomJobItem(String jobName, String itemId) async {
    if (!mounted) return;
    
    final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
    updatedCustomJobs[jobName] = updatedCustomJobs[jobName]!
        .where((item) => item.id != itemId)
        .toList();
    
    setState(() {
      _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
    });
    
    try {
      await _supabaseService.deleteServiceItem(itemId);
    } catch (e) {
      print('Item not in DB or error deleting: $e');
    }
  }

  void _updateCustomJobItem(String jobName, ServiceItem updatedItem) async {
    if (!mounted) return;
    
    final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
    updatedCustomJobs[jobName] = updatedCustomJobs[jobName]!.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    
    setState(() {
      _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
    });
    
    try {
      await _supabaseService.updateServiceItem(updatedItem.id, updatedItem.toJson());
    } catch (e) {
      print('Error updating item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    }
  }

  void _removeCustomJobSection(String jobName) async {
    if (!mounted) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Job Section'),
        content: Text('Are you sure you want to remove "$jobName" section? All items in this section will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Delete all items in this job from database
    final itemsToDelete = _serviceDetail.customJobs[jobName] ?? [];
    for (var item in itemsToDelete) {
      try {
        await _supabaseService.deleteServiceItem(item.id);
      } catch (e) {
        print('Error deleting item: $e');
      }
    }
    
    // Remove from state
    final updatedCustomJobs = Map<String, List<ServiceItem>>.from(_serviceDetail.customJobs);
    updatedCustomJobs.remove(jobName);
    
    if (mounted) {
      setState(() {
        _serviceDetail = _serviceDetail.copyWith(customJobs: updatedCustomJobs);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Job "$jobName" removed successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveLayout(
      currentRoute: '/service-details',
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard'),
          ),
          title: const Text('Service Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            _ActionButton(
              label: 'Generate Estimate',
              color: const Color(0xFF3B82F6),
              onPressed: _generateEstimate,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Generate Receipt',
              color: const Color(0xFF10B981),
              onPressed: _generateReceipt,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Inventory Maker',
              color: const Color(0xFF8B5CF6),
              onPressed: _openInventoryMaker,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Process Payment',
              color: const Color(0xFF1F2937),
              onPressed: _processPayment,
            ),
            const SizedBox(width: 8),
            _ActionButton(
              label: 'Delete Interaction',
              color: const Color(0xFFEF4444),
              onPressed: _deleteInteraction,
            ),
            const SizedBox(width: 16),
          ],
        ),
      body: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final bodyBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB);
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Sidebar
              Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final sidebarBg = isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB);
                
                return Container(
                  width: 320,
                  color: sidebarBg,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CustomerSection(customer: _serviceDetail.customer),
                        const SizedBox(height: 20),
                        _VehicleSection(vehicle: _serviceDetail.vehicle),
                        const SizedBox(height: 20),
                        _CustomerNotesSection(
                          notes: _customerNotes,
                          onNotesChanged: (notes) {
                            setState(() => _customerNotes = notes);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              ),
              
              // Main Content
              Expanded(
              child: Container(
                color: bodyBg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          final isDark = theme.brightness == Brightness.dark;
                          final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              _AddJobButton(
                                onJobSelected: _addJobFromTemplate,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    
                    // Periodic Service Section
                    _ServiceSection(
                      title: 'Periodic Service',
                      items: _serviceDetail.periodicServiceItems,
                      partsCost: _serviceDetail.periodicPartsCost,
                      labourCost: _serviceDetail.periodicLabourCost,
                      total: _serviceDetail.periodicTotal,
                      onAddPart: _addPeriodicPart,
                      onAddLabor: _addPeriodicLabor,
                      onAddOther: _addPeriodicItem,
                      onRemoveItem: _removePeriodicItem,
                      onUpdateItem: _updatePeriodicItem,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bodyshop Section
                    _ServiceSection(
                      title: 'Bodyshop',
                      items: _serviceDetail.bodyshopItems,
                      partsCost: _serviceDetail.bodyshopPartsCost,
                      labourCost: _serviceDetail.bodyshopLabourCost,
                      total: _serviceDetail.bodyshopTotal,
                      onAddPart: _addBodyshopPart,
                      onAddLabor: _addBodyshopLabor,
                      onAddOther: _addBodyshopItem,
                      onRemoveItem: _removeBodyshopItem,
                      onUpdateItem: _updateBodyshopItem,
                    ),
                    
                    // Custom Job Sections
                    ..._serviceDetail.customJobs.entries.map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _ServiceSection(
                          title: entry.key,
                          items: entry.value,
                          partsCost: entry.value.fold(0.0, (sum, item) => sum + item.partsCost),
                          labourCost: entry.value.fold(0.0, (sum, item) => sum + item.labourCost),
                          total: entry.value.fold(0.0, (sum, item) => sum + item.partsCost + item.labourCost),
                          onAddPart: () => _addCustomJobPart(entry.key),
                          onAddLabor: () => _addCustomJobLabor(entry.key),
                          onAddOther: () => _addCustomJobOther(entry.key),
                          onRemoveItem: (itemId) => _removeCustomJobItem(entry.key, itemId),
                          onUpdateItem: (item) => _updateCustomJobItem(entry.key, item),
                          onRemoveSection: () => _removeCustomJobSection(entry.key),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        },
      ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  final CustomerInfo customer;

  const _CustomerSection({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    onPressed: () {
                      final state = context.findAncestorStateOfType<_ServiceDetailsPageState>();
                      state?._editCustomer();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: labelColor,
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.person_add, size: 18),
                    onPressed: () {
                      // TODO: Implement profile
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: const Color(0xFF3B82F6),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Info rows
          _InfoRow(label: 'Name', value: customer.name, textColor: textColor, labelColor: labelColor),
          _InfoRow(label: 'Phone', value: customer.phone, textColor: textColor, labelColor: labelColor),
          _InfoRow(label: 'Email', value: customer.email, textColor: textColor, labelColor: labelColor),
          _InfoRow(
            label: 'Date',
            value: '${customer.date.day}/${customer.date.month}/${customer.date.year}',
            textColor: textColor,
            labelColor: labelColor,
          ),
          const SizedBox(height: 16),
          // GST Number input
          TextField(
            decoration: InputDecoration(
              labelText: 'GST Number (Optional)',
              hintText: 'Enter 15-digit GSTIN',
              filled: true,
              fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              labelStyle: TextStyle(color: labelColor, fontSize: 13),
              hintStyle: TextStyle(color: labelColor, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: 13, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _VehicleSection extends StatelessWidget {
  final VehicleInfo vehicle;

  const _VehicleSection({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: () {
                  final state = context.findAncestorStateOfType<_ServiceDetailsPageState>();
                  state?._editVehicle();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: labelColor,
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Info rows
          _InfoRow(label: 'Reg. No.', value: vehicle.registrationNumber, textColor: textColor, labelColor: labelColor),
          _InfoRow(label: 'Make & Model', value: vehicle.makeAndModel, textColor: textColor, labelColor: labelColor),
          _InfoRow(label: 'Year', value: vehicle.year.toString(), textColor: textColor, labelColor: labelColor),
          _InfoRow(label: 'Fuel Type', value: vehicle.fuelType, textColor: textColor, labelColor: labelColor),
        ],
      ),
    );
  }
}

class _CustomerNotesSection extends StatelessWidget {
  final String notes;
  final ValueChanged<String> onNotesChanged;

  const _CustomerNotesSection({
    required this.notes,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Add a new task...',
              filled: true,
              fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
              ),
              hintStyle: TextStyle(color: labelColor, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: 13, color: textColor),
            maxLines: 3,
            onChanged: onNotesChanged,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Add note
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  final Color labelColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  final String title;
  final List<ServiceItem> items;
  final double partsCost;
  final double labourCost;
  final double total;
  final VoidCallback onAddPart;
  final VoidCallback onAddLabor;
  final VoidCallback onAddOther;
  final Function(String) onRemoveItem;
  final Function(ServiceItem) onUpdateItem;
  final VoidCallback? onRemoveSection; // Optional: for custom jobs only

  const _ServiceSection({
    required this.title,
    required this.items,
    required this.partsCost,
    required this.labourCost,
    required this.total,
    required this.onAddPart,
    required this.onAddLabor,
    required this.onAddOther,
    required this.onRemoveItem,
    required this.onUpdateItem,
    this.onRemoveSection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 16, color: labelColor),
                  if (onRemoveSection != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.close, size: 18),
                      onPressed: onRemoveSection,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      color: const Color(0xFFEF4444),
                      tooltip: 'Remove section',
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _SmallButton(label: 'Add Part', onPressed: onAddPart, isDark: isDark, labelColor: labelColor, borderColor: borderColor),
                  const SizedBox(width: 8),
                  _SmallButton(label: 'Add Labor', onPressed: onAddLabor, isDark: isDark, labelColor: labelColor, borderColor: borderColor),
                  const SizedBox(width: 8),
                  _SmallButton(label: 'Add Other', onPressed: onAddOther, isDark: isDark, labelColor: labelColor, borderColor: borderColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Service Items
          ...items.map((item) => _ServiceItemRow(
            item: item,
            onRemove: () => onRemoveItem(item.id),
            onUpdate: onUpdateItem,
          )),
          
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No items added',
                  style: TextStyle(color: labelColor),
                ),
              ),
            ),
          
          Divider(height: 32, color: borderColor),
          
          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Parts: ₹${partsCost.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: labelColor),
              ),
              const SizedBox(width: 32),
              Text(
                'Labour: ₹${labourCost.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: labelColor),
              ),
              const SizedBox(width: 32),
              Text(
                'Total: ₹${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final Color labelColor;
  final Color borderColor;

  const _SmallButton({
    required this.label,
    required this.onPressed,
    required this.isDark,
    required this.labelColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(color: borderColor),
        backgroundColor: isDark ? const Color(0xFF21262D) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: labelColor),
      ),
    );
  }
}

class _ServiceItemRow extends StatefulWidget {
  final ServiceItem item;
  final VoidCallback onRemove;
  final Function(ServiceItem) onUpdate;

  const _ServiceItemRow({
    required this.item,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_ServiceItemRow> createState() => _ServiceItemRowState();
}

class _ServiceItemRowState extends State<_ServiceItemRow> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _partsCostController;
  late TextEditingController _labourCostController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _partsCostController = TextEditingController(
      text: widget.item.partsCost.toStringAsFixed(0),
    );
    _labourCostController = TextEditingController(
      text: widget.item.labourCost.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_ServiceItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _nameController.text = widget.item.name;
      _quantityController.text = widget.item.quantity.toString();
      _partsCostController.text = widget.item.partsCost.toStringAsFixed(0);
      _labourCostController.text = widget.item.labourCost.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _partsCostController.dispose();
    _labourCostController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_quantityController.text) ?? widget.item.quantity;
    final partsCost = double.tryParse(_partsCostController.text) ?? 0;
    final labourCost = double.tryParse(_labourCostController.text) ?? 0;

    if (name.isEmpty) {
      // Revert name if empty
      _nameController.text = widget.item.name;
      return;
    }

    widget.onUpdate(widget.item.copyWith(
      name: name,
      quantity: qty,
      partsCost: partsCost,
      labourCost: labourCost,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              onChanged: (value) {
                // Update on change for real-time editing
                if (value.trim().isNotEmpty) {
                  widget.onUpdate(widget.item.copyWith(name: value.trim()));
                }
              },
              onEditingComplete: () {
                _updateItem();
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final qty = int.tryParse(value) ?? widget.item.quantity;
                widget.onUpdate(widget.item.copyWith(quantity: qty));
              },
              onEditingComplete: () {
                _updateItem();
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _partsCostController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
                hintText: '0',
              ),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final cost = double.tryParse(value) ?? 0;
                widget.onUpdate(widget.item.copyWith(partsCost: cost));
              },
              onEditingComplete: () {
                _updateItem();
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _labourCostController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isDense: true,
                hintText: '0',
              ),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final cost = double.tryParse(value) ?? 0;
                widget.onUpdate(widget.item.copyWith(labourCost: cost));
              },
              onEditingComplete: () {
                _updateItem();
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _AddServiceItemDialog extends StatefulWidget {
  final Function(ServiceItem) onAdd;
  final String itemType;
  final String itemCategory; // 'part', 'labor', or 'other'

  const _AddServiceItemDialog({
    required this.onAdd,
    required this.itemType,
    this.itemCategory = 'other',
  });

  @override
  State<_AddServiceItemDialog> createState() => _AddServiceItemDialogState();
}

class _AddServiceItemDialogState extends State<_AddServiceItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _partsCostController;
  late TextEditingController _labourCostController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    
    // Pre-fill based on item category
    if (widget.itemCategory == 'part') {
      _partsCostController = TextEditingController(text: '0');
      _labourCostController = TextEditingController(text: '0');
    } else if (widget.itemCategory == 'labor') {
      _partsCostController = TextEditingController(text: '0');
      _labourCostController = TextEditingController(text: '0');
    } else {
      _partsCostController = TextEditingController(text: '0');
      _labourCostController = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _partsCostController.dispose();
    _labourCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.itemCategory == 'part' 
        ? 'Add Part'
        : widget.itemCategory == 'labor' 
            ? 'Add Labor'
            : 'Add Other';

    return AlertDialog(
      title: Text(dialogTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.itemCategory == 'part' 
                    ? 'Part Name'
                    : widget.itemCategory == 'labor'
                        ? 'Labor Description'
                        : 'Service Name',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (widget.itemCategory != 'labor')
              TextField(
                controller: _partsCostController,
                decoration: const InputDecoration(
                  labelText: 'Parts Cost (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: widget.itemCategory == 'part',
              ),
            if (widget.itemCategory != 'labor') const SizedBox(height: 16),
            TextField(
              controller: _labourCostController,
              decoration: const InputDecoration(
                labelText: 'Labour Cost (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: widget.itemCategory == 'labor',
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
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter item name')),
              );
              return;
            }
            
            // Generate a unique ID for the new item
            final uuid = DateTime.now().millisecondsSinceEpoch.toString() + '_' + 
                _nameController.text.trim().toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
            
            final item = ServiceItem(
              id: uuid,
              name: _nameController.text.trim(),
              quantity: int.tryParse(_quantityController.text) ?? 1,
              partsCost: double.tryParse(_partsCostController.text) ?? 0,
              labourCost: double.tryParse(_labourCostController.text) ?? 0,
              itemType: widget.itemType,
            );
            widget.onAdd(item);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Edit Customer Dialog




// Edit Customer Dialog
class _EditCustomerDialog extends StatefulWidget {
  final CustomerInfo customer;
  final Function(CustomerInfo) onSave;

  const _EditCustomerDialog({
    required this.customer,
    required this.onSave,
  });

  @override
  State<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<_EditCustomerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _emailController = TextEditingController(text: widget.customer.email);
    _gstController = TextEditingController(text: widget.customer.gstNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Customer Information'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number (Optional)',
                border: OutlineInputBorder(),
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
          onPressed: () {
            final updatedCustomer = widget.customer.copyWith(
              name: _nameController.text,
              phone: _phoneController.text,
              email: _emailController.text,
              gstNumber: _gstController.text.isEmpty ? null : _gstController.text,
            );
            widget.onSave(updatedCustomer);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Edit Vehicle Dialog
class _EditVehicleDialog extends StatefulWidget {
  final VehicleInfo vehicle;
  final Function(VehicleInfo) onSave;

  const _EditVehicleDialog({
    required this.vehicle,
    required this.onSave,
  });

  @override
  State<_EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<_EditVehicleDialog> {
  late TextEditingController _regController;
  late TextEditingController _makeModelController;
  late TextEditingController _yearController;
  late String _fuelType;

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController(text: widget.vehicle.registrationNumber);
    _makeModelController = TextEditingController(text: widget.vehicle.makeAndModel);
    _yearController = TextEditingController(text: widget.vehicle.year.toString());
    _fuelType = widget.vehicle.fuelType;
  }

  @override
  void dispose() {
    _regController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Vehicle Information'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _regController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _makeModelController,
              decoration: const InputDecoration(
                labelText: 'Make & Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _fuelType,
              decoration: const InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EV', child: Text('EV')),
                DropdownMenuItem(value: 'ICE', child: Text('ICE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fuelType = value);
                }
              },
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
          onPressed: () {
            final updatedVehicle = widget.vehicle.copyWith(
              registrationNumber: _regController.text,
              makeAndModel: _makeModelController.text,
              year: int.tryParse(_yearController.text) ?? widget.vehicle.year,
              fuelType: _fuelType,
            );
            widget.onSave(updatedVehicle);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Estimate Preview Dialog
class _EstimatePreviewDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _EstimatePreviewDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Service Estimate'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${serviceDetail.customer.name}'),
              Text('Vehicle: ${serviceDetail.vehicle.registrationNumber}'),
              const Divider(height: 24),
              const Text('Periodic Service:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.periodicServiceItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              Text('Subtotal: ₹${serviceDetail.periodicTotal.toStringAsFixed(2)}'),
              const Divider(height: 24),
              const Text('Bodyshop:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.bodyshopItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              Text('Subtotal: ₹${serviceDetail.bodyshopTotal.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Text(
                'Grand Total: ₹${serviceDetail.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Estimate PDF generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Download PDF'),
        ),
      ],
    );
  }
}

// Receipt Preview Dialog
class _ReceiptPreviewDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _ReceiptPreviewDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Service Receipt'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GoGreen Fleet Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Receipt Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              const Divider(height: 24),
              Text('Customer: ${serviceDetail.customer.name}'),
              Text('Phone: ${serviceDetail.customer.phone}'),
              Text('Email: ${serviceDetail.customer.email}'),
              if (serviceDetail.customer.gstNumber != null)
                Text('GST: ${serviceDetail.customer.gstNumber}'),
              const Divider(height: 24),
              Text('Vehicle: ${serviceDetail.vehicle.registrationNumber}'),
              Text('Model: ${serviceDetail.vehicle.makeAndModel}'),
              const Divider(height: 24),
              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.periodicServiceItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              ...serviceDetail.bodyshopItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Text(
                'Total Amount: ₹${serviceDetail.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt PDF generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Download PDF'),
        ),
      ],
    );
  }
}

// Inventory Maker Dialog
class _InventoryMakerDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _InventoryMakerDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    final allItems = [...serviceDetail.periodicServiceItems, ...serviceDetail.bodyshopItems];
    
    return AlertDialog(
      title: const Text('Inventory Maker'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Parts needed for this service:'),
            const SizedBox(height: 16),
            ...allItems.where((item) => item.partsCost > 0).map((item) => 
              ListTile(
                title: Text(item.name),
                subtitle: Text('Quantity: ${item.quantity}'),
                trailing: Text('₹${item.partsCost.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate inventory list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inventory list generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Generate List'),
        ),
      ],
    );
  }
}

// Payment Dialog
class _PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;

  const _PaymentDialog({
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _paymentMethod = 'Cash';
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Process Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
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
          onPressed: () {
            // TODO: Process payment in database
            widget.onPaymentComplete();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Process Payment'),
        ),
      ],
    );
  }
}

class _AddJobButton extends StatefulWidget {
  final Function(String) onJobSelected;

  const _AddJobButton({
    required this.onJobSelected,
  });

  @override
  State<_AddJobButton> createState() => _AddJobButtonState();
}

class _AddJobButtonState extends State<_AddJobButton> {
  bool _isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      setState(() => _isDropdownOpen = false);
      return;
    }

    // Wait for the button to be laid out before calculating position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry != null) return;
      
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final dropdownBg = isDark ? const Color(0xFF161B22) : Colors.white;
      final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFF3B82F6);
      final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
      final labelColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

      final jobTemplates = JobTemplates.getTemplates();
      
      const dropdownWidth = 250.0;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          _removeOverlay();
          setState(() => _isDropdownOpen = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: dropdownWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 8),
                followerAnchor: Alignment.topCenter,
                targetAnchor: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: dropdownBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF21262D) : const Color(0xFFF9FAFB),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Select Job Template',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
                        ),
                        ...jobTemplates.map((template) {
                          return InkWell(
                            onTap: () {
                              _removeOverlay();
                              setState(() => _isDropdownOpen = false);
                              widget.onJobSelected(template.name);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              color: Colors.transparent,
                              child: Text(
                                template.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isDropdownOpen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonBg = isDark ? const Color(0xFF161B22) : const Color(0xFF3B82F6);
    final textColor = Colors.white;

    return CompositedTransformTarget(
      link: _layerLink,
      child: ElevatedButton(
        key: _buttonKey,
        onPressed: () => _showDropdown(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBg,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Job',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(
              _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
