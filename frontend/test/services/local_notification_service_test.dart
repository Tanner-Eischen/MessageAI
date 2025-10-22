import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/local_notification_service.dart';

void main() {
  group('LocalNotificationService', () {
    late LocalNotificationService service;

    setUp(() {
      service = LocalNotificationService();
    });

    test('initialize completes without error', () async {
      expect(
        () async => await service.initialize(),
        returnsNormally,
      );
    });

    test('showNotification handles valid parameters', () async {
      expect(
        () async => await service.showNotification(
          id: 1,
          title: 'Test',
          body: 'Test notification',
        ),
        returnsNormally,
      );
    });

    test('showMessageNotification formats correctly', () async {
      expect(
        () async => await service.showMessageNotification(
          conversationId: 'conv-123',
          senderName: 'John Doe',
          messageBody: 'Hello!',
        ),
        returnsNormally,
      );
    });

    test('cancelNotification handles any id', () async {
      expect(
        () async => await service.cancelNotification(999),
        returnsNormally,
      );
    });

    test('cancelAllNotifications completes', () async {
      expect(
        () async => await service.cancelAllNotifications(),
        returnsNormally,
      );
    });

    test('getPendingNotifications returns list', () async {
      final pending = await service.getPendingNotifications();
      expect(pending, isA<List>());
    });

    test('requestPermissions returns boolean', () async {
      final result = await service.requestPermissions();
      expect(result, isA<bool>());
    });
  });
}
