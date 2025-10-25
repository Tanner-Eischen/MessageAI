import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/follow_up_item.dart';
import 'package:messageai/features/followups/widgets/follow_up_card.dart';

/// Phase 4: FollowUpCard Widget Tests
void main() {
  group('FollowUpCard Widget', () {
    late FollowUpItem testItem;
    bool completeCalled = false;
    bool snoozeCalled = false;
    bool dismissCalled = false;

    setUp(() {
      completeCalled = false;
      snoozeCalled = false;
      dismissCalled = false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      testItem = FollowUpItem(
        id: 'test-123',
        userId: 'user-456',
        conversationId: 'conv-789',
        itemType: FollowUpItemType.actionItem,
        title: 'Send quarterly report',
        description: 'Review and send Q4 financial report to client',
        extractedText: "I'll send you the Q4 report by Friday",
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now - 3600,
        dueAt: now + 7200,
      );
    });

    testWidgets('renders all basic elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () => completeCalled = true,
              onSnooze: () => snoozeCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      // Check title is displayed
      expect(find.text('Send quarterly report'), findsOneWidget);

      // Check description is displayed
      expect(find.text('Review and send Q4 financial report to client'), findsOneWidget);

      // Check action buttons exist
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.close), findsOneWidget);
    });

    testWidgets('displays type icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Action item should have task_alt icon
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('displays extracted text for action items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should show quote icon and extracted text
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.text("I'll send you the Q4 report by Friday"), findsOneWidget);
    });

    testWidgets('displays priority and time metadata', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should show priority
      expect(find.textContaining('Priority: 80'), findsOneWidget);

      // Should show time since detected
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('displays due date badge when present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should show time until due
      final timeUntilDue = testItem.getTimeUntilDue();
      expect(find.text(timeUntilDue), findsOneWidget);
    });

    testWidgets('highlights overdue items in red', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final overdueItem = FollowUpItem(
        id: 'overdue-123',
        userId: 'user-456',
        conversationId: 'conv-789',
        itemType: FollowUpItemType.actionItem,
        title: 'Overdue task',
        status: FollowUpStatus.pending,
        priority: 90,
        detectedAt: now - 7200,
        dueAt: now - 3600, // 1 hour ago
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: overdueItem,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should display "Overdue"
      expect(find.text('Overdue'), findsOneWidget);

      // Card should have red background (from Colors.red.shade50)
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.red.shade50));
    });

    testWidgets('calls onComplete when Done button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () => completeCalled = true,
              onSnooze: () => snoozeCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      // Tap Done button
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
      expect(snoozeCalled, isFalse);
      expect(dismissCalled, isFalse);
    });

    testWidgets('calls onSnooze when Snooze button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () => completeCalled = true,
              onSnooze: () => snoozeCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      // Tap Snooze button
      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();

      expect(snoozeCalled, isTrue);
      expect(completeCalled, isFalse);
      expect(dismissCalled, isFalse);
    });

    testWidgets('calls onDismiss when close button tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: testItem,
              onComplete: () => completeCalled = true,
              onSnooze: () => snoozeCalled = true,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      // Tap close button
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pumpAndSettle();

      expect(dismissCalled, isTrue);
      expect(completeCalled, isFalse);
      expect(snoozeCalled, isFalse);
    });

    testWidgets('renders without description', (tester) async {
      final itemWithoutDescription = FollowUpItem(
        id: 'test-123',
        userId: 'user-456',
        conversationId: 'conv-789',
        itemType: FollowUpItemType.actionItem,
        title: 'Simple task',
        status: FollowUpStatus.pending,
        priority: 50,
        detectedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowUpCard(
              item: itemWithoutDescription,
              onComplete: () {},
              onSnooze: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Simple task'), findsOneWidget);
    });

    testWidgets('renders different item types with correct icons', (tester) async {
      final types = [
        FollowUpItemType.actionItem,
        FollowUpItemType.unansweredQuestion,
        FollowUpItemType.pendingResponse,
        FollowUpItemType.scheduledFollowup,
      ];

      for (final type in types) {
        final item = FollowUpItem(
          id: 'test-${type.value}',
          userId: 'user',
          conversationId: 'conv',
          itemType: type,
          title: 'Test ${type.displayName}',
          status: FollowUpStatus.pending,
          priority: 50,
          detectedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FollowUpCard(
                item: item,
                onComplete: () {},
                onSnooze: () {},
                onDismiss: () {},
              ),
            ),
          ),
        );

        // Should have the correct icon (at least one, may appear in multiple places)
        expect(find.byIcon(type.icon), findsWidgets);

        await tester.pumpAndSettle();
      }
    });
  });
}

