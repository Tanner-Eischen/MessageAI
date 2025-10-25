import 'package:flutter/material.dart';

/// Available conversation filters
enum ConversationFilter {
  all,
  urgent,          // Smart Inbox: AI detected high priority
  rsd,             // Smart Inbox: Contains RSD triggers
  boundary,        // Smart Inbox: Boundary violations detected
  unanswered,      // Follow-up: They asked you questions
  tasks,           // Follow-up: You made promises
  overdue,         // Follow-up: Deadline passed
}

/// Configuration for each filter
class ConversationFilterConfig {
  final ConversationFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  
  const ConversationFilterConfig({
    required this.filter,
    required this.label,
    required this.icon,
    required this.color,
  });
  
  static const Map<ConversationFilter, ConversationFilterConfig> configs = {
    ConversationFilter.all: ConversationFilterConfig(
      filter: ConversationFilter.all,
      label: 'All',
      icon: Icons.inbox_rounded,
      color: Colors.grey,
    ),
    ConversationFilter.urgent: ConversationFilterConfig(
      filter: ConversationFilter.urgent,
      label: 'Urgent',
      icon: Icons.priority_high_rounded,
      color: Colors.red,
    ),
    ConversationFilter.rsd: ConversationFilterConfig(
      filter: ConversationFilter.rsd,
      label: 'RSD',
      icon: Icons.warning_amber_rounded,
      color: Colors.orange,
    ),
    ConversationFilter.boundary: ConversationFilterConfig(
      filter: ConversationFilter.boundary,
      label: 'Boundary',
      icon: Icons.shield_outlined,
      color: Colors.purple,
    ),
    ConversationFilter.unanswered: ConversationFilterConfig(
      filter: ConversationFilter.unanswered,
      label: 'Unanswered',
      icon: Icons.help_outline_rounded,
      color: Colors.blue,
    ),
    ConversationFilter.tasks: ConversationFilterConfig(
      filter: ConversationFilter.tasks,
      label: 'Tasks',
      icon: Icons.task_alt_rounded,
      color: Colors.green,
    ),
    ConversationFilter.overdue: ConversationFilterConfig(
      filter: ConversationFilter.overdue,
      label: 'Overdue',
      icon: Icons.schedule_rounded,
      color: Colors.deepOrange,
    ),
  };
}
