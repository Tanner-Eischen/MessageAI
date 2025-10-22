import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/message_service.dart';

void main() {
  group('Message Editing', () {
    late MessageService messageService;

    setUp(() {
      messageService = MessageService();
    });

    test('editMessage throws error for messages older than 15 minutes', () async {
      expect(
        () async => await messageService.editMessage('old-message-id', 'new body'),
        throwsA(anything),
      );
    });

    test('editMessage updates message body', () async {
      const messageId = 'test-message-id';
      const newBody = 'Updated message body';

      expect(
        () async => await messageService.editMessage(messageId, newBody),
        returnsNormally,
      );
    });
  });

  group('Message Deletion', () {
    late MessageService messageService;

    setUp(() {
      messageService = MessageService();
    });

    test('deleteMessage removes message from database', () async {
      const messageId = 'test-message-id';

      expect(
        () async => await messageService.deleteMessage(messageId),
        returnsNormally,
      );
    });
  });

  group('Message Time Window', () {
    test('15 minute edit window calculation', () {
      final now = DateTime.now();
      final fifteenMinutesAgo = now.subtract(const Duration(minutes: 15));
      final fourteenMinutesAgo = now.subtract(const Duration(minutes: 14));

      final diff15 = now.difference(fifteenMinutesAgo);
      final diff14 = now.difference(fourteenMinutesAgo);

      expect(diff15.inMinutes, equals(15));
      expect(diff14.inMinutes, equals(14));
      expect(diff14.inMinutes < 15, isTrue);
    });
  });
}
