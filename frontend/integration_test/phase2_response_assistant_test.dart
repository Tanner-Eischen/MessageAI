import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/services/draft_confidence_service.dart';
import 'package:messageai/services/message_formatter_service.dart';

/// Phase 2: Adaptive Response Assistant Integration Tests
/// Tests: Draft Confidence Checker, Social Scripts, Boundary Support
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2: Adaptive Response Assistant', () {
    late DraftConfidenceService confidenceService;
    late MessageFormatterService formatterService;

    setUp(() {
      confidenceService = DraftConfidenceService();
      formatterService = MessageFormatterService();
    });

    group('Draft Confidence Checker', () {
      test('analyzes confident professional message', () async {
        final result = await confidenceService.analyzeDraft(
          "Thank you for your email. I'll review the proposal and send my feedback by Friday.",
        );

        expect(result, isNotNull);
        expect(result!.overallConfidence, greaterThan(0.7));
        expect(result.flags, isEmpty);
      });

      test('detects excessive apologizing', () async {
        final result = await confidenceService.analyzeDraft(
          "Sorry to bother you, I'm really sorry but I just wanted to ask if maybe you could possibly help me? Sorry!",
        );

        expect(result, isNotNull);
        expect(result!.flags, isNotEmpty);
        expect(
          result.flags,
          anyElement((flag) => flag.type.contains('excessive_apologizing')),
        );
        expect(result.overallConfidence, lessThan(0.5));
      });

      test('detects hedging language', () async {
        final result = await confidenceService.analyzeDraft(
          "I kind of think that maybe we should perhaps consider possibly doing this differently.",
        );

        expect(result, isNotNull);
        expect(
          result!.flags,
          anyElement((flag) => flag.type.contains('hedging')),
        );
        expect(result.suggestions, isNotEmpty);
      });

      test('detects self-deprecation', () async {
        final result = await confidenceService.analyzeDraft(
          "I'm not great at this, but here's my terrible attempt at solving the problem.",
        );

        expect(result, isNotNull);
        expect(
          result!.flags,
          anyElement((flag) => flag.type.contains('self_deprecating')),
        );
      });

      test('provides specific suggestions for improvement', () async {
        final result = await confidenceService.analyzeDraft(
          "Sorry, but I think maybe we could possibly try this?",
        );

        expect(result, isNotNull);
        expect(result!.suggestions, isNotEmpty);
        expect(result.improvedVersion, isNotNull);
        expect(result.improvedVersion, isNot(equals(result.suggestions.first)));
      });
    });

    group('Message Formatter with Templates', () {
      test('formats declining invitation message', () async {
        final result = await formatterService.formatMessage(
          situation: 'declining_invitation',
          context: 'dinner party',
          userInput: "I can't make it",
        );

        expect(result, isNotNull);
        expect(result.formattedMessage, isNotEmpty);
        expect(result.formattedMessage, contains(['thank', 'appreciate', 'unfortunately']));
        expect(result.tone, equals('polite'));
      });

      test('formats boundary setting message', () async {
        final result = await formatterService.formatMessage(
          situation: 'setting_boundary',
          context: 'work hours',
          userInput: "I don't work on weekends",
        );

        expect(result, isNotNull);
        expect(result.formattedMessage, isNotEmpty);
        expect(result.formattedMessage.toLowerCase(), contains(['weekend', 'time', 'balance']));
        expect(result.tone, equals('assertive'));
      });

      test('formats apologizing message', () async {
        final result = await formatterService.formatMessage(
          situation: 'apologizing',
          context: 'missed deadline',
          userInput: "I'm sorry for missing the deadline",
        );

        expect(result, isNotNull);
        expect(result.formattedMessage, contains(['apologize', 'sorry']));
        expect(result.actionItems, isNotEmpty);
      });

      test('formats info dump with structure', () async {
        final result = await formatterService.formatMessage(
          situation: 'info_dump',
          context: 'project explanation',
          userInput: "So there's this thing and it does stuff and also this other thing connects to it...",
        );

        expect(result, isNotNull);
        expect(result.formattedMessage, isNotEmpty);
        // Should have better structure
        expect(result.formattedMessage, contains(['\n', 'first', 'second', '1', '2']));
      });

      test('formats clarifying question', () async {
        final result = await formatterService.formatMessage(
          situation: 'asking_clarification',
          context: 'meeting details',
          userInput: "When is the meeting?",
        );

        expect(result, isNotNull);
        expect(result.formattedMessage, contains(['could', 'please', 'clarify', 'confirm']));
      });
    });

    group('Situation Detection', () {
      test('detects when user is declining', () async {
        final situation = await formatterService.detectSituation(
          "I don't think I can make it to the event",
        );

        expect(situation, isNotNull);
        expect(situation, equals('declining_invitation'));
      });

      test('detects when user is setting boundary', () async {
        final situation = await formatterService.detectSituation(
          "I need you to stop calling me after 9pm",
        );

        expect(situation, isNotNull);
        expect(situation, contains('boundary'));
      });

      test('detects when user is apologizing', () async {
        final situation = await formatterService.detectSituation(
          "I'm really sorry about the mistake I made",
        );

        expect(situation, isNotNull);
        expect(situation, contains('apolog'));
      });
    });

    group('Comprehensive Draft Analysis', () {
      test('analyzes and improves weak professional email', () async {
        final draft = """
Sorry to bother you! I was just wondering if maybe you might possibly 
have a moment to look at my work? I know you're super busy and I'm 
probably not doing this right, but I'd really appreciate it if you could 
possibly give me some feedback? Sorry again for bothering you!
        """;

        final result = await confidenceService.analyzeDraft(draft);

        expect(result, isNotNull);
        expect(result!.flags.length, greaterThanOrEqualTo(3));
        expect(result.overallConfidence, lessThan(0.4));
        expect(result.improvedVersion, isNotNull);
        expect(result.improvedVersion!.length, lessThan(draft.length));
      });

      test('validates strong professional message', () async {
        final draft = """
Hi Sarah,

I wanted to follow up on the project proposal we discussed. I've reviewed 
the requirements and have some suggestions that could improve efficiency.

Could we schedule a 30-minute call this week to discuss?

Best regards,
Alex
        """;

        final result = await confidenceService.analyzeDraft(draft);

        expect(result, isNotNull);
        expect(result!.overallConfidence, greaterThan(0.7));
        expect(result.flags, isEmpty);
      });
    });
  });
}

