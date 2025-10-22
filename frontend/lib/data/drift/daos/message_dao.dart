import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDb> with _$MessageDaoMixin {
  MessageDao(AppDb db) : super(db);

  /// Get all messages for a conversation ordered by creation time
  Future<List<Message>> getMessagesByConversation(String conversationId) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  /// Get recent messages for a conversation
  Future<List<Message>> getRecentMessages(String conversationId, {int limit = 50}) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  /// Insert a new message
  Future<void> insertMessage(Message message) async {
    await into(messages).insert(message);
  }

  /// Update message sync status
  Future<void> markMessageAsSynced(String messageId) async {
    await (update(messages)..where((m) => m.id.equals(messageId)))
        .write(const MessagesCompanion(isSynced: Value(true)));
  }

  /// Get unsynced messages
  Future<List<Message>> getUnsyncedMessages() async {
    return (select(messages)..where((m) => m.isSynced.equals(false)))
        .get();
  }

  /// Delete message by ID
  Future<int> deleteMessage(String id) async {
    return (delete(messages)..where((m) => m.id.equals(id))).go();
  }

  /// Get message by ID
  Future<Message?> getMessageById(String id) async {
    return (select(messages)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get the most recent message for a conversation
  Future<Message?> getLatestMessageForConversation(String conversationId) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get unsynced message count
  Future<int> getUnsyncedMessageCount() async {
    final result = await (select(messages)..where((m) => m.isSynced.equals(false))).get();
    return result.length;
  }

  /// Search messages in a conversation
  Future<List<Message>> searchMessages(String conversationId, String query) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId) & m.body.contains(query))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Insert multiple messages
  Future<void> insertMessages(List<Message> messageList) async {
    await batch((batch) {
      batch.insertAll(messages, messageList);
    });
  }

  /// Upsert a message (insert or update)
  Future<void> upsertMessage(Message message) async {
    await into(messages).insertOnConflictUpdate(message);
  }

  /// Update message body and edited timestamp
  Future<void> updateMessage(
    String messageId, {
    String? body,
    int? editedAt,
  }) async {
    final companion = MessagesCompanion(
      body: body != null ? Value(body) : const Value.absent(),
      editedAt: editedAt != null ? Value(editedAt) : const Value.absent(),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );

    await (update(messages)..where((m) => m.id.equals(messageId)))
        .write(companion);
  }
}
