import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();

  factory MessageService() {
    return _instance;
  }

  MessageService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;

  /// Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? mediaUrl,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw 'User not authenticated';
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final messageId = const Uuid().v4();
    
    final message = Message(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUser.id,
      body: body,
      mediaUrl: mediaUrl,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    // Save to local database first (optimistic UI)
    await _db.messageDao.upsertMessage(message);
    
    // Update conversation last message time
    await _db.conversationDao.updateLastMessageTime(conversationId);

    // Sync to backend
    try {
      print('━' * 60);
      print('📤 SENDING MESSAGE TO SUPABASE');
      print('━' * 60);
      print('Message ID: $messageId');
      print('Conversation ID: $conversationId');
      print('Sender ID: ${currentUser.id}');
      print('Body: $body');
      print('Media URL: $mediaUrl');
      print('Auth Token: ${_supabase.auth.currentSession?.accessToken?.substring(0, 20)}...');
      print('━' * 60);
      
      final payload = {
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'body': body,
        'media_url': mediaUrl,
        'created_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      };
      
      print('Payload: $payload');
      
      final response = await _supabase.from('messages').insert(payload);
      
      print('Response: $response');

      // Mark as synced
      await _db.messageDao.markMessageAsSynced(messageId);
      
      print('✅ Message synced to backend successfully: $messageId');
      print('━' * 60);
    } catch (e, stackTrace) {
      print('━' * 60);
      print('❌ ERROR SYNCING MESSAGE TO BACKEND');
      print('━' * 60);
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('Stack trace:');
      print(stackTrace);
      print('━' * 60);
      print('❌ Message will be queued for retry');
      // Message stays in local DB with isSynced=false for retry later
    }

    return message;
  }

  /// Sync messages from backend for a conversation
  Future<void> syncMessages(String conversationId) async {
    try {
      print('🔄 Syncing messages for conversation: $conversationId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        print('❌ User not authenticated, skipping sync');
        return;
      }

      // Fetch messages from backend ordered by created_at
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      print('📥 Fetched ${(response as List).length} messages from backend');

      // Save to local database with proper timestamps
      for (final msgData in response) {
        final createdAt = DateTime.parse(msgData['created_at'] as String);
        final updatedAt = DateTime.parse(msgData['updated_at'] as String);
        
        final message = Message(
          id: msgData['id'] as String,
          conversationId: msgData['conversation_id'] as String,
          senderId: msgData['sender_id'] as String,
          body: msgData['body'] as String,
          mediaUrl: msgData['media_url'] as String?,
          createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
          updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
          isSynced: true,
        );

        // Use upsert to avoid duplicates
        await _db.messageDao.upsertMessage(message);
      }

      print('✅ Messages synced successfully (${response.length} messages)');
    } catch (e) {
      print('❌ Error syncing messages: $e');
      rethrow;
    }
  }

  /// Get messages for a conversation (with optional sync)
  Future<List<Message>> getMessagesByConversation(
    String conversationId, {
    bool syncFirst = false,
  }) async {
    if (syncFirst) {
      await syncMessages(conversationId);
    }
    return _db.messageDao.getMessagesByConversation(conversationId);
  }

  /// Get recent messages for a conversation
  Future<List<Message>> getRecentMessages(String conversationId, {int limit = 50}) async {
    return _db.messageDao.getRecentMessages(conversationId, limit: limit);
  }

  /// Get message by ID
  Future<Message?> getMessageById(String id) async {
    return _db.messageDao.getMessageById(id);
  }

  /// Delete message
  Future<void> deleteMessage(String id) async {
    await _db.messageDao.deleteMessage(id);
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}

