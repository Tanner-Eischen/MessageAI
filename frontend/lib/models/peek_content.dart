import 'package:flutter/material.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/models/action_item.dart';

/// ============================================================================
/// BOUNDARY VIOLATION TYPES - Top-level enum
/// ============================================================================

enum BoundaryViolationType {
  AFTER_HOURS,
  GUILT_TRIP,
  URGENT_PRESSURE,
  REPEATED_REQUESTS,
  OTHER;

  String get displayName {
    switch (this) {
      case BoundaryViolationType.AFTER_HOURS:
        return 'After-hours request';
      case BoundaryViolationType.GUILT_TRIP:
        return 'Guilt-tripping language';
      case BoundaryViolationType.URGENT_PRESSURE:
        return 'Urgent pressure';
      case BoundaryViolationType.REPEATED_REQUESTS:
        return 'Repeated requests';
      case BoundaryViolationType.OTHER:
        return 'Boundary concern';
    }
  }
}

/// Abstract base class for all content that can appear in the Peek Zone
abstract class PeekContent {
  /// Display title with emoji prefix
  String get title;
  
  /// Icon to display
  IconData get icon;
  
  /// Color for the icon and accents
  Color get color;
  
  /// Unique type identifier for deduplication in intervention queue
  String get contentType;
}

/// ============================================================================
/// RSD TRIGGER ANALYSIS - Appears when RSD-triggering patterns detected
/// ============================================================================

class RSDAnalysis extends PeekContent {
  final Message message;
  final Participant sender;
  final List<MessageInterpretation> interpretations;

  RSDAnalysis({
    required this.message,
    required this.sender,
    required this.interpretations,
  });

  @override
  String get title => '🧠 RSD: "${message.body.length > 30 ? '${message.body.substring(0, 27)}...' : message.body}"';
  
  @override
  IconData get icon => Icons.psychology_outlined;
  
  @override
  Color get color => Colors.amber;
  
  @override
  String get contentType => 'RSDAnalysis';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RSDAnalysis &&
          runtimeType == other.runtimeType &&
          message.id == other.message.id;

  @override
  int get hashCode => message.id.hashCode;
}

/// ============================================================================
/// BOUNDARY VIOLATION DETECTION - Appears when boundary patterns detected
/// ============================================================================

class BoundaryAnalysis extends PeekContent {
  final Message message;
  final BoundaryViolationType violationType;
  final int frequency;
  final List<String> suggestions;
  final String? explanation;

  BoundaryAnalysis({
    required this.message,
    required this.violationType,
    required this.frequency,
    required this.suggestions,
    this.explanation,
  });

  @override
  String get title => '⚠️ Boundary: ${violationType.displayName}';
  
  @override
  IconData get icon => Icons.block;
  
  @override
  Color get color => Colors.orange;
  
  @override
  String get contentType => 'BoundaryAnalysis';

  /// Human-readable ordinal suffix (1st, 2nd, 3rd, etc.)
  String get frequencyOrdinal {
    if (frequency % 100 >= 11 && frequency % 100 <= 13) return '${frequency}th';
    switch (frequency % 10) {
      case 1:
        return '${frequency}st';
      case 2:
        return '${frequency}nd';
      case 3:
        return '${frequency}rd';
      default:
        return '${frequency}th';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundaryAnalysis &&
          runtimeType == other.runtimeType &&
          message.id == other.message.id &&
          violationType == other.violationType;

  @override
  int get hashCode => message.id.hashCode ^ violationType.hashCode;
}

/// ============================================================================
/// ACTION ITEM TRACKING - Appears when commitments/deadlines detected
/// ============================================================================

class ActionItemDetails extends PeekContent {
  final ActionItem action;
  final DateTime? dueDate;
  final bool isOverdue;
  final List<String> suggestions;

  ActionItemDetails({
    required this.action,
    this.dueDate,
    this.isOverdue = false,
    required this.suggestions,
  });

  @override
  String get title => '✅ Action: ${action.commitmentText.length > 30 ? '${action.commitmentText.substring(0, 27)}...' : action.commitmentText}';
  
  @override
  IconData get icon => Icons.check_circle;
  
  @override
  Color get color => isOverdue ? Colors.red : Colors.green;
  
  @override
  String get contentType => 'ActionItemDetails';

  /// Format due date for display
  String get dueDateFormatted {
    if (dueDate == null) return 'No date set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (dueDay == today) return 'Today';
    if (dueDay == tomorrow) return 'Tomorrow';
    
    final daysLeft = dueDay.difference(today).inDays;
    if (daysLeft < 0) return '$daysLeft days ago';
    if (daysLeft == 0) return 'Today';
    return 'In $daysLeft days';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionItemDetails &&
          runtimeType == other.runtimeType &&
          action.id == other.action.id;

  @override
  int get hashCode => action.id.hashCode;
}

/// ============================================================================
/// RELATIONSHIP CONTEXT - Default peek zone content showing sender patterns
/// ============================================================================

class RelationshipContextPeek extends PeekContent {
  final Participant sender;
  final String relationship;
  final String communicationStyle;
  final String lastMessage;
  final double reliabilityScore; // 0-100
  final ConversationTraits? traits;

  RelationshipContextPeek({
    required this.sender,
    required this.relationship,
    required this.communicationStyle,
    required this.lastMessage,
    required this.reliabilityScore,
    this.traits,
  });

  @override
  String get title => sender.userId;
  
  @override
  IconData get icon => Icons.person;
  
  @override
  Color get color => Colors.blue;
  
  @override
  String get contentType => 'RelationshipContext';

  /// Generate star rating from score (0-5 stars)
  int get starRating {
    return (reliabilityScore / 20).round().clamp(0, 5);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipContextPeek &&
          runtimeType == other.runtimeType &&
          sender.userId == other.sender.userId;

  @override
  int get hashCode => sender.userId.hashCode;
}

/// Conversation-level trait metrics used by RelationshipContextPeek
class ConversationTraits {
  /// 0-100 likelihood or prevalence scores
  final double sarcasm;
  final double rsdTriggers; // frequency of RSD-triggering patterns
  final double literalness; // higher = more literal
  final double humor;       // higher = more humor/jokes
  final double reciprocity; // turn-taking / balance

  /// Average response time in minutes for the other party
  final double avgResponseMinutes;

  ConversationTraits({
    required this.sarcasm,
    required this.rsdTriggers,
    required this.literalness,
    required this.humor,
    required this.reciprocity,
    required this.avgResponseMinutes,
  });
}

/// ============================================================================
/// UTILITY EXTENSIONS
/// ============================================================================

/// Extension to easily identify content types
extension PeekContentExtension on PeekContent {
  bool get isRSDAnalysis => this is RSDAnalysis;
  bool get isBoundaryAnalysis => this is BoundaryAnalysis;
  bool get isActionItem => this is ActionItemDetails;
  bool get isRelationshipContext => this is RelationshipContextPeek;

  RSDAnalysis? asRSDAnalysis() => this is RSDAnalysis ? this as RSDAnalysis : null;
  BoundaryAnalysis? asBoundaryAnalysis() => this is BoundaryAnalysis ? this as BoundaryAnalysis : null;
  ActionItemDetails? asActionItemDetails() => this is ActionItemDetails ? this as ActionItemDetails : null;
  RelationshipContextPeek? asRelationshipContext() => this is RelationshipContextPeek ? this as RelationshipContextPeek : null;
}
