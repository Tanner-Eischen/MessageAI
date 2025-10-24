import 'package:flutter/material.dart';

/// Follow-up item types
enum FollowUpItemType {
  actionItem('action_item', 'Action Item', Icons.task_alt),
  unansweredQuestion('unanswered_question', 'Unanswered Question', Icons.help_outline),
  pendingResponse('pending_response', 'Pending Response', Icons.pending),
  scheduledFollowup('scheduled_followup', 'Scheduled', Icons.schedule);

  final String value;
  final String displayName;
  final IconData icon;

  const FollowUpItemType(this.value, this.displayName, this.icon);

  static FollowUpItemType fromString(String value) {
    return FollowUpItemType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FollowUpItemType.pendingResponse,
    );
  }

  Color getColor() {
    switch (this) {
      case FollowUpItemType.actionItem:
        return Colors.orange;
      case FollowUpItemType.unansweredQuestion:
        return Colors.blue;
      case FollowUpItemType.pendingResponse:
        return Colors.purple;
      case FollowUpItemType.scheduledFollowup:
        return Colors.green;
    }
  }
}

/// Follow-up item status
enum FollowUpStatus {
  pending('pending'),
  completed('completed'),
  dismissed('dismissed'),
  snoozed('snoozed');

  final String value;
  const FollowUpStatus(this.value);

  static FollowUpStatus fromString(String value) {
    return FollowUpStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FollowUpStatus.pending,
    );
  }
}

/// Model for follow-up item
class FollowUpItem {
  final String id;
  final String userId;
  final String conversationId;
  final String? messageId;
  final FollowUpItemType itemType;
  final String title;
  final String? description;
  final String? extractedText;
  final FollowUpStatus status;
  final int priority;
  final int detectedAt;
  final int? dueAt;
  final int? remindAt;
  final int? snoozedUntil;
  final int? completedAt;
  final Map<String, dynamic>? triggers;

  FollowUpItem({
    required this.id,
    required this.userId,
    required this.conversationId,
    this.messageId,
    required this.itemType,
    required this.title,
    this.description,
    this.extractedText,
    required this.status,
    required this.priority,
    required this.detectedAt,
    this.dueAt,
    this.remindAt,
    this.snoozedUntil,
    this.completedAt,
    this.triggers,
  });

  factory FollowUpItem.fromJson(Map<String, dynamic> json) {
    return FollowUpItem(
      id: json['item_id'] as String? ?? json['id'] as String,
      userId: json['user_id'] as String,
      conversationId: json['conversation_id'] as String,
      messageId: json['message_id'] as String?,
      itemType: FollowUpItemType.fromString(json['item_type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      extractedText: json['extracted_text'] as String?,
      status: FollowUpStatus.fromString(json['status'] as String? ?? 'pending'),
      priority: json['priority'] as int,
      detectedAt: json['detected_at'] as int,
      dueAt: json['due_at'] as int?,
      remindAt: json['remind_at'] as int?,
      snoozedUntil: json['snoozed_until'] as int?,
      completedAt: json['completed_at'] as int?,
      triggers: json['triggers'] as Map<String, dynamic>?,
    );
  }

  bool get isOverdue {
    if (dueAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now > dueAt!;
  }

  bool get isDueSoon {
    if (dueAt == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hoursUntilDue = (dueAt! - now) / 3600;
    return hoursUntilDue > 0 && hoursUntilDue <= 24;
  }

  String getTimeUntilDue() {
    if (dueAt == null) return '';
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = dueAt! - now;
    
    if (diff < 0) return 'Overdue';
    if (diff < 3600) return '${diff ~/ 60}m';
    if (diff < 86400) return '${diff ~/ 3600}h';
    return '${diff ~/ 86400}d';
  }

  String getTimeSinceDetected() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - detectedAt;
    
    if (diff < 3600) return '${diff ~/ 60}m ago';
    if (diff < 86400) return '${diff ~/ 3600}h ago';
    return '${diff ~/ 86400}d ago';
  }
}

