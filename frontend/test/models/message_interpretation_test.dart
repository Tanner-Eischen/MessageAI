import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('MessageInterpretation Model Tests', () {
    test('fromJson parses correctly', () {
      final json = {
        'interpretation': 'Simple acknowledgment',
        'tone': 'Neutral',
        'likelihood': 70,
        'reasoning': 'Most common use of ok',
        'context_clues': ['No prior conflict', 'Normal conversation flow'],
      };

      final interp = MessageInterpretation.fromJson(json);

      expect(interp.interpretation, 'Simple acknowledgment');
      expect(interp.tone, 'Neutral');
      expect(interp.likelihood, 70);
      expect(interp.reasoning, 'Most common use of ok');
      expect(interp.contextClues.length, 2);
      expect(interp.contextClues[0], 'No prior conflict');
    });

    test('toJson serializes correctly', () {
      const interp = MessageInterpretation(
        interpretation: 'Mildly annoyed',
        tone: 'Frustrated',
        likelihood: 20,
        reasoning: 'Brief response could indicate frustration',
        contextClues: ['Shorter than usual', 'No warmth markers'],
      );

      final json = interp.toJson();

      expect(json['interpretation'], 'Mildly annoyed');
      expect(json['tone'], 'Frustrated');
      expect(json['likelihood'], 20);
      expect(json['reasoning'], 'Brief response could indicate frustration');
      expect((json['context_clues'] as List).length, 2);
    });

    test('isLikely returns true for likelihood >= 60', () {
      const interp = MessageInterpretation(
        interpretation: 'test',
        tone: 'test',
        likelihood: 70,
        reasoning: 'test',
        contextClues: [],
      );

      expect(interp.isLikely, true);
      expect(interp.isPossible, false);
      expect(interp.isUnlikely, false);
    });

    test('isPossible returns true for likelihood 30-59', () {
      const interp = MessageInterpretation(
        interpretation: 'test',
        tone: 'test',
        likelihood: 45,
        reasoning: 'test',
        contextClues: [],
      );

      expect(interp.isLikely, false);
      expect(interp.isPossible, true);
      expect(interp.isUnlikely, false);
    });

    test('isUnlikely returns true for likelihood < 30', () {
      const interp = MessageInterpretation(
        interpretation: 'test',
        tone: 'test',
        likelihood: 10,
        reasoning: 'test',
        contextClues: [],
      );

      expect(interp.isLikely, false);
      expect(interp.isPossible, false);
      expect(interp.isUnlikely, true);
    });

    test('edge case: likelihood = 60 is likely', () {
      const interp = MessageInterpretation(
        interpretation: 'test',
        tone: 'test',
        likelihood: 60,
        reasoning: 'test',
        contextClues: [],
      );

      expect(interp.isLikely, true);
    });

    test('edge case: likelihood = 30 is possible', () {
      const interp = MessageInterpretation(
        interpretation: 'test',
        tone: 'test',
        likelihood: 30,
        reasoning: 'test',
        contextClues: [],
      );

      expect(interp.isPossible, true);
    });
  });
}

