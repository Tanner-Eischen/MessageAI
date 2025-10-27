import 'package:messageai/models/peek_content.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/services/boundary_violation_service.dart';
import 'package:messageai/services/action_item_service.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/models/action_item.dart';

/// Service that bridges AI analysis results with Peek Zone content models
/// 
/// This service:
/// - Calls AI analysis services
/// - Converts their data to PeekContent types
/// - Manages content for display in peek zone
class PeekZoneService {
  final _boundaryService = BoundaryViolationService();
  final _actionItemService = ActionItemService();

  /// Convert AI analysis to RSDAnalysis for peek zone display
  /// Only creates RSD content if actual RSD triggers are detected
  Future<RSDAnalysis?> createRSDContent(
    Message message,
    Participant sender,
    AIAnalysis? analysis,
  ) async {
    try {
      // Only show RSD content if there are actual RSD triggers (not just alternative interpretations)
      if (analysis?.rsdTriggers == null || analysis!.rsdTriggers!.isEmpty) {
        return null;
      }
      
      // Still need alternative interpretations to show the analysis
      if (analysis.alternativeInterpretations == null || analysis.alternativeInterpretations!.isEmpty) {
        return null;
      }

      return RSDAnalysis(
        message: message,
        sender: sender,
        interpretations: analysis.alternativeInterpretations ?? [],
      );
    } catch (e) {
      print('❌ Error creating RSD content: $e');
      return null;
    }
  }

  /// Detect boundary violations and create BoundaryAnalysis for peek zone
  Future<BoundaryAnalysis?> createBoundaryContent(
    Message message,
  ) async {
    try {
      final violations = await _boundaryService.detectViolations(
        messageId: message.id,
        messageBody: message.body,
        senderId: message.senderId,
        messageTimestamp: message.createdAt,
      );

      if (violations == null || violations.violations.isEmpty) {
        return null;
      }

      final primaryViolation = violations.violations.first;
      
      // Map violation type to our enum
      final violationType = _mapViolationType(primaryViolation.type);

      // Build suggestions from violation data
      final suggestions = <String>[
        primaryViolation.suggestedGentle,
        primaryViolation.suggestedModerate,
        primaryViolation.suggestedFirm,
      ].where((s) => s.isNotEmpty).toList();

      return BoundaryAnalysis(
        message: message,
        violationType: violationType,
        frequency: violations.violationCount,
        suggestions: suggestions,
        explanation: primaryViolation.explanation,
      );
    } catch (e) {
      print('❌ Error creating boundary content: $e');
      return null;
    }
  }

  /// Create action item content from message analysis
  Future<ActionItemDetails?> createActionContent(
    Message message,
    Participant sender,
  ) async {
    try {
      print('🔍 PEEK_ZONE_SVC: Extracting action items from message: ${message.id}');
      
      // First, check if we already have action items for this message
      final existingItems = await _actionItemService.getMessageActionItems(message.id);
      
      if (existingItems.isNotEmpty) {
        print('✅ PEEK_ZONE_SVC: Found ${existingItems.length} existing action items');
        
        // Use the first/most recent action item
        final item = existingItems.first;
        final actionItem = ActionItem(
          id: item.id,
          followUpItemId: '', // Not available from existing items
          actionType: item.actionType,
          actionTarget: item.actionTarget,
          commitmentText: item.commitmentText,
          mentionedDeadline: null, // Not in ActionItemWithStatus
          extractedDeadline: item.extractedDeadline,
        );
        
        final dueDate = item.extractedDeadline != null 
          ? DateTime.fromMillisecondsSinceEpoch(item.extractedDeadline! * 1000)
          : null;
        
        final now = DateTime.now();
        final isOverdue = dueDate != null && dueDate.isBefore(now);
        
        return ActionItemDetails(
          action: actionItem,
          dueDate: dueDate,
          isOverdue: isOverdue,
          suggestions: [
            'Set a reminder',
            'Add to calendar',
            'Mark as complete when done',
          ],
        );
      }
      
      // No existing items, try to extract new ones
      print('🤖 PEEK_ZONE_SVC: No existing items, calling extraction backend...');
      
      final extractionResult = await _actionItemService.extractCommitments(
        messageId: message.id,
        messageBody: message.body,
        conversationId: message.conversationId,
      );
      
      if (extractionResult == null || extractionResult.actionItems.isEmpty) {
        print('ℹ️ PEEK_ZONE_SVC: No action items detected');
        return null;
      }
      
      print('✅ PEEK_ZONE_SVC: Extracted ${extractionResult.actionItems.length} action items');
      
      // Use the first extracted action item
      final extractedItem = extractionResult.actionItems.first;
      
      // Create ActionItem for display
      final actionItem = ActionItem(
        id: extractedItem.id,
        followUpItemId: '', // Not relevant for newly extracted items
        actionType: extractedItem.actionType,
        actionTarget: null,
        commitmentText: extractedItem.commitment,
        mentionedDeadline: null,
        extractedDeadline: extractedItem.deadline != null 
          ? extractedItem.deadline!.millisecondsSinceEpoch ~/ 1000
          : null,
      );
      
      final isOverdue = extractedItem.deadline != null && 
                       extractedItem.deadline!.isBefore(DateTime.now());
      
      return ActionItemDetails(
        action: actionItem,
        dueDate: extractedItem.deadline,
        isOverdue: isOverdue,
        suggestions: [
          'Set a reminder',
          'Add to calendar',
          'Mark as complete when done',
        ],
      );
    } catch (e, stackTrace) {
      print('❌ PEEK_ZONE_SVC: Error creating action content: $e');
      print('   Stack trace: $stackTrace');
      return null;
    }
  }

