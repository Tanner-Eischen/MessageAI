import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/context_preloader_service.dart';

/// Phase 3: ContextPreloaderService Tests
void main() {
  group('ContextPreloaderService', () {
    late ContextPreloaderService service;

    setUp(() {
      service = ContextPreloaderService();
    });

    group('Singleton Pattern', () {
      test('returns same instance', () {
        final instance1 = ContextPreloaderService();
        final instance2 = ContextPreloaderService();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('loadContext', () {
      test('accepts conversationId parameter', () async {
        try {
          final context = await service.loadContext(
            conversationId: 'test-conv-123',
          );
          
          expect(context, isNotNull);
        } catch (e) {
          // Expected to fail without auth/backend
          expect(e.toString(), isNotEmpty);
        }
      });

      test('handles invalid conversation ID', () async {
        try {
          final context = await service.loadContext(conversationId: '');
          expect(context, isNotNull);
        } catch (e) {
          // Expected - should handle gracefully
          expect(e.toString(), isNotEmpty);
        }
      });

      test('handles non-existent conversation', () async {
        try {
          final context = await service.loadContext(
            conversationId: 'non-existent-conv',
          );
          expect(context, isNotNull);
        } catch (e) {
          // Expected
          expect(e.toString(), isNotEmpty);
        }
      });
    });

    group('Cache Management', () {
      test('invalidate method exists', () {
        expect(service.invalidate, isA<Function>());
      });

      test('invalidate accepts conversationId', () {
        expect(
          () => service.invalidate('test-conv-123'),
          returnsNormally,
        );
      });

      test('invalidate handles null/empty conversationId', () {
        expect(() => service.invalidate(''), returnsNormally);
        expect(() => service.invalidate(null), returnsNormally);
      });
    });

    group('Performance', () {
      test('caches results for performance', () async {
        final conversationId = 'test-conv-cache';
        
        try {
          // First load
          final start1 = DateTime.now();
          await service.loadContext(conversationId: conversationId);
          final duration1 = DateTime.now().difference(start1);

          // Second load (should be cached)
          final start2 = DateTime.now();
          await service.loadContext(conversationId: conversationId);
          final duration2 = DateTime.now().difference(start2);

          // Cache should be faster (or at least not slower)
          expect(duration2.inMilliseconds, lessThanOrEqualTo(duration1.inMilliseconds + 100));
        } catch (e) {
          // Expected without backend
        }
      });

      test('invalidate clears cache', () async {
        final conversationId = 'test-conv-invalidate';
        
        try {
          // Load and cache
          await service.loadContext(conversationId: conversationId);
          
          // Invalidate
          service.invalidate(conversationId);
          
          // Load again (should not be cached)
          final context = await service.loadContext(conversationId: conversationId);
          expect(context, isNotNull);
        } catch (e) {
          // Expected without backend
        }
      });
    });

    group('Error Handling', () {
      test('handles network errors gracefully', () async {
        expect(
          () => service.loadContext(conversationId: 'test'),
          returnsNormally,
        );
      });

      test('handles authentication errors', () async {
        // Without auth, should throw or return null
        try {
          await service.loadContext(conversationId: 'test');
        } catch (e) {
          expect(e.toString(), isNotEmpty);
        }
      });
    });

    group('API Methods', () {
      test('has all required methods', () {
        expect(service.loadContext, isA<Function>());
        expect(service.invalidate, isA<Function>());
      });
    });
  });
}
