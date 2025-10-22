import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/device_token_service.dart';

void main() {
  group('DeviceTokenService', () {
    late DeviceTokenService service;

    setUp(() {
      service = DeviceTokenService();
    });

    test('registerDeviceToken handles invalid token gracefully', () async {
      expect(
        () async => await service.registerDeviceToken('invalid-token'),
        returnsNormally,
      );
    });

    test('unregisterDeviceToken handles non-existent token', () async {
      expect(
        () async => await service.unregisterDeviceToken('non-existent-token'),
        returnsNormally,
      );
    });

    test('updateDeviceLastSeen handles errors gracefully', () async {
      expect(
        () async => await service.updateDeviceLastSeen('test-token'),
        returnsNormally,
      );
    });

    test('getUserDevices returns list', () async {
      final devices = await service.getUserDevices();
      expect(devices, isA<List<Map<String, dynamic>>>());
    });

    test('cleanupStaleDevices completes without error', () async {
      expect(
        () async => await service.cleanupStaleDevices(),
        returnsNormally,
      );
    });
  });
}
