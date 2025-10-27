/// Feature #5: Conversation "Catch Me Up" Summary Models
/// Helps ADHD users understand conversation context after 24+ hours away
library;

/// Main conversation summary model
class ConversationSummary {
  final String id;
  final String conversationId;
  final String lastDiscussed;
  final List<String> theirQuestions;
  final List<String> userCommitments;
  final String conversationTone;
  final String lastMessageFromThem;
  final List<String> keyPoints;
  final String emotionalContext;
  final String suggestedResponseAngle;
  final double confidence;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool isValid;

  ConversationSummary({
    required this.id,
    required this.conversationId,
    required this.lastDiscussed,
    required this.theirQuestions,
    required this.userCommitments,
    required this.conversationTone,
    required this.lastMessageFromThem,
    required this.keyPoints,
    required this.emotionalContext,
    required this.suggestedResponseAngle,
    required this.confidence,
    required this.generatedAt,
    required this.expiresAt,
    this.isValid = true,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      lastDiscussed: json['last_discussed'] as String? ?? '',
      theirQuestions: List<String>.from(json['their_questions'] as List? ?? []),
      userCommitments:
          List<String>.from(json['user_commitments'] as List? ?? []),
      conversationTone: json['conversation_tone'] as String? ?? 'neutral',
      lastMessageFromThem: json['last_message_from_them'] as String? ?? '',
      keyPoints: List<String>.from(json['key_points'] as List? ?? []),
      emotionalContext: json['emotional_context'] as String? ?? '',
      suggestedResponseAngle: json['suggested_response_angle'] as String? ?? '',
      confidence: (json['summary_confidence'] as num?)?.toDouble() ?? 0.85,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      isValid: (json['is_valid'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'last_discussed': lastDiscussed,
      'their_questions': theirQuestions,
      'user_commitments': userCommitments,
      'conversation_tone': conversationTone,
      'last_message_from_them': lastMessageFromThem,
      'key_points': keyPoints,
      'emotional_context': emotionalContext,
      'suggested_response_angle': suggestedResponseAngle,
      'summary_confidence': confidence,
      'generated_at': generatedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_valid': isValid,
    };
  }

  /// Get emoji for conversation tone
  String getToneEmoji() {
    switch (conversationTone.toLowerCase()) {
      case 'excited':
        return '🤩';
      case 'happy':
        return '😊';
      case 'grateful':
        return '🙏';
      case 'supportive':
        return '💪';
      case 'concerned':
        return '😟';
      case 'worried':
        return '😰';
      case 'angry':
        return '😠';
      case 'sarcastic':
        return '😏';
      case 'casual':
        return '👋';
      default:
        return '💬';
    }
  }

  /// Get human-readable tone label
  String getToneLabel() {
    return conversationTone[0].toUpperCase() +
        conversationTone.substring(1).toLowerCase();
  }

  /// Check if summary is still valid
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt) || !isValid;
  }

  /// Get confidence percentage (0-100)
  int getConfidencePercentage() {
    return (confidence * 100).toInt();
  }

  /// Get confidence badge text
  String getConfidenceBadge() {
    final percentage = getConfidencePercentage();
    if (percentage >= 90) return '✅ Very accurate';
    if (percentage >= 75) return '👍 Accurate';
    if (percentage >= 60) return '⚠️ Moderate confidence';
    return '❓ Lower confidence';
  }

  /// Format quick summary for display
  String formatQuickSummary() {
    final buffer = StringBuffer();

    buffer.writeln('📌 **Last Discussed**');
    buffer.writeln(lastDiscussed);
    buffer.writeln();

    if (theirQuestions.isNotEmpty) {
      buffer.writeln('💬 **Their Questions**');
      for (final q in theirQuestions) {
        buffer.writeln('  • $q');
      }
      buffer.writeln();
    }

    if (userCommitments.isNotEmpty) {
      buffer.writeln('✅ **Your Commitments**');
      for (final c in userCommitments) {
        buffer.writeln('  • $c');
      }
      buffer.writeln();
    }

    buffer.writeln('😊 **Tone**: ${getToneLabel()}');
    buffer.writeln('🎯 **Confidence**: ${getConfidenceBadge()}');

    return buffer.toString().trim();
  }

  /// Check if summary is worth showing (not expired and valid)
  bool shouldShow() {
    return !isExpired() && isValid && lastDiscussed.isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSummary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ConversationSummary(id: $id, tone: $conversationTone, confidence: $confidence)';
}

/// Extended summary with full details
class ConversationSummaryExtended extends ConversationSummary {
  final String fullSummary;
  final List<String> untrackedQuestions;
  final List<String> mentionedActionItems;

  ConversationSummaryExtended({
    required super.id,
    required super.conversationId,
    required super.lastDiscussed,
    required super.theirQuestions,
    required super.userCommitments,
    required super.conversationTone,
    required super.lastMessageFromThem,
    required super.keyPoints,
    required super.emotionalContext,
    required super.suggestedResponseAngle,
    required super.confidence,
    required super.generatedAt,
    required super.expiresAt,
    super.isValid,
    required this.fullSummary,
    required this.untrackedQuestions,
    required this.mentionedActionItems,
  });

