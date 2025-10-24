import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/relationship_profile.dart';

/// Service for generating relationship summaries (Phase 3: Context System)
class RelationshipSummaryService {
  final SupabaseClient _supabase;

  RelationshipSummaryService(this._supabase);

  /// Generate or update relationship summary
  Future<RelationshipProfile> generateSummary({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      print('👥 Generating relationship summary...');
      
      final response = await _supabase.functions.invoke(
        'ai-relationship-summary',
        body: {
          'user_id': userId,
          'other_user_id': otherUserId,
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

  /// Get existing relationship profile
  Future<RelationshipProfile?> getProfile({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final response = await _supabase
          .from('relationship_profiles')
          .select()
          .eq('user_id', userId)
          .eq('other_user_id', otherUserId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return RelationshipProfile.fromJson(response);
    } catch (e) {
      print('Error fetching relationship profile: $e');
      return null;
    }
  }

  /// Refresh relationship summary
  Future<RelationshipProfile> refreshSummary({
    required String userId,
    required String otherUserId,
  }) async {
    return generateSummary(userId: userId, otherUserId: otherUserId);
  }
}

