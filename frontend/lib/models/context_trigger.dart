/// Model for context triggers
class ContextTrigger {
  final String id;
  final String userId;
  final String followUpItemId;
  final String triggerType;
  final Map<String, dynamic> triggerConfig;
  final bool isActive;
  final int? lastTriggered;
  final int triggerCount;
  final int createdAt;
  final int updatedAt;

  ContextTrigger({
    required this.id,
    required this.userId,
    required this.followUpItemId,
    required this.triggerType,
    required this.triggerConfig,
    required this.isActive,
    this.lastTriggered,
    required this.triggerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContextTrigger.fromJson(Map<String, dynamic> json) {
    return ContextTrigger(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      followUpItemId: json['follow_up_item_id'] as String,
      triggerType: json['trigger_type'] as String,
      triggerConfig: json['trigger_config'] as Map<String, dynamic>,
      isActive: json['is_active'] as bool? ?? true,
      lastTriggered: json['last_triggered'] as int?,
      triggerCount: json['trigger_count'] as int? ?? 0,
      createdAt: json['created_at'] as int,
      updatedAt: json['updated_at'] as int,
    );
  }

  String getTriggerLabel() {
    switch (triggerType) {
      case 'app_opened':
        final app = triggerConfig['app'] as String?;
        return 'When you open ${app ?? "the app"}';
      case 'calendar_event':
        final event = triggerConfig['event'] as String?;
        return 'Before ${event ?? "calendar event"}';
      case 'location':
        final location = triggerConfig['location'] as String?;
        return 'At ${location ?? "this location"}';
      case 'time_of_day':
        final time = triggerConfig['time'] as String?;
        return 'At $time';
      case 'day_of_week':
        final day = triggerConfig['day'] as String?;
        return 'Every $day';
      default:
        return 'Context trigger';
    }
  }

  String getTriggerEmoji() {
    switch (triggerType) {
      case 'app_opened':
        return '📱';
      case 'calendar_event':
        return '📅';
      case 'location':
        return '📍';
      case 'time_of_day':
        return '⏰';
      case 'day_of_week':
        return '📆';
      default:
        return '🔔';
    }
  }
}

