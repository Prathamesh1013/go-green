import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_card.dart';

class DealershipColumn extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> subcategories;
  final VoidCallback onAddCard;
  final Function(String cardId) onCardTap;
  final Function(String cardId) onCardDelete;
  final Widget Function(BuildContext, int, Map<String, dynamic>)? itemBuilder;
  final Function(Map<String, dynamic>)? onCardDropped;

  const DealershipColumn({
    super.key,
    required this.subcategories,
    required this.onAddCard,
    required this.onCardTap,
    required this.onCardDelete,
    this.itemBuilder,
    this.onCardDropped,
  });

  @override
  State<DealershipColumn> createState() => _DealershipColumnState();
}

class _DealershipColumnState extends State<DealershipColumn> {
  // Track expanded state for each subcategory
  final Map<String, bool> _expandedState = {
    'nashik': true,
    'pune_station1': true,
    'pune_station2': true,
  };

  int get totalCount {
    return widget.subcategories.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        if (widget.onCardDropped != null) {
          widget.onCardDropped!(data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? const Color(0xFFf3f4f6) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? const Color(0xFF9ca3af) : const Color(0xFFe5e7eb),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFf3f4f6), // Light gray
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Dealership',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: widget.onAddCard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: const Color(0xFF6b7280),
                    ),
                  ],
                ),
              ),
              // Subcategories
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildSubcategory('Nashik', 'nashik'),
                    _buildSubcategory('Pune Station 1', 'pune_station1'),
                    _buildSubcategory('Pune Station 2', 'pune_station2'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategory(String title, String key) {
    final cards = widget.subcategories[key] ?? [];
    final isExpanded = _expandedState[key] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedState[key] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFf9fafb),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 20,
                  color: const Color(0xFF6b7280),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cards.isEmpty ? Colors.grey.shade300 : const Color(0xFF3b82f6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cards.isEmpty ? Colors.grey.shade600 : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && cards.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: widget.itemBuilder != null
                  ? widget.itemBuilder!(context, index, card)
                  : KanbanCard(
                      id: card['id'] ?? '',
                      title: card['title'] ?? '',
                      description: card['description'],
                      dueDate: card['due_date'] != null ? DateTime.parse(card['due_date']) : null,
                      onTap: () => widget.onCardTap(card['id']),
                      onDelete: () => widget.onCardDelete(card['id']),
                    ),
            );
          }).toList(),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
