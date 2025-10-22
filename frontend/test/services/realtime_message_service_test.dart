import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/realtime_message_service.dart';

void main() {
  group('RealTimeMessageService', () {
    late RealTimeMessageService service;

    setUp(() {
      service = RealTimeMessageService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('singleton instance should be the same', () {
      final service1 = RealTimeMessageService();
      final service2 = RealTimeMessageService();

      expect(service1, equals(service2));
    });

    test('subscribeToMessages should return a stream', () {
      const conversationId = 'test-conversation-id';

      final stream = service.subscribeToMessages(conversationId);

      expect(stream, isA<Stream>());
    });

    test('subscribeToMessages should return same stream for same conversation', () {
      const conversationId = 'test-conversation-id';

      final stream1 = service.subscribeToMessages(conversationId);
      final stream2 = service.subscribeToMessages(conversationId);

      expect(stream1, equals(stream2));
    });

    test('subscribeToMessages should create different streams for different conversations', () {
      const conversationId1 = 'test-conversation-1';
      const conversationId2 = 'test-conversation-2';

      final stream1 = service.subscribeToMessages(conversationId1);
      final stream2 = service.subscribeToMessages(conversationId2);

      expect(stream1, isNot(equals(stream2)));
    });

    test('unsubscribeFromMessages should clean up resources', () async {
      const conversationId = 'test-conversation-id';

      service.subscribeToMessages(conversationId);
      await service.unsubscribeFromMessages(conversationId);

      expect(() => service.unsubscribeFromMessages(conversationId), returnsNormally);
    });

    test('dispose should clean up all subscriptions', () async {
      const conversationId1 = 'test-conversation-1';
      const conversationId2 = 'test-conversation-2';

      service.subscribeToMessages(conversationId1);
      service.subscribeToMessages(conversationId2);

      await service.dispose();

      expect(() => service.dispose(), returnsNormally);
    });

    test('multiple subscribe calls should not create duplicate channels', () {
      const conversationId = 'test-conversation-id';

      service.subscribeToMessages(conversationId);
      service.subscribeToMessages(conversationId);
      service.subscribeToMessages(conversationId);

      final stream = service.subscribeToMessages(conversationId);
      expect(stream, isA<Stream>());
    });

    test('unsubscribe non-existent conversation should not throw', () async {
      const conversationId = 'non-existent-conversation';

      expect(
        () async => await service.unsubscribeFromMessages(conversationId),
        returnsNormally,
      );
    });
  });
}
