import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_column.dart';
import 'package:gogreen_admin/widgets/upcoming_column.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:gogreen_admin/widgets/tp_vehicle_card.dart';

class DashboardKanbanBoard extends StatefulWidget {
  const DashboardKanbanBoard({super.key});

  @override
  State<DashboardKanbanBoard> createState() => _DashboardKanbanBoardState();
}

class _DashboardKanbanBoardState extends State<DashboardKanbanBoard> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, List<Map<String, dynamic>>> _columnCards = {
    'upcoming': [],
    'third_party_garage': [],
    'upcoming_non_registered': [],
    'nashik_tp': [],
    'kalyan_tp': [],
    'ongoing_dealership': [],
    'non_workshop_active': [],
    'payment_pending': [],
    'completed': [],
  };
  
  // Upcoming subcategories
  Map<String, List<Map<String, dynamic>>> _upcomingSubcategories = {
    'overdue': [],
    'today': [],
    'tomorrow': [],
    '7_days': [],
  };
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _supabaseService.getKanbanCards();
      
      final grouped = <String, List<Map<String, dynamic>>>{
        'upcoming': [],
        'third_party_garage': [],
        'upcoming_non_registered': [],
        'nashik_tp': [],
        'kalyan_tp': [],
        'ongoing_dealership': [],
        'non_workshop_active': [],
        'payment_pending': [],
        'completed': [],
      };
      
      final upcomingSub = <String, List<Map<String, dynamic>>>{
        'overdue': [],
        'today': [],
        'tomorrow': [],
        '7_days': [],
      };

      for (var card in cards) {
        final column = card['column_status'] ?? 'nashik_tp';
        if (grouped.containsKey(column)) {
          grouped[column]!.add(card);
          
          // Categorize upcoming cards by due date
          if (column == 'upcoming' && card['due_date'] != null) {
            final dueDate = DateTime.parse(card['due_date']);
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            final sevenDays = today.add(const Duration(days: 7));
            
            if (dueDate.isBefore(today)) {
              upcomingSub['overdue']!.add(card);
            } else if (dueDate.year == today.year && dueDate.month == today.month && dueDate.day == today.day) {
              upcomingSub['today']!.add(card);
            } else if (dueDate.year == tomorrow.year && dueDate.month == tomorrow.month && dueDate.day == tomorrow.day) {
              upcomingSub['tomorrow']!.add(card);
            } else if (dueDate.isBefore(sevenDays)) {
              upcomingSub['7_days']!.add(card);
            }
          }
        }
      }

      setState(() {
        _columnCards = grouped;
        _upcomingSubcategories = upcomingSub;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCard(String columnStatus) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Card'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: selectedDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () async {
                          try {
                            await _supabaseService.createKanbanCard({
                              'title': titleController.text.trim(),
                              'description': descriptionController.text.trim(),
                              'column_status': columnStatus,
                              'due_date': selectedDate?.toIso8601String(),
                              'position': _columnCards[columnStatus]!.length,
                            });
                            
                            Navigator.pop(dialogContext);
                            _loadCards();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Card added successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add card: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Card'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await _supabaseService.deleteKanbanCard(cardId);
      _loadCards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card deleted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete card: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _moveCard(String cardId, String newColumn) async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateKanbanCardStatus(cardId, newColumn);
      await _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move card: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateCardDate(String cardId, DateTime newDate) async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateKanbanCardDate(cardId, newDate);
      await _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update date: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCard(BuildContext context, int index, Map<String, dynamic> card) {
    return TPVehicleCard(
      data: card,
      onTap: () {
        // Navigate to Service Details page
        context.go('/service-details/${card['id']}');
      },
      onDelete: () => _deleteCard(card['id']),
      onDateChange: (date) => _updateCardDate(card['id'], date),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFf9fafb),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kanban Board',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Column with subcategories
                  UpcomingColumn(
                    subcategories: _upcomingSubcategories,
                    onAddCard: () => _addCard('upcoming'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'upcoming'),
                  ),
                  // Dealership
                  KanbanColumn(
                    title: 'Dealership',
                    count: _columnCards['upcoming_non_registered']!.length,
                    cards: _columnCards['upcoming_non_registered']!,
                    onAddCard: () => _addCard('upcoming_non_registered'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFf3f4f6), // Light gray
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'upcoming_non_registered'),
                  ),
                  // Third Party Garage
                  KanbanColumn(
                    title: 'Third Party Garage',
                    count: _columnCards['third_party_garage']!.length,
                    cards: _columnCards['third_party_garage']!,
                    onAddCard: () => _addCard('third_party_garage'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFccfbf1), // Pastel cyan
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'third_party_garage'),
                  ),
                  // Insurance
                  KanbanColumn(
                    title: 'Insurance',
                    count: _columnCards['nashik_tp']!.length,
                    cards: _columnCards['nashik_tp']!,
                    onAddCard: () => _addCard('nashik_tp'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFe0e7ff), // Pastel indigo
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'nashik_tp'),
                  ),
                  // Fitness
                  KanbanColumn(
                    title: 'Fitness',
                    count: _columnCards['kalyan_tp']!.length,
                    cards: _columnCards['kalyan_tp']!,
                    onAddCard: () => _addCard('kalyan_tp'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFf3e8ff), // Pastel purple
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'kalyan_tp'),
                  ),
                  // Ongoing Dealership
                  KanbanColumn(
                    title: 'Ongoing Dealership',
                    count: _columnCards['ongoing_dealership']!.length,
                    cards: _columnCards['ongoing_dealership']!,
                    onAddCard: () => _addCard('ongoing_dealership'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFdbeafe), // Pastel blue
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'ongoing_dealership'),
                  ),
                  // Payment Pending
                  KanbanColumn(
                    title: 'Payment Pending',
                    count: _columnCards['payment_pending']!.length,
                    cards: _columnCards['payment_pending']!,
                    onAddCard: () => _addCard('payment_pending'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFfef3c7), // Pastel yellow
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'payment_pending'),
                  ),
                  // Payment Completed
                  KanbanColumn(
                    title: 'Payment Completed',
                    count: _columnCards['completed']!.length,
                    cards: _columnCards['completed']!,
                    onAddCard: () => _addCard('completed'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
                    headerColor: const Color(0xFFd1fae5), // Pastel green
                    itemBuilder: _buildCard,
                    onCardDropped: (data) => _moveCard(data['id'], 'completed'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
