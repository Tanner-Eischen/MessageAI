import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/action_item.dart';

void main() {
  group('ActionItem', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 'action-123',
        'follow_up_item_id': 'follow-456',
        'action_type': 'send',
        'action_target': 'quarterly report',
        'commitment_text': "I'll send you the quarterly report by Friday",
        'mentioned_deadline': 'by Friday',
        'extracted_deadline': 1640000000,
      };

      final action = ActionItem.fromJson(json);

      expect(action.id, 'action-123');
      expect(action.followUpItemId, 'follow-456');
      expect(action.actionType, 'send');
      expect(action.actionTarget, 'quarterly report');
      expect(action.commitmentText, "I'll send you the quarterly report by Friday");
      expect(action.mentionedDeadline, 'by Friday');
      expect(action.extractedDeadline, 1640000000);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'action-123',
        'follow_up_item_id': 'follow-456',
        'action_type': 'call',
        'commitment_text': "I'll call you later",
      };

      final action = ActionItem.fromJson(json);

      expect(action.actionTarget, isNull);
      expect(action.mentionedDeadline, isNull);
      expect(action.extractedDeadline, isNull);
    });

    group('getActionEmoji', () {
      test('returns correct emoji for send', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'send',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📤');
      });

      test('returns correct emoji for call', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'call',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📞');
      });

      test('returns correct emoji for meet', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'meet',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '🤝');
      });

      test('returns correct emoji for review', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'review',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📋');
      });

      test('returns correct emoji for decide', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'decide',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '🤔');
      });

      test('returns correct emoji for follow_up', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'follow_up',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '🔄');
      });

      test('returns correct emoji for check', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'check',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '✅');
      });

      test('returns correct emoji for schedule', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'schedule',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📅');
      });

      test('returns default emoji for unknown type', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'unknown',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📌');
      });

      test('handles case insensitive action types', () {
        final action = ActionItem(
          id: 'test',
          followUpItemId: 'follow',
          actionType: 'SEND',
          commitmentText: 'test',
        );
        expect(action.getActionEmoji(), '📤');
      });
    });
  });
}

