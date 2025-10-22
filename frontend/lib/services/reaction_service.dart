import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class ReactionService {
  static final ReactionService _instance = ReactionService._internal();

  factory ReactionService() {
    return _instance;
  }

  ReactionService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final reactionId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final reaction = Reaction(
      id: reactionId,
      messageId: messageId,
      userId: currentUser.id,
      emoji: emoji,
      createdAt: now,
      isSynced: false,
    );

    await _db.reactionDao.insertReaction(reaction);

    try {
      await _supabase.from('reactions').insert({
        'id': reactionId,
        'message_id': messageId,
        'user_id': currentUser.id,
        'emoji': emoji,
        'created_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      });

      await _db.reactionDao.markReactionAsSynced(reactionId);
      print('Reaction synced to backend: $reactionId');
    } catch (e) {
      print('Error syncing reaction to backend: $e');
    }
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    await _db.reactionDao.deleteReaction(messageId, currentUser.id, emoji);

    try {
      await _supabase
          .from('reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', currentUser.id)
          .eq('emoji', emoji);

      print('Reaction removed from backend');
    } catch (e) {
      print('Error removing reaction from backend: $e');
    }
  }

  Future<void> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final existing = await _db.reactionDao.getUserReaction(
      messageId,
      currentUser.id,
      emoji,
    );

    if (existing != null) {
      await removeReaction(messageId: messageId, emoji: emoji);
    } else {
      await addReaction(messageId: messageId, emoji: emoji);
    }
  }

  Future<Map<String, List<Reaction>>> getReactionsGrouped(String messageId) async {
    return _db.reactionDao.getReactionsGroupedByEmoji(messageId);
  }

  Future<List<Reaction>> getReactionsForMessage(String messageId) async {
    return _db.reactionDao.getReactionsForMessage(messageId);
  }

  Future<bool> hasUserReacted(String messageId, String emoji) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    final reaction = await _db.reactionDao.getUserReaction(
      messageId,
      currentUser.id,
      emoji,
    );

    return reaction != null;
  }

  Stream<List<Reaction>> watchReactions(String messageId) {
    return _db.reactionDao.getReactionsForMessage(messageId).asStream();
  }
}
