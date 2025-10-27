import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/widgets/message_bubble.dart';
import 'package:messageai/features/messages/widgets/peek_zone/height_controller.dart';

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
  final PlatformFile? selectedFile;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onClearImage;
  final ScrollController? scrollController;
  final bool showComposeBar;
  final HeightController? heightController;
  final bool _composeBarOnly;

  const MessageListPanel({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.receiptsCache,
    required this.typingUsers,
    required this.onlineUsers,
    required this.messageController,
    required this.isSending,
    required this.isUploadingImage,
    required this.selectedImage,
    required this.selectedFile,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickFile,
    required this.onClearImage,
    this.scrollController,
    this.showComposeBar = true,
    this.heightController,
  })  : _composeBarOnly = false;

  const MessageListPanel.composeBarOnly({
    super.key,
    required this.messageController,
    required this.isSending,
    required this.isUploadingImage,
    required this.selectedImage,
    required this.selectedFile,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickFile,
    required this.onClearImage,
  })  : messages = null,
        currentUserId = null,
        receiptsCache = null,
        typingUsers = null,
        onlineUsers = null,
        scrollController = null,
        showComposeBar = true,
        heightController = null,
        _composeBarOnly = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_composeBarOnly) {
      return _buildComposeBar(context, ref, isDark);
    }
    
    return Container(
      color: isDark ? AppTheme.darkGray200 : const Color(0xFFEFF2FF),
      child: Column(
        children: [
          Expanded(
            child: messages == null || messages!.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkGray300 : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.gray200 : AppTheme.gray700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(
                      top: 44,  // Space for drag handle + margin
                      bottom: AppTheme.spacingS,
                      left: AppTheme.spacingXS,
                      right: AppTheme.spacingXS,
                    ),
                    itemCount: messages!.length + ((typingUsers?.isNotEmpty ?? false) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && (typingUsers?.isNotEmpty ?? false)) {
                        return _buildTypingIndicator(context, isDark);
                      }
                      
                      final messageIndex = (typingUsers?.isNotEmpty ?? false) ? index - 1 : index;
                      final message = messages![messages!.length - 1 - messageIndex];
                      final isOwn = message.senderId == currentUserId;
                      final isOnline = onlineUsers?.contains(message.senderId) ?? false;

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
          
          if (showComposeBar)
            _buildComposeBar(context, ref, isDark),
        ],
      ),
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
    // Get receipts for this message
    final messageReceipts = receiptsCache?[message.id];
    
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: MessageBubble(
              message: message,
              isFromCurrentUser: isOwn,
              isMostRecentReceived: !isOwn && messages != null && messages!.isNotEmpty && messages!.last.id == message.id,
              heightController: heightController,
              receipts: messageReceipts,
            ),
          ),
        ],
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
        color: isDark ? AppTheme.darkGray100 : const Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
            width: 1,
          ),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            
            // File preview
            if (selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkGray200 : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: AppTheme.accentBlue,
                      size: 32,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFile!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.white : AppTheme.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
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
                  ],
                ),
              ),
            ],
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                
                IconButton(
                  onPressed: isUploadingImage || isSending ? null : onPickFile,
                  icon: Icon(
                    Icons.attach_file,
                    color: isUploadingImage || isSending
                        ? (isDark ? AppTheme.gray600 : AppTheme.gray400)
                        : AppTheme.accentBlue,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                ),
                
                const SizedBox(width: AppTheme.spacingXXS),
                
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