  factory ConversationSummaryExtended.fromJson(Map<String, dynamic> json) {
    final base = ConversationSummary.fromJson(json);
    return ConversationSummaryExtended(
      id: base.id,
      conversationId: base.conversationId,
      lastDiscussed: base.lastDiscussed,
      theirQuestions: base.theirQuestions,
      userCommitments: base.userCommitments,
      conversationTone: base.conversationTone,
      lastMessageFromThem: base.lastMessageFromThem,
      keyPoints: base.keyPoints,
      emotionalContext: base.emotionalContext,
      suggestedResponseAngle: base.suggestedResponseAngle,
      confidence: base.confidence,
      generatedAt: base.generatedAt,
      expiresAt: base.expiresAt,
      isValid: base.isValid,
      fullSummary: json['full_summary'] as String? ?? '',
      untrackedQuestions: List<String>.from(json['untracked_questions'] as List? ?? []),
      mentionedActionItems: List<String>.from(json['mentioned_action_items'] as List? ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'full_summary': fullSummary,
      'untracked_questions': untrackedQuestions,
      'mentioned_action_items': mentionedActionItems,
    };
  }

  /// Format full summary for detailed view
  String formatFullSummary() {
    final buffer = StringBuffer();

    buffer.writeln('📌 **What You Discussed**');
    buffer.writeln(lastDiscussed);
    buffer.writeln();

    if (fullSummary.isNotEmpty) {
      buffer.writeln('📝 **Full Summary**');
      buffer.writeln(fullSummary);
      buffer.writeln();
    }

    if (keyPoints.isNotEmpty) {
      buffer.writeln('📍 **Key Points**');
      for (final point in keyPoints) {
        buffer.writeln('  • $point');
      }
      buffer.writeln();
    }

    if (theirQuestions.isNotEmpty) {
      buffer.writeln('💬 **Their Questions**');
      for (final q in theirQuestions) {
        buffer.writeln('  • $q');
      }
      buffer.writeln();
    }

    if (untrackedQuestions.isNotEmpty) {
      buffer.writeln('❓ **Unanswered Questions**');
      for (final q in untrackedQuestions) {
        buffer.writeln('  • $q');
      }
      buffer.writeln();
    }

    if (userCommitments.isNotEmpty) {
      buffer.writeln('✅ **Your Commitments**');
      for (final c in userCommitments) {
        buffer.writeln('  • $c');
      }
      buffer.writeln();
    }

    if (mentionedActionItems.isNotEmpty) {
      buffer.writeln('🎯 **Mentioned Action Items**');
      for (final item in mentionedActionItems) {
        buffer.writeln('  • $item');
      }
      buffer.writeln();
    }

    if (emotionalContext.isNotEmpty) {
      buffer.writeln('❤️ **Emotional Context**');
      buffer.writeln(emotionalContext);
      buffer.writeln();
    }

    if (suggestedResponseAngle.isNotEmpty) {
      buffer.writeln('💡 **How to Respond**');
      buffer.writeln(suggestedResponseAngle);
      buffer.writeln();
    }

    buffer.writeln('💭 **Last Message**');
    buffer.writeln('"$lastMessageFromThem"');

    return buffer.toString().trim();
  }
}

/// Summary trigger reason
enum SummaryTrigger {
  inactivity24h,
  messageThreshold,
  manual,
  none;

  String get label {
    switch (this) {
      case SummaryTrigger.inactivity24h:
        return 'After 24+ hours away';
      case SummaryTrigger.messageThreshold:
        return '20+ new messages';
      case SummaryTrigger.manual:
        return 'You asked for summary';
      case SummaryTrigger.none:
        return 'Not triggered';
    }
  }

  String get emoji {
    switch (this) {
      case SummaryTrigger.inactivity24h:
        return '⏰';
      case SummaryTrigger.messageThreshold:
        return '💬';
      case SummaryTrigger.manual:
        return '🔍';
      case SummaryTrigger.none:
        return '•';
    }
  }
}

/// Summary generation status
class SummaryStatus {
  final bool shouldShow;
  final SummaryTrigger trigger;
  final int inactivityHours;
  final int newMessagesCount;

  SummaryStatus({
    required this.shouldShow,
    required this.trigger,
    required this.inactivityHours,
    required this.newMessagesCount,
  });

  factory SummaryStatus.fromJson(Map<String, dynamic> json) {
    SummaryTrigger parseTrigger(String? trigger) {
      switch (trigger) {
        case 'inactivity_24h':
          return SummaryTrigger.inactivity24h;
        case 'message_threshold':
          return SummaryTrigger.messageThreshold;
        case 'manual':
          return SummaryTrigger.manual;
        default:
          return SummaryTrigger.none;
      }
    }

    return SummaryStatus(
      shouldShow: (json['should_show'] as bool?) ?? false,
      trigger: parseTrigger(json['trigger_type'] as String?),
      inactivityHours: (json['inactivity_hours'] as int?) ?? 0,
      newMessagesCount: (json['new_messages_count'] as int?) ?? 0,
    );
  }

  String getDescription() {
    if (!shouldShow) return 'No summary needed';
    
    if (trigger == SummaryTrigger.inactivity24h) {
      return '${trigger.emoji} You\'ve been away for $inactivityHours hours';
    }
    
    if (trigger == SummaryTrigger.messageThreshold) {
      return '${trigger.emoji} $newMessagesCount new messages while you were away';
    }
    
    return '${trigger.emoji} ${trigger.label}';
  }
}
