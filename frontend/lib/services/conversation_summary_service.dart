import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/conversation_summary.dart';

class ConversationSummaryService {
  static final ConversationSummaryService _instance =
      ConversationSummaryService._internal();

  factory ConversationSummaryService() {
    return _instance;
  }

  ConversationSummaryService._internal();

  final _supabase = Supabase.instance.client;

  /// Check if summary should be shown for a conversation
  Future<SummaryStatus?> shouldShowSummary(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc(
        'should_show_conversation_summary',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': userId,
        },
      ) as Map<String, dynamic>;

      return SummaryStatus.fromJson(response);
    } catch (e) {
      print('❌ Error checking summary status: $e');
      return null;
    }
  }

  /// Get cached summary (quick view)
  Future<ConversationSummary?> getSummary(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc(
        'get_conversation_summary',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': userId,
          'p_detail_level': 'quick',
        },
      ) as List;

      if (response.isEmpty) return null;

      return ConversationSummary.fromJson(response.first as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error getting summary: $e');
      return null;
    }
  }

  /// Get detailed summary (expanded view)
  Future<ConversationSummaryExtended?> getDetailedSummary(
    String conversationId,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase.rpc(
        'get_conversation_summary',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': userId,
          'p_detail_level': 'full',
        },
      ) as List;

      if (response.isEmpty) return null;

      return ConversationSummaryExtended.fromJson(
        response.first as Map<String, dynamic>,
      );
    } catch (e) {
      print('❌ Error getting detailed summary: $e');
      return null;
    }
  }

  /// Generate new summary or get cached if valid
  Future<ConversationSummary?> generateSummary(
    String conversationId, {
    bool forceRefresh = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      print('🔄 Generating summary for conversation $conversationId...');

      // Call edge function to generate/fetch summary
      final response = await _supabase.functions.invoke(
        'generate-conversation-summary',
        body: {
          'conversation_id': conversationId,
          'user_id': userId,
          'detail_level': 'quick',
          'force_refresh': forceRefresh,
        },
      );

      if (response.data == null) {
        throw Exception('No response from summary generation');
      }

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Unknown error');
      }

      final summary = ConversationSummary.fromJson(
        data['summary'] as Map<String, dynamic>,
      );

      print('✅ Summary generated successfully');

      // Track generation
      await _trackSummaryGenerated(
        conversationId,
        data['cacheStatus'] == 'generated',
      );

      return summary;
    } catch (e) {
      print('❌ Error generating summary: $e');
      return null;
    }
  }

  /// Track that user clicked on summary
  Future<void> trackSummaryClick(String summaryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('summary_generation_log')
          .update({'clicked': true})
          .eq('id', summaryId)
          .eq('user_id', userId);

      print('📊 Tracked summary click');
    } catch (e) {
      print('⚠️ Error tracking click: $e');
    }
  }

  /// Track that user expanded summary
  Future<void> trackExpansion(String summaryId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('summary_generation_log')
          .update({'expanded_to_full': true})
          .eq('id', summaryId)
          .eq('user_id', userId);

      print('📊 Tracked summary expansion');
    } catch (e) {
      print('⚠️ Error tracking expansion: $e');
    }
  }

  /// Track user feedback on summary accuracy
  Future<void> trackFeedback(String summaryId, bool wasHelpful) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('summary_generation_log')
          .update({'was_helpful': wasHelpful})
          .eq('id', summaryId)
          .eq('user_id', userId);

      print('📊 Tracked summary feedback: ${wasHelpful ? '👍' : '👎'}');
    } catch (e) {
      print('⚠️ Error tracking feedback: $e');
    }
  }

  /// Internal: Track summary generation for analytics
  Future<void> _trackSummaryGenerated(
    String conversationId,
    bool wasGenerated,
  ) async {
    try {
      // This would be called by the backend, but we can track client-side too
      print('📊 Summary ${wasGenerated ? 'generated' : 'cached'}');
    } catch (e) {
      print('⚠️ Error tracking generation: $e');
    }
  }

  /// Get all summaries for a user (for analytics/history)
  Future<List<ConversationSummary>> getUserSummaries() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('conversation_summaries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((item) => ConversationSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting user summaries: $e');
      return [];
    }
  }

  /// Refresh a specific summary (force regeneration)
  Future<ConversationSummary?> refreshSummary(String conversationId) async {
    return generateSummary(conversationId, forceRefresh: true);
  }

  /// Dismiss/invalidate a summary
  Future<bool> dismissSummary(String conversationId) async {
    try {
      await _supabase
          .from('conversation_summaries')
          .update({'is_valid': false})
          .eq('conversation_id', conversationId)
          .eq('user_id', _supabase.auth.currentUser?.id ?? '');

      print('✅ Summary dismissed');
      return true;
    } catch (e) {
      print('❌ Error dismissing summary: $e');
      return false;
    }
  }

  /// Get summary statistics for user
  Future<Map<String, dynamic>> getSummaryStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final summaries = await getUserSummaries();
      final total = summaries.length;
      final avgConfidence =
          total > 0 ? summaries.map((s) => s.confidence).reduce((a, b) => a + b) / total : 0.0;
      final recentUsed = summaries.take(10).where((s) => !s.isExpired()).length;

      return {
        'total_summaries': total,
        'avg_confidence': avgConfidence,
        'recently_used': recentUsed,
        'active_conversations': summaries.where((s) => !s.isExpired()).length,
      };
    } catch (e) {
      print('❌ Error getting stats: $e');
      return {};
    }
  }

  /// Clean up expired summaries (called periodically)
  Future<int> cleanupExpiredSummaries() async {
    try {
      final result = await _supabase.rpc('cleanup_expired_summaries') as int;
      print('🧹 Cleaned up $result expired summaries');
      return result;
    } catch (e) {
      print('❌ Error cleaning up summaries: $e');
      return 0;
    }
  }
}
