import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/models/maintenance_job.dart';
import 'package:gogreen_admin/models/compliance.dart';
import 'package:gogreen_admin/models/interaction.dart';
import 'package:gogreen_admin/models/task.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  // Get Supabase client (lazy initialization)
  static SupabaseClient get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase must be initialized before use. Call SupabaseService.initialize() in main.dart. Error: $e');
    }
  }

  // Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  // ==================== VEHICLES ====================
  
  Future<List<Vehicle>> getVehicles({
    String? status,
    String? healthState,
    String? hubId,
  }) async {
    try {
      var query = _client.from('crm_vehicles').select('*');

      // Apply filters if provided (note: these fields may not exist in crm_vehicles)
      if (status != null) {
        query = query.eq('status', status);
      }
      if (healthState != null) {
        query = query.eq('health_state', healthState);
      }
      if (hubId != null) {
        query = query.eq('primary_hub_id', hubId);
      }

      // Order by created_at (crm_vehicles) or created_date (vehicle table)
      final response = await query.order('created_at', ascending: false);
      
      // Fetch hub data separately and combine
      final vehicles = (response as List).map((json) => Vehicle.fromJson(json)).toList();
      
      // Fetch hubs for vehicles that have primary_hub_id
      final hubIds = vehicles
          .where((v) => v.primaryHubId != null)
          .map((v) => v.primaryHubId!)
          .toSet()
          .toList();
      
      if (hubIds.isNotEmpty) {
        final hubsResponse = await _client
            .from('hub')
            .select('hub_id, name, city, state')
            .inFilter('hub_id', hubIds);
        
        final hubsMap = Map<String, Map<String, dynamic>>.fromEntries(
          (hubsResponse as List).map((h) => MapEntry(h['hub_id'] as String, h as Map<String, dynamic>)),
        );
        
        // Attach hub info to vehicles
        for (var i = 0; i < vehicles.length; i++) {
          final vehicle = vehicles[i];
          if (vehicle.primaryHubId != null && hubsMap.containsKey(vehicle.primaryHubId)) {
            final hubData = hubsMap[vehicle.primaryHubId]!;
            final hubInfo = HubInfo(
              hubId: hubData['hub_id'] as String,
              name: hubData['name'] as String? ?? '',
              city: hubData['city'] as String?,
              state: hubData['state'] as String?,
            );
            vehicles[i] = vehicle.copyWith(hub: hubInfo);
          }
        }
      }
      
      return vehicles;
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  Future<Vehicle?> getVehicleByRegistrationNumber(String registrationNumber) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .eq('registration_number', registrationNumber)
          .maybeSingle();

      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching vehicle by registration number: $e');
    }
  }

  Future<Vehicle> getVehicleById(String vehicleId) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .single();

      var vehicle = Vehicle.fromJson(response);
      
      // Fetch hub data if primary_hub_id exists
      if (vehicle.primaryHubId != null) {
        try {
          final hubResponse = await _client
              .from('hub')
              .select('hub_id, name, city, state')
              .eq('hub_id', vehicle.primaryHubId!)
              .single();
          
          final hubInfo = HubInfo(
            hubId: hubResponse['hub_id'] as String,
            name: hubResponse['name'] as String? ?? '',
            city: hubResponse['city'] as String?,
            state: hubResponse['state'] as String?,
          );
          vehicle = vehicle.copyWith(hub: hubInfo);
        } catch (e) {
          // Hub not found, continue without hub info
          debugPrint('Hub not found for vehicle: $e');
        }
      }

      return vehicle;
    } catch (e) {
      throw Exception('Error fetching vehicle: $e');
    }
  }

  Future<Map<String, dynamic>?> getVehicleWithCustomer(String vehicleId) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error fetching vehicle with customer: $e');
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .insert(data)
          .select('*')
          .single();

      var vehicle = Vehicle.fromJson(response);
      
      // Fetch hub data if primary_hub_id exists
      if (vehicle.primaryHubId != null) {
        try {
          final hubResponse = await _client
              .from('hub')
              .select('hub_id, name, city, state')
              .eq('hub_id', vehicle.primaryHubId!)
              .single();
          
          final hubInfo = HubInfo(
            hubId: hubResponse['hub_id'] as String,
            name: hubResponse['name'] as String? ?? '',
            city: hubResponse['city'] as String?,
            state: hubResponse['state'] as String?,
          );
          vehicle = vehicle.copyWith(hub: hubInfo);
        } catch (e) {
          // Hub not found, continue without hub info
          debugPrint('Hub not found for vehicle: $e');
        }
      }

      return vehicle;
    } catch (e) {
      throw Exception('Error creating vehicle: $e');
    }
  }

  Future<Vehicle> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .update(data)
          .eq('vehicle_id', vehicleId)
          .select('*')
          .single();

      var vehicle = Vehicle.fromJson(response);
      
      // Fetch hub data if primary_hub_id exists
      if (vehicle.primaryHubId != null) {
        try {
          final hubResponse = await _client
              .from('hub')
              .select('hub_id, name, city, state')
              .eq('hub_id', vehicle.primaryHubId!)
              .single();
          
          final hubInfo = HubInfo(
            hubId: hubResponse['hub_id'] as String,
            name: hubResponse['name'] as String? ?? '',
            city: hubResponse['city'] as String?,
            state: hubResponse['state'] as String?,
          );
          vehicle = vehicle.copyWith(hub: hubInfo);
        } catch (e) {
          // Hub not found, continue without hub info
          debugPrint('Hub not found for vehicle: $e');
        }
      }

      return vehicle;
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  // ==================== HUBS ====================
  
  Future<List<Map<String, dynamic>>> getHubs() async {
    try {
      final response = await _client
          .from('hub')
          .select('*')
          .order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching hubs: $e');
    }
  }

  // ==================== MAINTENANCE JOBS ====================
  
  Future<List<MaintenanceJob>> getJobs({String? vehicleId}) async {
    try {
      var query = _client.from('maintenance_job').select('*');

      if (vehicleId != null) {
        query = query.eq('vehicle_id', vehicleId);
      }

      final response = await query.order('diagnosis_date', ascending: false);
      
      return (response as List)
          .map((json) => MaintenanceJob.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  Future<MaintenanceJob> createMaintenanceJob(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('maintenance_job')
          .insert(data)
          .select('*')
          .single();

      return MaintenanceJob.fromJson(response);
    } catch (e) {
      throw Exception('Error creating maintenance job: $e');
    }
  }

  Future<MaintenanceJob> updateMaintenanceJob(String jobId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('maintenance_job')
          .update(data)
          .eq('job_id', jobId)
          .select('*')
          .single();

      return MaintenanceJob.fromJson(response);
    } catch (e) {
      throw Exception('Error updating maintenance job: $e');
    }
  }

  // ==================== COMPLIANCE ====================
  
  Future<List<ComplianceDocument>> getComplianceDocuments(String vehicleId) async {
    try {
      final response = await _client
          .from('compliance_document')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('expiry_date');

      return (response as List)
          .map((json) => ComplianceDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching compliance documents: $e');
    }
  }

  Future<ComplianceDocument> createComplianceDocument(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('compliance_document')
          .insert(data)
          .select()
          .single();

      return ComplianceDocument.fromJson(response);
    } catch (e) {
      throw Exception('Error creating compliance document: $e');
    }
  }

  Future<List<ComplianceDocument>> getComplianceDocumentsForFleet({
    List<String>? vehicleIds,
  }) async {
    try {
      var query = _client.from('compliance_document').select('*');

      if (vehicleIds != null && vehicleIds.isNotEmpty) {
        query = query.inFilter('vehicle_id', vehicleIds);
      }

      final response = await query.order('expiry_date', ascending: true);

      return (response as List)
          .map((json) => ComplianceDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching fleet compliance documents: $e');
    }
  }

  // ==================== STORAGE ====================
  
  Future<void> uploadFile(String path, Uint8List bytes, String mimeType) async {
    try {
      await _client.storage.from('vehicle-documents').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
    } catch (e) {
      // Check if it's a bucket not found error
      if (e.toString().contains('Bucket not found') || 
          e.toString().contains('404') ||
          (e is StorageException && e.statusCode?.toString() == '404')) {
        throw Exception(
          'Storage bucket "vehicle-documents" not found. '
          'Please create the bucket in your Supabase Storage settings.'
        );
      }
      // Check if it's an RLS policy violation (403 Unauthorized)
      if (e.toString().contains('row-level security policy') ||
          e.toString().contains('violates row-level security') ||
          e.toString().contains('403') ||
          (e is StorageException && e.statusCode?.toString() == '403')) {
        throw Exception(
          'Storage upload denied: Row-Level Security (RLS) policy violation. '
          'Please configure Storage policies in Supabase. See SUPABASE_SETUP.md for instructions.'
        );
      }
      throw Exception('Error uploading file: $e');
    }
  }

  String getPublicUrl(String path) {
    return _client.storage.from('vehicle-documents').getPublicUrl(path);
  }

  // ==================== CHARGING SESSIONS ====================
  
  Future<List<dynamic>> getChargingSessions(String vehicleId, {int? limit}) async {
    try {
      var query = _client
          .from('charging_session')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('start_time', ascending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      return response as List;
    } catch (e) {
      throw Exception('Error fetching charging sessions: $e');
    }
  }

  // ==================== STATISTICS ====================
  
  Future<Map<String, dynamic>> getFleetStatistics() async {
    try {
      // Get total vehicles
      final totalResponse = await _client
          .from('crm_vehicles')
          .select('vehicle_id');

      final total = (totalResponse as List).length;

      // Get vehicles by status (if status field exists in crm_vehicles)
      int onRoad = total; // Default to total if status field doesn't exist
      try {
        final onRoadResponse = await _client
            .from('crm_vehicles')
            .select('vehicle_id')
            .eq('status', 'active')
            .eq('health_state', 'healthy');
        onRoad = (onRoadResponse as List).length;
      } catch (e) {
        // If status/health_state fields don't exist, assume all vehicles are on road
        debugPrint('Status/health_state fields not found in crm_vehicles, using total count: $e');
      }

      // Get vehicles on repair (has active maintenance jobs)
      int onRepair = 0;
      try {
        final onRepairResponse = await _client
            .from('maintenance_job')
            .select('vehicle_id')
            .inFilter('status', ['pending_diagnosis', 'in_progress', 'on_hold'])
            .eq('job_category', 'breakdown');
        onRepair = (onRepairResponse as List).length;
      } catch (e) {
        debugPrint('Error fetching on repair vehicles: $e');
      }

      return {
        'total': total,
        'onRoad': onRoad,
        'onRepair': onRepair,
      };
    } catch (e) {
      throw Exception('Error fetching statistics: $e');
    }
  }

  // ==================== INTERACTIONS ====================
  
  Future<List<Interaction>> getInteractions({String? vehicleId, String? status}) async {
    try {
      var query = _client.from('crm_interactions').select('*');

      if (vehicleId != null) {
        query = query.eq('vehicle_id', vehicleId);
      }
      if (status != null) {
        query = query.eq('interaction_status', status);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Interaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching interactions: $e');
    }
  }

  Future<Interaction> getInteractionById(String interactionId) async {
    try {
      final response = await _client
          .from('crm_interactions')
          .select('*')
          .eq('interaction_id', interactionId)
          .single();

      return Interaction.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching interaction: $e');
    }
  }

  Future<Interaction> createInteraction(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('crm_interactions')
          .insert(data)
          .select('*')
          .single();

      return Interaction.fromJson(response);
    } catch (e) {
      throw Exception('Error creating interaction: $e');
    }
  }

  Future<Interaction> updateInteraction(String interactionId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('crm_interactions')
          .update(data)
          .eq('interaction_id', interactionId)
          .select('*')
          .single();

      return Interaction.fromJson(response);
    } catch (e) {
      throw Exception('Error updating interaction: $e');
    }
  }

  // ==================== CUSTOMERS (DRIVERS) ====================
  
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    try {
      final response = await _client
          .from('crm_customers')
          .select('*')
          .eq('customer_id', customerId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error fetching customer: $e');
    }
  }

  // ==================== TASKS ====================
  
  Future<List<Task>> getTasksByInteractionId(String interactionId) async {
    try {
      // Try crm_tasks first, fallback to tasks table
      try {
        final response = await _client
            .from('crm_tasks')
            .select('*')
            .eq('interaction_id', interactionId)
            .order('created_at', ascending: false);
        
        return (response as List)
            .map((json) => Task.fromJson(json))
            .toList();
      } catch (e) {
        // Try tasks table
        final response = await _client
            .from('tasks')
            .select('*')
            .eq('interaction_id', interactionId)
            .order('created_at', ascending: false);
        
        return (response as List)
            .map((json) => Task.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      return [];
    }
  }

  Future<Task> createTask(Map<String, dynamic> data) async {
    try {
      // Try crm_tasks first, fallback to tasks table
      try {
        final response = await _client
            .from('crm_tasks')
            .insert(data)
            .select('*')
            .single();
        return Task.fromJson(response);
      } catch (e) {
        final response = await _client
            .from('tasks')
            .insert(data)
            .select('*')
            .single();
        return Task.fromJson(response);
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      try {
        await _client.from('crm_tasks').delete().eq('task_id', taskId);
      } catch (e) {
        await _client.from('tasks').delete().eq('task_id', taskId);
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  // ==================== MAINTENANCE JOBS (HISTORY) ====================
  
  Future<List<MaintenanceJob>> getMaintenanceJobsByVehicleId(String vehicleId) async {
    try {
      final response = await _client
          .from('maintenance_job')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('diagnosis_date', ascending: false);

      return (response as List)
          .map((json) => MaintenanceJob.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching maintenance jobs: $e');
      return [];
    }
  }

  // ==================== KANBAN BOARD ====================
  
  Future<List<Map<String, dynamic>>> getKanbanCards() async {
    try {
      final response = await _client
          .from('kanban_cards')
          .select('*')
          .order('position', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching kanban cards: $e');
      }
      return []; // Return empty list if table doesn't exist yet
    }
  }

  Future<void> createKanbanCard(Map<String, dynamic> cardData) async {
    try {
      await _client.from('kanban_cards').insert({
        ...cardData,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating kanban card: $e');
      }
      throw Exception('Failed to create kanban card: $e');
    }
  }

  Future<void> deleteKanbanCard(String cardId) async {
    try {
      await _client.from('kanban_cards').delete().eq('id', cardId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting kanban card: $e');
      }
      throw Exception('Failed to delete kanban card: $e');
    }
  }

  Future<void> updateKanbanCardStatus(String cardId, String newStatus) async {
    try {
      await _client.from('kanban_cards').update({
        'column_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cardId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating kanban card status: $e');
      }
      throw Exception('Failed to update kanban card status: $e');
    }
  }

  Future<void> updateKanbanCardDate(String cardId, DateTime newDate) async {
    try {
      await _client.from('kanban_cards').update({
        'due_date': newDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cardId);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating kanban card date: $e');
      }
      throw Exception('Failed to update kanban card date: $e');
    }
  }

  // ==================== MOBILE SYNC DETAILS ====================

  Future<List<Map<String, dynamic>>> getInventoryPhotosByVehicleId(String vehicleId) async {
    try {
      final response = await _client
          .from('mobile_inventory_photos')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching inventory photos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDailyInventoryByVehicleId(String vehicleId) async {
    try {
      final response = await _client
          .from('mobile_daily_inventory')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('check_date', ascending: false)
          .limit(10);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching daily inventory logs: $e');
      return [];
    }
  }

  // ==================== SERVICE DETAILS ====================
  
  Future<Map<String, dynamic>?> getServiceDetailByCardId(String cardId) async {
    try {
      // Get the kanban card first
      final cardResponse = await _client
          .from('kanban_cards')
          .select('*')
          .eq('id', cardId)
          .maybeSingle();
      
      if (cardResponse == null) return null;

      // Get service items for this card
      final itemsResponse = await _client
          .from('service_items')
          .select('*')
          .eq('kanban_card_id', cardId);

      return {
        ...cardResponse,
        'service_items': itemsResponse as List,
      };
    } catch (e) {
      debugPrint('Error fetching service detail: $e');
      return null;
    }
  }

  Future<void> updateServiceDetail(String cardId, Map<String, dynamic> data) async {
    try {
      await _client.from('kanban_cards').update({
        'customer_name': data['customer_name'],
        'customer_phone': data['customer_phone'],
        'customer_email': data['customer_email'],
        'gst_number': data['gst_number'],
        'vehicle_reg_number': data['vehicle_reg_number'],
        'vehicle_make_model': data['vehicle_make_model'],
        'vehicle_year': data['vehicle_year'],
        'vehicle_fuel_type': data['vehicle_fuel_type'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', cardId);
    } catch (e) {
      throw Exception('Error updating service detail: $e');
    }
  }

  Future<Map<String, dynamic>> addServiceItem(String cardId, Map<String, dynamic> itemData) async {
    try {
      // Remove 'id' from itemData if present - let database generate UUID
      final dataToInsert = Map<String, dynamic>.from(itemData);
      dataToInsert.remove('id');
      
      final response = await _client.from('service_items').insert({
        'kanban_card_id': cardId,
        ...dataToInsert,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();
      
      return response;
    } catch (e) {
      throw Exception('Error adding service item: $e');
    }
  }

  Future<void> updateServiceItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      await _client.from('service_items').update({
        ...itemData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
    } catch (e) {
      throw Exception('Error updating service item: $e');
    }
  }

  Future<void> deleteServiceItem(String itemId) async {
    try {
      await _client.from('service_items').delete().eq('id', itemId);
    } catch (e) {
      throw Exception('Error deleting service item: $e');
    }
  }

  // ==================== UNIVERSAL SEARCH ====================
  
  Future<List<Map<String, dynamic>>> universalSearch(String query) async {
    if (query.trim().isEmpty) {
      debugPrint('🔍 Search query is empty');
      return [];
    }
    
    debugPrint('🔍 Starting universal search for: "$query"');
    
    try {
      final searchTerm = '%${query.trim().toLowerCase()}%';
      final results = <Map<String, dynamic>>[];
      
      // Search vehicles first
      try {
        debugPrint('🔍 Searching crm_vehicles table...');
        final vehicleResponse = await _client
            .from('crm_vehicles')
            .select('vehicle_id, registration_number, make_model_year, customer_id')
            .or('registration_number.ilike.$searchTerm,make_model_year.ilike.$searchTerm')
            .limit(10);
        
        debugPrint('🔍 Found ${(vehicleResponse as List).length} vehicles');
        
        // Get unique customer IDs
        final customerIds = (vehicleResponse as List)
            .map((v) => v['customer_id'] as String?)
            .where((id) => id != null)
            .toSet()
            .toList();
        
        debugPrint('🔍 Fetching ${customerIds.length} customer records...');
        
        // Fetch customer details for these vehicles
        Map<String, Map<String, dynamic>> customers = {};
        if (customerIds.isNotEmpty) {
          try {
            final customerResponse = await _client
                .from('crm_customers')
                .select('customer_id, full_name, mobile_number')
                .inFilter('customer_id', customerIds);
            
            debugPrint('🔍 Found ${(customerResponse as List).length} customers');
            
            for (var customer in (customerResponse as List)) {
              customers[customer['customer_id']] = customer;
            }
          } catch (e) {
            debugPrint('❌ Error fetching customers: $e');
          }
        }
        
        // Combine vehicle and customer data
        for (var vehicle in (vehicleResponse as List)) {
          final customerId = vehicle['customer_id'];
          final customer = customers[customerId];
          final customerName = customer?['full_name'] ?? 'Unknown Customer';
          
          results.add({
            'type': 'vehicle',
            'id': vehicle['vehicle_id'],
            'customer_id': customerId,
            'customer_name': customerName,
            'vehicle_details': '${vehicle['make_model_year']} - ${vehicle['registration_number']}',
            'registration_number': vehicle['registration_number'],
            'make_model': vehicle['make_model_year'],
          });
        }
        
        debugPrint('🔍 Total results: ${results.length}');
      } catch (e) {
        debugPrint('❌ Error searching vehicles: $e');
        debugPrint('❌ Error details: ${e.toString()}');
      }
      
      // Also search customers by name
      try {
        debugPrint('🔍 Searching crm_customers by name...');
        final customerResponse = await _client
            .from('crm_customers')
            .select('customer_id, full_name, mobile_number')
            .ilike('full_name', searchTerm)
            .limit(5);
        
        debugPrint('🔍 Found ${(customerResponse as List).length} customers by name');
        
        // For each customer, try to find their vehicles
        for (var customer in (customerResponse as List)) {
          try {
            final vehiclesResponse = await _client
                .from('crm_vehicles')
                .select('vehicle_id, registration_number, make_model_year')
                .eq('customer_id', customer['customer_id'])
                .limit(1);
            
            if ((vehiclesResponse as List).isNotEmpty) {
              final vehicle = vehiclesResponse[0];
              // Check if we already have this combination
              final alreadyExists = results.any((r) => 
                r['customer_id'] == customer['customer_id'] && 
                r['id'] == vehicle['vehicle_id']
              );
              
              if (!alreadyExists) {
                results.add({
                  'type': 'vehicle',
                  'id': vehicle['vehicle_id'],
                  'customer_id': customer['customer_id'],
                  'customer_name': customer['full_name'],
                  'vehicle_details': '${vehicle['make_model_year']} - ${vehicle['registration_number']}',
                  'registration_number': vehicle['registration_number'],
                  'make_model': vehicle['make_model_year'],
                });
              }
            }
          } catch (e) {
            debugPrint('❌ Error fetching vehicles for customer: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Error searching customers: $e');
      }
      
      debugPrint('🔍 Final results count: ${results.length}');
      return results.take(10).toList();
    } catch (e) {
      debugPrint('❌ Error in universal search: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}

