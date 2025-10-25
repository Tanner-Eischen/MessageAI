import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'dart:async';

/// Service for interpreting messages (Phase 1: Smart Message Interpreter)
/// Calls ai-interpret-message Edge Function which returns enhanced tone analysis
/// with RSD triggers, alternative interpretations, and evidence
class MessageInterpreterService {
  final SupabaseClient _supabase;

  MessageInterpreterService(this._supabase);

  /// Interpret a message with alternative meanings, RSD detection, and evidence
  /// Returns full AIAnalysis with enhanced interpretation fields
  Future<AIAnalysis> interpretMessage(String messageId, String messageBody) async {
    try {
      print('🔍 Interpreting message...');
      
      // 🔧 Add timeout to prevent hanging
      final response = await _supabase.functions.invoke(
        'ai-interpret-message',
        body: {
          'message_id': messageId,
          'message_body': messageBody,
        },
      ).timeout(
        const Duration(seconds: 15), // 🆕 15 second timeout for deeper interpretation
        onTimeout: () {
          throw TimeoutException('Message interpretation timed out');
        },
      );

      if (response.data == null) {
        throw Exception('No response from message interpreter service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Message interpretation failed');
      }

      // Backend returns full enhanced tone analysis with interpretations
      final analysis = AIAnalysis.fromJson(
        data['interpretation'] as Map<String, dynamic>,
      );
      
      print('✅ Message interpreted: '
            '${analysis.alternativeInterpretations?.length ?? 0} alternatives, '
            '${analysis.rsdTriggers?.length ?? 0} RSD triggers');
      
      return analysis;
    } catch (e) {
      print('❌ Error interpreting message: $e');
      rethrow;
    }
  }

  /// Quick check: does message have RSD triggers?
  Future<bool> hasRsdTriggers(String messageId, String messageBody) async {
    final analysis = await interpretMessage(messageId, messageBody);
    return analysis.rsdTriggers?.isNotEmpty ?? false;
  }

  /// Get alternative interpretations for a message
  Future<List<MessageInterpretation>> getAlternativeInterpretations(
    String messageId, 
    String messageBody,
  ) async {
    final analysis = await interpretMessage(messageId, messageBody);
    return analysis.alternativeInterpretations ?? [];
  }

  /// Get RSD triggers for a message
  Future<List<RSDTrigger>> getRsdTriggers(
    String messageId,
    String messageBody,
  ) async {
    final analysis = await interpretMessage(messageId, messageBody);
    return analysis.rsdTriggers ?? [];
  }

  /// Get evidence points for interpretation
  Future<List<Evidence>> getEvidence(
    String messageId,
    String messageBody,
  ) async {
    final analysis = await interpretMessage(messageId, messageBody);
    return analysis.evidence ?? [];
  }
}

