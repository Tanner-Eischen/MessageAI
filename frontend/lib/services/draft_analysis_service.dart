import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/draft_analysis.dart';

/// Service for analyzing draft messages on-demand
/// User manually requests analysis via button press
class DraftAnalysisService {
  final SupabaseClient _supabase;

  DraftAnalysisService(this._supabase);

  /// Analyze a draft message (called when user clicks "Check" button)
  Future<DraftAnalysis> analyzeDraft({
    required String draftMessage,
    String? conversationId,
    RelationshipType? relationshipType,
    List<String>? conversationHistory,
  }) async {
    try {
      print('🔍 Analyzing draft message...');
      
      final response = await _supabase.functions.invoke(
        'ai_analyze_draft',
        body: {
          'draft_message': draftMessage,
          if (conversationId != null) 'conversation_id': conversationId,
          if (relationshipType != null && relationshipType != RelationshipType.none)
            'relationship_type': relationshipType.value,
          if (conversationHistory != null && conversationHistory.isNotEmpty)
            'conversation_history': conversationHistory,
        },
      );

      if (response.data == null) {
        throw Exception('No response from draft analysis service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Analysis failed');
      }

      final analysis = DraftAnalysis.fromJson(data['analysis'] as Map<String, dynamic>);
      
      print('✅ Draft analysis complete: ${analysis.confidenceScore}% confidence');
      
      return analysis;
    } catch (e) {
      print('❌ Error analyzing draft: $e');
      rethrow;
    }
  }

  /// Get recent messages from conversation for context
  Future<List<String>> getConversationContext(String conversationId, {int limit = 3}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('body')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((m) => m['body'] as String).toList();
    } catch (e) {
      print('Warning: Could not fetch conversation context: $e');
      return [];
    }
  }

  /// Get or detect relationship type for conversation
  Future<RelationshipType> getRelationshipType(String conversationId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('relationship_type')
          .eq('id', conversationId)
          .single();

      return RelationshipType.fromString(response['relationship_type'] as String?);
    } catch (e) {
      print('Warning: Could not fetch relationship type: $e');
      return RelationshipType.none;
    }
  }

  /// Update relationship type for conversation
  Future<void> setRelationshipType(String conversationId, RelationshipType type) async {
    try {
      await _supabase
          .from('conversations')
          .update({'relationship_type': type.value})
          .eq('id', conversationId);
      
      print('✅ Relationship type updated to: ${type.displayName}');
    } catch (e) {
      print('❌ Error updating relationship type: $e');
      rethrow;
    }
  }
}

