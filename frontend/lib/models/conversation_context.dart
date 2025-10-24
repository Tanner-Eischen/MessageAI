/// Model for conversation context
class ConversationContext {
  final String conversationId;
  final String lastDiscussed;
  final List<KeyPoint> keyPoints;
  final List<String> pendingQuestions;
  final bool fromCache;
  final int? cacheAge;

  ConversationContext({
    required this.conversationId,
    required this.lastDiscussed,
    required this.keyPoints,
    required this.pendingQuestions,
    this.fromCache = false,
    this.cacheAge,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      conversationId: json['conversation_id'] as String? ?? '',
      lastDiscussed: json['last_discussed'] as String,
      keyPoints: (json['key_points'] as List<dynamic>)
          .map((e) => KeyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingQuestions: (json['pending_questions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
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

