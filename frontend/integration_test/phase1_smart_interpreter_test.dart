import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/services/tone_analysis_service.dart';
import 'package:messageai/services/message_interpreter_service.dart';

/// Phase 1: Smart Message Interpreter Integration Tests
/// Tests: Enhanced Tone Analysis, RSD Detection, Alternative Interpretations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1: Smart Message Interpreter', () {
    late ToneAnalysisService toneService;
    late MessageInterpreterService interpreterService;

    setUp(() {
      toneService = ToneAnalysisService();
      interpreterService = MessageInterpreterService();
    });

    group('Enhanced Tone Analysis (23 tones)', () {
      test('analyzes supportive message correctly', () async {
        final result = await toneService.analyzeTone(
          "You're doing great! I'm here to help if you need anything.",
        );

        expect(result, isNotNull);
        expect(result!.primaryTone, isIn(['supportive', 'encouraging', 'warm']));
        expect(result.intensity, greaterThan(0.5));
        expect(result.neurodivergentContext, isNotNull);
      });

      test('analyzes sarcastic message correctly', () async {
        final result = await toneService.analyzeTone(
          "Oh great, another meeting. Just what I needed today.",
        );

        expect(result, isNotNull);
        expect(result!.primaryTone, contains('sarcastic'));
        expect(result.confidence, greaterThan(0.6));
      });

      test('detects mixed tones', () async {
        final result = await toneService.analyzeTone(
          "I appreciate your help, but I'm a bit frustrated with the delay.",
        );

        expect(result, isNotNull);
        expect(result!.tones.length, greaterThanOrEqualTo(2));
        expect(result.tones, anyElement(contains('appreciative')));
        expect(result.tones, anyElement(contains('frustrated')));
      });

      test('provides neurodivergent-friendly context', () async {
        final result = await toneService.analyzeTone(
          "Can you send me that thing we talked about?",
        );

        expect(result, isNotNull);
        expect(result!.neurodivergentContext, isNotNull);
        expect(result.neurodivergentContext!.needsClarification, isTrue);
      });
    });

    group('RSD Detection', () {
      test('detects potential RSD trigger - criticism', () async {
        final result = await interpreterService.interpretMessage(
          "You didn't do this correctly.",
          senderName: 'Boss',
        );

        expect(result.rsdAlert, isNotNull);
        expect(result.rsdAlert!.triggerType, contains('criticism'));
        expect(result.rsdAlert!.severity, greaterThan(0.5));
      });

      test('detects potential RSD trigger - rejection', () async {
        final result = await interpreterService.interpretMessage(
          "I don't think this is a good fit for us right now.",
          senderName: 'Client',
        );

        expect(result.rsdAlert, isNotNull);
        expect(result.rsdAlert!.triggerType, contains('rejection'));
      });

      test('does not flag neutral messages', () async {
        final result = await interpreterService.interpretMessage(
          "The meeting is scheduled for 3pm tomorrow.",
          senderName: 'Colleague',
        );

        expect(result.rsdAlert, isNull);
      });

      test('provides coping strategies for RSD triggers', () async {
        final result = await interpreterService.interpretMessage(
          "Your work is consistently below expectations.",
          senderName: 'Manager',
        );

        expect(result.rsdAlert, isNotNull);
        expect(result.rsdAlert!.copingStrategies, isNotEmpty);
      });
    });

    group('Alternative Interpretations', () {
      test('provides multiple interpretations for ambiguous messages', () async {
        final result = await interpreterService.interpretMessage(
          "We need to talk.",
          senderName: 'Friend',
        );

        expect(result.alternativeInterpretations, isNotEmpty);
        expect(result.alternativeInterpretations.length, greaterThanOrEqualTo(2));
      });

      test('extracts evidence for each interpretation', () async {
        final result = await interpreterService.interpretMessage(
          "Thanks for your input. I'll consider it.",
          senderName: 'Boss',
        );

        for (final interpretation in result.alternativeInterpretations) {
          expect(interpretation.evidence, isNotEmpty);
          expect(interpretation.likelihood, greaterThan(0));
          expect(interpretation.likelihood, lessThanOrEqualTo(1));
        }
      });

      test('handles literal interpretation for neurodivergent users', () async {
        final result = await interpreterService.interpretMessage(
          "That's interesting.",
          senderName: 'Coworker',
        );

        expect(
          result.alternativeInterpretations,
          anyElement((interp) => interp.interpretation.contains('literal')),
        );
      });
    });

    group('Comprehensive Message Analysis', () {
      test('analyzes complex professional email', () async {
        final message = """
Hi there,

I wanted to follow up on our conversation from last week. 
While I appreciate your efforts, I think we need to reconsider 
our approach. Can we schedule a call to discuss?

Best regards
        """;

        final result = await interpreterService.interpretMessage(
          message,
          senderName: 'Project Lead',
        );

        expect(result.toneAnalysis, isNotNull);
        expect(result.alternativeInterpretations, isNotEmpty);
        // Should detect "reconsider" as potential concern
        expect(result.rsdAlert != null || result.toneAnalysis!.primaryTone.contains('concern'), isTrue);
      });

      test('analyzes casual message with emojis', () async {
        final result = await interpreterService.interpretMessage(
          "Hey! 😊 Just checking in. How's it going?",
          senderName: 'Friend',
        );

        expect(result.toneAnalysis, isNotNull);
        expect(result.toneAnalysis!.primaryTone, contains(['friendly', 'casual', 'warm']));
        expect(result.rsdAlert, isNull);
      });
    });
  });
}

