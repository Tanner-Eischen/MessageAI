import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'package:messageai/state/ai_providers.dart';
import 'package:messageai/core/theme/app_theme.dart';

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
              onLongPress: () => _showContextMenu(context, ref),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Check mark for received messages (interpreter feature)
                        if (!isSent)
                          analysisAsync.when(
                            data: (analysis) {
                              // Auto-flag concerning messages or show on all received
                              final showCheckMark = analysis != null && 
                                (analysis.urgencyLevel == 'High' || 
                                 analysis.urgencyLevel == 'Critical' ||
                                 (analysis.contextFlags?['rsd_trigger'] == true));
                              
                              if (showCheckMark) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8, top: 2),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show interpretation
                                      ToneDetailSheet.show(
                                        context,
                                        analysis,
                                        message.body,
                                        message.id,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.psychology_outlined,
                                        size: 16,
                                        color: Color(0xFF7C3AED), // Purple - interpreter feature
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        Expanded(
                          child: Text(
                            message.body,
                            style: TextStyle(
                              color: isSent ? Colors.white : theme.textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tone Badge
                              ToneBadge(
                                analysis: analysis,
                                onTap: () => ToneDetailSheet.show(
                                  context,
                                  analysis,
                                  message.body,
                                  message.id,
                                ),
                              ),
                              // ✅ PHASE 1: RSD Warning Badge (immediate visibility)
                              if (analysis.rsdTriggers?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 14,
                                        color: Colors.orange[800],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'May trigger RSD',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '• Tap for details',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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

  /// Show context menu with AI features and copy/paste options (iPhone-style)
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.read(messageAnalysisProvider(message.id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // iPhone-style popup menu
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Blur background
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              // Center popup
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkGray100.withOpacity(0.95) : AppTheme.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI Features (for received messages)
                      if (!isSent) ...[
                        _buildPopupOption(
                          context,
                          icon: Icons.psychology_outlined,
                          label: 'Analyze Message',
                          color: const Color(0xFF7C3AED), // Purple - interpreter
                          isDark: isDark,
                          isFirst: true,
                          onTap: () {
                            Navigator.pop(context);
                            analysisAsync.whenData((analysis) {
                              if (analysis != null) {
                                ToneDetailSheet.show(context, analysis, message.body, message.id);
                              }
                            });
                          },
                        ),
                        Divider(height: 1, color: isDark ? AppTheme.darkGray300 : AppTheme.gray300),
                      ],
                      
                      // Copy
                      _buildPopupOption(
                        context,
                        icon: Icons.content_copy,
                        label: 'Copy',
                        color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                        isDark: isDark,
                        isFirst: isSent,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.body));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      
                      // Retry (if unsent)
                      if (isSent && !message.isSynced) ...[
                        Divider(height: 1, color: isDark ? AppTheme.darkGray300 : AppTheme.gray300),
                        _buildPopupOption(
                          context,
                          icon: Icons.refresh,
                          label: 'Retry',
                          color: AppTheme.accentOrange,
                          isDark: isDark,
                          isLast: true,
                          onTap: () {
                            Navigator.pop(context);
                            onRetry?.call();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPopupOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
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
