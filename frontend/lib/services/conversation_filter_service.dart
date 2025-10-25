import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/conversation_filter.dart';
import 'package:messageai/models/conversation_with_metadata.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/message_service.dart';

/// Service for filtering conversations based on AI analysis and follow-ups
class ConversationFilterService {
  final _aiService = AIAnalysisService();
  final _messageService = MessageService();
  
  /// Get metadata for a single conversation
  Future<ConversationWithMetadata> getConversationMetadata(
    Conversation conversation,
  ) async {
    try {
      // Get recent messages for this conversation (check last 20 messages)
      final messages = await _messageService.getRecentMessages(
        conversation.id,
        limit: 20,
      );
      
      // Get current user ID
      final currentUserId = _messageService.getCurrentUserId();
      
      // Check for AI flags in recent messages
      bool hasUrgent = false;
      bool hasRSD = false;
      bool hasBoundary = false;
      
      for (final message in messages) {
        // Skip messages from current user
        if (message.senderId == currentUserId) {
          continue;
        }
        
        // Try to get cached AI analysis
        try {
          final analysis = await _aiService.getAnalysis(message.id);
          if (analysis != null) {
            // Check for urgency (High or Critical)
            if (analysis.urgencyLevel == 'High' || 
                analysis.urgencyLevel == 'Critical') {
              hasUrgent = true;
            }
            
            // Check for RSD triggers
            if (analysis.rsdTriggers != null && 
                analysis.rsdTriggers!.isNotEmpty) {
              hasRSD = true;
            }
            
            // Check for boundary violations
            if (analysis.boundaryAnalysis?.hasViolation == true) {
              hasBoundary = true;
            }
          }
        } catch (e) {
          // Skip if analysis doesn't exist or failed
          continue;
        }
      }
      
      // TODO: Get follow-up counts from follow-up service
      // For now, hardcoded to 0
      int unansweredCount = 0;
      int taskCount = 0;
      int overdueCount = 0;
      
      return ConversationWithMetadata(
        conversation: conversation,
        hasUrgentMessages: hasUrgent,
        hasRSDTriggers: hasRSD,
        hasBoundaryViolations: hasBoundary,
        unansweredCount: unansweredCount,
        taskCount: taskCount,
        overdueCount: overdueCount,
      );
    } catch (e) {
      print('❌ Error getting conversation metadata: $e');
      // Return conversation with no metadata on error
      return ConversationWithMetadata(conversation: conversation);
    }
  }
  
  /// Filter conversations based on selected filters
  Future<List<ConversationWithMetadata>> filterConversations(
    List<Conversation> conversations,
    Set<ConversationFilter> activeFilters,
  ) async {
    // Get metadata for all conversations
    final withMetadata = await Future.wait(
      conversations.map((conv) => getConversationMetadata(conv)),
    );
    
    // Filter based on active filters
    return withMetadata
        .where((conv) => conv.matchesAnyFilter(activeFilters))
        .toList();
  }
  
  /// Calculate badge counts for all filters
  Future<Map<ConversationFilter, int>> getFilterCounts(
    List<ConversationWithMetadata> conversationsWithMeta,
  ) async {
    return {
      ConversationFilter.urgent: conversationsWithMeta
          .where((m) => m.hasUrgentMessages)
          .length,
      ConversationFilter.rsd: conversationsWithMeta
          .where((m) => m.hasRSDTriggers)
          .length,
      ConversationFilter.boundary: conversationsWithMeta
          .where((m) => m.hasBoundaryViolations)
          .length,
      ConversationFilter.unanswered: conversationsWithMeta
          .where((m) => m.unansweredCount > 0)
          .length,
      ConversationFilter.tasks: conversationsWithMeta
          .where((m) => m.taskCount > 0)
          .length,
      ConversationFilter.overdue: conversationsWithMeta
          .where((m) => m.overdueCount > 0)
          .length,
    };
  }
}
