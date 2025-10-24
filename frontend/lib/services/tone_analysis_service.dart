import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/ai_analysis_enhanced.dart';

/// Service for analyzing tone of messages
class ToneAnalysisService {
  final SupabaseClient _supabase;

  ToneAnalysisService(this._supabase);

  /// Analyze the tone of a message
  Future<EnhancedToneAnalysis> analyzeTone(String message) async {
    try {
      print('🎭 Analyzing tone...');
      
      final response = await _supabase.functions.invoke(
        'ai_analyze_tone',
        body: {
          'message': message,
        },
      );

      if (response.data == null) {
        throw Exception('No response from tone analysis service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Tone analysis failed');
      }

      final analysis = EnhancedToneAnalysis.fromJson(
        data['analysis'] as Map<String, dynamic>,
      );
      
      print('✅ Tone analyzed: ${analysis.primaryTone}');
      
      return analysis;
    } catch (e) {
      print('❌ Error analyzing tone: $e');
      rethrow;
    }
  }

  /// Quick analysis: just get primary tone
  Future<String> getPrimaryTone(String message) async {
    final analysis = await analyzeTone(message);
    return analysis.primaryTone;
  }

  /// Check if message has RSD triggers
  Future<bool> hasRsdTriggers(String message) async {
    final analysis = await analyzeTone(message);
    return analysis.rsdTriggers.isNotEmpty;
  }
}

