import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/conversation_context.dart';

void main() {
  group('KeyPoint', () {
    test('fromJson creates KeyPoint correctly', () {
      final json = {
        'text': 'Discussed project deadline',
        'timestamp': 1640000000,
      };

      final keyPoint = KeyPoint.fromJson(json);

      expect(keyPoint.text, 'Discussed project deadline');
      expect(keyPoint.timestamp, 1640000000);
    });

    test('getTimeAgo returns "just now" for recent timestamps', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final keyPoint = KeyPoint(
        text: 'Test',
        timestamp: now - 30, // 30 seconds ago
      );

      expect(keyPoint.getTimeAgo(), 'just now');
    });

    test('getTimeAgo returns minutes for timestamps < 1 hour', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final keyPoint = KeyPoint(
        text: 'Test',
        timestamp: now - 600, // 10 minutes ago
      );

      expect(keyPoint.getTimeAgo(), '10m ago');
    });

    test('getTimeAgo returns hours for timestamps < 1 day', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final keyPoint = KeyPoint(
        text: 'Test',
        timestamp: now - 7200, // 2 hours ago
      );

      expect(keyPoint.getTimeAgo(), '2h ago');
    });

    test('getTimeAgo returns days for timestamps < 1 week', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final keyPoint = KeyPoint(
        text: 'Test',
        timestamp: now - 259200, // 3 days ago
      );

      expect(keyPoint.getTimeAgo(), '3d ago');
    });

    test('getTimeAgo returns weeks for older timestamps', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final keyPoint = KeyPoint(
        text: 'Test',
        timestamp: now - 1209600, // 2 weeks ago
      );

      expect(keyPoint.getTimeAgo(), '2w ago');
    });
  });

  group('ConversationContext', () {
    test('fromJson creates ConversationContext correctly', () {
      final json = {
        'conversation_id': 'conv-123',
        'last_discussed': 'Project deadline and budget',
        'key_points': [
          {'text': 'Deadline is next Friday', 'timestamp': 1640000000},
          {'text': 'Budget approved', 'timestamp': 1640001000},
        ],
        'pending_questions': ['When can we start?', 'Who is the lead?'],
        'from_cache': true,
        'cache_age': 120,
      };

      final context = ConversationContext.fromJson(json);

      expect(context.conversationId, 'conv-123');
      expect(context.lastDiscussed, 'Project deadline and budget');
      expect(context.keyPoints.length, 2);
      expect(context.keyPoints[0].text, 'Deadline is next Friday');
      expect(context.keyPoints[1].text, 'Budget approved');
      expect(context.pendingQuestions.length, 2);
      expect(context.pendingQuestions[0], 'When can we start?');
      expect(context.fromCache, true);
      expect(context.cacheAge, 120);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'conversation_id': 'conv-123',
        'last_discussed': 'Project deadline',
        'key_points': [],
      };

      final context = ConversationContext.fromJson(json);

      expect(context.conversationId, 'conv-123');
      expect(context.keyPoints.isEmpty, true);
      expect(context.pendingQuestions.isEmpty, true);
      expect(context.fromCache, false);
      expect(context.cacheAge, null);
    });

    test('fromJson defaults conversation_id to empty string if null', () {
      final json = {
        'last_discussed': 'Test',
        'key_points': [],
      };

      final context = ConversationContext.fromJson(json);

      expect(context.conversationId, '');
    });

    test('handles empty key_points and pending_questions lists', () {
      final json = {
        'conversation_id': 'conv-123',
        'last_discussed': 'Test',
        'key_points': [],
        'pending_questions': [],
      };

      final context = ConversationContext.fromJson(json);

      expect(context.keyPoints.isEmpty, true);
      expect(context.pendingQuestions.isEmpty, true);
    });
  });
}

