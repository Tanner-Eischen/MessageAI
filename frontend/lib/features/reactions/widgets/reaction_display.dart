import 'package:flutter/material.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/services/reaction_service.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class ReactionDisplay extends StatefulWidget {
  final String messageId;
  final VoidCallback? onTap;

  const ReactionDisplay({
    super.key,
    required this.messageId,
    this.onTap,
  });

  @override
  State<ReactionDisplay> createState() => _ReactionDisplayState();
}

class _ReactionDisplayState extends State<ReactionDisplay> {
  final _reactionService = ReactionService();
  final _supabase = SupabaseClientProvider.client;
  Map<String, List<Reaction>> _reactions = {};

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    final reactions = await _reactionService.getReactionsGrouped(widget.messageId);
    if (mounted) {
      setState(() {
        _reactions = reactions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentUserId = _supabase.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: _reactions.entries.map((entry) {
          final emoji = entry.key;
          final reactions = entry.value;
          final count = reactions.length;
          final hasUserReacted = reactions.any((r) => r.userId == currentUserId);

          return InkWell(
            onTap: () async {
              await _reactionService.toggleReaction(
                messageId: widget.messageId,
                emoji: emoji,
              );
              await _loadReactions();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasUserReacted
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasUserReacted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (count > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasUserReacted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
