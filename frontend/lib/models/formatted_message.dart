/// Result of message formatting
class FormattedMessage {
  final int originalLength;
  final String formattedMessage;
  final List<String> formattingApplied;
  final int characterCount;
  final String estimatedReadTime;
  final String? tone;
  final List<String>? actionItems;

  FormattedMessage({
    required this.originalLength,
    required this.formattedMessage,
    required this.formattingApplied,
    required this.characterCount,
    required this.estimatedReadTime,
    this.tone,
    this.actionItems,
  });

  factory FormattedMessage.fromJson(Map<String, dynamic> json) {
    return FormattedMessage(
      originalLength: json['original_length'] as int,
      formattedMessage: json['formatted_message'] as String,
      formattingApplied: (json['formatting_applied'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      characterCount: json['character_count'] as int,
      estimatedReadTime: json['estimated_read_time'] as String,
      tone: json['tone'] as String?,
      actionItems: json['action_items'] != null
          ? (json['action_items'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_length': originalLength,
      'formatted_message': formattedMessage,
      'formatting_applied': formattingApplied,
      'character_count': characterCount,
      'estimated_read_time': estimatedReadTime,
      if (tone != null) 'tone': tone,
      if (actionItems != null) 'action_items': actionItems,
    };
  }

  double getSavingsPercentage() {
    if (originalLength == 0) return 0;
    return ((originalLength - characterCount) / originalLength) * 100;
  }

  @override
  String toString() {
    return 'FormattedMessage(original: $originalLength chars, formatted: $characterCount chars, saved: ${getSavingsPercentage().toStringAsFixed(0)}%)';
  }
}

