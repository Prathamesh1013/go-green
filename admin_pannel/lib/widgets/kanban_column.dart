import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';
import 'package:gogreen_admin/widgets/kanban_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final int count;
  final List<Map<String, dynamic>> cards;
  final VoidCallback onAddCard;
  final Function(String cardId) onCardTap;
  final Function(String cardId) onCardDelete;
  final Color? headerColor;
  final Widget Function(BuildContext, int, Map<String, dynamic>)? itemBuilder;
  final Function(Map<String, dynamic>)? onCardDropped;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.count,
    required this.cards,
    required this.onAddCard,
    required this.onCardTap,
    required this.onCardDelete,
    this.headerColor,
    this.itemBuilder,
    this.onCardDropped,
  });

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
                decoration: BoxDecoration(
                  color: headerColor ?? const Color(0xFFf3f4f6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFe5e7eb),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        count.toString(),
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
                      onPressed: onAddCard,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: const Color(0xFF6b7280),
                    ),
                  ],
                ),
              ),
              // Cards List
              Expanded(
                child: cards.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No items',
                            style: const TextStyle(
                              color: Color(0xFF9ca3af),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          
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
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
