import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/presence_service.dart';

void main() {
  group('PresenceService', () {
    late PresenceService service;

    setUp(() {
      service = PresenceService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('singleton instance should be the same', () {
      final service1 = PresenceService();
      final service2 = PresenceService();

      expect(service1, equals(service2));
    });

    test('getOnlineUsers should return empty set initially', () {
      const conversationId = 'test-conversation-id';
      final onlineUsers = service.getOnlineUsers(conversationId);

      expect(onlineUsers, isEmpty);
    });

    test('isUserOnline should return false for unknown user', () {
      const conversationId = 'test-conversation-id';
      const userId = 'test-user-id';

      final isOnline = service.isUserOnline(conversationId, userId);

      expect(isOnline, isFalse);
    });

    test('subscribeToPresence should return a stream', () {
      const conversationId = 'test-conversation-id';

      final stream = service.subscribeToPresence(conversationId);

      expect(stream, isA<Stream<Set<String>>>());
    });

    test('subscribeToPresence should return same stream for same conversation', () {
      const conversationId = 'test-conversation-id';

      final stream1 = service.subscribeToPresence(conversationId);
      final stream2 = service.subscribeToPresence(conversationId);

      expect(stream1, equals(stream2));
    });

    test('unsubscribeFromPresence should clean up resources', () async {
      const conversationId = 'test-conversation-id';

      service.subscribeToPresence(conversationId);
      await service.unsubscribeFromPresence(conversationId);

      final onlineUsers = service.getOnlineUsers(conversationId);
      expect(onlineUsers, isEmpty);
    });

    test('dispose should clean up all subscriptions', () async {
      const conversationId1 = 'test-conversation-1';
      const conversationId2 = 'test-conversation-2';

      service.subscribeToPresence(conversationId1);
      service.subscribeToPresence(conversationId2);

      await service.dispose();

      expect(service.getOnlineUsers(conversationId1), isEmpty);
      expect(service.getOnlineUsers(conversationId2), isEmpty);
    });

    test('setPresenceStatus should not throw when channel exists', () async {
      const conversationId = 'test-conversation-id';

      service.subscribeToPresence(conversationId);

      expect(
        () async => await service.setPresenceStatus(conversationId, true),
        returnsNormally,
      );
    });

    test('setPresenceStatus should handle channel not existing', () async {
      const conversationId = 'non-existent-conversation';

      expect(
        () async => await service.setPresenceStatus(conversationId, true),
        returnsNormally,
      );
    });
  });
}
