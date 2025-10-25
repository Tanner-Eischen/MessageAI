import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/state/ai_providers.dart';

/// Badge showing number of pending follow-ups for a conversation
class FollowUpBadge extends ConsumerWidget {
  final String conversationId;
  final bool compact;

  const FollowUpBadge({
    Key? key,
    required this.conversationId,
    this.compact = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpsAsync = ref.watch(conversationFollowUpsProvider(conversationId));

    return followUpsAsync.when(
      data: (followUps) {
        if (followUps.isEmpty) {
          return const SizedBox.shrink();
        }

        final overdue = followUps.where((f) => f.isOverdue).length;
        final dueSoon = followUps.where((f) => f.isDueSoon).length;

        if (compact) {
          return _buildCompactBadge(followUps.length, overdue, dueSoon);
        } else {
          return _buildExpandedBadge(followUps.length, overdue, dueSoon);
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCompactBadge(int total, int overdue, int dueSoon) {
    Color color;
    if (overdue > 0) {
      color = Colors.red;
    } else if (dueSoon > 0) {
      color = Colors.orange;
    } else {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notification_important,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedBadge(int total, int overdue, int dueSoon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.task_alt,
            size: 16,
            color: Colors.purple,
          ),
          const SizedBox(width: 6),
          Text(
            '$total follow-up${total != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.purple[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (overdue > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$overdue overdue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

