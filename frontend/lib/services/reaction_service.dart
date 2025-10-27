import 'package:drift/drift.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:uuid/uuid.dart';

class ReactionService {
  static final ReactionService _instance = ReactionService._internal();
  factory ReactionService() => _instance;
  ReactionService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;
  final _uuid = const Uuid();

  /// Add or toggle a reaction to a message
  Future<void> toggleReaction(String messageId, String emoji) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if reaction already exists
      final existing = await _db.customSelect(
        'SELECT * FROM reactions WHERE message_id = ? AND user_id = ? AND emoji = ?',
        variables: [Variable(messageId), Variable(userId), Variable(emoji)],
      ).get();

      if (existing.isNotEmpty) {
        // Remove reaction
        final reactionId = existing.first.read<String>('id');
        await removeReaction(reactionId);
      } else {
        // Add reaction
        await addReaction(messageId, emoji);
      }
    } catch (e) {
      print('Error toggling reaction: $e');
      rethrow;
    }
  }

  /// Add a reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final reactionId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      // Add to backend
      await _supabase.from('message_reactions').insert({
        'id': reactionId,
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      });

      // Add to local database
      await _db.into(_db.reactions).insert(
        ReactionsCompanion.insert(
          id: reactionId,
          messageId: messageId,
          userId: userId,
          emoji: emoji,
          createdAt: now,
          isSynced: const Value(true),
        ),
      );
    } catch (e) {
      print('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove a reaction
  Future<void> removeReaction(String reactionId) async {
    try {
      // Delete from backend
      await _supabase
          .from('message_reactions')
          .delete()
          .eq('id', reactionId);

      // Delete from local database
      await (_db.delete(_db.reactions)..where((r) => r.id.equals(reactionId))).go();
    } catch (e) {
      print('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Get reactions for a message
  Future<Map<String, List<String>>> getMessageReactions(String messageId) async {
    try {
      // Fetch from local database
      final results = await (_db.select(_db.reactions)
            ..where((r) => r.messageId.equals(messageId)))
          .get();

      // Group by emoji and collect user IDs
      final Map<String, List<String>> grouped = {};
      for (final reaction in results) {
        if (!grouped.containsKey(reaction.emoji)) {
          grouped[reaction.emoji] = [];
        }
        grouped[reaction.emoji]!.add(reaction.userId);
      }

      return grouped;
    } catch (e) {
      print('Error getting reactions: $e');
      return {};
    }
  }

  /// Subscribe to reactions for a message (real-time updates)
  Stream<Map<String, List<String>>> subscribeToReactions(String messageId) {
    return _supabase
        .from('message_reactions')
        .stream(primaryKey: ['id'])
        .eq('message_id', messageId)
        .map((data) {
          final Map<String, List<String>> grouped = {};
          for (final item in data) {
            final emoji = item['emoji'] as String;
            final userId = item['user_id'] as String;
            
            if (!grouped.containsKey(emoji)) {
              grouped[emoji] = [];
            }
            grouped[emoji]!.add(userId);
          }
          return grouped;
        });
  }
}

