import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';

class SupabaseService {
  // Get Supabase client (lazy initialization)
  static SupabaseClient get _client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase must be initialized before use. Error: $e');
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
  
  /// Fetch all vehicles from the database
  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Vehicle.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }

  /// Get a specific vehicle by ID
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .maybeSingle();

      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching vehicle: $e');
      return null;
    }
  }

  /// Update vehicle status or other fields
  Future<Vehicle> updateVehicle(String vehicleId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('crm_vehicles')
          .update(data)
          .eq('vehicle_id', vehicleId)
          .select('*')
          .maybeSingle();

      if (response == null) {
        throw Exception('Vehicle not found or update denied for ID: $vehicleId');
      }

      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  // ==================== MAINTENANCE JOBS / ISSUES ====================
  
  /// Create a new maintenance job (reported issue)
  Future<Map<String, dynamic>> createMaintenanceJob(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('maintenance_job')
          .insert(data)
          .select('*')
          .single();

      return response;
    } catch (e) {
      throw Exception('Error creating maintenance job: $e');
    }
  }

  /// Get maintenance jobs for a specific vehicle
  Future<List<Map<String, dynamic>>> getMaintenanceJobs(String vehicleId) async {
    try {
      final response = await _client
          .from('maintenance_job')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('diagnosis_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching maintenance jobs: $e');
      return [];
    }
  }

  /// Delete a maintenance job
  Future<void> deleteMaintenanceJob(String jobId) async {
    try {
      await _client
          .from('maintenance_job')
          .delete()
          .eq('job_id', jobId);
    } catch (e) {
      throw Exception('Error deleting maintenance job: $e');
    }
  }

  // ==================== DAILY INVENTORY ====================
  
  /// Create a daily inventory check record
  Future<Map<String, dynamic>> createDailyInventory(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('mobile_daily_inventory')
          .insert(data)
          .select('*')
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating daily inventory: $e');
      throw Exception('Error creating daily inventory: $e');
    }
  }

  /// Get daily inventory for a vehicle
  Future<List<Map<String, dynamic>>> getDailyInventory(String vehicleId) async {
    try {
      final response = await _client
          .from('mobile_daily_inventory')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('check_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching daily inventory: $e');
      return [];
    }
  }

  // ==================== STORAGE ====================
  
  /// Upload a file to Supabase Storage
  Future<String> uploadFile(String path, Uint8List bytes, String mimeType) async {
    try {
      await _client.storage.from('vehicle-documents').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      
      return getPublicUrl(path);
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
          'Please configure Storage policies in Supabase.'
        );
      }
      throw Exception('Error uploading file: $e');
    }
  }

  /// Get public URL for a file in storage
  String getPublicUrl(String path) {
    return _client.storage.from('vehicle-documents').getPublicUrl(path);
  }

  /// Save inventory photo record to database
  Future<void> saveInventoryPhoto({
    required String vehicleId,
    required String category,
    required String photoUrl,
    String? inventoryId,
  }) async {
    try {
      await _client.from('mobile_inventory_photos').insert({
        'vehicle_id': vehicleId,
        'category': category,
        'photo_url': photoUrl,
        if (inventoryId != null) 'inventory_id': inventoryId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving inventory photo record: $e');
      throw Exception('Error saving inventory photo record: $e');
    }
  }

  /// Get inventory photos for a vehicle
  Future<List<Map<String, dynamic>>> getInventoryPhotos(String vehicleId) async {
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

  // ==================== SERVICE SCHEDULES ====================
  
  /// Create a service schedule
  Future<Map<String, dynamic>> createServiceSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('service_schedule')
          .insert(data)
          .select('*')
          .single();

      return response;
    } catch (e) {
      throw Exception('Error creating service schedule: $e');
    }
  }

  /// Get service schedules for a vehicle
  Future<List<Map<String, dynamic>>> getServiceSchedules(String vehicleId) async {
    try {
      final response = await _client
          .from('service_schedule')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching service schedules: $e');
      return [];
    }
  }

  // ==================== OFFLINE QUEUE ====================
  
  /// Save pending operation to offline queue
  Future<void> savePendingOperation(Map<String, dynamic> operation) async {
    try {
      // Store in a local table or SharedPreferences for offline support
      // This will be synced when connection is restored
      debugPrint('Saving pending operation: $operation');
      // Implementation depends on offline strategy
    } catch (e) {
      debugPrint('Error saving pending operation: $e');
    }
  }

  // ==================== HEALTH CHECK ====================
  
  /// Check if Supabase connection is working
  Future<bool> checkConnection() async {
    try {
      await _client.from('crm_vehicles').select('vehicle_id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Supabase connection check failed: $e');
      return false;
    }
  }
}
