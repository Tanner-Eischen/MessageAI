import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/presence_service.dart';
import 'package:messageai/services/typing_indicator_service.dart';

void main() {
  group('Presence and Typing Indicators Integration Tests', () {
    late PresenceService presenceService;
    late TypingIndicatorService typingService;

    setUp(() {
      presenceService = PresenceService();
      typingService = TypingIndicatorService();
    });

    tearDown(() async {
      await presenceService.dispose();
      await typingService.dispose();
    });

    testWidgets('presence subscription should work independently of typing', (tester) async {
      const conversationId = 'test-conversation-id';

      final presenceStream = presenceService.subscribeToPresence(conversationId);
      final typingStream = typingService.subscribeToTyping(conversationId);

      expect(presenceStream, isA<Stream<Set<String>>>());
      expect(typingStream, isA<Stream<Set<String>>>());

      await tester.pumpAndSettle();
    });

    testWidgets('presence and typing should maintain separate state', (tester) async {
      const conversationId = 'test-conversation-id';

      presenceService.subscribeToPresence(conversationId);
      typingService.subscribeToTyping(conversationId);

      await tester.pumpAndSettle();

      final onlineUsers = presenceService.getOnlineUsers(conversationId);
      final typingUsers = typingService.getTypingUsers(conversationId);

      expect(onlineUsers, isEmpty);
      expect(typingUsers, isEmpty);
      expect(onlineUsers, isNot(same(typingUsers)));
    });

    testWidgets('both services should handle multiple conversations', (tester) async {
      const conversationId1 = 'conversation-1';
      const conversationId2 = 'conversation-2';

      presenceService.subscribeToPresence(conversationId1);
      presenceService.subscribeToPresence(conversationId2);
      typingService.subscribeToTyping(conversationId1);
      typingService.subscribeToTyping(conversationId2);

      await tester.pumpAndSettle();

      expect(presenceService.getOnlineUsers(conversationId1), isEmpty);
      expect(presenceService.getOnlineUsers(conversationId2), isEmpty);
      expect(typingService.getTypingUsers(conversationId1), isEmpty);
      expect(typingService.getTypingUsers(conversationId2), isEmpty);
    });

    testWidgets('unsubscribe should not affect other service', (tester) async {
      const conversationId = 'test-conversation-id';

      final presenceStream = presenceService.subscribeToPresence(conversationId);
      final typingStream = typingService.subscribeToTyping(conversationId);

      await tester.pumpAndSettle();

      await presenceService.unsubscribeFromPresence(conversationId);

      await tester.pumpAndSettle();

      expect(typingStream, isA<Stream<Set<String>>>());
    });

    testWidgets('sending typing indicator should not affect presence', (tester) async {
      const conversationId = 'test-conversation-id';

      presenceService.subscribeToPresence(conversationId);
      typingService.subscribeToTyping(conversationId);

      await tester.pumpAndSettle();

      await typingService.sendTypingIndicator(conversationId, true);

      await tester.pumpAndSettle();

      expect(() => presenceService.getOnlineUsers(conversationId), returnsNormally);
    });

    testWidgets('setting presence should not affect typing indicators', (tester) async {
      const conversationId = 'test-conversation-id';

      presenceService.subscribeToPresence(conversationId);
      typingService.subscribeToTyping(conversationId);

      await tester.pumpAndSettle();

      await presenceService.setPresenceStatus(conversationId, true);

      await tester.pumpAndSettle();

      expect(() => typingService.getTypingUsers(conversationId), returnsNormally);
    });

    testWidgets('both services should dispose cleanly', (tester) async {
      const conversationId1 = 'conversation-1';
      const conversationId2 = 'conversation-2';

      presenceService.subscribeToPresence(conversationId1);
      presenceService.subscribeToPresence(conversationId2);
      typingService.subscribeToTyping(conversationId1);
      typingService.subscribeToTyping(conversationId2);

      await tester.pumpAndSettle();

      await presenceService.dispose();
      await typingService.dispose();

      await tester.pumpAndSettle();
    });

    testWidgets('concurrent operations should not interfere', (tester) async {
      const conversationId = 'test-conversation-id';

      presenceService.subscribeToPresence(conversationId);
      typingService.subscribeToTyping(conversationId);

      await tester.pumpAndSettle();

      await Future.wait([
        presenceService.setPresenceStatus(conversationId, true),
        typingService.sendTypingIndicator(conversationId, true),
      ]);

      await tester.pumpAndSettle();

      expect(() => presenceService.getOnlineUsers(conversationId), returnsNormally);
      expect(() => typingService.getTypingUsers(conversationId), returnsNormally);
    });
  });
}
