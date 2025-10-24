import 'package:flutter/material.dart';
import 'package:messageai/features/conversations/widgets/relationship_summary_sheet.dart';

/// Quick access button to see who someone is
class WhoIsThisButton extends StatelessWidget {
  final String conversationId;
  final bool compact;

  const WhoIsThisButton({
    Key? key,
    required this.conversationId,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return compact
        ? IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Who is this?',
            onPressed: () => _showSummary(context),
          )
        : OutlinedButton.icon(
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Who is this?'),
            onPressed: () => _showSummary(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          );
  }

  void _showSummary(BuildContext context) {
    showRelationshipSummary(context, conversationId);
  }
}

