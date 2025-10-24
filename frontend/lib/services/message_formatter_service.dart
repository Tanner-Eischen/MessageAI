import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/models/formatted_message.dart';

/// Service for formatting messages
class MessageFormatterService {
  final SupabaseClient _supabase;

  MessageFormatterService(this._supabase);

  /// Format a message with specified options
  Future<FormattedMessage> formatMessage({
    required String message,
    bool condense = false,
    bool chunk = false,
    bool addTldr = false,
    bool addStructure = false,
  }) async {
    try {
      print('🎨 Formatting message...');
      
      final response = await _supabase.functions.invoke(
        'ai-format-message',
        body: {
          'message': message,
          'options': {
            'condense': condense,
            'chunk': chunk,
            'add_tldr': addTldr,
            'add_structure': addStructure,
          },
        },
      );

      if (response.data == null) {
        throw Exception('No response from message formatting service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Formatting failed');
      }

      final formatted = FormattedMessage.fromJson(
        data['formatted'] as Map<String, dynamic>,
      );
      
      print('✅ Message formatted: ${formatted.originalLength} → ${formatted.characterCount} chars');
      
      return formatted;
    } catch (e) {
      print('❌ Error formatting message: $e');
      rethrow;
    }
  }

  /// Quick format: condense only
  Future<FormattedMessage> condenseMessage(String message) {
    return formatMessage(message: message, condense: true);
  }

  /// Quick format: add structure
  Future<FormattedMessage> structureMessage(String message) {
    return formatMessage(message: message, addStructure: true, chunk: true);
  }

  /// Quick format: full formatting (all options)
  Future<FormattedMessage> fullFormat(String message) {
    return formatMessage(
      message: message,
      condense: true,
      chunk: true,
      addTldr: true,
      addStructure: true,
    );
  }

  /// Detect the situation/context of a message
  Future<String> detectSituation(String message) async {
    try {
      print('🔍 Detecting situation for message...');
      
      final response = await _supabase.functions.invoke(
        'ai-format-message',
        body: {
          'message': message,
          'detect_situation': true,
        },
      );

      if (response.data == null) {
        throw Exception('No response from situation detection service');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Situation detection failed');
      }

      final situation = data['situation'] as String? ?? 'unknown';
      
      print('✅ Situation detected: $situation');
      
      return situation;
    } catch (e) {
      print('❌ Error detecting situation: $e');
      return 'unknown';
    }
  }
}

