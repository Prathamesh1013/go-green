import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_card.dart';

class UpcomingColumn extends StatelessWidget {
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

  int get totalCount {
    return subcategories.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: (data) => true,
      onAccept: (data) {
        if (onCardDropped != null) {
          onCardDropped!(data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? AppColors.blue50 : AppColors.lightBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? AppColors.blue500 : AppColors.lightBorder,
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Upcoming',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        totalCount.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: onAddCard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              // Subcategories
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildSubcategory(context, 'Overdue', subcategories['overdue'] ?? [], Colors.red),
                    _buildSubcategory(context, 'Today', subcategories['today'] ?? [], Colors.grey),
                    _buildSubcategory(context, 'Tomorrow', subcategories['tomorrow'] ?? [], Colors.orange),
                    _buildSubcategory(context, '7+ Days', subcategories['7_days'] ?? [], Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubcategory(BuildContext context, String title, List<Map<String, dynamic>> cards, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '(${cards.length})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'No vehicles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          ...cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            
            if (itemBuilder != null) {
              return itemBuilder!(context, index, card);
            }

            return KanbanCard(
              id: card['id'] ?? '',
              title: card['title'] ?? '',
              description: card['description'],
              dueDate: card['due_date'] != null
                  ? DateTime.tryParse(card['due_date'])
                  : null,
              onTap: () => onCardTap(card['id'] ?? ''),
              onDelete: () => onCardDelete(card['id'] ?? ''),
            );
          }).toList(),
        const SizedBox(height: 12),
      ],
    );
  }
}
