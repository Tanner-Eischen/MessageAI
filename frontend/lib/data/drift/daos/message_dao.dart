import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDb> {
  MessageDao(AppDb db) : super(db);

  /// Get all messages for a conversation
  Future<List<Message>> getMessagesByConversation(String conversationId) async {
    return (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt)]))
        .get();
  }

  /// Get message by ID
  Future<Message?> getMessageById(String id) async {
    return (select(messages)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert message
  Future<void> insertMessage(Message message) async {
    await into(messages).insert(message);
  }

  /// Batch insert messages
  Future<void> insertMessages(List<Message> msgs) async {
    await batch((batch) {
      batch.insertAll(messages, msgs, mode: InsertMode.insertOrReplace);
    });
  }

  /// Update message body and sync status
  Future<void> updateMessage(String id, String body) async {
    await (update(messages)..where((m) => m.id.equals(id)))
        .write(MessagesCompanion(
          body: Value(body),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ));
  }

  /// Mark message as synced
  Future<void> markMessageAsSynced(String id) async {
    await (update(messages)..where((m) => m.id.equals(id)))
        .write(const MessagesCompanion(isSynced: Value(true)));
  }

  /// Mark multiple messages as synced
  Future<void> markMessagesAsSynced(List<String> ids) async {
    await batch((batch) {
      for (final id in ids) {
        batch.update(messages, const MessagesCompanion(isSynced: Value(true)),
            where: (m) => m.id.equals(id));
      }
    });
  }

  /// Delete message
  Future<int> deleteMessage(String id) async {
    return (delete(messages)..where((m) => m.id.equals(id))).go();
  }

  /// Get unsynced messages
  Future<List<Message>> getUnsyncedMessages() async {
    return (select(messages)..where((m) => m.isSynced.equals(false)))
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

  /// Count messages in conversation
  Future<int> getMessageCount(String conversationId) async {
    final result = await (select(messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..addColumns([countAll()]))
        .map((row) => row.read<int>(countAll()))
        .getSingle();
    return result;
  }

  /// Get unsynced messages count
  Future<int> getUnsyncedMessageCount() async {
    final result = await (select(messages)
          ..where((m) => m.isSynced.equals(false))
          ..addColumns([countAll()]))
        .map((row) => row.read<int>(countAll()))
        .getSingle();
    return result;
  }

  /// Search messages in conversation
  Future<List<Message>> searchMessages(String conversationId, String query) async {
    return (select(messages)
          ..where((m) =>
              m.conversationId.equals(conversationId) &
              m.body.like('%$query%'))
          ..orderBy([(m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc)]))
        .get();
  }
}
