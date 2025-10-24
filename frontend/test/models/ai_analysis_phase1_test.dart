import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('AIAnalysis Phase 1 Integration Tests', () {
    test('fromJson parses Phase 1 fields correctly', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-123',
        'tone': 'Neutral',
        'urgency_level': 'Low',
        'intent': 'Quick acknowledgment',
        'confidence_score': 0.85,
        'analysis_timestamp': 1234567890,
        'rsd_triggers': [
          {
            'pattern': 'ok',
            'severity': 'high',
            'explanation': 'Single-word responses can trigger RSD',
            'reassurance': 'This is likely just a quick acknowledgment',
          }
        ],
        'alternative_interpretations': [
          {
            'interpretation': 'Simple acknowledgment',
            'tone': 'Neutral',
            'likelihood': 70,
            'reasoning': 'Most common use',
            'context_clues': ['No conflict'],
          }
        ],
        'evidence': [
          {
            'type': 'length',
            'quote': 'ok',
            'supports': 'brevity',
            'reasoning': 'Very short message',
          }
        ],
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.id, 'test-id');
      expect(analysis.messageId, 'msg-123');
      expect(analysis.tone, 'Neutral');
      
      // Check Phase 1 fields
      expect(analysis.rsdTriggers, isNotNull);
      expect(analysis.rsdTriggers!.length, 1);
      expect(analysis.rsdTriggers![0].pattern, 'ok');
      expect(analysis.rsdTriggers![0].severity, 'high');
      
      expect(analysis.alternativeInterpretations, isNotNull);
      expect(analysis.alternativeInterpretations!.length, 1);
      expect(analysis.alternativeInterpretations![0].interpretation, 'Simple acknowledgment');
      expect(analysis.alternativeInterpretations![0].likelihood, 70);
      
      expect(analysis.evidence, isNotNull);
      expect(analysis.evidence!.length, 1);
      expect(analysis.evidence![0].type, 'length');
      expect(analysis.evidence![0].quote, 'ok');
    });

    test('toJson serializes Phase 1 fields correctly', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-123',
        tone: 'Neutral',
        urgencyLevel: 'Low',
        intent: 'Test',
        confidenceScore: 0.85,
        analysisTimestamp: 1234567890,
        rsdTriggers: [
          const RSDTrigger(
            pattern: 'ok',
            severity: 'high',
            explanation: 'test',
            reassurance: 'test',
          )
        ],
        alternativeInterpretations: [
          const MessageInterpretation(
            interpretation: 'test',
            tone: 'Neutral',
            likelihood: 70,
            reasoning: 'test',
            contextClues: [],
          )
        ],
        evidence: [
          const Evidence(
            type: 'keyword',
            quote: 'ASAP',
            supports: 'urgency',
            reasoning: 'test',
          )
        ],
      );

      final json = analysis.toJson();

      expect(json['rsd_triggers'], isNotNull);
      expect(json['rsd_triggers'], isList);
      expect((json['rsd_triggers'] as List).length, 1);
      
      expect(json['alternative_interpretations'], isNotNull);
      expect(json['alternative_interpretations'], isList);
      expect((json['alternative_interpretations'] as List).length, 1);
      
      expect(json['evidence'], isNotNull);
      expect(json['evidence'], isList);
      expect((json['evidence'] as List).length, 1);
    });

    test('fromJson handles null Phase 1 fields', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-123',
        'tone': 'Neutral',
        'analysis_timestamp': 1234567890,
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.rsdTriggers, null);
      expect(analysis.alternativeInterpretations, null);
      expect(analysis.evidence, null);
    });

    test('fromJson handles empty Phase 1 arrays', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-123',
        'tone': 'Neutral',
        'analysis_timestamp': 1234567890,
        'rsd_triggers': [],
        'alternative_interpretations': [],
        'evidence': [],
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.rsdTriggers, isNotNull);
      expect(analysis.rsdTriggers!.isEmpty, true);
      expect(analysis.alternativeInterpretations, isNotNull);
      expect(analysis.alternativeInterpretations!.isEmpty, true);
      expect(analysis.evidence, isNotNull);
      expect(analysis.evidence!.isEmpty, true);
    });
  });
}

