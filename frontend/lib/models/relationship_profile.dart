/// Model for relationship profile
class RelationshipProfile {
  final String id;
  final String userId;
  final String conversationId;
  final String participantName;
  final String? participantUserId;
  final String? relationshipType;
  final String? relationshipNotes;
  final String? conversationSummary;
  final List<String> safeTopics;
  final List<String> topicsToAvoid;
  final String? communicationStyle;
  final int? typicalResponseTime;
  final int totalMessages;
  final int? firstMessageAt;
  final int? lastMessageAt;

  RelationshipProfile({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.participantName,
    this.participantUserId,
    this.relationshipType,
    this.relationshipNotes,
    this.conversationSummary,
    this.safeTopics = const [],
    this.topicsToAvoid = const [],
    this.communicationStyle,
    this.typicalResponseTime,
    this.totalMessages = 0,
    this.firstMessageAt,
    this.lastMessageAt,
  });

  factory RelationshipProfile.fromJson(Map<String, dynamic> json) {
    return RelationshipProfile(
      id: json['profile_id'] as String? ?? json['id'] as String,
      userId: json['user_id'] as String,
      conversationId: json['conversation_id'] as String,
      participantName: json['participant_name'] as String,
      participantUserId: json['participant_user_id'] as String?,
      relationshipType: json['relationship_type'] as String?,
      relationshipNotes: json['relationship_notes'] as String?,
      conversationSummary: json['conversation_summary'] as String?,
      safeTopics: (json['safe_topics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      topicsToAvoid: (json['topics_to_avoid'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      communicationStyle: json['communication_style'] as String?,
      typicalResponseTime: json['typical_response_time'] as int?,
      totalMessages: json['total_messages'] as int? ?? 0,
      firstMessageAt: json['first_message_at'] as int?,
      lastMessageAt: json['last_message_at'] as int?,
    );
  }

  String getRelationshipEmoji() {
    switch (relationshipType?.toLowerCase()) {
      case 'boss':
        return '👔';
      case 'colleague':
        return '🤝';
      case 'friend':
        return '😊';
      case 'family':
        return '👨‍👩‍👧‍👦';
      case 'client':
        return '💼';
      default:
        return '👤';
    }
  }

  String formatResponseTime() {
    if (typicalResponseTime == null) return 'Unknown';

    final minutes = typicalResponseTime! ~/ 60;
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hr';

    final days = hours ~/ 24;
    return '$days days';
  }
}

