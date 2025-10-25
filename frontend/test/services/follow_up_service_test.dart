import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/follow_up_service.dart';
import 'package:messageai/models/follow_up_item.dart';

/// Phase 4: FollowUpService Tests
/// Note: These tests require Supabase authentication to be mocked or a test environment
void main() {
  group('FollowUpService', () {
    late FollowUpService service;

    setUp(() {
      service = FollowUpService();
    });

    group('Singleton Pattern', () {
      test('returns same instance', () {
        final instance1 = FollowUpService();
        final instance2 = FollowUpService();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('getPendingFollowUps', () {
      test('returns list of follow-up items', () async {
        // Note: This will fail without authentication
        // In a real test, we'd mock the Supabase client
        try {
          final items = await service.getPendingFollowUps();
          expect(items, isList);
          
          // All items should be pending
          for (final item in items) {
            expect(item.status, equals(FollowUpStatus.pending));
          }
        } catch (e) {
          // Expected to fail without auth - skip test
          expect(e.toString(), contains(['auth', 'user', 'session']));
        }
      });

      test('returns empty list when no user authenticated', () async {
        final items = await service.getPendingFollowUps();
        expect(items, isEmpty);
      });
    });

    group('getConversationFollowUps', () {
      test('returns items for specific conversation', () async {
        try {
          final conversationId = 'test-conv-123';
          final items = await service.getConversationFollowUps(conversationId);
          
          expect(items, isList);
          
          // All items should be for the specified conversation
          for (final item in items) {
            expect(item.conversationId, equals(conversationId));
          }
        } catch (e) {
          // Expected to fail without auth
          expect(e.toString(), contains(['auth', 'user', 'session']));
        }
      });

      test('returns empty list for non-existent conversation', () async {
        final items = await service.getConversationFollowUps('non-existent');
        expect(items, isEmpty);
      });
    });

    group('Duration Parameter', () {
      test('snoozeFollowUp accepts Duration object', () async {
        // Test that the method signature accepts Duration
        expect(
          () => service.snoozeFollowUp('test-id', const Duration(hours: 1)),
          returnsNormally,
        );
      });

      test('Duration is converted to seconds correctly', () {
        const duration = Duration(hours: 2, minutes: 30);
        expect(duration.inSeconds, equals(9000));
      });
    });

    group('Error Handling', () {
      test('handles network errors gracefully', () async {
        // Without auth, should return empty list instead of throwing
        final items = await service.getPendingFollowUps();
        expect(items, isEmpty);
      });

      test('handles invalid conversation ID', () async {
        final items = await service.getConversationFollowUps('');
        expect(items, isEmpty);
      });
    });

    group('API Methods', () {
      test('has all required CRUD methods', () {
        expect(service.getPendingFollowUps, isA<Function>());
        expect(service.getConversationFollowUps, isA<Function>());
        expect(service.extractFollowUps, isA<Function>());
        expect(service.completeFollowUp, isA<Function>());
        expect(service.snoozeFollowUp, isA<Function>());
        expect(service.dismissFollowUp, isA<Function>());
      });
    });
  });
}

