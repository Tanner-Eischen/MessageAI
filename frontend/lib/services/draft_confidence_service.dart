import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/draft_confidence.dart';

/// Service for analyzing draft confidence (Phase 2: Response Assistant)
class DraftConfidenceService {
  final SupabaseClient _supabase;

  DraftConfidenceService(this._supabase);

  /// Analyze the confidence/quality of a draft response
  Future<DraftConfidence> analyzeDraft(String draft) async {
    try {
      print('✍️ Analyzing draft...');
      
      final response = await _supabase.functions.invoke(
        'ai_analyze_draft',
        body: {
          'draft': draft,
        },
      );

      if (response.data == null) {
        throw Exception('No response from draft confidence service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Draft analysis failed');
      }

      final confidence = DraftConfidence.fromJson(
        data['analysis'] as Map<String, dynamic>,
      );
      
      print('✅ Draft analyzed: ${confidence.overallScore}% confidence');
      
      return confidence;
    } catch (e) {
      print('❌ Error analyzing draft: $e');
      rethrow;
    }
  }

  /// Quick check: is draft good enough to send?
  Future<bool> isReadyToSend(String draft) async {
    final confidence = await analyzeDraft(draft);
    return confidence.overallScore >= 70; // 70% threshold
  }

  /// Get suggestions for improving draft
  Future<List<String>> getSuggestions(String draft) async {
    final confidence = await analyzeDraft(draft);
    return confidence.suggestions;
  }
}



