import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_card.dart';

class UpcomingColumn extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> subcategories;
  final VoidCallback onAddCard;
  final Function(String cardId) onCardTap;
  final Function(String cardId) onCardDelete;
  final Widget Function(BuildContext, int, Map<String, dynamic>)? itemBuilder;
  final Function(Map<String, dynamic>)? onCardDropped;

  const UpcomingColumn({
    super.key,
    required this.subcategories,
    required this.onAddCard,
    required this.onCardTap,
    required this.onCardDelete,
    this.itemBuilder,
    this.onCardDropped,
  });

  @override
  State<UpcomingColumn> createState() => _UpcomingColumnState();
}

class _UpcomingColumnState extends State<UpcomingColumn> {
  // Track expanded state for each subcategory
  final Map<String, bool> _expandedState = {
    'overdue': true,
    'today': true,
    'tomorrow': true,
    '7_days': true,
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
            color: candidateData.isNotEmpty ? const Color(0xFFdbeafe) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? const Color(0xFF3b82f6) : const Color(0xFFe5e7eb),
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
                  color: Color(0xFFfce7f3), // Pastel pink
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Upcoming',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        totalCount.toString(),
                        style: const TextStyle(
                          color: Color(0xFF6b7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
                    _buildSubcategory(context, 'Overdue', 'overdue', widget.subcategories['overdue'] ?? [], const Color(0xFFef4444)),
                    _buildSubcategory(context, 'Today', 'today', widget.subcategories['today'] ?? [], const Color(0xFF6b7280)),
                    _buildSubcategory(context, 'Tomorrow', 'tomorrow', widget.subcategories['tomorrow'] ?? [], const Color(0xFFf59e0b)),
                    _buildSubcategory(context, '7+ Days', '7_days', widget.subcategories['7_days'] ?? [], const Color(0xFF3b82f6)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategory(BuildContext context, String title, String key, List<Map<String, dynamic>> cards, Color color) {
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
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '(${cards.length})',
                  style: const TextStyle(
                    color: Color(0xFF9ca3af),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: const Color(0xFF6b7280),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: [
              const SizedBox(height: 8),
              if (cards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    'No vehicles',
                    style: TextStyle(
                      color: Color(0xFF6b7280),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                ...cards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  
                  if (widget.itemBuilder != null) {
                    return widget.itemBuilder!(context, index, card);
                  }

                  return KanbanCard(
                    id: card['id'] ?? '',
                    title: card['title'] ?? '',
                    description: card['description'],
                    dueDate: card['due_date'] != null
                        ? DateTime.tryParse(card['due_date'])
                        : null,
                    onTap: () => widget.onCardTap(card['id'] ?? ''),
                    onDelete: () => widget.onCardDelete(card['id'] ?? ''),
                  );
                }).toList(),
            ],
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
