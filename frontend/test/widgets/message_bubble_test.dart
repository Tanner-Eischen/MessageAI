import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/features/conversations/widgets/message_bubble.dart';
import 'package:messageai/data/drift/app_db.dart';

void main() {
  group('MessageBubble Widget', () {
    late Message testMessage;

    setUp(() {
      testMessage = Message(
        id: 'test-message-id',
        conversationId: 'test-conversation',
        senderId: 'test-sender',
        body: 'Test message body',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );
    });

    testWidgets('displays message content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: testMessage,
              isSent: true,
            ),
          ),
        ),
      );

      expect(find.text('Test message body'), findsOneWidget);
    });

    testWidgets('shows edited indicator when message is edited', (tester) async {
      final editedMessage = Message(
        id: 'test-message-id',
        conversationId: 'test-conversation',
        senderId: 'test-sender',
        body: 'Edited message',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        editedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: editedMessage,
              isSent: true,
            ),
          ),
        ),
      );

      expect(find.text('(edited)'), findsOneWidget);
    });

    testWidgets('shows loading indicator for unsynced messages', (tester) async {
      final unsyncedMessage = Message(
        id: 'test-message-id',
        conversationId: 'test-conversation',
        senderId: 'test-sender',
        body: 'Unsynced message',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: unsyncedMessage,
              isSent: true,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays media thumbnail when media URL is present', (tester) async {
      final messageWithMedia = Message(
        id: 'test-message-id',
        conversationId: 'test-conversation',
        senderId: 'test-sender',
        body: 'Message with media',
        mediaUrl: 'https://example.com/image.jpg',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: messageWithMedia,
              isSent: true,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('long press triggers message menu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: testMessage,
              isSent: true,
              onDelete: () {},
              onEdit: () {},
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
    });
  });
}
