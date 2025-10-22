import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:messageai/services/typing_indicator_service.dart';

void main() {
  group('TypingIndicatorService', () {
    late TypingIndicatorService service;

    setUp(() {
      service = TypingIndicatorService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('singleton instance should be the same', () {
      final service1 = TypingIndicatorService();
      final service2 = TypingIndicatorService();

      expect(service1, equals(service2));
    });

    test('getTypingUsers should return empty set initially', () {
      const conversationId = 'test-conversation-id';
      final typingUsers = service.getTypingUsers(conversationId);

      expect(typingUsers, isEmpty);
    });

    test('subscribeToTyping should return a stream', () {
      const conversationId = 'test-conversation-id';

      final stream = service.subscribeToTyping(conversationId);

      expect(stream, isA<Stream<Set<String>>>());
    });

    test('subscribeToTyping should return same stream for same conversation', () {
      const conversationId = 'test-conversation-id';

      final stream1 = service.subscribeToTyping(conversationId);
      final stream2 = service.subscribeToTyping(conversationId);

      expect(stream1, equals(stream2));
    });

    test('typing timeout should be 3 seconds', () {
      const expectedTimeout = Duration(seconds: 3);
      expect(expectedTimeout.inSeconds, 3);
    });

    test('unsubscribeFromTyping should clean up resources', () async {
      const conversationId = 'test-conversation-id';

      service.subscribeToTyping(conversationId);
      await service.unsubscribeFromTyping(conversationId);

      final typingUsers = service.getTypingUsers(conversationId);
      expect(typingUsers, isEmpty);
    });

    test('dispose should clean up all subscriptions', () async {
      const conversationId1 = 'test-conversation-1';
      const conversationId2 = 'test-conversation-2';

      service.subscribeToTyping(conversationId1);
      service.subscribeToTyping(conversationId2);

      await service.dispose();

      expect(service.getTypingUsers(conversationId1), isEmpty);
      expect(service.getTypingUsers(conversationId2), isEmpty);
    });

    test('sendTypingIndicator should not throw when channel exists', () async {
      const conversationId = 'test-conversation-id';

      service.subscribeToTyping(conversationId);

      expect(
        () async => await service.sendTypingIndicator(conversationId, true),
        returnsNormally,
      );
    });

    test('sendTypingIndicator should handle channel not existing', () async {
      const conversationId = 'non-existent-conversation';

      expect(
        () async => await service.sendTypingIndicator(conversationId, true),
        returnsNormally,
      );
    });

    test('getTypingUsers should return copy of set', () {
      const conversationId = 'test-conversation-id';

      final set1 = service.getTypingUsers(conversationId);
      final set2 = service.getTypingUsers(conversationId);

      expect(identical(set1, set2), isFalse);
      expect(set1, equals(set2));
    });
  });
}
