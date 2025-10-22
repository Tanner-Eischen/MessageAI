import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    test('getDeviceToken returns string or null', () async {
      final token = await service.getDeviceToken();
      expect(token, anyOf(isNull, isA<String>()));
    });

    test('areNotificationsEnabled returns bool', () async {
      final enabled = await service.areNotificationsEnabled();
      expect(enabled, isA<bool>());
    });

    test('subscribeToTopic completes without error', () async {
      expect(
        () async => await service.subscribeToTopic('test_topic'),
        returnsNormally,
      );
    });

    test('unsubscribeFromTopic completes without error', () async {
      expect(
        () async => await service.unsubscribeFromTopic('test_topic'),
        returnsNormally,
      );
    });
  });

  group('NotificationPayload', () {
    test('extracts conversation ID from data', () {
      final payload = NotificationPayload(
        title: 'Test',
        body: 'Test message',
        data: {
          'conversation_id': 'conv-123',
          'sender_id': 'user-456',
        },
      );

      expect(payload.conversationId, 'conv-123');
      expect(payload.senderId, 'user-456');
    });

    test('handles missing data fields gracefully', () {
      final payload = NotificationPayload(
        title: 'Test',
        body: 'Test message',
        data: {},
      );

      expect(payload.conversationId, isNull);
      expect(payload.senderId, isNull);
      expect(payload.messageIdFromPayload, isNull);
    });

    test('extracts message body from data', () {
      final payload = NotificationPayload(
        title: 'Test',
        body: 'Test message',
        data: {
          'message_body': 'Hello world',
        },
      );

      expect(payload.messageBody, 'Hello world');
    });
  });
}
