import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/conversation_filter.dart';

/// Conversation with metadata for filtering
class ConversationWithMetadata {
  final Conversation conversation;
  final bool hasUrgentMessages;
  final bool hasRSDTriggers;
  final bool hasBoundaryViolations;
  final int unansweredCount;
  final int taskCount;
  final int overdueCount;
  
  ConversationWithMetadata({
    required this.conversation,
    this.hasUrgentMessages = false,
    this.hasRSDTriggers = false,
    this.hasBoundaryViolations = false,
    this.unansweredCount = 0,
    this.taskCount = 0,
    this.overdueCount = 0,
  });
  
  /// Check if conversation matches a filter
  bool matchesFilter(ConversationFilter filter) {
    switch (filter) {
      case ConversationFilter.all:
        return true;
      case ConversationFilter.urgent:
        return hasUrgentMessages;
      case ConversationFilter.rsd:
        return hasRSDTriggers;
      case ConversationFilter.boundary:
        return hasBoundaryViolations;
      case ConversationFilter.unanswered:
        return unansweredCount > 0;
      case ConversationFilter.tasks:
        return taskCount > 0;
      case ConversationFilter.overdue:
        return overdueCount > 0;
    }
  }
  
  /// Check if conversation matches any of the given filters
  bool matchesAnyFilter(Set<ConversationFilter> filters) {
    if (filters.isEmpty || filters.contains(ConversationFilter.all)) {
      return true;
    }
    return filters.any((filter) => matchesFilter(filter));
  }
  
  /// Get all active flags for this conversation
  Set<ConversationFilter> getActiveFilters() {
    final active = <ConversationFilter>{};
    if (hasUrgentMessages) active.add(ConversationFilter.urgent);
    if (hasRSDTriggers) active.add(ConversationFilter.rsd);
    if (hasBoundaryViolations) active.add(ConversationFilter.boundary);
    if (unansweredCount > 0) active.add(ConversationFilter.unanswered);
    if (taskCount > 0) active.add(ConversationFilter.tasks);
    if (overdueCount > 0) active.add(ConversationFilter.overdue);
    return active;
  }
}
