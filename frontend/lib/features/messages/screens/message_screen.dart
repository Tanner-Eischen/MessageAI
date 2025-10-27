import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:messageai/services/message_service.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/services/presence_service.dart';
import 'package:messageai/services/realtime_message_service.dart';
import 'package:messageai/services/typing_indicator_service.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/features/messages/widgets/message_list_panel.dart';
import 'package:messageai/features/messages/widgets/peek_zone/ai_insights_background.dart';
import 'package:messageai/features/messages/widgets/peek_zone/dynamic_peek_zone.dart';
import 'package:messageai/features/messages/widgets/peek_zone/height_controller.dart';
import 'package:messageai/features/messages/widgets/test_menu_fab.dart';
import 'package:messageai/models/peek_content.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

class MessageScreen extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const MessageScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

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
  late HeightController _heightController;
  bool _isSending = false;
  bool _isUploadingImage = false;
  String? _currentUserId;
  final Map<String, List<Receipt>> _receiptsCache = {};
  Set<String> _typingUsers = {};
  Timer? _typingTimer;
  Timer? _pollTimer;
  Timer? _presenceCheckTimer;
  XFile? _selectedImage;
  PlatformFile? _selectedFile;
  Set<String> _onlineUsers = {};
  
  // Real-time subscriptions (stored to prevent garbage collection)
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<Receipt>>? _receiptsSubscription;
  StreamSubscription<Set<String>>? _typingSubscription;

  @override
  void initState() {
    super.initState();
    
    // Get current user first
    _currentUserId = _messageService.getCurrentUserId();
    
    // Create fallback default content immediately
    final fallbackContent = RelationshipContextPeek(
      sender: const Participant(
        id: '',
        conversationId: '',
        userId: 'Loading...',
        joinedAt: 0,
        isAdmin: false,
        isSynced: false,
      ),
      relationship: 'Contact',
      communicationStyle: 'Analyzing patterns...',
      lastMessage: 'Recently',
      reliabilityScore: 0.0,
    );
    
    // Initialize HeightController with fallback content
    _heightController = HeightController(defaultContent: fallbackContent);
    print('✅ [SCREEN] HeightController initialized with fallback content');
    
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
    
    // Load conversation context (will update HeightController with real data)
    _loadContext();
    
    // Mark messages as read when opening conversation
    _messagesFuture.then((_) => _markMessagesAsRead());
    
    // Listen for text changes to send typing indicators
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadContext() async {
    try {
      print('🔄 [SCREEN] Loading context for conversation: ${widget.conversationId}');
      
      // Load participants and set up default relationship context for peek zone
      try {
        final participants = await _participantsFuture;
        if (participants.isNotEmpty && mounted) {
          // Get the first participant (other than current user) as the primary contact
          final contact = participants.firstWhere(
            (p) => p.userId != _currentUserId,
            orElse: () => participants.first,
          );
          
          // Create default relationship context for peek zone
          final relationshipContent = RelationshipContextPeek(
            sender: contact,
            relationship: 'Contact', // Default, would be enhanced with real data
            communicationStyle: 'Loading patterns...',
            lastMessage: 'Recently',
            reliabilityScore: 80.0, // Default, would be calculated from history
          );
          
          _heightController.setDefaultContent(relationshipContent);
          print('✅ [SCREEN] Peek Zone content updated for: ${contact.userId}');
        }
      } catch (e) {
        print('⚠️ [SCREEN] Could not load participants for peek zone: $e');
      }
    } catch (e) {
      print('❌ [SCREEN] Error loading context: $e');
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

  void _initializeRealtime() {
    try {
      print('🔔 Initializing real-time features...');
      
      // Subscribe to presence
      _presenceService.setPresenceStatus(widget.conversationId, true);
      
      // Poll presence status every 2 seconds to update UI
      _presenceCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (mounted) {
          setState(() {
            _onlineUsers = _presenceService.getOnlineUsers(widget.conversationId);
          });
        }
      });
      
      // Subscribe to real-time messages and STORE THE SUBSCRIPTION
      _messagesSubscription = _realtimeService.subscribeToMessages(widget.conversationId).listen((messages) {
        if (mounted) {
          _loadReceipts();
          _markMessagesAsRead(); // Mark new messages as read
        }
      });
      
      // Subscribe to real-time receipts and STORE THE SUBSCRIPTION
      _receiptsSubscription = _realtimeService.subscribeToReceipts(widget.conversationId).listen((receipts) {
        if (mounted) {
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
        }
      });
      
      // Subscribe to typing indicators and STORE THE SUBSCRIPTION
      _typingSubscription = _typingService.subscribeToTyping(widget.conversationId).listen((typingUserIds) {
        if (mounted) {
          setState(() {
            _typingUsers = typingUserIds;
          });
        }
      });
    } catch (e) {
      print('❌ Realtime init failed: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    
    // Cancel all timers
    _typingTimer?.cancel();
    _pollTimer?.cancel();
    _presenceCheckTimer?.cancel();
    
    // Set user as offline before leaving
    _presenceService.setPresenceStatus(widget.conversationId, false);
    
    // Cancel all real-time subscriptions
    _presenceService.unsubscribeFromPresence(widget.conversationId);
    _messagesSubscription?.cancel();
    _receiptsSubscription?.cancel();
    _typingSubscription?.cancel();
    
    // Clean up realtime services
    _realtimeService.unsubscribeFromMessages(widget.conversationId);
    _realtimeService.unsubscribeFromReceipts(widget.conversationId);
    _typingService.unsubscribeFromTyping(widget.conversationId);
    
    // Dispose HeightController
    _heightController.dispose();
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
          _selectedFile = null; // Clear any selected file
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
  
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedImage = null; // Clear any selected image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
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
  
  Future<String?> _uploadFile(PlatformFile file) async {
    setState(() => _isUploadingImage = true);
    
    try {
      final userId = SupabaseClientProvider.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      final fileBytes = Uint8List.fromList(file.bytes ?? []);
      if (fileBytes.isEmpty) throw Exception('File is empty');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$userId/files/$fileName';
      
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
          SnackBar(content: Text('Error uploading file: $e')),
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
    final hasFile = _selectedFile != null;
    
    if (!hasText && !hasImage && !hasFile) return;
    if (_isSending || _isUploadingImage) return;

    // Clear input immediately for better UX
    _messageController.clear();
    final imageToSend = _selectedImage;
    final fileToSend = _selectedFile;
    setState(() {
      _selectedImage = null;
      _selectedFile = null;
    });
    
    // Stop typing indicator when message is sent
    _typingTimer?.cancel();
    _typingService.sendTypingIndicator(widget.conversationId, false);

    setState(() => _isSending = true);

    try {
      String? mediaUrl;
      String displayText = messageText;
      
      // Upload image if present
      if (imageToSend != null) {
        mediaUrl = await _uploadImage(imageToSend);
        if (mediaUrl == null) {
          throw Exception('Failed to upload image');
        }
        if (!hasText) displayText = '📷 Photo';
      }
      
      // Upload file if present
      if (fileToSend != null) {
        mediaUrl = await _uploadFile(fileToSend);
        if (mediaUrl == null) {
          throw Exception('Failed to upload file');
        }
        if (!hasText) {
          final extension = fileToSend.extension?.toUpperCase() ?? 'FILE';
          displayText = '📎 $extension File: ${fileToSend.name}';
        }
      }
      
      await _messageService.sendMessage(
        conversationId: widget.conversationId,
        body: displayText,
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
        if (fileToSend != null) {
          setState(() {
            _selectedFile = fileToSend;
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
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
        appBar: _buildAppBar(),
        body: SafeArea(
          top: false,  // Let AppBar handle top safe area
          child: DynamicPeekZone(
            heightController: _heightController,
            conversationId: widget.conversationId,
            backgroundBuilder: (context, currentMode, currentContent) {
              return AIInsightsBackground(
                conversationId: widget.conversationId,
                heightController: _heightController,
              );
            },
            messagePanel: _buildMessageList(),
            composeBar: _buildComposeBar(),
            // onHeightChanged disabled to avoid per-frame logging

            onViewModeChanged: (mode) {
              print('🎯 View mode: ${mode.name}');
            },
          ),
        ),
        // Test menu FAB (always visible for demo purposes)
        floatingActionButton: TestMenuFab(
          conversationId: widget.conversationId,
          onMessageSent: _refreshMessages,
        ),
      ),
    );
  }

  /// Refresh messages after test data is loaded
  void _refreshMessages() {
    setState(() {
      _messagesFuture = _messageService.getMessagesByConversation(
        widget.conversationId,
        syncFirst: false,
      );
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 40,  // MUCH smaller - 40px instead of 56px
      titleSpacing: 4,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.of(context).pop(),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Much smaller avatar with online indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.group, size: 14, color: Colors.grey[700]),
              ),
              if (_onlineUsers.isNotEmpty)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '${_onlineUsers.length}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.conversationTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      elevation: 0.5,
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add, size: 18),
          onPressed: _showAddParticipantsDialog,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, size: 18),
          onPressed: () => _showParticipantsInfo(context),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return FutureBuilder<List<Message>>(
      future: _messagesFuture,
      builder: (context, futureSnapshot) {
        // Once initial messages are loaded, listen to real-time updates
        if (futureSnapshot.connectionState == ConnectionState.done) {
          return StreamBuilder<List<Message>>(
            stream: _realtimeService.subscribeToMessages(widget.conversationId),
            initialData: futureSnapshot.data ?? [],
            builder: (context, streamSnapshot) {
              final messages = streamSnapshot.data ?? [];

              return MessageListPanel(
                messages: messages,
                currentUserId: _currentUserId,
                receiptsCache: _receiptsCache,
                typingUsers: _typingUsers,
                onlineUsers: _onlineUsers,
                messageController: _messageController,
                isSending: _isSending,
                isUploadingImage: _isUploadingImage,
                selectedImage: _selectedImage,
                selectedFile: _selectedFile,
                onSendMessage: _sendMessage,
                onPickImage: _pickImage,
                onPickFile: _pickFile,
                onClearImage: () {
                  setState(() {
                    _selectedImage = null;
                    _selectedFile = null;
                  });
                },
                showComposeBar: false,
                heightController: _heightController,
              );
            },
          );
        } else {
          // Show loading while fetching initial messages
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildComposeBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
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


