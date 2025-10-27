import 'package:messageai/data/remote/supabase_client.dart';

/// Model for detected boundary violation
class BoundaryViolationData {
  final String type;
  final String severity; // low, medium, high
  final String explanation;
  final List<String> evidence;
  final String suggestedGentle;
  final String suggestedModerate;
  final String suggestedFirm;

  const BoundaryViolationData({
    required this.type,
    required this.severity,
    required this.explanation,
    required this.evidence,
    required this.suggestedGentle,
    required this.suggestedModerate,
    required this.suggestedFirm,
  });

  factory BoundaryViolationData.fromJson(Map<String, dynamic> json) {
    return BoundaryViolationData(
      type: json['type'] as String,
      severity: json['severity'] as String,
      explanation: json['explanation'] as String,
      evidence: List<String>.from(json['evidence'] as List? ?? []),
      suggestedGentle: json['suggestedGentle'] as String,
      suggestedModerate: json['suggestedModerate'] as String,
      suggestedFirm: json['suggestedFirm'] as String,
    );
  }
}

/// Response from boundary detection
class BoundaryDetectionResponse {
  final bool success;
  final List<BoundaryViolationData> violations;
  final int violationCount;
  final int senderViolationHistory;
  final bool isRepeatOffender;

  const BoundaryDetectionResponse({
    required this.success,
    required this.violations,
    required this.violationCount,
    required this.senderViolationHistory,
    required this.isRepeatOffender,
  });

  factory BoundaryDetectionResponse.fromJson(Map<String, dynamic> json) {
    final violationsList = (json['violations'] as List? ?? [])
        .map((v) => BoundaryViolationData.fromJson(v as Map<String, dynamic>))
        .toList();

    return BoundaryDetectionResponse(
      success: json['success'] as bool? ?? false,
      violations: violationsList,
      violationCount: json['violationCount'] as int? ?? 0,
      senderViolationHistory: json['senderViolationHistory'] as int? ?? 0,
      isRepeatOffender: json['isRepeatOffender'] as bool? ?? false,
    );
  }
}

/// Service for boundary violation detection and management
class BoundaryViolationService {
  final _supabase = SupabaseClientProvider.client;

  /// Detect boundary violations in a message
  Future<BoundaryDetectionResponse?> detectViolations({
    required String messageId,
    required String messageBody,
    required String senderId,
    required int messageTimestamp,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      print('🔍 Detecting boundary violations for message from $senderId');

      final response = await _supabase.functions.invoke(
        'detect-boundary-violations',
        body: {
          'messageId': messageId,
          'messageBody': messageBody,
          'senderId': senderId,
          'messageTimestamp': messageTimestamp,
        },
        headers: {
          'x-user-id': userId,
        },
      );

      // FunctionResponse.data is dynamic, convert to Map
      final responseData = response.data as Map<String, dynamic>? ?? {};

      if (responseData['success'] != true) {
        print('❌ Boundary detection failed: ${responseData['error']}');
        return null;
      }

      print('✅ Detected ${responseData['violationCount']} boundary violations');
      return BoundaryDetectionResponse.fromJson(responseData);
    } catch (e) {
      print('❌ Error detecting boundary violations: $e');
      return null;
    }
  }

  /// Get all boundary violations for a conversation
  Future<List<BoundaryViolationData>> getConversationViolations(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in');
        return [];
      }

      print('🔍 Fetching boundary violations for conversation: $conversationId');
      print('👤 Current user ID: $userId');

      // First get all message IDs from this conversation
      final messagesResponse = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId);
      
      final messageIds = (messagesResponse as List)
          .map((m) => m['id'] as String)
          .toList();
      
      print('📬 Found ${messageIds.length} messages in conversation');
      if (messageIds.isNotEmpty) {
        print('   First few message IDs: ${messageIds.take(3).join(", ")}');
      }
      
      if (messageIds.isEmpty) {
        print('📊 No messages in conversation');
        return [];
      }

      // Then get violations for those messages
      print('🔍 Querying boundary_violations table...');
      final response = await _supabase
          .from('boundary_violations')
          .select()
          .eq('user_id', userId)
          .in_('message_id', messageIds)
          .order('message_timestamp', ascending: false);

      print('📊 Query returned ${(response as List).length} boundary violations');
      if ((response as List).isNotEmpty) {
        print('   First violation: ${(response as List).first}');
      }

      return (response).map((item) {
        return BoundaryViolationData(
          type: item['violation_type'] as String? ?? 'other',
          severity: item['severity'] as String? ?? 'low',
          explanation: item['explanation'] as String? ?? '',
          evidence: List<String>.from(item['evidence'] as List? ?? []),
          suggestedGentle: item['suggested_gentle'] as String? ?? '',
          suggestedModerate: item['suggested_moderate'] as String? ?? '',
          suggestedFirm: item['suggested_firm'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      print('❌ Error getting conversation violations: $e');
      return [];
    }
  }

  /// Save a boundary response template for future use
  Future<bool> saveBoundaryScript({
    required String senderId,
    required String title,
    required String description,
    required String scriptText,
    required String assertiveness, // gentle, moderate, firm
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('boundary_scripts')
          .insert({
            'user_id': userId,
            'sender_id': senderId,
            'script_title': title,
            'script_description': description,
            'script_text': scriptText,
            'assertiveness': assertiveness,
          });

      print('✅ Boundary script saved');
      return true;
    } catch (e) {
      print('❌ Error saving boundary script: $e');
      return false;
    }
  }

  /// Get saved boundary scripts for a sender
  Future<List<Map<String, dynamic>>> getSavedScripts(String senderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('boundary_scripts')
          .select()
          .eq('user_id', userId)
          .eq('sender_id', senderId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching saved scripts: $e');
      return [];
    }
  }

  /// Track that user used a boundary response
  Future<bool> trackBoundaryResponse({
    required String violationId,
    required String responseText,
    required String selectedLevel, // gentle, moderate, firm
  }) async {
    try {
      await _supabase
          .from('boundary_violations')
          .update({
            'user_selected_response': selectedLevel,
            'response_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          })
          .eq('id', violationId);

      print('✅ Boundary response tracked');
      return true;
    } catch (e) {
      print('❌ Error tracking response: $e');
      return false;
    }
  }

  /// Get violation history for a sender
  Future<int> getSenderViolationCount(String senderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;

      final response = await _supabase
          .from('boundary_violations')
          .select('id')
          .eq('user_id', userId)
          .eq('sender_id', senderId)
          .gte('message_timestamp', thirtyDaysAgo);

      return (response as List).length;
    } catch (e) {
      print('❌ Error getting violation count: $e');
      return 0;
    }
  }

  /// Format violation for display
  String formatViolationForDisplay(BoundaryViolationData violation) {
    final severityEmoji = {
      'low': '🟡',
      'medium': '🟠',
      'high': '🔴',
    }[violation.severity] ?? '⚪';

    return '$severityEmoji ${violation.type.replaceAll('_', ' ').toUpperCase()}';
  }

  /// Get color for severity
  String getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return 'FFC107'; // Amber
      case 'medium':
        return 'FF9800'; // Orange
      case 'high':
        return 'F44336'; // Red
      default:
        return '9E9E9E'; // Grey
    }
  }
}
