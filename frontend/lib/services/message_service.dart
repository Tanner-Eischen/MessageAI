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
    String? replyToId,
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
      replyToId: replyToId,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    // Save to local database first (optimistic UI)
    await _db.messageDao.insertMessage(message);

    // Update conversation last message time
    await _db.conversationDao.updateLastMessageTime(conversationId);

    // Sync to backend
    try {
      await _supabase.from('messages').insert({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': currentUser.id,
        'body': body,
        'media_url': mediaUrl,
        'reply_to_id': replyToId,
        'created_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      });

      // Mark as synced
      await _db.messageDao.markMessageAsSynced(messageId);

      print('Message synced to backend: $messageId');
    } catch (e) {
      print('Error syncing message to backend: $e');
      // Message stays in local DB with isSynced=false for retry later
    }

    return message;
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessagesByConversation(String conversationId) async {
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

  /// Edit message (within 15 minutes)
  Future<void> editMessage(String messageId, String newBody) async {
    final message = await getMessageById(messageId);
    if (message == null) {
      throw 'Message not found';
    }

    final now = DateTime.now();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000);
    final difference = now.difference(createdAt);

    if (difference.inMinutes >= 15) {
      throw 'Cannot edit messages older than 15 minutes';
    }

    final updatedAt = now.millisecondsSinceEpoch ~/ 1000;

    await _db.messageDao.updateMessage(
      messageId,
      body: newBody,
      editedAt: updatedAt,
    );

    try {
      await _supabase.from('messages').update({
        'body': newBody,
        'edited_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', messageId);

      print('Message edited successfully: $messageId');
    } catch (e) {
      print('Error editing message: $e');
      rethrow;
    }
  }

  /// Delete message
  Future<void> deleteMessage(String id) async {
    await _db.messageDao.deleteMessage(id);

    try {
      await _supabase.from('messages').delete().eq('id', id);
      print('Message deleted from backend: $id');
    } catch (e) {
      print('Error deleting message from backend: $e');
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}

