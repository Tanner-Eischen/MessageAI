import 'package:flutter/material.dart';
import 'package:messageai/services/message_service.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/services/presence_service.dart';
import 'package:messageai/services/realtime_message_service.dart';
import 'package:messageai/services/typing_indicator_service.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/receipt_dao.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

class MessageScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const MessageScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageService = MessageService();
  final _conversationService = ConversationService();
  final _presenceService = PresenceService();
  final _realtimeService = RealTimeMessageService();
  final _typingService = TypingIndicatorService();
  final _receiptDao = AppDb.instance.receiptDao;
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();
  late Future<List<Message>> _messagesFuture;
  late Future<List<Participant>> _participantsFuture;
  bool _isSending = false;
  bool _isUploadingImage = false;
  String? _currentUserId;
  Map<String, List<Receipt>> _receiptsCache = {};
  Set<String> _typingUsers = {};
  Timer? _typingTimer;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _currentUserId = _messageService.getCurrentUserId();
    _messagesFuture = _messageService.getMessagesByConversation(widget.conversationId);
    _participantsFuture = _conversationService.getParticipants(widget.conversationId);
    
    // Initialize real-time features
    _initializeRealtime();
    
    // Load receipts
    _loadReceipts();
    
    // Listen for text changes to send typing indicators
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadReceipts() async {
    try {
      final receipts = await _receiptDao.getReceiptsByConversation(widget.conversationId);
      setState(() {
        _receiptsCache.clear();
        for (final receipt in receipts) {
          if (!_receiptsCache.containsKey(receipt.messageId)) {
            _receiptsCache[receipt.messageId] = [];
          }
          _receiptsCache[receipt.messageId]!.add(receipt);
        }
      });
    } catch (e) {
      print('Error loading receipts: $e');
    }
  }

  Future<void> _initializeRealtime() async {
    try {
      // Subscribe to presence updates
      await _presenceService.subscribeToPresence(widget.conversationId);
      // Set current user as online
      await _presenceService.setPresenceStatus(widget.conversationId, true);
      
      // Subscribe to real-time messages
      _realtimeService.subscribeToMessages(widget.conversationId).listen((messages) {
        setState(() {
          _messagesFuture = Future.value(messages);
        });
        // Reload receipts when messages update
        _loadReceipts();
      });
      
      // Subscribe to typing indicators
      _typingService.subscribeToTyping(widget.conversationId).listen((typingUserIds) {
        setState(() {
          _typingUsers = typingUserIds;
        });
      });
    } catch (e) {
      print('Error initializing realtime: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _typingTimer?.cancel();
    // Clean up realtime subscriptions
    _presenceService.unsubscribeFromPresence(widget.conversationId);
    _realtimeService.unsubscribeFromMessages(widget.conversationId);
    _typingService.unsubscribeFromTyping(widget.conversationId);
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      // User is typing
      _typingService.sendTypingIndicator(widget.conversationId, true);
      
      // Reset the timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        // Stop typing after 2 seconds of inactivity
        _typingService.sendTypingIndicator(widget.conversationId, false);
      });
    } else {
      // User cleared text, stop typing
      _typingTimer?.cancel();
      _typingService.sendTypingIndicator(widget.conversationId, false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    setState(() => _isUploadingImage = true);
    
    try {
      final userId = SupabaseClientProvider.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final fileBytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final path = '$userId/$fileName';
      
      await SupabaseClientProvider.client.storage
          .from('media')
          .uploadBinary(path, fileBytes);
      
      final url = SupabaseClientProvider.client.storage
          .from('media')
          .getPublicUrl(path);
      
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final hasText = messageText.isNotEmpty;
    final hasImage = _selectedImage != null;
    
    if (!hasText && !hasImage) return;
    if (_isSending || _isUploadingImage) return;

    // Clear input immediately for better UX
    _messageController.clear();
    final imageToSend = _selectedImage;
    setState(() {
      _selectedImage = null;
    });
    
    // Stop typing indicator when message is sent
    _typingTimer?.cancel();
    _typingService.sendTypingIndicator(widget.conversationId, false);

    setState(() => _isSending = true);

    try {
      String? mediaUrl;
      
      // Upload image if present
      if (imageToSend != null) {
        mediaUrl = await _uploadImage(imageToSend);
        if (mediaUrl == null) {
          throw Exception('Failed to upload image');
        }
      }
      
      await _messageService.sendMessage(
        conversationId: widget.conversationId,
        body: hasText ? messageText : '📷 Photo',
        mediaUrl: mediaUrl,
      );

      setState(() {
        _messagesFuture = _messageService.getMessagesByConversation(widget.conversationId);
      });
      
      // Reload receipts to update delivery status
      _loadReceipts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        _messageController.text = messageText;
        if (imageToSend != null) {
          setState(() {
            _selectedImage = imageToSend;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.group,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.conversationTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddParticipantsDialog,
            tooltip: 'Add participants',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showParticipantsInfo(context),
            tooltip: 'Options',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing indicator as first item (at bottom)
                    if (index == 0 && _typingUsers.isNotEmpty) {
                      return _buildTypingIndicator();
                    }
                    
                    // Adjust index if typing indicator is showing
                    final messageIndex = _typingUsers.isNotEmpty ? index - 1 : index;
                    final message = messages[messages.length - 1 - messageIndex];
                    final isOwn = message.senderId == _currentUserId;

                    return Align(
                      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: EdgeInsets.only(
                          left: isOwn ? 64 : 8,
                          right: isOwn ? 8 : 64,
                          top: 2,
                          bottom: 2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isOwn
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(8),
                            topRight: const Radius.circular(8),
                            bottomLeft: Radius.circular(isOwn ? 8 : 0),
                            bottomRight: Radius.circular(isOwn ? 0 : 8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            // Show image if present
                            if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  message.mediaUrl!,
                                  width: 250,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 250,
                                      height: 250,
                                      color: Colors.grey[300],
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
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, size: 50),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              message.body,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (isOwn) ...[
                                  const SizedBox(width: 4),
                                  _buildDeliveryIndicator(message, isOwn),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: isDark ? const Color(0xFF1E2A30) : Colors.white,
            child: Column(
              children: [
                // Show selected image preview
                if (_selectedImage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
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
                    // Image picker button
                    IconButton(
                      onPressed: _isUploadingImage || _isSending ? null : _pickImage,
                      icon: Icon(
                        Icons.image,
                        color: _isUploadingImage || _isSending
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A373F) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.transparent : Colors.grey[300]!,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isSending && !_isUploadingImage,
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: (_isSending || _isUploadingImage) ? null : _sendMessage,
                        icon: (_isSending || _isUploadingImage)
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showAddParticipantsDialog() {
    final emailController = TextEditingController();
    bool isSearching = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Participant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  helperText: 'Example: user@example.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSearching ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email')),
                  );
                  return;
                }

                setState(() => isSearching = true);

                try {
                  // Add participant by email using database function
                  final response = await SupabaseClientProvider.client
                      .rpc('add_participant_by_email', params: {
                    'p_conversation_id': widget.conversationId,
                    'p_email': email,
                  });

                  final result = response as Map<String, dynamic>;
                  
                  if (result['success'] == false) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['error'] ?? 'Failed to add participant')),
                      );
                    }
                    setState(() => isSearching = false);
                    return;
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    this.setState(() {
                      _participantsFuture = _conversationService.getParticipants(widget.conversationId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added $email to conversation')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                  setState(() => isSearching = false);
                }
              },
              child: isSearching 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FutureBuilder<List<Participant>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final participants = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants (${participants.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (participants.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No participants yet'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        final isOnline = _presenceService.isUserOnline(
                          widget.conversationId,
                          participant.userId,
                        );
                        
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                child: Text(
                                  participant.userId[0].toUpperCase(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(participant.userId),
                          subtitle: Text(
                            isOnline
                                ? (participant.isAdmin ? 'Admin • Online' : 'Member • Online')
                                : (participant.isAdmin ? 'Admin • Offline' : 'Member • Offline'),
                          ),
                          trailing: participant.userId != _currentUserId
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _removeParticipant(participant.userId);
                                  },
                                )
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _removeParticipant(String userId) async {
    try {
      await _conversationService.removeParticipant(
        widget.conversationId,
        userId,
      );
      setState(() {
        _participantsFuture = _conversationService.getParticipants(widget.conversationId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildDeliveryIndicator(Message message, bool isOwn) {
    if (!isOwn) return const SizedBox.shrink();

    final receipts = _receiptsCache[message.id] ?? [];
    final hasDelivered = receipts.any((r) => r.status == 'delivered' || r.status == 'read');
    final hasRead = receipts.any((r) => r.status == 'read');

    IconData icon;
    Color color;

    if (hasRead) {
      // Double check, blue - message read
      icon = Icons.done_all;
      color = const Color(0xFF53BDEB); // WhatsApp blue for read receipts
    } else if (hasDelivered) {
      // Double check, gray - message delivered
      icon = Icons.done_all;
      color = Colors.grey[600]!;
    } else {
      // Single check, gray - message sent
      icon = Icons.done;
      color = Colors.grey[600]!;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Widget _buildTypingIndicator() {
    final count = _typingUsers.length;
    final text = count == 1 
        ? 'Someone is typing...' 
        : '$count people are typing...';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: _TypingAnimation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation();

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
                color: Colors.grey[600]!.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
