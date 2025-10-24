import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'package:messageai/state/ai_providers.dart';

/// Widget to display a single message with AI analysis
class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isSent;
  final bool isLoading;
  final VoidCallback? onRetry;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSent,
    this.isLoading = false,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Fetch AI analysis for this message
    final analysisAsync = ref.watch(messageAnalysisProvider(message.id));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  message.senderId.isNotEmpty 
                      ? message.senderId[0].toUpperCase() 
                      : 'U',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: isSent && !message.isSynced ? onRetry : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.image,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Text(
                      message.body,
                      style: TextStyle(
                        color: isSent ? Colors.white : theme.textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(DateTime.fromMillisecondsSinceEpoch(
                              message.createdAt * 1000,
                            )),
                            style: TextStyle(
                              color: isSent 
                                  ? Colors.white70 
                                  : theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                          if (isSent) ...[
                            const SizedBox(width: 4),
                            if (isLoading)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white70,
                                  ),
                                ),
                              )
                            else if (message.isSynced)
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: Colors.white70,
                              )
                            else
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.white70,
                              ),
                          ],
                        ],
                      ),
                    ),
                    // AI Analysis Badge (shows tone analysis if available)
                    analysisAsync.when(
                      data: (analysis) {
                        if (analysis == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ToneBadge(
                            analysis: analysis,
                            onTap: () => ToneDetailSheet.show(
                              context,
                              analysis,
                              message.body,
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSent)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
