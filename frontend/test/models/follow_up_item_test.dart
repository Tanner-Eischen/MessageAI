import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/follow_up_item.dart';

void main() {
  group('FollowUpItemType', () {
    test('fromString returns correct enum', () {
      expect(
        FollowUpItemType.fromString('action_item'),
        FollowUpItemType.actionItem,
      );
      expect(
        FollowUpItemType.fromString('unanswered_question'),
        FollowUpItemType.unansweredQuestion,
      );
    });

    test('fromString returns default for invalid value', () {
      expect(
        FollowUpItemType.fromString('invalid'),
        FollowUpItemType.pendingResponse,
      );
    });

    test('getColor returns correct colors', () {
      expect(
        FollowUpItemType.actionItem.getColor().value,
        greaterThan(0),
      );
    });

    test('enum has correct values', () {
      expect(FollowUpItemType.actionItem.value, 'action_item');
      expect(FollowUpItemType.actionItem.displayName, 'Action Item');
    });
  });

  group('FollowUpStatus', () {
    test('fromString returns correct enum', () {
      expect(FollowUpStatus.fromString('pending'), FollowUpStatus.pending);
      expect(FollowUpStatus.fromString('completed'), FollowUpStatus.completed);
    });

    test('fromString returns default for invalid value', () {
      expect(FollowUpStatus.fromString('invalid'), FollowUpStatus.pending);
    });
  });

  group('FollowUpItem', () {
    late FollowUpItem item;

    setUp(() {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      item = FollowUpItem(
        id: 'test-id',
        userId: 'user-123',
        conversationId: 'conv-456',
        itemType: FollowUpItemType.actionItem,
        title: 'Send report',
        description: 'Send quarterly report to client',
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now - 3600, // 1 hour ago
        dueAt: now + 7200, // 2 hours from now
      );
    });

    test('fromJson creates correct instance', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'conversation_id': 'conv-456',
        'item_type': 'action_item',
        'title': 'Test',
        'status': 'pending',
        'priority': 50,
        'detected_at': 1000,
      };

      final item = FollowUpItem.fromJson(json);

      expect(item.id, 'test-id');
      expect(item.userId, 'user-123');
      expect(item.conversationId, 'conv-456');
      expect(item.itemType, FollowUpItemType.actionItem);
      expect(item.status, FollowUpStatus.pending);
    });

    test('isOverdue returns false for future due date', () {
      expect(item.isOverdue, false);
    });

    test('isOverdue returns true for past due date', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final overdueItem = FollowUpItem(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        itemType: FollowUpItemType.actionItem,
        title: 'Overdue',
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now - 7200,
        dueAt: now - 3600, // 1 hour ago
      );

      expect(overdueItem.isOverdue, true);
    });

    test('isDueSoon returns true for items due within 24h', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final dueSoonItem = FollowUpItem(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        itemType: FollowUpItemType.actionItem,
        title: 'Due Soon',
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now,
        dueAt: now + (12 * 3600), // 12 hours from now
      );

      expect(dueSoonItem.isDueSoon, true);
    });

    test('isDueSoon returns false for items due later', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final laterItem = FollowUpItem(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        itemType: FollowUpItemType.actionItem,
        title: 'Later',
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now,
        dueAt: now + (48 * 3600), // 48 hours from now
      );

      expect(laterItem.isDueSoon, false);
    });

    test('getTimeUntilDue returns correct format', () {
      expect(item.getTimeUntilDue(), isNotEmpty);
    });

    test('getTimeUntilDue returns "Overdue" for past due', () {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final overdueItem = FollowUpItem(
        id: 'test',
        userId: 'user',
        conversationId: 'conv',
        itemType: FollowUpItemType.actionItem,
        title: 'Overdue',
        status: FollowUpStatus.pending,
        priority: 80,
        detectedAt: now - 7200,
        dueAt: now - 3600,
      );

      expect(overdueItem.getTimeUntilDue(), 'Overdue');
    });

    test('getTimeSinceDetected returns correct format', () {
      expect(item.getTimeSinceDetected(), contains('ago'));
    });

    test('fromJson handles item_id or id field', () {
      final json1 = {
        'item_id': 'test-1',
        'user_id': 'user',
        'conversation_id': 'conv',
        'item_type': 'action_item',
        'title': 'Test',
        'status': 'pending',
        'priority': 50,
        'detected_at': 1000,
      };

      final json2 = {
        'id': 'test-2',
        'user_id': 'user',
        'conversation_id': 'conv',
        'item_type': 'action_item',
        'title': 'Test',
        'status': 'pending',
        'priority': 50,
        'detected_at': 1000,
      };

      expect(FollowUpItem.fromJson(json1).id, 'test-1');
      expect(FollowUpItem.fromJson(json2).id, 'test-2');
    });
  });
}

