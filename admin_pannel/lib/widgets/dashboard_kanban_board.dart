import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_column.dart';
import 'package:gogreen_admin/widgets/upcoming_column.dart';
import 'package:gogreen_admin/widgets/dealership_column.dart';
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
  
  // Dealership subcategories (locations)
  Map<String, List<Map<String, dynamic>>> _dealershipSubcategories = {
    'nashik': [],
    'pune_station1': [],
    'pune_station2': [],
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

      final dealershipSub = <String, List<Map<String, dynamic>>>{
        'nashik': [],
        'pune_station1': [],
        'pune_station2': [],
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
          
          // Categorize dealership cards by location
          if (column == 'upcoming_non_registered') {
            final location = card['location'] ?? 'nashik'; // Default to nashik
            if (dealershipSub.containsKey(location)) {
              dealershipSub[location]!.add(card);
            }
          }
        }
      }

      setState(() {
        _columnCards = grouped;
        _upcomingSubcategories = upcomingSub;
        _dealershipSubcategories = dealershipSub;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCard(String columnStatus) async {
    final searchController = TextEditingController();
    String selectedServiceType = 'Periodic Service';
    String selectedLocation = 'nashik'; // Default location for dealership
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1a1f2e),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(20),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Universal Search with Autocomplete
                    Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          print('🔍 Autocomplete: Empty text, returning empty results');
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        
                        print('🔍 Autocomplete: Searching for "${textEditingValue.text}"');
                        try {
                          final results = await _supabaseService.universalSearch(textEditingValue.text);
                          print('🔍 Autocomplete: Got ${results.length} results');
                          return results;
                        } catch (e) {
                          print('❌ Autocomplete error: $e');
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                      },
                      displayStringForOption: (Map<String, dynamic> option) {
                        return option['customer_name'] ?? '';
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        print('✅ Selected: ${selection['customer_name']}');
                        setDialogState(() {
                          searchController.text = selection['customer_name'] ?? '';
                        });
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search customer or vehicle...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFF2d3548),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        print('🔍 Options view builder: ${options.length} options');
                        if (options.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF2d3548),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 300,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(0),
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  
                                  return InkWell(
                                    onTap: () {
                                      print('🔍 Tapped option: ${option['customer_name']}');
                                      onSelected(option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: index < options.length - 1
                                            ? Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option['customer_name'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (option['vehicle_details'] != null)
                                            const SizedBox(height: 4),
                                          if (option['vehicle_details'] != null)
                                            Text(
                                              option['vehicle_details'],
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13,
                                              ),
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
                    const SizedBox(height: 16),
                    
                    // Date and Time Row
                    Row(
                      children: [
                        // Date Picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setDialogState(() => selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d3548),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time Picker
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setDialogState(() => selectedTime = time);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d3548),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.access_time, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Service Type Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d3548),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: selectedServiceType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF2d3548),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setDialogState(() => selectedServiceType = newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Periodic Service',
                            child: Text('Periodic Service'),
                          ),
                          DropdownMenuItem(
                            value: 'Suspension Overhaul',
                            child: Text('Suspension Overhaul'),
                          ),
                          DropdownMenuItem(
                            value: 'AC Service',
                            child: Text('AC Service'),
                          ),
                          DropdownMenuItem(
                            value: 'Tyre Changes',
                            child: Text('Tyre Changes'),
                          ),
                          DropdownMenuItem(
                            value: 'Wheel Alignment and Balance',
                            child: Text('Wheel Alignment and Balance'),
                          ),
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location Dropdown (only for Dealership)
                    if (columnStatus == 'upcoming_non_registered') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d3548),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: selectedLocation,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: const Color(0xFF2d3548),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          hint: const Text('Select Location', style: TextStyle(color: Colors.white70)),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setDialogState(() => selectedLocation = newValue);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'nashik',
                              child: Text('Nashik'),
                            ),
                            DropdownMenuItem(
                              value: 'pune_station1',
                              child: Text('Pune Station 1'),
                            ),
                            DropdownMenuItem(
                              value: 'pune_station2',
                              child: Text('Pune Station 2'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // Add Task Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final title = searchController.text.trim().isEmpty
                                ? selectedServiceType
                                : searchController.text.trim();
                            
                            final dateTime = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            
                            await _supabaseService.createKanbanCard({
                              'title': title,
                              'description': selectedServiceType,
                              'column_status': columnStatus,
                              'due_date': dateTime.toIso8601String(),
                              'position': _columnCards[columnStatus]!.length,
                              if (columnStatus == 'upcoming_non_registered') 'location': selectedLocation,
                            });
                            
                            Navigator.pop(dialogContext);
                            _loadCards();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task added successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add task: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563eb),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                  // Dealership with location subcategories
                  DealershipColumn(
                    subcategories: _dealershipSubcategories ?? {
                      'nashik': [],
                      'pune_station1': [],
                      'pune_station2': [],
                    },
                    onAddCard: () => _addCard('upcoming_non_registered'),
                    onCardTap: (cardId) {},
                    onCardDelete: _deleteCard,
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
