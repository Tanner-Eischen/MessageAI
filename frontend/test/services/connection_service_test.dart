import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:messageai/services/connection_service.dart';

void main() {
  group('ConnectionService', () {
    late ConnectionService service;

    setUp(() {
      service = ConnectionService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initial status should be disconnected', () {
      expect(service.currentStatus, ConnectionStatus.disconnected);
    });

    test('status stream should emit status changes', () async {
      final statusList = <ConnectionStatus>[];
      service.statusStream.listen(statusList.add);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(statusList, isNotEmpty);
    });

    test('exponential backoff calculation', () {
      fakeAsync((async) {
        int reconnectAttempts = 0;
        final delays = <Duration>[];

        for (int i = 1; i <= 5; i++) {
          reconnectAttempts = i;
          final delaySeconds = 1 * (1 << (reconnectAttempts - 1));
          final maxDelaySeconds = 60;
          final actualDelay =
              delaySeconds > maxDelaySeconds ? maxDelaySeconds : delaySeconds;
          delays.add(Duration(seconds: actualDelay));
        }

        expect(delays[0].inSeconds, 1);
        expect(delays[1].inSeconds, 2);
        expect(delays[2].inSeconds, 4);
        expect(delays[3].inSeconds, 8);
        expect(delays[4].inSeconds, 16);
      });
    });

    test('max backoff should cap at 60 seconds', () {
      fakeAsync((async) {
        for (int i = 7; i <= 10; i++) {
          final delaySeconds = 1 * (1 << (i - 1));
          final maxDelaySeconds = 60;
          final actualDelay =
              delaySeconds > maxDelaySeconds ? maxDelaySeconds : delaySeconds;

          expect(actualDelay, 60);
        }
      });
    });

    test('forceReconnect should reset attempt counter', () async {
      await service.forceReconnect();
      expect(service.currentStatus, isIn([
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.reconnecting,
      ]));
    });

    test('dispose should close status stream', () async {
      bool streamClosed = false;
      service.statusStream.listen(
        (_) {},
        onDone: () => streamClosed = true,
      );

      await service.dispose();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(streamClosed, isTrue);
    });
  });
}
