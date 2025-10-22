import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDb> with _$ConversationDaoMixin {
  ConversationDao(AppDb db) : super(db);

  /// Get all conversations ordered by last message
  Future<List<Conversation>> getAllConversations() async {
    final query = select(conversations)
      ..orderBy([(c) => OrderingTerm(expression: c.lastMessageAt, mode: OrderingMode.desc)]);
    return query.get();
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String id) async {
    return (select(conversations)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or update conversation
  Future<void> upsertConversation(Conversation conversation) async {
    await into(conversations).insert(
      conversation,
      onConflict: DoUpdate((_) => conversation),
    );
  }

  /// Batch insert conversations
  Future<void> insertConversations(List<Conversation> convs) async {
    await batch((batch) {
      batch.insertAll(conversations, convs, mode: InsertMode.insertOrReplace);
    });
  }

  /// Delete conversation by ID
  Future<int> deleteConversation(String id) async {
    return (delete(conversations)..where((c) => c.id.equals(id))).go();
  }

  /// Update conversation sync status
  Future<void> markConversationAsSynced(String id) async {
    await (update(conversations)..where((c) => c.id.equals(id)))
        .write(const ConversationsCompanion(isSynced: Value(true)));
  }

  /// Get unsynced conversations
  Future<List<Conversation>> getUnsyncedConversations() async {
    return (select(conversations)..where((c) => c.isSynced.equals(false)))
        .get();
  }

  /// Update last message time
  Future<void> updateLastMessageTime(String conversationId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(conversations)..where((c) => c.id.equals(conversationId)))
        .write(ConversationsCompanion(
          updatedAt: Value(now),
          lastMessageAt: Value(now),
        ));
  }

  /// Get recent conversations (for list)
  Future<List<Conversation>> getRecentConversations({int limit = 20}) async {
    return (select(conversations)
          ..orderBy([(c) => OrderingTerm(expression: c.lastMessageAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  /// Count total conversations
  Future<int> getConversationCount() async {
    final result = await select(conversations).get();
    return result.length;
  }
}
