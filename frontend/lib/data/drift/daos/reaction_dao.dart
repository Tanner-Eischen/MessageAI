import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';

part 'reaction_dao.g.dart';

@DriftAccessor(tables: [Reactions])
class ReactionDao extends DatabaseAccessor<AppDb> with _$ReactionDaoMixin {
  ReactionDao(AppDb db) : super(db);

  Future<List<Reaction>> getReactionsForMessage(String messageId) async {
    return (select(reactions)..where((r) => r.messageId.equals(messageId))).get();
  }

  Future<Map<String, List<Reaction>>> getReactionsGroupedByEmoji(String messageId) async {
    final allReactions = await getReactionsForMessage(messageId);
    final Map<String, List<Reaction>> grouped = {};

    for (final reaction in allReactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return grouped;
  }

  Future<void> insertReaction(Reaction reaction) async {
    await into(reactions).insert(reaction, mode: InsertMode.replace);
  }

  Future<void> deleteReaction(String messageId, String userId, String emoji) async {
    await (delete(reactions)
          ..where((r) =>
              r.messageId.equals(messageId) &
              r.userId.equals(userId) &
              r.emoji.equals(emoji)))
        .go();
  }

  Future<Reaction?> getUserReaction(String messageId, String userId, String emoji) async {
    return (select(reactions)
          ..where((r) =>
              r.messageId.equals(messageId) &
              r.userId.equals(userId) &
              r.emoji.equals(emoji)))
        .getSingleOrNull();
  }

  Future<List<Reaction>> getUserReactionsForMessage(String messageId, String userId) async {
    return (select(reactions)
          ..where((r) =>
              r.messageId.equals(messageId) &
              r.userId.equals(userId)))
        .get();
  }

  Future<int> getReactionCount(String messageId) async {
    final result = await (select(reactions)..where((r) => r.messageId.equals(messageId))).get();
    return result.length;
  }

  Future<void> markReactionAsSynced(String reactionId) async {
    await (update(reactions)..where((r) => r.id.equals(reactionId)))
        .write(const ReactionsCompanion(isSynced: Value(true)));
  }

  Future<List<Reaction>> getUnsyncedReactions() async {
    return (select(reactions)..where((r) => r.isSynced.equals(false))).get();
  }
}
