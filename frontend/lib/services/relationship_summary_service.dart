import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/relationship_profile.dart';

/// Service for generating relationship summaries (Phase 3: Context System)
class RelationshipSummaryService {
  final SupabaseClient _supabase;

  RelationshipSummaryService(this._supabase);

  /// Generate or update relationship summary
  Future<RelationshipProfile> generateSummary({
    required String conversationId,
    bool forceRegenerate = false,
  }) async {
    try {
      print('👥 Generating relationship summary...');
      
      final response = await _supabase.functions.invoke(
        'ai-relationship-summary',
        body: {
          'conversation_id': conversationId,
          'force_regenerate': forceRegenerate,
        },
      );

      if (response.data == null) {
        throw Exception('No response from relationship summary service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Summary generation failed');
      }

      final profile = RelationshipProfile.fromJson(
        data['profile'] as Map<String, dynamic>,
      );
      
      print('✅ Relationship summary generated');
      
      return profile;
    } catch (e) {
      print('❌ Error generating relationship summary: $e');
      rethrow;
    }
  }

  /// Refresh relationship summary (force regenerate)
  Future<RelationshipProfile> refreshSummary({
    required String conversationId,
  }) async {
    return generateSummary(
      conversationId: conversationId,
      forceRegenerate: true,
    );
  }
}