  /// Create relationship context peek content (default)
  Future<RelationshipContextPeek?> createRelationshipContext(
    Message message,
    Participant sender,
  ) async {
    try {
      // TODO: Fetch sender profile and communication patterns
      return RelationshipContextPeek(
        sender: sender,
        relationship: 'Contact', // TODO: Get actual relationship type
        communicationStyle: 'Direct', // TODO: Analyze actual style
        lastMessage: message.body.length > 50 
          ? '${message.body.substring(0, 47)}...' 
          : message.body,
        reliabilityScore: 75.0, // TODO: Calculate from history
      );
    } catch (e) {
      print('❌ Error creating relationship context: $e');
      return null;
    }
  }

  /// Map boundary violation type string to enum
  BoundaryViolationType _mapViolationType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'after_hours':
      case 'afterhours':
        return BoundaryViolationType.AFTER_HOURS;
      case 'guilt_trip':
      case 'guiltrip':
        return BoundaryViolationType.GUILT_TRIP;
      case 'urgent_pressure':
      case 'urgentpressure':
        return BoundaryViolationType.URGENT_PRESSURE;
      case 'repeated_requests':
      case 'repeatedrequests':
        return BoundaryViolationType.REPEATED_REQUESTS;
      default:
        return BoundaryViolationType.OTHER;
    }
  }

  /// Get the best peek content for a message
  /// Returns content in priority order: RSD > Boundary > Action > Relationship
  Future<PeekContent> getBestContent(
    Message message,
    Participant sender,
    AIAnalysis? analysis,
  ) async {
    try {
      // Try RSD first (highest priority)
      final rsdContent = await createRSDContent(message, sender, analysis);
      if (rsdContent != null) {
        return rsdContent;
      }

      // Try Boundary violation detection
      final boundaryContent = await createBoundaryContent(message);
      if (boundaryContent != null) {
        return boundaryContent;
      }

      // Try Action items
      final actionContent = await createActionContent(message, sender);
      if (actionContent != null) {
        return actionContent;
      }

      // Fallback to relationship context
      return await createRelationshipContext(message, sender) 
        ?? _createFallbackContent(sender);
    } catch (e) {
      print('❌ Error getting best content: $e');
      return _createFallbackContent(sender);
    }
  }

  /// Create fallback relationship context
  RelationshipContextPeek _createFallbackContent(Participant sender) {
    return RelationshipContextPeek(
      sender: sender,
      relationship: 'Contact',
      communicationStyle: 'Unknown',
      lastMessage: 'No recent context',
      reliabilityScore: 50.0,
    );
  }
}




  /// Derive conversation-level traits from history (stubbed)
  Future<ConversationTraits> _deriveTraits(String conversationId, String senderUserId) async {
    return ConversationTraits(
      sarcasm: 28,
      rsdTriggers: 12,
      literalness: 64,
      humor: 54,
      reciprocity: 72,
      avgResponseMinutes: 37,
    );
  }

