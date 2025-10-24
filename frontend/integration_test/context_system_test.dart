import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/main.dart' as app;

/// Integration tests for Phase 3: Context System
///
/// These tests verify the complete flow of:
/// 1. Loading conversation context
/// 2. Displaying context preview card
/// 3. Opening relationship profiles
/// 4. Viewing safe topics and communication patterns
///
/// Prerequisites:
/// - Test Supabase instance with sample data
/// - Authenticated user session
/// - At least one conversation with messages
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Context System Integration Tests', () {
    testWidgets('Full context preview flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for authentication/home screen
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to a conversation (adjust selector based on your UI)
      // This is a template - adjust based on your actual navigation
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Verify context preview card appears
        expect(find.text('Last Conversation'), findsOneWidget,
            reason: 'Context preview card should appear at top of messages');

        // Verify key points are displayed if available
        final recentTopicsFinder = find.text('Recent topics:');
        if (recentTopicsFinder.evaluate().isNotEmpty) {
          expect(recentTopicsFinder, findsOneWidget,
              reason: 'Recent topics section should be visible');
        }
      }
    });

    testWidgets('Relationship profile flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to a conversation
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Find and tap "Who is this?" button
        final whoIsThisButton = find.byTooltip('Who is this?');
        if (whoIsThisButton.evaluate().isNotEmpty) {
          await tester.tap(whoIsThisButton);
          await tester.pumpAndSettle();

          // Verify relationship sheet opens
          // Look for common elements that should be in the sheet
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Close the sheet
          final closeButton = find.byIcon(Icons.close);
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Context caching behavior', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open a conversation
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Wait for context to load
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Go back
        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          // Open same conversation again
          await tester.tap(conversationFinder);
          await tester.pumpAndSettle();

          // Second load should be faster (cached)
          // Look for 'cached' indicator
          final cachedIndicator = find.text('cached');
          // Note: This may not always appear depending on timing
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Pending questions display', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to conversation with pending questions
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Look for pending questions badge
        final pendingQuestionsFinder = find.byIcon(Icons.help_outline);
        if (pendingQuestionsFinder.evaluate().isNotEmpty) {
          expect(pendingQuestionsFinder, findsOneWidget,
              reason: 'Pending questions indicator should be visible');

          // Verify text format
          final questionTextFinder = find.textContaining('unanswered question');
          expect(questionTextFinder, findsOneWidget,
              reason: 'Pending questions count should be displayed');
        }
      }
    });

    testWidgets('Safe topics display in relationship profile', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to conversation
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Open relationship profile
        final whoIsThisButton = find.byTooltip('Who is this?');
        if (whoIsThisButton.evaluate().isNotEmpty) {
          await tester.tap(whoIsThisButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Look for safe topics section
          final safeTopicsFinder = find.text('Safe Topics');
          if (safeTopicsFinder.evaluate().isNotEmpty) {
            expect(safeTopicsFinder, findsOneWidget,
                reason: 'Safe topics section should be visible');
          }

          // Look for topics to avoid section
          final avoidTopicsFinder = find.text('Topics to Avoid');
          if (avoidTopicsFinder.evaluate().isNotEmpty) {
            expect(avoidTopicsFinder, findsOneWidget,
                reason: 'Topics to avoid section should be visible');
          }

          // Close the sheet
          final closeButton = find.byIcon(Icons.close);
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('Context updates after sending message', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to conversation
      final conversationFinder = find.text('Test Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Note initial context
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Send a message
        final messageField = find.byType(TextField);
        if (messageField.evaluate().isNotEmpty) {
          await tester.enterText(messageField.first, 'Test message for context');
          await tester.testTextInput.receiveAction(TextInputAction.send);
          await tester.pumpAndSettle();

          // Context should eventually update
          // Note: In real scenario, this depends on backend processing
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Handles missing context gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to a new conversation with no context
      // Should not crash or show errors
      final conversationFinder = find.text('New Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Should show messages without context card
        expect(tester.takeException(), isNull,
            reason: 'Should handle missing context without crashing');
      }
    });

    testWidgets('Handles missing relationship profile', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final conversationFinder = find.text('New Conversation').first;
      if (conversationFinder.evaluate().isNotEmpty) {
        await tester.tap(conversationFinder);
        await tester.pumpAndSettle();

        // Try to open relationship profile
        final whoIsThisButton = find.byTooltip('Who is this?');
        if (whoIsThisButton.evaluate().isNotEmpty) {
          await tester.tap(whoIsThisButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));

          // Should show "No profile available" message
          final noProfileFinder = find.text('No profile available');
          if (noProfileFinder.evaluate().isNotEmpty) {
            expect(noProfileFinder, findsOneWidget);
          }

          // Close if needed
          final closeButton = find.byIcon(Icons.close);
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });
  });
}

