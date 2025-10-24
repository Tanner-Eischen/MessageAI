import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'package:messageai/state/ai_providers.dart';
import 'package:messageai/widgets/user_avatar.dart';

/// Panel containing the message list and compose bar
/// This widget slides up and down over the AI insights background
class MessageListPanel extends ConsumerWidget {
  final List<Message> messages;
  final String? currentUserId;
  final Map<String, List<Receipt>> receiptsCache;
  final Set<String> typingUsers;
  final Set<String> onlineUsers;
  final TextEditingController messageController;
  final bool isSending;
  final bool isUploadingImage;
  final XFile? selectedImage;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Message list
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingS,
                    horizontal: AppTheme.spacingXS,
                  ),
                  itemCount: messages.length + (typingUsers.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator as first item (at bottom)
                    if (index == 0 && typingUsers.isNotEmpty) {
                      return _buildTypingIndicator(context, isDark);
                    }
                    
                    // Adjust index if typing indicator is showing
                    final messageIndex = typingUsers.isNotEmpty ? index - 1 : index;
                    final message = messages[messages.length - 1 - messageIndex];
                    final isOwn = message.senderId == currentUserId;
                    final isOnline = onlineUsers.contains(message.senderId);

                    return _buildMessageBubble(
                      context,
                      ref,
                      message,
                      isOwn,
                      isOnline,
                      isDark,
                    );
                  },
                ),
        ),
        
        // Compose bar
        _buildComposeBar(context, isDark),
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
    // Fetch AI analysis for this message
    final analysisAsync = ref.watch(messageAnalysisProvider(message.id));
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
          
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            margin: EdgeInsets.only(
              left: isOwn ? 64 : 0,
              right: isOwn ? AppTheme.spacingS : 64,
              top: AppTheme.spacingXXS,
              bottom: AppTheme.spacingXXS,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: isOwn
                  ? (isDark ? AppTheme.darkGray300 : AppTheme.gray200)
                  : (isDark ? AppTheme.darkGray100 : AppTheme.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.radiusXL),
                topRight: const Radius.circular(AppTheme.radiusXL),
                bottomLeft: Radius.circular(isOwn ? AppTheme.radiusXL : AppTheme.radiusXS),
                bottomRight: Radius.circular(isOwn ? AppTheme.radiusXS : AppTheme.radiusXL),
              ),
              border: !isOwn
                  ? Border.all(
                      color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Show image if present
                if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    child: Image.network(
                      message.mediaUrl!,
                      width: 250,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 250,
                          height: 250,
                          color: isDark ? AppTheme.darkGray200 : AppTheme.gray200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 250,
                          height: 250,
                          color: isDark ? AppTheme.darkGray200 : AppTheme.gray200,
                          child: const Icon(Icons.broken_image, size: 50),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXS),
                ],
                
                // Message text
                Text(
                  message.body,
                  style: TextStyle(
                    color: isDark ? AppTheme.white : AppTheme.black,
                    fontSize: AppTheme.fontSizeM,
                    height: AppTheme.lineHeightNormal,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXXS),
                
                // Timestamp and delivery indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXS,
                        color: isDark ? AppTheme.gray600 : AppTheme.gray600,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: AppTheme.spacingXXS),
                      _buildDeliveryIndicator(message),
                    ],
                  ],
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
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator(BuildContext context, bool isDark) {
    final count = typingUsers.length;
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
  
  Widget _buildComposeBar(BuildContext context, bool isDark) {
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
          children: [
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
            
            // Input row
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
                
                const SizedBox(width: AppTheme.spacingS),
                
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
    final receipts = receiptsCache[message.id] ?? [];
    
    // Filter out own receipts (shouldn't exist for sent messages, but just in case)
    final otherReceipts = receipts.where((r) => r.userId != currentUserId).toList();
    
    final hasDelivered = otherReceipts.any((r) => r.status == 'delivered' || r.status == 'read');
    final hasRead = otherReceipts.any((r) => r.status == 'read');

    IconData icon;
    Color color;

    if (hasRead) {
      icon = Icons.done_all;
      color = AppTheme.accentBlue;
    } else if (hasDelivered) {
      icon = Icons.done_all;
      color = AppTheme.gray600;
    } else {
      icon = Icons.done;
      color = AppTheme.gray600;
    }

    return Icon(
      icon,
      size: 14,
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

