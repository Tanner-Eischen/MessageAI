import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/widgets/draft_feedback_panel.dart';
import 'package:messageai/features/messages/widgets/message_bubble.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'package:messageai/state/ai_providers.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/widgets/user_avatar.dart';

/// Panel containing the message list and compose bar
/// This widget slides up and down over the AI insights background
class MessageListPanel extends ConsumerWidget {
  final List<Message>? messages;
  final String? currentUserId;
  final Map<String, List<Receipt>>? receiptsCache;
  final Set<String>? typingUsers;
  final Set<String>? onlineUsers;
  final TextEditingController messageController;
  final bool isSending;
  final bool isUploadingImage;
  final XFile? selectedImage;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final ScrollController? scrollController; // For DraggableScrollableSheet
  final bool showComposeBar; // Whether to show the compose bar
  final bool _composeBarOnly; // Internal flag for compose bar only mode

  const MessageListPanel({
    Key? key,
    required this.messages,
    required this.currentUserId,
    required this.receiptsCache,
    required this.typingUsers,
    required this.onlineUsers,
    required this.messageController,
    required this.isSending,
    required this.isUploadingImage,
    required this.selectedImage,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onClearImage,
    this.scrollController,
    this.showComposeBar = true,
  })  : _composeBarOnly = false,
        super(key: key);

  // Constructor for compose bar only (pinned at bottom)
  const MessageListPanel.composeBarOnly({
    Key? key,
    required this.messageController,
    required this.isSending,
    required this.isUploadingImage,
    required this.selectedImage,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onClearImage,
  })  : messages = null,
        currentUserId = null,
        receiptsCache = null,
        typingUsers = null,
        onlineUsers = null,
        scrollController = null,
        showComposeBar = true,
        _composeBarOnly = true,
        super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // If compose bar only mode, just return the compose bar
    if (_composeBarOnly) {
      return _buildComposeBar(context, ref, isDark);
    }
    
    // Otherwise, show message list and optionally compose bar
    return Column(
      children: [
        // Message list
        Expanded(
          child: messages == null || messages!.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  controller: scrollController, // Use provided scroll controller for dragging
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingS,
                    horizontal: AppTheme.spacingXS,
                  ),
                  itemCount: messages!.length + ((typingUsers?.isNotEmpty ?? false) ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator as first item (at bottom)
                    if (index == 0 && (typingUsers?.isNotEmpty ?? false)) {
                      return _buildTypingIndicator(context, isDark);
                    }
                    
                    // Adjust index if typing indicator is showing
                    final messageIndex = (typingUsers?.isNotEmpty ?? false) ? index - 1 : index;
                    final message = messages![messages!.length - 1 - messageIndex];
                    final isOwn = message.senderId == currentUserId;
                    final isOnline = onlineUsers?.contains(message.senderId) ?? false;

                    // 🔧 FIXED: Add key based on message ID to prevent unnecessary rebuilds
                    return KeyedSubtree(
                      key: ValueKey(message.id),
                      child: _buildMessageBubble(
                        context,
                        ref,
                        message,
                        isOwn,
                        isOnline,
                        isDark,
                      ),
                    );
                  },
                ),
        ),
        
