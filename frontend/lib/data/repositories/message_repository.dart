import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/message_dao.dart';
import 'package:messageai/data/drift/daos/pending_outbox_dao.dart';
import 'package:messageai/gen/api/clients/messages_api.dart';
import 'package:messageai/gen/api/models/message_payload.dart';

/// Repository for message operations combining API and local database
class MessageRepository {
  final MessagesApi _messagesApi;
  final MessageDao _messageDao;
  final PendingOutboxDao _outboxDao;

  MessageRepository({
    required MessagesApi messagesApi,
    required MessageDao messageDao,
    required PendingOutboxDao outboxDao,
  })  : _messagesApi = messagesApi,
        _messageDao = messageDao,
        _outboxDao = outboxDao;

  /// Send a message (optimistic - save locally first, sync later)
  Future<Message> sendMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String body,
    String? mediaUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Create message locally first (optimistic)
    final message = Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      mediaUrl: mediaUrl,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
    
    // Save to local DB
    await _messageDao.insertMessage(message);
    
    // Queue for sync
    await _outboxDao.addPendingOperation(
      id: '${id}_send',
      operation: 'send_message',
      payload: message.toJson().toString(),
      conversationId: conversationId,
    );
    
    return message;
  }

  /// Get messages for a conversation from local DB
  Future<List<Message>> getConversationMessages(String conversationId) async {
    return _messageDao.getMessagesByConversation(conversationId);
  }

  /// Get recent messages for a conversation (paginated)
  Future<List<Message>> getRecentMessages(String conversationId, {int limit = 50}) async {
    return _messageDao.getRecentMessages(conversationId, limit: limit);
  }

  /// Sync unsynced messages to server
  Future<void> syncUnsyncedMessages() async {
    final unsyncedMessages = await _messageDao.getUnsyncedMessages();
    
    for (final message in unsyncedMessages) {
      try {
        final payload = MessagePayload(
          id: message.id,
          conversationId: message.conversationId,
          body: message.body,
        );
        
        // Send to server
        await _messagesApi.send(payload);
        
        // Mark as synced locally
        await _messageDao.markMessageAsSynced(message.id);
        
        // Remove from outbox
        await _outboxDao.removePendingOperation('${message.id}_send');
      } catch (e) {
        // Log error and continue
        print('Error syncing message ${message.id}: $e');
      }
    }
  }

  /// Search messages in a conversation
  Future<List<Message>> searchMessages(String conversationId, String query) async {
    return _messageDao.searchMessages(conversationId, query);
  }

  /// Insert messages from server
  Future<void> insertServerMessages(List<Message> messages) async {
    await _messageDao.insertMessages(messages);
  }

  /// Update message from server
  Future<void> updateMessageFromServer(Message message) async {
    await _messageDao.upsertMessage(message);
  }

  /// Upsert message (helper)
  Future<void> upsertMessage(Message message) async {
    // This would be added to MessageDao
    await _messageDao.insertMessage(message);
  }

  /// Get pending message count (for UI)
  Future<int> getPendingMessageCount() async {
    return _messageDao.getUnsyncedMessageCount();
  }
}

extension on Message {
  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'body': body,
    'media_url': mediaUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_synced': isSynced,
  };
}
