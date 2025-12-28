import 'package:flutter/foundation.dart';
import 'package:gogreen_admin/models/interaction.dart';
import 'package:gogreen_admin/services/supabase_service.dart';

class InteractionProvider with ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  
  List<Interaction> _interactions = [];
  bool _isLoading = false;
  String? _error;

  List<Interaction> get interactions => _interactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInteractions({String? vehicleId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _interactions = await _service.getInteractions(
        vehicleId: vehicleId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading interactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInteractionStatus(String interactionId, String newStatus) async {
    try {
      await _service.updateInteraction(interactionId, {
        'interaction_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Update local state
      final index = _interactions.indexWhere((i) => i.interactionId == interactionId);
      if (index != -1) {
        _interactions[index] = _interactions[index].copyWith(
          interactionStatus: newStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createInteraction(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final interaction = await _service.createInteraction(data);
      _interactions.add(interaction);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadInteractions();
  }
}