        // Compose bar (conditionally shown)
        if (showComposeBar)
          _buildComposeBar(context, ref, isDark),
      ],
    );
  }
  
  Widget _buildMessageBubble(
    BuildContext context,
    WidgetRef ref,
    Message message,
    bool isOwn,
    bool isOnline,
    bool isDark,
  ) {
    // 🔧 FIXED: Use the actual MessageBubble widget instead of inline building!
    // This ensures all the analysis event listeners and UI updates work
    
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show avatar for other users' messages (left side)
          if (!isOwn) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.spacingS,
                right: AppTheme.spacingXXS,
                bottom: AppTheme.spacingXXS,
              ),
              child: Stack(
                children: [
                  UserAvatar(
                    userId: message.senderId,
                    fallbackText: message.senderId.substring(0, 1).toUpperCase(),
                    radius: 16,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.accentGreen : AppTheme.gray500,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppTheme.black : AppTheme.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 🔧 FIXED: Use MessageBubble widget instead of inline GestureDetector
          // 🟣 UPDATED: Add sparkle indicator to the most recent received message
          Flexible(
            child: MessageBubble(
              message: message,
              isFromCurrentUser: isOwn,
              isMostRecentReceived: !isOwn && messages != null && messages!.isNotEmpty && messages!.last.id == message.id,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show context menu with AI features and copy/paste options
  void _showMessageContextMenu(
    BuildContext context,
    WidgetRef ref,
    Message message,
    bool isOwn,
    bool isDark,
  ) {
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
                      if (!isOwn) ...[
                        _buildPopupOption(
                          context,
                          ref,
                          message,
                          icon: Icons.psychology_outlined,
                          label: 'Analyze Message',
                          color: const Color(0xFF7C3AED), // Purple - interpreter
                          isDark: isDark,
                          isFirst: true,
                        ),
                        Divider(height: 1, color: isDark ? AppTheme.darkGray300 : AppTheme.gray300),
                      ],
                      
                      // Copy
                      _buildCopyOption(
                        context,
                        message,
                        isDark: isDark,
                        isFirst: isOwn,
                      ),
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
    BuildContext context,
    WidgetRef ref,
    Message message, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          // Trigger analysis if it doesn't exist
          final requestAnalysis = ref.read(requestAnalysisProvider);
          final analysis = await requestAnalysis(message.id, message.body);
          
          if (context.mounted) {
            Navigator.pop(context); // Close loading
            
            if (analysis != null) {
              // 🆕 Removed: Provider invalidation no longer needed
              // Analysis is now handled in MessageBubble widget for manual long-press only
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis complete - view in message details'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to analyze message. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
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
  
  Widget _buildCopyOption(
    BuildContext context,
    Message message, {
    required bool isDark,
    bool isFirst = false,
  }) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: message.body));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: const Radius.circular(14),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_copy, size: 22, color: isDark ? AppTheme.gray400 : AppTheme.gray700),
            const SizedBox(width: 12),
            Text(
              'Copy',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.gray400 : AppTheme.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypingIndicator(BuildContext context, bool isDark) {
    final count = typingUsers?.length ?? 0;
    final text = count == 1 
        ? 'Someone is typing...' 
        : '$count people are typing...';
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkGray100 : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                    fontSize: AppTheme.fontSizeS,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: _TypingAnimation(isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComposeBar(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ PHASE 2: Draft Feedback Panel (constrained height, scrollable internally)
             Consumer(
               builder: (context, ref, child) {
                 final draftAnalysis = ref.watch(draftAnalysisProvider);
                 
                 return draftAnalysis.when(
                   data: (analysis) {
                     if (analysis == null) return const SizedBox.shrink();
                     
                     return ConstrainedBox(
                       constraints: BoxConstraints(
                         maxHeight: MediaQuery.of(context).size.height * 0.3,
                       ),
                       child: SingleChildScrollView(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             DraftFeedbackPanel(
                               analysis: analysis,
                               draftMessage: messageController.text,
                               onApplySuggestion: (suggestion) {
                                 messageController.text = suggestion;
                               },
                               onTemplateSelected: (template) {
                                 messageController.text = template;
                               },
                               onClose: () {
                                 ref.read(draftAnalysisProvider.notifier).clear();
                               },
                             ),
                             const SizedBox(height: AppTheme.spacingS),
                           ],
                         ),
                       ),
                     );
                   },
                   loading: () => Padding(
                     padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
                     child: const LinearProgressIndicator(
                       backgroundColor: Colors.transparent,
                     ),
                   ),
                   error: (_, __) => const SizedBox.shrink(),
                 );
               },
             ),
            
            // Show selected image preview
            if (selectedImage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      child: Image.file(
                        File(selectedImage!.path),
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: AppTheme.spacingXXS,
                      right: AppTheme.spacingXXS,
                      child: GestureDetector(
                        onTap: onClearImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingXXS),
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Input row (always at bottom)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image picker button
                IconButton(
                  onPressed: isUploadingImage || isSending ? null : onPickImage,
                  icon: Icon(
                    Icons.image,
                    color: isUploadingImage || isSending
                        ? (isDark ? AppTheme.gray600 : AppTheme.gray400)
                        : AppTheme.accentBlue,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                ),
                
                const SizedBox(width: AppTheme.spacingXXS),
                
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkGray200 : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(
                        color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                    ),
                    child: TextField(
                      controller: messageController,
                      enabled: !isSending && !isUploadingImage,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacingS,
                        ),
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingXXS),
                
                // ✅ PHASE 2: Check Message Button (Draft Analysis)
                Consumer(
                  builder: (context, ref, child) {
                    final hasText = messageController.text.trim().isNotEmpty;
                    
                    return IconButton(
                      onPressed: !hasText ? null : () {
                        ref.read(draftAnalysisProvider.notifier).analyzeDraft(
                          draftMessage: messageController.text,
                        );
                      },
                      icon: Icon(
                        Icons.auto_awesome,
                        color: !hasText
                            ? (isDark ? AppTheme.gray600 : AppTheme.gray400)
                            : Colors.blue,
                      ),
                      tooltip: 'Check message confidence',
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                    );
                  },
                ),
                
                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.white : AppTheme.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: (isSending || isUploadingImage) ? null : onSendMessage,
                    icon: (isSending || isUploadingImage)
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? AppTheme.black : AppTheme.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            size: 20,
                            color: isDark ? AppTheme.black : AppTheme.white,
                          ),
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeliveryIndicator(Message message) {
    // Default to single checkmark if no receipts
    final receipts = receiptsCache?[message.id] ?? [];
    
    // Filter out own receipts (shouldn't exist for sent messages, but just in case)
    final otherReceipts = receipts.where((r) => r.userId != currentUserId).toList();
    
    // Check receipt statuses (case-insensitive to be safe)
    final hasRead = otherReceipts.any((r) => r.status.toLowerCase() == 'read');
    final hasDelivered = otherReceipts.any((r) => r.status.toLowerCase() == 'delivered');

    IconData icon;
    Color color;

    // Always show at least a single checkmark for sent messages
    if (hasRead) {
      icon = Icons.done_all; // Double checkmark for read
      color = AppTheme.accentBlue;
    } else if (hasDelivered || receipts.isNotEmpty) {
      icon = Icons.done_all; // Double checkmark for delivered
      color = AppTheme.gray600;
    } else {
      icon = Icons.done; // Single checkmark for sent (default)
      color = AppTheme.gray600;
    }

    return Icon(
      icon,
      size: 16, // Slightly larger for better visibility
      color: color,
    );
  }
  
  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animated typing indicator dots
class _TypingAnimation extends StatefulWidget {
  final bool isDark;
  
  const _TypingAnimation({required this.isDark});

  @override
  State<_TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: (widget.isDark ? AppTheme.gray600 : AppTheme.gray600)
                    .withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

