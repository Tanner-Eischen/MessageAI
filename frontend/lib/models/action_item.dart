/// Model for action item details
class ActionItem {
  final String id;
  final String followUpItemId;
  final String actionType;
  final String? actionTarget;
  final String commitmentText;
  final String? mentionedDeadline;
  final int? extractedDeadline;

  ActionItem({
    required this.id,
    required this.followUpItemId,
    required this.actionType,
    this.actionTarget,
    required this.commitmentText,
    this.mentionedDeadline,
    this.extractedDeadline,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] as String,
      followUpItemId: json['follow_up_item_id'] as String,
      actionType: json['action_type'] as String,
      actionTarget: json['action_target'] as String?,
      commitmentText: json['commitment_text'] as String,
      mentionedDeadline: json['mentioned_deadline'] as String?,
      extractedDeadline: json['extracted_deadline'] as int?,
    );
  }

  String getActionEmoji() {
    switch (actionType.toLowerCase()) {
      case 'send':
        return '📤';
      case 'call':
        return '📞';
      case 'meet':
        return '🤝';
      case 'review':
        return '📋';
      case 'decide':
        return '🤔';
      case 'follow_up':
        return '🔄';
      case 'check':
        return '✅';
      case 'schedule':
        return '📅';
      default:
        return '📌';
    }
  }
}

