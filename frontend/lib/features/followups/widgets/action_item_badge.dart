import 'package:flutter/material.dart';

/// Badge showing follow-up count in conversations
class ActionItemBadge extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const ActionItemBadge({
    Key? key,
    required this.count,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notification_important,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              '$count follow-up${count > 1 ? "s" : ""}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

