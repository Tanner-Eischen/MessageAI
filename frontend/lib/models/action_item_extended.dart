/// Extended Action Item Model with Status Tracking (Feature #4)
class ActionItemWithStatus {
  final String id;
  final String commitmentText;
  final String actionType;
  final String? actionTarget;
  final String status;  // pending, in_progress, completed, rescheduled, cancelled
  final int? extractedDeadline;  // Unix timestamp
  final bool deadlineEstimated;
  final DateTime? statusUpdatedAt;
  final DateTime createdAt;
  final int daysUntilDue;
  final bool isOverdue;
  final bool isCompleted;
  
  ActionItemWithStatus({
    required this.id,
    required this.commitmentText,
    required this.actionType,
    this.actionTarget,
    required this.status,
    this.extractedDeadline,
    required this.deadlineEstimated,
    this.statusUpdatedAt,
    required this.createdAt,
    required this.daysUntilDue,
    required this.isOverdue,
    required this.isCompleted,
  });

  factory ActionItemWithStatus.fromJson(Map<String, dynamic> json) {
    final extractedDeadline = json['extracted_deadline'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Calculate days until due
    int daysUntilDue = 0;
    bool isOverdue = false;
    
    if (extractedDeadline != null) {
      final daysDiff = (extractedDeadline - now) ~/ 86400;
      daysUntilDue = daysDiff > 0 ? daysDiff : 0;
      isOverdue = extractedDeadline < now && 
                  (json['status'] as String?) != 'completed';
    }
    
    final status = json['status'] as String? ?? 'pending';
    final isCompleted = status == 'completed';
    
    return ActionItemWithStatus(
      id: json['id'] as String,
      commitmentText: json['commitment_text'] as String,
      actionType: json['action_type'] as String,
      actionTarget: json['action_target'] as String?,
      status: status,
      extractedDeadline: extractedDeadline,
      deadlineEstimated: (json['deadline_estimated'] as bool?) ?? false,
      statusUpdatedAt: json['status_updated_at'] != null 
          ? DateTime.parse(json['status_updated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      daysUntilDue: daysUntilDue,
      isOverdue: isOverdue,
      isCompleted: isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commitment_text': commitmentText,
      'action_type': actionType,
      if (actionTarget != null) 'action_target': actionTarget,
      'status': status,
      if (extractedDeadline != null) 'extracted_deadline': extractedDeadline,
      'deadline_estimated': deadlineEstimated,
      if (statusUpdatedAt != null) 'status_updated_at': statusUpdatedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get emoji for action type
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

  /// Get status emoji
  String getStatusEmoji() {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'in_progress':
        return '⚙️';
      case 'completed':
        return '✅';
      case 'rescheduled':
        return '📅';
      case 'cancelled':
        return '❌';
      default:
        return '•';
    }
  }

  /// Get status label
  String getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'rescheduled':
        return 'Rescheduled';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Get urgency color based on deadline
  String getUrgencyColor() {
    if (isCompleted) return '#10B981';  // green
    if (isOverdue) return '#EF4444';    // red
    if (daysUntilDue == 0) return '#F59E0B';  // amber
    if (daysUntilDue <= 2) return '#FB923C';  // orange
    return '#3B82F6';  // blue
  }

  /// Format deadline for display
  String formatDeadline() {
    if (extractedDeadline == null) return 'No deadline';
    
    final deadline = DateTime.fromMillisecondsSinceEpoch(extractedDeadline! * 1000);
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    if (deadline.year == today.year &&
        deadline.month == today.month &&
        deadline.day == today.day) {
      return 'Today at ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
    }
    
    if (deadline.year == tomorrow.year &&
        deadline.month == tomorrow.month &&
        deadline.day == tomorrow.day) {
      return 'Tomorrow at ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
    }
    
    return '${deadline.month}/${deadline.day} at ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionItemWithStatus &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActionItemWithStatus(id: $id, text: $commitmentText, status: $status, due: $daysUntilDue days)';
  }
}

/// Commitment Streak Model (Gamification)
class CommitmentStreak {
  final String userId;
  final int currentStreakCount;
  final DateTime? currentStreakStartedAt;
  final int bestStreakCount;
  final DateTime? bestStreakStartedAt;
  final int totalCompleted;
  final int totalCommitments;
  final double completionRate;  // 0.0 to 1.0

  CommitmentStreak({
    required this.userId,
    required this.currentStreakCount,
    this.currentStreakStartedAt,
    required this.bestStreakCount,
    this.bestStreakStartedAt,
    required this.totalCompleted,
    required this.totalCommitments,
    required this.completionRate,
  });

  factory CommitmentStreak.fromJson(Map<String, dynamic> json) {
    return CommitmentStreak(
      userId: json['user_id'] as String,
      currentStreakCount: json['current_streak_count'] as int? ?? 0,
      currentStreakStartedAt: json['current_streak_started_at'] != null
          ? DateTime.parse(json['current_streak_started_at'] as String)
          : null,
      bestStreakCount: json['best_streak_count'] as int? ?? 0,
      bestStreakStartedAt: json['best_streak_started_at'] != null
          ? DateTime.parse(json['best_streak_started_at'] as String)
          : null,
      totalCompleted: json['total_completed'] as int? ?? 0,
      totalCommitments: json['total_commitments'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_streak_count': currentStreakCount,
      if (currentStreakStartedAt != null)
        'current_streak_started_at': currentStreakStartedAt!.toIso8601String(),
      'best_streak_count': bestStreakCount,
      if (bestStreakStartedAt != null)
        'best_streak_started_at': bestStreakStartedAt!.toIso8601String(),
      'total_completed': totalCompleted,
      'total_commitments': totalCommitments,
      'completion_rate': completionRate,
    };
  }

  /// Get motivational message based on streak
  String getMotivationalMessage() {
    if (currentStreakCount == 0) {
      return '🚀 Start your promise-keeping streak today!';
    }
    
    if (currentStreakCount == 1) {
      return '🔥 You\'re on a roll! 1 commitment kept';
    }
    
    if (currentStreakCount < 7) {
      return '🔥 Amazing! $currentStreakCount days in a row';
    }
    
    if (currentStreakCount < 30) {
      return '🔥🔥 Incredible! $currentStreakCount days - almost a month!';
    }
    
    if (currentStreakCount < 100) {
      return '🔥🔥🔥 WOW! $currentStreakCount days - you\'re unstoppable!';
    }
    
    return '👑 LEGENDARY! $currentStreakCount days keeping your word!';
  }

  /// Get percentage of completion
  int getCompletionPercentage() {
    return (completionRate * 100).round();
  }

  /// Check if on track to beat personal best
  bool isOnTrackForNewBest() {
    return currentStreakCount > bestStreakCount;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitmentStreak &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'CommitmentStreak(streak: $currentStreakCount, best: $bestStreakCount, rate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}
