import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/drift/daos/message_dao.dart';
import 'package:messageai/data/drift/daos/pending_outbox_dao.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Test suite for offline message queueing functionality
void main() {
  late AppDb database;
  late MessageDao messageDao;
  late PendingOutboxDao outboxDao;

  setUp(() {
    // Create in-memory database for testing
    database = AppDb._testConstructor(NativeDatabase.memory());
    messageDao = database.messageDao;
    outboxDao = database.pendingOutboxDao;
  });

  tearDown(() async {
    await database.close();
  });

  group('Offline Message Queueing', () {
    test('Message is saved locally with isSynced=false', () async {
      // Arrange
      final message = Message(
        id: 'test-msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Hello, offline world!',
        mediaUrl: null,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );

      // Act
      await messageDao.insertMessage(message);

      // Assert
      final retrieved = await messageDao.getMessageById('test-msg-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-msg-1');
      expect(retrieved.body, 'Hello, offline world!');
      expect(retrieved.isSynced, false);
    });

    test('Unsynced messages can be queried', () async {
      // Arrange - insert synced and unsynced messages
      await messageDao.insertMessage(Message(
        id: 'msg-synced',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Synced message',
        createdAt: 1000,
        updatedAt: 1000,
        isSynced: true,
      ));

      await messageDao.insertMessage(Message(
        id: 'msg-unsynced-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Unsynced message 1',
        createdAt: 1001,
        updatedAt: 1001,
        isSynced: false,
      ));

      await messageDao.insertMessage(Message(
        id: 'msg-unsynced-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Unsynced message 2',
        createdAt: 1002,
        updatedAt: 1002,
        isSynced: false,
      ));

      // Act
      final unsyncedMessages = await messageDao.getUnsyncedMessages();

      // Assert
      expect(unsyncedMessages.length, 2);
      expect(unsyncedMessages[0].id, 'msg-unsynced-1');
      expect(unsyncedMessages[1].id, 'msg-unsynced-2');
    });

    test('Message can be marked as synced', () async {
      // Arrange
      await messageDao.insertMessage(Message(
        id: 'msg-to-sync',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Will be synced',
        createdAt: 1000,
        updatedAt: 1000,
        isSynced: false,
      ));

      // Act
      await messageDao.markMessageAsSynced('msg-to-sync');

      // Assert
      final message = await messageDao.getMessageById('msg-to-sync');
      expect(message!.isSynced, true);
    });

    test('Pending operation is added to outbox', () async {
      // Act
      await outboxDao.addPendingOperation(
        id: 'op-1',
        operation: 'send_message',
        payload: '{"id":"msg-1","body":"test"}',
        conversationId: 'conv-1',
      );

      // Assert
      final operations = await outboxDao.getAllPendingOperations();
      expect(operations.length, 1);
      expect(operations[0].id, 'op-1');
      expect(operations[0].operation, 'send_message');
    });

    test('Pending operation can be removed after sync', () async {
      // Arrange
      await outboxDao.addPendingOperation(
        id: 'op-to-remove',
        operation: 'send_message',
        payload: '{"id":"msg-1"}',
        conversationId: 'conv-1',
      );

      // Act
      await outboxDao.removePendingOperation('op-to-remove');

      // Assert
      final operations = await outboxDao.getAllPendingOperations();
      expect(operations.length, 0);
    });

    test('Retry count is tracked for failed operations', () async {
      // Arrange
      await outboxDao.addPendingOperation(
        id: 'op-retry',
        operation: 'send_message',
        payload: '{"id":"msg-1"}',
        conversationId: 'conv-1',
      );

      // Act - simulate retries
      await outboxDao.updateRetryInfo('op-retry', 1, 'Network error');
      await outboxDao.updateRetryInfo('op-retry', 2, 'Network error');

      // Assert
      final operations = await outboxDao.getAllPendingOperations();
      expect(operations[0].retryCount, 2);
      expect(operations[0].lastError, 'Network error');
    });

    test('Operations with max retries are excluded from retryable', () async {
      // Arrange
      await outboxDao.addPendingOperation(
        id: 'op-1',
        operation: 'send_message',
        payload: '{}',
        conversationId: 'conv-1',
      );
      await outboxDao.addPendingOperation(
        id: 'op-2',
        operation: 'send_message',
        payload: '{}',
        conversationId: 'conv-1',
      );

      // Simulate max retries on op-1
      await outboxDao.updateRetryInfo('op-1', 3, 'Max retries reached');

      // Act
      final retryable = await outboxDao.getRetryableOperations(maxRetries: 3);

      // Assert
      expect(retryable.length, 1);
      expect(retryable[0].id, 'op-2');
    });

    test('Multiple messages are queued in order', () async {
      // Arrange - simulate sending 5 messages offline
      for (int i = 1; i <= 5; i++) {
        await messageDao.insertMessage(Message(
          id: 'msg-$i',
          conversationId: 'conv-1',
          senderId: 'user-1',
          body: 'Message $i',
          createdAt: 1000 + i,
          updatedAt: 1000 + i,
          isSynced: false,
        ));

        await outboxDao.addPendingOperation(
          id: 'op-$i',
          operation: 'send_message',
          payload: '{"id":"msg-$i"}',
          conversationId: 'conv-1',
        );
      }

      // Assert
      final messages = await messageDao.getUnsyncedMessages();
      final operations = await outboxDao.getAllPendingOperations();

      expect(messages.length, 5);
      expect(operations.length, 5);

      // Check they're in order
      for (int i = 0; i < 5; i++) {
        expect(messages[i].id, 'msg-${i + 1}');
      }
    });

    test('Unsynced message count is accurate', () async {
      // Arrange
      await messageDao.insertMessage(Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Unsynced 1',
        createdAt: 1000,
        updatedAt: 1000,
        isSynced: false,
      ));
      await messageDao.insertMessage(Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Unsynced 2',
        createdAt: 1001,
        updatedAt: 1001,
        isSynced: false,
      ));
      await messageDao.insertMessage(Message(
        id: 'msg-3',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: 'Synced',
        createdAt: 1002,
        updatedAt: 1002,
        isSynced: true,
      ));

      // Act
      final count = await messageDao.getUnsyncedMessageCount();

      // Assert
      expect(count, 2);
    });
  });

  group('Offline Queue Edge Cases', () {
    test('Empty queue returns empty list', () async {
      final operations = await outboxDao.getAllPendingOperations();
      expect(operations, isEmpty);
    });

    test('Message with media URL is queued correctly', () async {
      // Arrange
      await messageDao.insertMessage(Message(
        id: 'msg-media',
        conversationId: 'conv-1',
        senderId: 'user-1',
        body: '📷 Photo',
        mediaUrl: 'https://example.com/image.jpg',
        createdAt: 1000,
        updatedAt: 1000,
        isSynced: false,
      ));

      // Assert
      final message = await messageDao.getMessageById('msg-media');
      expect(message!.mediaUrl, 'https://example.com/image.jpg');
      expect(message.isSynced, false);
    });

    test('Conversation-specific operations can be queried', () async {
      // Arrange
      await outboxDao.addPendingOperation(
        id: 'op-conv1',
        operation: 'send_message',
        payload: '{}',
        conversationId: 'conv-1',
      );
      await outboxDao.addPendingOperation(
        id: 'op-conv2',
        operation: 'send_message',
        payload: '{}',
        conversationId: 'conv-2',
      );

      // Act
      final conv1Ops = await outboxDao.getPendingOperationsByConversation('conv-1');

      // Assert
      expect(conv1Ops.length, 1);
      expect(conv1Ops[0].conversationId, 'conv-1');
    });
  });
}

/// Extension for AppDb to create test instance
extension AppDbTest on AppDb {
  static AppDb _testConstructor(DatabaseConnection connection) {
    return AppDb._internal(connection);
  }
}

extension on AppDb {
  AppDb._internal(DatabaseConnection connection) : super._testConstructor(connection);
  
  AppDb._testConstructor(DatabaseConnection connection)
      : super._createWithConnection(connection);
}

// Add this constructor to AppDb class in app_db.dart:
// AppDb._createWithConnection(DatabaseConnection connection) : super(connection);

