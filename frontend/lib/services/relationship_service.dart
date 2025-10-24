import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/models/relationship_profile.dart';
import 'package:messageai/models/safe_topic.dart';

/// Service for managing relationship profiles
class RelationshipService {
  static final RelationshipService _instance = RelationshipService._internal();
  factory RelationshipService() => _instance;
  RelationshipService._internal();

  final _supabase = SupabaseClientProvider.client;

  /// Get relationship profile for a conversation
  Future<RelationshipProfile?> getProfile(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc('get_relationship_profile', params: {
        'p_user_id': userId,
        'p_conversation_id': conversationId,
      });

      if (response == null || response.isEmpty) return null;

      return RelationshipProfile.fromJson({
        'user_id': userId,
        'conversation_id': conversationId,
        ...response as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting relationship profile: $e');
      return null;
    }
  }

  /// Get safe topics for a conversation
  Future<List<SafeTopic>> getSafeTopics(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_safe_topics', params: {
        'p_user_id': userId,
        'p_conversation_id': conversationId,
      });

      if (response == null) return [];

      return (response as List)
          .map((data) => SafeTopic.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting safe topics: $e');
      return [];
    }
  }

  /// Update relationship notes
  Future<void> updateNotes(String conversationId, String notes) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('relationship_profiles')
          .update({'relationship_notes': notes})
          .eq('user_id', userId)
          .eq('conversation_id', conversationId);
    } catch (e) {
      print('Error updating notes: $e');
      rethrow;
    }
  }

  /// Update relationship type
  Future<void> updateRelationshipType(
    String conversationId,
    String relationshipType,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('relationship_profiles')
          .update({'relationship_type': relationshipType})
          .eq('user_id', userId)
          .eq('conversation_id', conversationId);
    } catch (e) {
      print('Error updating relationship type: $e');
      rethrow;
    }
  }
}

