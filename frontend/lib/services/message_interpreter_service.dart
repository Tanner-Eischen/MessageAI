import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/message_interpretation.dart';

/// Service for interpreting messages (Phase 1: Smart Message Interpreter)
class MessageInterpreterService {
  final SupabaseClient _supabase;

  MessageInterpreterService(this._supabase);

  /// Interpret a message with alternative meanings
  Future<MessageInterpretation> interpretMessage(String message) async {
    try {
      print('🔍 Interpreting message...');
      
      final response = await _supabase.functions.invoke(
        'ai-interpret-message',
        body: {
          'message': message,
        },
      );

      if (response.data == null) {
        throw Exception('No response from message interpreter service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Message interpretation failed');
      }

      final interpretation = MessageInterpretation.fromJson(
        data['interpretation'] as Map<String, dynamic>,
      );
      
      print('✅ Message interpreted with ${interpretation.alternativeInterpretations.length} alternatives');
      
      return interpretation;
    } catch (e) {
      print('❌ Error interpreting message: $e');
      rethrow;
    }
  }

  /// Quick check: does message have RSD triggers?
  Future<bool> hasRsdTriggers(String message) async {
    final interpretation = await interpretMessage(message);
    return interpretation.rsdTriggers.isNotEmpty;
  }

  /// Get just the alternative interpretations
  Future<List<String>> getAlternatives(String message) async {
    final interpretation = await interpretMessage(message);
    return interpretation.alternativeInterpretations;
  }
}

