import 'package:messageai/data/remote/supabase_client.dart';

/// Model for sender communication pattern
class SenderPatternData {
  final String senderId;
  final int totalMessages;
  final String communicationStyle; // "brief_and_direct", "warm_and_verbose", "balanced"
  final double averageHelpfulness;
  final String context; // Formatted string for UI display
  final bool hasData; // Whether we have enough samples (3+)

  const SenderPatternData({
    required this.senderId,
    required this.totalMessages,
    required this.communicationStyle,
    required this.averageHelpfulness,
    required this.context,
    required this.hasData,
  });

  factory SenderPatternData.fromJson(Map<String, dynamic> json) {
    return SenderPatternData(
      senderId: json['profile']['senderId'] as String,
      totalMessages: json['profile']['totalMessages'] as int,
      communicationStyle: json['profile']['communicationStyle'] as String,
      averageHelpfulness: (json['profile']['averageHelpfulness'] as num).toDouble(),
      context: json['context'] as String? ?? '',
      hasData: json['hasData'] as bool? ?? false,
    );
  }
}

/// Service for fetching and managing sender communication patterns
class AISenderPatternService {
  final _supabase = SupabaseClientProvider.client;

  /// Get communication patterns for a sender
  /// NOTE: analysis_feedback table doesn't exist yet, returning null
  /// Returns null if unable to fetch or if insufficient data
  Future<SenderPatternData?> getSenderPatterns(String senderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      print('⏭️  Sender patterns feature not yet available');
      // TODO: Implement when analysis_feedback table is created
      return null;
    } catch (e) {
      print('⚠️ Error fetching sender patterns: $e');
      return null;
    }
  }

  /// Get patterns for multiple senders (batch)
  Future<Map<String, SenderPatternData>> getSenderPatternsBatch(
    List<String> senderIds,
  ) async {
    final results = <String, SenderPatternData>{};

    for (final senderId in senderIds) {
      final pattern = await getSenderPatterns(senderId);
      if (pattern != null) {
        results[senderId] = pattern;
      }
    }

    return results;
  }

  /// Get pattern context formatted for display in UI
  String formatPatternForDisplay(SenderPatternData pattern) {
    if (!pattern.hasData) {
      return 'Learning communication style...';
    }

    final helpfulnessPercent = (pattern.averageHelpfulness * 100).toStringAsFixed(0);
    return '''${pattern.communicationStyle.replaceAll('_', ' ').toUpperCase()}
${pattern.totalMessages} messages analyzed
$helpfulnessPercent% of analyses were helpful''';
  }
}
