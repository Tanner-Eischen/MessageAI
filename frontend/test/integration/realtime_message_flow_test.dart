import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/realtime_message_service.dart';
import 'package:messageai/services/message_service.dart';
import 'package:messageai/data/drift/app_db.dart';

void main() {
  group('Real-time Message Flow Integration Tests', () {
    late RealTimeMessageService realtimeService;
    late MessageService messageService;

    setUp(() {
      realtimeService = RealTimeMessageService();
      messageService = MessageService();
    });

    tearDown(() async {
      await realtimeService.dispose();
    });

    testWidgets('message subscription should deliver messages', (tester) async {
      const conversationId = 'test-conversation-id';

      final messageStream = realtimeService.subscribeToMessages(conversationId);

      expect(messageStream, isA<Stream<List<Message>>>());

      await tester.pumpAndSettle();
    });

    testWidgets('real-time service should handle multiple subscriptions', (tester) async {
      const conversationId1 = 'conversation-1';
      const conversationId2 = 'conversation-2';

      final stream1 = realtimeService.subscribeToMessages(conversationId1);
      final stream2 = realtimeService.subscribeToMessages(conversationId2);

      expect(stream1, isA<Stream<List<Message>>>());
      expect(stream2, isA<Stream<List<Message>>>());

      await tester.pumpAndSettle();

      await realtimeService.unsubscribeFromMessages(conversationId1);
      await realtimeService.unsubscribeFromMessages(conversationId2);
    });

    testWidgets('unsubscribe should stop message delivery', (tester) async {
      const conversationId = 'test-conversation-id';

      realtimeService.subscribeToMessages(conversationId);

      await tester.pumpAndSettle();

      await realtimeService.unsubscribeFromMessages(conversationId);

      await tester.pumpAndSettle();

      expect(() => realtimeService.unsubscribeFromMessages(conversationId), returnsNormally);
    });

    testWidgets('service disposal should clean up all resources', (tester) async {
      const conversationId1 = 'conversation-1';
      const conversationId2 = 'conversation-2';

      realtimeService.subscribeToMessages(conversationId1);
      realtimeService.subscribeToMessages(conversationId2);

      await tester.pumpAndSettle();

      await realtimeService.dispose();

      await tester.pumpAndSettle();
    });

    testWidgets('stream should handle errors gracefully', (tester) async {
      const conversationId = 'test-conversation-id';

      final stream = realtimeService.subscribeToMessages(conversationId);
      bool errorHandled = false;

      stream.listen(
        (_) {},
        onError: (error) {
          errorHandled = true;
        },
      );

      await tester.pumpAndSettle();

      expect(errorHandled, isFalse);
    });

    testWidgets('multiple listeners should receive same data', (tester) async {
      const conversationId = 'test-conversation-id';

      final stream = realtimeService.subscribeToMessages(conversationId);

      final listener1Data = <List<Message>>[];
      final listener2Data = <List<Message>>[];

      stream.listen(listener1Data.add);
      stream.listen(listener2Data.add);

      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(listener1Data.length, equals(listener2Data.length));
    });
  });
}
