import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('Evidence Model Tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'type': 'keyword',
        'quote': 'ASAP',
        'supports': 'urgency',
        'reasoning': 'Explicit urgency marker',
      };

      final evidence = Evidence.fromJson(json);

      expect(evidence.type, 'keyword');
      expect(evidence.quote, 'ASAP');
      expect(evidence.supports, 'urgency');
      expect(evidence.reasoning, 'Explicit urgency marker');
    });

    test('toJson serializes correctly', () {
      const evidence = Evidence(
        type: 'punctuation',
        quote: '!!!',
        supports: 'high intensity',
        reasoning: 'Multiple exclamation marks show strong emotion',
      );

      final json = evidence.toJson();

      expect(json['type'], 'punctuation');
      expect(json['quote'], '!!!');
      expect(json['supports'], 'high intensity');
      expect(json['reasoning'], 'Multiple exclamation marks show strong emotion');
    });

    test('isKeywordEvidence returns true for keyword type', () {
      const evidence = Evidence(
        type: 'keyword',
        quote: 'ASAP',
        supports: 'urgency',
        reasoning: 'test',
      );

      expect(evidence.isKeywordEvidence, true);
      expect(evidence.isPunctuationEvidence, false);
      expect(evidence.isEmojiEvidence, false);
    });

    test('isPunctuationEvidence returns true for punctuation type', () {
      const evidence = Evidence(
        type: 'punctuation',
        quote: '!!!',
        supports: 'intensity',
        reasoning: 'test',
      );

      expect(evidence.isKeywordEvidence, false);
      expect(evidence.isPunctuationEvidence, true);
      expect(evidence.isEmojiEvidence, false);
    });

    test('isEmojiEvidence returns true for emoji type', () {
      const evidence = Evidence(
        type: 'emoji',
        quote: '😊',
        supports: 'friendly tone',
        reasoning: 'test',
      );

      expect(evidence.isKeywordEvidence, false);
      expect(evidence.isPunctuationEvidence, false);
      expect(evidence.isEmojiEvidence, true);
    });
  });
}

