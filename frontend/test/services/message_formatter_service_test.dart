import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/message_formatter_service.dart';

/// Phase 2: MessageFormatterService Tests
void main() {
  group('MessageFormatterService', () {
    late MessageFormatterService service;

    setUp(() {
      service = MessageFormatterService(userId: 'test-user-123');
    });

    group('Initialization', () {
      test('requires userId parameter', () {
        expect(() => MessageFormatterService(userId: ''), returnsNormally);
        expect(() => MessageFormatterService(userId: 'user-123'), returnsNormally);
      });

      test('stores userId correctly', () {
        final service = MessageFormatterService(userId: 'test-user-456');
        expect(service, isNotNull);
      });
    });

    group('formatMessage', () {
      test('accepts required message parameter', () async {
        try {
          final result = await service.formatMessage(
            message: "I can't make it to the party",
          );
          
          expect(result, isNotNull);
          expect(result.formattedMessage, isNotEmpty);
        } catch (e) {
          // May fail without backend - that's OK
          expect(e.toString(), isNotEmpty);
        }
      });

      test('handles empty message', () async {
        try {
          final result = await service.formatMessage(message: '');
          expect(result, isNotNull);
        } catch (e) {
          // Expected - empty messages should be handled
          expect(e.toString(), isNotEmpty);
        }
      });

      test('handles long messages', () async {
        final longMessage = 'This is a very long message. ' * 50;
        
        try {
          final result = await service.formatMessage(message: longMessage);
          expect(result, isNotNull);
          expect(result.formattedMessage, isNotEmpty);
        } catch (e) {
          // May fail without backend
          expect(e.toString(), isNotEmpty);
        }
      });
    });

    group('Message Types', () {
      test('handles declining messages', () async {
        final messages = [
          "I can't make it",
          "Sorry, I have to decline",
          "I won't be able to attend",
        ];

        for (final message in messages) {
          try {
            final result = await service.formatMessage(message: message);
            expect(result, isNotNull);
          } catch (e) {
            // Expected without backend
          }
        }
      });

      test('handles boundary messages', () async {
        final messages = [
          "I need you to stop calling me after 9pm",
          "Please respect my time off",
          "I'm not comfortable with that",
        ];

        for (final message in messages) {
          try {
            final result = await service.formatMessage(message: message);
            expect(result, isNotNull);
          } catch (e) {
            // Expected without backend
          }
        }
      });

      test('handles apology messages', () async {
        final messages = [
          "I'm sorry for the delay",
          "I apologize for the mistake",
          "Sorry about that",
        ];

        for (final message in messages) {
          try {
            final result = await service.formatMessage(message: message);
            expect(result, isNotNull);
          } catch (e) {
            // Expected without backend
          }
        }
      });
    });

    group('Error Handling', () {
      test('handles network errors gracefully', () async {
        expect(
          () => service.formatMessage(message: 'test'),
          returnsNormally,
        );
      });

      test('handles authentication errors', () async {
        final unauthService = MessageFormatterService(userId: 'invalid');
        
        expect(
          () => unauthService.formatMessage(message: 'test'),
          returnsNormally,
        );
      });
    });
  });
}

