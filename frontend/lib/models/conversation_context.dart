/// Model for conversation context
class ConversationContext {
  final String conversationId;
  final String lastDiscussed;
  final List<KeyPoint> keyPoints;
  final List<String> pendingQuestions;
  final List<SafeTopic>? safeTopics;
  final String? relationshipType;
  final bool fromCache;
  final int? cacheAge;

  ConversationContext({
    required this.conversationId,
    required this.lastDiscussed,
    required this.keyPoints,
    required this.pendingQuestions,
    this.safeTopics,
    this.relationshipType,
    this.fromCache = false,
    this.cacheAge,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    // 🔧 FIXED: Handle key_points that come as List<String> from backend
    List<KeyPoint> parseKeyPoints(dynamic keyPointsData) {
      if (keyPointsData == null) return [];
      
      if (keyPointsData is List<dynamic>) {
        return keyPointsData.map((e) {
          if (e is Map<String, dynamic>) {
            // Already a KeyPoint map
            return KeyPoint.fromJson(e);
          } else if (e is String) {
            // String from backend - create KeyPoint with current timestamp
            return KeyPoint(
              text: e,
              timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            );
          }
          return null;
        }).whereType<KeyPoint>().toList();
      }
      return [];
    }
    
    return ConversationContext(
      conversationId: json['conversation_id'] as String? ?? '',
      lastDiscussed: json['last_discussed'] as String,
      keyPoints: parseKeyPoints(json['key_points']),
      pendingQuestions: (json['pending_questions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      safeTopics: (json['safe_topics'] as List<dynamic>?)
          ?.map((e) => SafeTopic.fromJson(e as Map<String, dynamic>))
          .toList(),
      relationshipType: json['relationship_type'] as String?,
      fromCache: json['from_cache'] as bool? ?? false,
      cacheAge: json['cache_age'] as int?,
    );
  }
}

/// Key point from conversation
class KeyPoint {
  final String text;
  final int timestamp;

  KeyPoint({
    required this.text,
    required this.timestamp,
  });

  factory KeyPoint.fromJson(Map<String, dynamic> json) {
    return KeyPoint(
      text: json['text'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  String getTimeAgo() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - timestamp;

    if (diff < 60) return 'just now';
    if (diff < 3600) return '${diff ~/ 60}m ago';
    if (diff < 86400) return '${diff ~/ 3600}h ago';
    if (diff < 604800) return '${diff ~/ 86400}d ago';
    return '${diff ~/ 604800}w ago';
  }
}

/// Safe topic model
class SafeTopic {
  final String id;
  final String name;
  final String emoji;
  final int frequency;

  SafeTopic({
    required this.id,
    required this.name,
    required this.emoji,
    required this.frequency,
  });

  factory SafeTopic.fromJson(Map<String, dynamic> json) {
    return SafeTopic(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['topic_name'] as String? ?? 'Topic',
      emoji: json['emoji'] as String? ?? '🗣️',
      frequency: json['frequency'] as int? ?? 0,
    );
  }
}

