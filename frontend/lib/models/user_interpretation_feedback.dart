
import 'package:uuid/uuid.dart';

/// Captures user feedback on which interpretation was actually correct
/// Used to improve confidence scoring and sender pattern recognition over time
class InterpretationFeedback {
  final String id;               // UUID for this feedback entry
  final String analysisId;       // Which analysis this feedback is for
  final String messageId;        // Which message triggered the analysis
  final String senderId;         // Who sent the original message
  final String userId;           // Who is providing the feedback
  final String? userChosenInterpretation;  // Which interpretation they selected (null = skipped)
  final int feedbackTimestamp;   // When they provided this feedback
  final bool? wasHelpful;        // Did this interpretation actually help them?
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const InterpretationFeedback({
    required this.id,
    required this.analysisId,
    required this.messageId,
    required this.senderId,
    required this.userId,
    this.userChosenInterpretation,
    required this.feedbackTimestamp,
    this.wasHelpful,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a new feedback entry with auto-generated UUID
  factory InterpretationFeedback.create({
    required String analysisId,
    required String messageId,
    required String senderId,
    required String userId,
    String? userChosenInterpretation,
    bool? wasHelpful,
  }) {
    final now = DateTime.now();
    return InterpretationFeedback(
      id: const Uuid().v4(),
      analysisId: analysisId,
      messageId: messageId,
      senderId: senderId,
      userId: userId,
      userChosenInterpretation: userChosenInterpretation,
      feedbackTimestamp: now.millisecondsSinceEpoch ~/ 1000,
      wasHelpful: wasHelpful,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from Supabase JSON response
  factory InterpretationFeedback.fromJson(Map<String, dynamic> json) {
    return InterpretationFeedback(
      id: json['id'] as String,
      analysisId: json['analysis_id'] as String,
      messageId: json['message_id'] as String,
      senderId: json['sender_id'] as String,
      userId: json['user_id'] as String,
      userChosenInterpretation: json['user_chosen_interpretation'] as String?,
      feedbackTimestamp: json['feedback_timestamp'] as int,
      wasHelpful: json['was_helpful'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'analysis_id': analysisId,
    'message_id': messageId,
    'sender_id': senderId,
    'user_id': userId,
    'user_chosen_interpretation': userChosenInterpretation,
    'feedback_timestamp': feedbackTimestamp,
    'was_helpful': wasHelpful,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Create a copy with updated fields (for mutations)
  InterpretationFeedback copyWith({
    String? userChosenInterpretation,
    bool? wasHelpful,
  }) {
    return InterpretationFeedback(
      id: id,
      analysisId: analysisId,
      messageId: messageId,
      senderId: senderId,
      userId: userId,
      userChosenInterpretation: userChosenInterpretation ?? this.userChosenInterpretation,
      feedbackTimestamp: feedbackTimestamp,
      wasHelpful: wasHelpful ?? this.wasHelpful,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if user has provided any feedback
  bool hasFeedback() {
    return userChosenInterpretation != null || wasHelpful != null;
  }

  @override
  String toString() => 'InterpretationFeedback(id: $id, senderId: $senderId, '
      'interpretation: $userChosenInterpretation, helpful: $wasHelpful)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretationFeedback &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
