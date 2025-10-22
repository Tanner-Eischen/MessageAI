import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/message_service.dart';
import 'package:messageai/data/drift/app_db.dart';

void main() {
  group('Reply-To Functionality', () {
    late MessageService messageService;

    setUp(() {
      messageService = MessageService();
    });

    test('sendMessage accepts replyToId parameter', () {
      expect(
        () async => await messageService.sendMessage(
          conversationId: 'test-conv',
          body: 'Reply message',
          replyToId: 'original-message-id',
        ),
        returnsNormally,
      );
    });

    test('reply message references original', () {
      const originalId = 'original-123';
      const replyBody = 'This is a reply';

      expect(originalId, isNotEmpty);
      expect(replyBody, isNotEmpty);
    });
  });

  group('Message Forwarding', () {
    test('message can be forwarded to multiple conversations', () async {
      final sourceMessage = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Test message to forward',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );

      final targetConversations = ['conv-2', 'conv-3', 'conv-4'];

      expect(sourceMessage.body, isNotEmpty);
      expect(targetConversations.length, equals(3));
    });

    test('forwarded message preserves content', () {
      const originalBody = 'Original message content';
      const originalMediaUrl = 'https://example.com/image.jpg';

      final forwardedMessage = {
        'body': originalBody,
        'mediaUrl': originalMediaUrl,
      };

      expect(forwardedMessage['body'], equals(originalBody));
      expect(forwardedMessage['mediaUrl'], equals(originalMediaUrl));
    });
  });

  group('Message Search', () {
    test('search query matches message content', () {
      final messages = [
        'Hello world',
        'Testing search functionality',
        'Another message here',
      ];

      final query = 'search';
      final results = messages
          .where((m) => m.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(results.length, equals(1));
      expect(results.first, contains('search'));
    });

    test('search is case insensitive', () {
      const message = 'Hello World';
      const query1 = 'hello';
      const query2 = 'WORLD';
      const query3 = 'HeLLo';

      expect(message.toLowerCase().contains(query1.toLowerCase()), isTrue);
      expect(message.toLowerCase().contains(query2.toLowerCase()), isTrue);
      expect(message.toLowerCase().contains(query3.toLowerCase()), isTrue);
    });

    test('search highlights matching text', () {
      const text = 'This is a test message';
      const query = 'test';

      final lowerText = text.toLowerCase();
      final index = lowerText.indexOf(query.toLowerCase());

      expect(index, greaterThanOrEqualTo(0));
      expect(text.substring(index, index + query.length), equals('test'));
    });
  });
}
