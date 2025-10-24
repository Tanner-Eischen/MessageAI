import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/features/conversations/widgets/context_preview_card.dart';
import 'package:messageai/models/conversation_context.dart';

void main() {
  group('ContextPreviewCard', () {
    testWidgets('displays last discussed topic', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project deadline and budget',
        keyPoints: [],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('Last Conversation'), findsOneWidget);
      expect(find.text('Project deadline and budget'), findsOneWidget);
    });

    testWidgets('displays key points', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [
          KeyPoint(text: 'Deadline is Friday', timestamp: now - 3600),
          KeyPoint(text: 'Budget approved', timestamp: now - 7200),
          KeyPoint(text: 'Team meeting scheduled', timestamp: now - 10800),
        ],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('Recent topics:'), findsOneWidget);
      expect(find.text('Deadline is Friday'), findsOneWidget);
      expect(find.text('Budget approved'), findsOneWidget);
      expect(find.text('Team meeting scheduled'), findsOneWidget);
    });

    testWidgets('limits key points to 3', (tester) async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [
          KeyPoint(text: 'Point 1', timestamp: now),
          KeyPoint(text: 'Point 2', timestamp: now),
          KeyPoint(text: 'Point 3', timestamp: now),
          KeyPoint(text: 'Point 4', timestamp: now),
          KeyPoint(text: 'Point 5', timestamp: now),
        ],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('Point 1'), findsOneWidget);
      expect(find.text('Point 2'), findsOneWidget);
      expect(find.text('Point 3'), findsOneWidget);
      expect(find.text('Point 4'), findsNothing);
      expect(find.text('Point 5'), findsNothing);
    });

    testWidgets('displays pending questions badge', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: ['When do we start?', 'Who is the lead?'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('2 unanswered questions'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('displays singular form for single question', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: ['When do we start?'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('1 unanswered question'), findsOneWidget);
    });

    testWidgets('displays cached indicator when fromCache is true',
        (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
        fromCache: true,
        cacheAge: 120,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('cached'), findsOneWidget);
    });

    testWidgets('does not display cached indicator when fromCache is false',
        (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
        fromCache: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('cached'), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(
              context: context,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ContextPreviewCard));
      expect(tapped, true);
    });

    testWidgets('does not crash when onTap is null', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      await tester.tap(find.byType(ContextPreviewCard));
      // Should not crash
      expect(find.byType(ContextPreviewCard), findsOneWidget);
    });

    testWidgets('hides key points section when empty', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.text('Recent topics:'), findsNothing);
    });

    testWidgets('hides pending questions section when empty', (tester) async {
      final context = ConversationContext(
        conversationId: 'conv-123',
        lastDiscussed: 'Project updates',
        keyPoints: [],
        pendingQuestions: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextPreviewCard(context: context),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsNothing);
    });
  });
}

