import 'package:flutter/material.dart';
import 'package:gogreen_admin/models/interaction.dart';
import 'package:gogreen_admin/theme/app_colors.dart';

class KanbanBoard extends StatefulWidget {
  final List<Interaction> interactions;
  final Function(Interaction) onInteractionTap;
  final Function(String interactionId, String newStatus) onStatusChange;
  final VoidCallback? onAddInteraction;

  const KanbanBoard({
    super.key,
    required this.interactions,
    required this.onInteractionTap,
    required this.onStatusChange,
    this.onAddInteraction,
  });

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final List<KanbanColumn> _columns = [
    KanbanColumn(id: 'pending', title: 'Pending', color: AppColors.warning),
    KanbanColumn(id: 'in_progress', title: 'In Progress', color: AppColors.primary),
    KanbanColumn(id: 'completed', title: 'Completed', color: AppColors.success),
    KanbanColumn(id: 'cancelled', title: 'Cancelled', color: AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interactions',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => widget.onAddInteraction?.call(),
              tooltip: 'Add Interaction',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _columns.map((column) {
              final columnInteractions = widget.interactions
                  .where((i) => i.interactionStatus.toLowerCase() == column.id.toLowerCase())
                  .toList();
              
              return Expanded(
                child: _KanbanColumnWidget(
                  column: column,
                  interactions: columnInteractions,
                  onInteractionTap: widget.onInteractionTap,
                  onInteractionMove: (interactionId, newStatus) {
                    widget.onStatusChange(interactionId, newStatus);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class KanbanColumn {
  final String id;
  final String title;
  final Color color;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.color,
  });
}

class _KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final List<Interaction> interactions;
  final Function(Interaction) onInteractionTap;
  final Function(String interactionId, String newStatus) onInteractionMove;

  const _KanbanColumnWidget({
    required this.column,
    required this.interactions,
    required this.onInteractionTap,
    required this.onInteractionMove,
  });

  void _handleDrop(String interactionId) {
    onInteractionMove(interactionId, column.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: column.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: column.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          column.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: column.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: column.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          interactions.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<String>(
              onAccept: (interactionId) {
                _handleDrop(interactionId);
              },
              builder: (context, candidateData, rejectedData) {
                final isHighlighted = candidateData.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isHighlighted ? column.color.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: interactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No interactions',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: interactions.length,
                          itemBuilder: (context, index) {
                            final interaction = interactions[index];
                            return Draggable<String>(
                              data: interaction.interactionId,
                              feedback: Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(8),
                                color: Theme.of(context).cardColor,
                                child: SizedBox(
                                  width: 200,
                                  child: _KanbanCard(
                                    interaction: interaction,
                                    onTap: () {},
                                    isDragging: true,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _KanbanCard(
                                  interaction: interaction,
                                  onTap: () {},
                                ),
                              ),
                              child: _KanbanCard(
                                interaction: interaction,
                                onTap: () => onInteractionTap(interaction),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Interaction interaction;
  final VoidCallback onTap;
  final bool isDragging;

  const _KanbanCard({
    required this.interaction,
    required this.onTap,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: Text(
                      interaction.interactionNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(interaction.customerPaymentStatus).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      interaction.customerPaymentStatus,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(interaction.customerPaymentStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                interaction.primaryJob,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${interaction.totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _formatDate(interaction.pickupDateTime),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'overdue':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

