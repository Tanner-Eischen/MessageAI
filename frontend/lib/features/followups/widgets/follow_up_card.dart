import 'package:flutter/material.dart';
import 'package:messageai/models/follow_up_item.dart';

/// Card displaying a follow-up item
class FollowUpCard extends StatelessWidget {
  final FollowUpItem item;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  const FollowUpCard({
    Key? key,
    required this.item,
    required this.onComplete,
    required this.onSnooze,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = item.itemType.getColor();
    final isOverdue = item.isOverdue;

    return Card(
      elevation: isOverdue ? 4 : 2,
      color: isOverdue ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  item.itemType.icon,
                  size: 20,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (item.dueAt != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withOpacity(0.2)
                          : item.isDueSoon
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.getTimeUntilDue(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? Colors.red
                            : item.isDueSoon
                                ? Colors.orange
                                : Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),

            // Description
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Original text (if action item)
            if (item.extractedText != null &&
                item.itemType == FollowUpItemType.actionItem) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 14, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.extractedText!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Metadata
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.priority_high, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Priority: ${item.priority}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  item.getTimeSinceDetected(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            // Actions
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Done', style: TextStyle(fontSize: 12)),
                    onPressed: onComplete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Snooze', style: TextStyle(fontSize: 12)),
                    onPressed: onSnooze,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
