import 'package:flutter/material.dart';
import 'package:messageai/services/message_service.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/services/presence_service.dart';
import 'package:messageai/services/realtime_message_service.dart';
import 'package:messageai/services/typing_indicator_service.dart';
import 'package:messageai/services/context_preloader_service.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/receipt_dao.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/widgets/user_avatar.dart';
import 'package:messageai/widgets/sliding_panel.dart';
import 'package:messageai/features/messages/widgets/message_list_panel.dart';
import 'package:messageai/features/messages/widgets/ai_insights_panel.dart';
import 'package:messageai/features/conversations/widgets/context_preview_card.dart';
import 'package:messageai/features/conversations/widgets/who_is_this_button.dart';
import 'package:messageai/models/conversation_context.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
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
  final _contextService = ContextPreloaderService();
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
  Set<String> _onlineUsers = {};
  double _panelPosition = 0.8; // Track sliding panel position (0.0 = down, 1.0 = up)
  ConversationContext? _conversationContext;

  @override
  void initState() {
    super.initState();
    _currentUserId = _messageService.getCurrentUserId();
    
    // Sync messages from backend first, then load
    _messagesFuture = _messageService.getMessagesByConversation(
      widget.conversationId,
      syncFirst: true,
    );
    _participantsFuture = _conversationService.getParticipants(widget.conversationId);
    
    // Initialize real-time features
    _initializeRealtime();
    
    // Load receipts
    _loadReceipts();
    
    // Load conversation context
    _loadContext();
    
    // Mark messages as read when opening conversation
    _messagesFuture.then((_) => _markMessagesAsRead());
    
    // Listen for text changes to send typing indicators
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadContext() async {
    try {
      final context = await _contextService.loadContext(widget.conversationId);
      if (mounted) {
        setState(() {
          _conversationContext = context;
        });
      }
    } catch (e) {
      print('Error loading context: $e');
    }
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

  Future<void> _markMessagesAsRead() async {
    try {
      if (_currentUserId == null) return;
      
      // Get all messages
      final messages = await _messagesFuture;
      
      // Find unread messages from others
      for (final message in messages) {
        // Skip own messages
        if (message.senderId == _currentUserId) continue;
        
        // Check if we already have a read receipt
        final existingReceipts = _receiptsCache[message.id] ?? [];
        final hasReadReceipt = existingReceipts.any((r) => 
          r.userId == _currentUserId && r.status == 'read'
        );
        
        if (!hasReadReceipt) {
          await _createReadReceipt(message.id);
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _createReadReceipt(String messageId) async {
    try {
      if (_currentUserId == null) return;
      
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Check if receipt already exists
      final existingReceipt = await _receiptDao.getReceipt(messageId, _currentUserId!);
      
      if (existingReceipt != null) {
        // Update existing receipt to "read"
        await _receiptDao.updateReceiptStatus(messageId, _currentUserId!, 'read');
        
        // Sync to backend
        final supabase = SupabaseClientProvider.client;
        await supabase.from('message_receipts')
          .update({
            'status': 'read',
            'at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
          })
          .eq('message_id', messageId)
          .eq('user_id', _currentUserId!);
      } else {
        // Create new receipt
        final receiptId = const Uuid().v4();
        final receipt = Receipt(
          id: receiptId,
          messageId: messageId,
          userId: _currentUserId!,
          status: 'read',
          createdAt: now,
          updatedAt: now,
          isSynced: false,
        );
        
        await _receiptDao.addReceipt(receipt);
        
        final supabase = SupabaseClientProvider.client;
        await supabase.from('message_receipts').insert({
          'id': receiptId,
          'message_id': messageId,
          'user_id': _currentUserId,
          'status': 'read',
          'at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        });
        
        await _receiptDao.markReceiptAsSynced(receiptId);
      }
    } catch (e) {
      print('Error creating read receipt: $e');
    }
  }

  Timer? _pollTimer;
  Timer? _presenceCheckTimer;

  Future<void> _initializeRealtime() async {
    try {
      // Subscribe to presence updates
      await _presenceService.subscribeToPresence(widget.conversationId);
      // Set current user as online
      await _presenceService.setPresenceStatus(widget.conversationId, true);
      
      // Poll presence status every 2 seconds to update UI
      _presenceCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            _onlineUsers = _presenceService.getOnlineUsers(widget.conversationId);
          });
        }
      });
      
      // Subscribe to real-time messages
      _realtimeService.subscribeToMessages(widget.conversationId).listen((messages) {
        setState(() {
          _messagesFuture = Future.value(messages);
        });
        _loadReceipts();
        _markMessagesAsRead(); // Mark new messages as read
      });
      
      // Subscribe to real-time receipts
      _realtimeService.subscribeToReceipts(widget.conversationId).listen((receipts) {
        print('📬 Receipt update: ${receipts.length} total receipts');
        setState(() {
          _receiptsCache.clear();
          for (final receipt in receipts) {
            if (!_receiptsCache.containsKey(receipt.messageId)) {
              _receiptsCache[receipt.messageId] = [];
            }
            _receiptsCache[receipt.messageId]!.add(receipt);
            print('   - Message ${receipt.messageId.substring(0, 8)}: ${receipt.status} by ${receipt.userId.substring(0, 8)}');
          }
        });
      });
      
      // Subscribe to typing indicators
      _typingService.subscribeToTyping(widget.conversationId).listen((typingUserIds) {
        setState(() {
          _typingUsers = typingUserIds;
        });
      });
    } catch (e) {
      print('❌ Realtime init failed: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _typingTimer?.cancel();
    _pollTimer?.cancel();
    _presenceCheckTimer?.cancel();
    // Set user as offline before leaving
    _presenceService.setPresenceStatus(widget.conversationId, false);
    // Clean up realtime subscriptions
    _presenceService.unsubscribeFromPresence(widget.conversationId);
    _realtimeService.unsubscribeFromMessages(widget.conversationId);
    _realtimeService.unsubscribeFromReceipts(widget.conversationId);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
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
                if (_onlineUsers.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${_onlineUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversationTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_onlineUsers.isNotEmpty)
                    Text(
                      '${_onlineUsers.length} online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        elevation: 1,
        actions: [
          WhoIsThisButton(
            conversationId: widget.conversationId,
            compact: true,
          ),
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
      body: FutureBuilder<List<Message>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final messages = snapshot.data ?? [];

          return Column(
            children: [
              // Context Preview at top
              if (_conversationContext != null)
                ContextPreviewCard(
                  context: _conversationContext!,
                  onTap: () {
                    // Could expand to show more details or scroll
                  },
                ),
              
              // Main message area
              Expanded(
                child: Stack(
                  children: [
                    // Background: AI Insights Panel
                    AIInsightsPanel(
                      conversationId: widget.conversationId,
                      messages: messages,
                      panelPosition: _panelPosition,
                    ),
                    
                    // Foreground: Sliding Message Panel
                    SlidingPanel(
                      onSlide: (position) {
                        setState(() {
                          _panelPosition = position;
                        });
                      },
                      child: MessageListPanel(
                        messages: messages,
                        currentUserId: _currentUserId,
                        receiptsCache: _receiptsCache,
                        typingUsers: _typingUsers,
                        onlineUsers: _onlineUsers,
                        messageController: _messageController,
                        isSending: _isSending,
                        isUploadingImage: _isUploadingImage,
                        selectedImage: _selectedImage,
                        onSendMessage: _sendMessage,
                        onPickImage: _pickImage,
                        onClearImage: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                    // Force refresh participants from backend
                    this.setState(() {
                      _participantsFuture = _conversationService.getParticipants(
                        widget.conversationId, 
                        syncFirst: true,  // Force sync from backend
                      );
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
                        
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _conversationService.getParticipantProfile(participant.userId),
                          builder: (context, profileSnapshot) {
                            final profile = profileSnapshot.data;
                            final displayName = profile?['email'] as String? ?? 
                                              profile?['username'] as String? ?? 
                                              profile?['display_name'] as String? ??
                                              participant.userId.substring(0, 8);
                            final avatarUrl = profile?['avatar_url'] as String?;
                            final initial = displayName.isNotEmpty 
                                ? displayName[0].toUpperCase() 
                                : 'U';
                            
                            return ListTile(
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Text(initial)
                                        : null,
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
                              title: Text(displayName),
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

}
