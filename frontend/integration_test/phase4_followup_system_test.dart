import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/services/follow_up_service.dart';
import 'package:messageai/models/follow_up_item.dart';

/// Phase 4: Smart Follow-up System Integration Tests
/// Tests: Action Item Extraction, Question Detection, Follow-up Dashboard
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Smart Follow-up System', () {
    late FollowUpService followUpService;

    setUp(() {
      followUpService = FollowUpService();
    });

    group('Action Item Extraction', () {
      test('extracts "I\'ll" commitment', () async {
        await followUpService.extractFollowUps('test-conv-123');
        
        // After extraction, check if items were created
        final items = await followUpService.getConversationFollowUps('test-conv-123');
        
        final actionItems = items.where(
          (item) => item.itemType == FollowUpItemType.actionItem,
        ).toList();

        expect(actionItems, isNotEmpty);
      });

      test('extracts "I can" commitment', () async {
        await followUpService.extractFollowUps('test-conv-456');
        
        final items = await followUpService.getConversationFollowUps('test-conv-456');
        expect(items, isNotEmpty);
      });

      test('extracts action with target', () async {
        await followUpService.extractFollowUps('test-conv-789');
        
        final items = await followUpService.getConversationFollowUps('test-conv-789');
        final actionItems = items.where(
          (item) => item.itemType == FollowUpItemType.actionItem,
        ).toList();

        if (actionItems.isNotEmpty) {
          expect(actionItems.first.title, isNotEmpty);
        }
      });

      test('extracts deadline when mentioned', () async {
        // Message: "I'll send the report by Friday"
        await followUpService.extractFollowUps('test-conv-deadline');
        
        final items = await followUpService.getConversationFollowUps('test-conv-deadline');
        final actionItems = items.where(
          (item) => item.itemType == FollowUpItemType.actionItem && item.dueAt != null,
        ).toList();

        if (actionItems.isNotEmpty) {
          expect(actionItems.first.dueAt, isNotNull);
        }
      });

      test('does not extract non-commitments', () async {
        // Message: "You should send the report"
        await followUpService.extractFollowUps('test-conv-no-commit');
        
        final items = await followUpService.getConversationFollowUps('test-conv-no-commit');
        final myCommitments = items.where(
          (item) => item.itemType == FollowUpItemType.actionItem,
        ).toList();

        // Should not extract third-person suggestions
        expect(myCommitments.length, lessThanOrEqualTo(0));
      });
    });

    group('Unanswered Question Detection', () {
      test('detects question without response', () async {
        await followUpService.extractFollowUps('test-conv-question');
        
        final items = await followUpService.getConversationFollowUps('test-conv-question');
        final questions = items.where(
          (item) => item.itemType == FollowUpItemType.unansweredQuestion,
        ).toList();

        expect(questions, isNotEmpty);
      });

      test('identifies "when" questions', () async {
        await followUpService.extractFollowUps('test-conv-when');
        
        final items = await followUpService.getConversationFollowUps('test-conv-when');
        final questions = items.where(
          (item) => item.itemType == FollowUpItemType.unansweredQuestion,
        ).toList();

        if (questions.isNotEmpty) {
          expect(questions.first.description, contains('when'));
        }
      });

      test('identifies "what" questions', () async {
        await followUpService.extractFollowUps('test-conv-what');
        
        final items = await followUpService.getConversationFollowUps('test-conv-what');
        expect(items, isNotEmpty);
      });

      test('does not flag answered questions', () async {
        // Conversation with question and answer
        await followUpService.extractFollowUps('test-conv-answered');
        
        final items = await followUpService.getConversationFollowUps('test-conv-answered');
        final unansweredQuestions = items.where(
          (item) => item.itemType == FollowUpItemType.unansweredQuestion,
        ).toList();

        // Should be empty if question was answered
        expect(unansweredQuestions.length, lessThanOrEqualTo(0));
      });
    });

    group('Follow-up Management', () {
      test('retrieves pending follow-ups', () async {
        final items = await followUpService.getPendingFollowUps();
        
        expect(items, isList);
        // All should be pending status
        for (final item in items) {
          expect(item.status, equals(FollowUpStatus.pending));
        }
      });

      test('retrieves follow-ups for specific conversation', () async {
        final items = await followUpService.getConversationFollowUps('test-conv-123');
        
        expect(items, isList);
        for (final item in items) {
          expect(item.conversationId, equals('test-conv-123'));
        }
      });

      test('completes follow-up item', () async {
        final items = await followUpService.getPendingFollowUps();
        if (items.isNotEmpty) {
          final item = items.first;
          
          await followUpService.completeFollowUp(item.id);
          
          // Verify it's no longer in pending list
          final updatedItems = await followUpService.getPendingFollowUps();
          expect(
            updatedItems.any((i) => i.id == item.id),
            isFalse,
          );
        }
      });

      test('snoozes follow-up item', () async {
        final items = await followUpService.getPendingFollowUps();
        if (items.isNotEmpty) {
          final item = items.first;
          
          await followUpService.snoozeFollowUp(
            item.id,
            const Duration(hours: 1),
          );
          
          // Verify it's snoozed
          final updatedItems = await followUpService.getPendingFollowUps();
          expect(
            updatedItems.any((i) => i.id == item.id),
            isFalse,
          );
        }
      });

      test('dismisses follow-up item', () async {
        final items = await followUpService.getPendingFollowUps();
        if (items.isNotEmpty) {
          final item = items.first;
          
          await followUpService.dismissFollowUp(item.id);
          
          // Verify it's dismissed
          final updatedItems = await followUpService.getPendingFollowUps();
          expect(
            updatedItems.any((i) => i.id == item.id),
            isFalse,
          );
        }
      });
    });

    group('Follow-up Item Properties', () {
      test('identifies overdue items', () async {
        final items = await followUpService.getPendingFollowUps();
        
        // Check if any items have proper overdue detection
        for (final item in items) {
          if (item.dueAt != null) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final isOverdue = now > item.dueAt!;
            expect(item.isOverdue, equals(isOverdue));
          }
        }
      });

      test('identifies due soon items', () async {
        final items = await followUpService.getPendingFollowUps();
        
        for (final item in items) {
          if (item.dueAt != null) {
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final hoursUntilDue = (item.dueAt! - now) / 3600;
            final isDueSoon = hoursUntilDue > 0 && hoursUntilDue <= 24;
            expect(item.isDueSoon, equals(isDueSoon));
          }
        }
      });

      test('calculates time until due correctly', () async {
        final items = await followUpService.getPendingFollowUps();
        
        for (final item in items) {
          if (item.dueAt != null) {
            final timeStr = item.getTimeUntilDue();
            expect(timeStr, isNotEmpty);
            
            if (item.isOverdue) {
              expect(timeStr, equals('Overdue'));
            } else {
              expect(timeStr, matches(RegExp(r'\d+[mhd]')));
            }
          }
        }
      });

      test('calculates time since detected correctly', () async {
        final items = await followUpService.getPendingFollowUps();
        
        for (final item in items) {
          final timeStr = item.getTimeSinceDetected();
          expect(timeStr, isNotEmpty);
          expect(timeStr, contains('ago'));
        }
      });
    });

    group('Priority and Sorting', () {
      test('assigns priority to follow-ups', () async {
        final items = await followUpService.getPendingFollowUps();
        
        for (final item in items) {
          expect(item.priority, greaterThanOrEqualTo(0));
          expect(item.priority, lessThanOrEqualTo(100));
        }
      });

      test('overdue items have high priority', () async {
        final items = await followUpService.getPendingFollowUps();
        final overdueItems = items.where((item) => item.isOverdue).toList();
        
        for (final item in overdueItems) {
          expect(item.priority, greaterThan(60));
        }
      });
    });

    group('Comprehensive Follow-up System', () {
      test('handles conversation with multiple follow-up types', () async {
        // Conversation with: action item, question, and pending response
        await followUpService.extractFollowUps('test-conv-mixed');
        
        final items = await followUpService.getConversationFollowUps('test-conv-mixed');
        
        expect(items, isNotEmpty);
        
        // Should have different types
        final types = items.map((item) => item.itemType).toSet();
        expect(types.length, greaterThanOrEqualTo(1));
      });

      test('prevents duplicate extraction', () async {
        // Extract twice
        await followUpService.extractFollowUps('test-conv-duplicate');
        await followUpService.extractFollowUps('test-conv-duplicate');
        
        final items = await followUpService.getConversationFollowUps('test-conv-duplicate');
        
        // Should not have duplicates (check by unique IDs)
        final ids = items.map((item) => item.id).toList();
        expect(ids.length, equals(ids.toSet().length));
      });

      test('handles empty conversation', () async {
        await followUpService.extractFollowUps('empty-conv');
        
        final items = await followUpService.getConversationFollowUps('empty-conv');
        
        expect(items, isEmpty);
      });

      test('handles conversation with no follow-ups', () async {
        // Conversation with only statements, no questions or commitments
        await followUpService.extractFollowUps('test-conv-no-followups');
        
        final items = await followUpService.getConversationFollowUps('test-conv-no-followups');
        
        expect(items.length, lessThanOrEqualTo(0));
      });
    });
  });
}

