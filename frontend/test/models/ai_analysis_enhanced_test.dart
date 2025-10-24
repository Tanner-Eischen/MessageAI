import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('AIAnalysis Enhanced Fields', () {
    test('parses complete enhanced analysis from JSON', () {
      final json = {
        'id': 'test-id-123',
        'message_id': 'msg-456',
        'tone': 'Overwhelmed',
        'urgency_level': 'High',
        'intent': 'expressing severe stress',
        'confidence_score': 0.92,
        'analysis_timestamp': 1234567890,
        'intensity': 'very_high',
        'secondary_tones': ['Frustrated', 'Concerned'],
        'context_flags': {
          'tone_indicator_present': true,
          'sarcasm_detected': false,
          'ambiguous': false,
        },
        'anxiety_assessment': {
          'risk_level': 'high',
          'mitigation_suggestions': [
            'Urgent tone detected. Consider asking for a specific timeline.'
          ],
        },
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.id, 'test-id-123');
      expect(analysis.messageId, 'msg-456');
      expect(analysis.tone, 'Overwhelmed');
      expect(analysis.urgencyLevel, 'High');
      expect(analysis.intent, 'expressing severe stress');
      expect(analysis.confidenceScore, 0.92);
      expect(analysis.intensity, 'very_high');
      expect(analysis.secondaryTones, ['Frustrated', 'Concerned']);
      expect(analysis.contextFlags?['tone_indicator_present'], true);
      expect(analysis.anxietyAssessment?['risk_level'], 'high');
    });

    test('parses analysis without enhanced fields (backward compatibility)', () {
      final json = {
        'id': 'test-id-123',
        'message_id': 'msg-456',
        'tone': 'Friendly',
        'urgency_level': 'Low',
        'intent': 'greeting',
        'confidence_score': 0.85,
        'analysis_timestamp': 1234567890,
        // No enhanced fields
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.tone, 'Friendly');
      expect(analysis.intensity, null);
      expect(analysis.secondaryTones, null);
      expect(analysis.contextFlags, null);
      expect(analysis.anxietyAssessment, null);
    });

    test('toJson includes all enhanced fields', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-id',
        tone: 'Playful',
        urgencyLevel: 'Low',
        intent: 'joking around',
        confidenceScore: 0.88,
        analysisTimestamp: 1234567890,
        intensity: 'medium',
        secondaryTones: ['Friendly'],
        contextFlags: {'tone_indicator_present': true},
        anxietyAssessment: {'risk_level': 'low'},
      );

      final json = analysis.toJson();

      expect(json['tone'], 'Playful');
      expect(json['intensity'], 'medium');
      expect(json['secondary_tones'], ['Friendly']);
      expect(json['context_flags'], {'tone_indicator_present': true});
      expect(json['anxiety_assessment'], {'risk_level': 'low'});
    });

    test('toJson excludes null enhanced fields', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-id',
        tone: 'Neutral',
        analysisTimestamp: 1234567890,
        // All optional fields are null
      );

      final json = analysis.toJson();

      expect(json.containsKey('intensity'), false);
      expect(json.containsKey('secondary_tones'), false);
      expect(json.containsKey('context_flags'), false);
      expect(json.containsKey('anxiety_assessment'), false);
    });

    test('toString includes intensity field', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-id',
        tone: 'Excited',
        intensity: 'high',
        analysisTimestamp: 1234567890,
      );

      final str = analysis.toString();

      expect(str.contains('Excited'), true);
      expect(str.contains('high'), true);
    });

    test('handles all 23 tone types', () {
      final tones = [
        'Friendly', 'Professional', 'Urgent', 'Casual', 'Formal', 'Concerned',
        'Excited', 'Neutral', 'Apologetic', 'Appreciative', 'Frustrated', 'Playful',
        'Sarcastic', 'Empathetic', 'Inquisitive', 'Assertive', 'Tentative', 'Defensive',
        'Encouraging', 'Disappointed', 'Overwhelmed', 'Relieved', 'Confused'
      ];

      for (final tone in tones) {
        final json = {
          'id': 'test-id',
          'message_id': 'msg-id',
          'tone': tone,
          'analysis_timestamp': 1234567890,
        };

        final analysis = AIAnalysis.fromJson(json);
        expect(analysis.tone, tone);
      }
    });

    test('handles all 5 intensity levels', () {
      final intensities = ['very_low', 'low', 'medium', 'high', 'very_high'];

      for (final intensity in intensities) {
        final json = {
          'id': 'test-id',
          'message_id': 'msg-id',
          'tone': 'Friendly',
          'intensity': intensity,
          'analysis_timestamp': 1234567890,
        };

        final analysis = AIAnalysis.fromJson(json);
        expect(analysis.intensity, intensity);
      }
    });

    test('parses complex context flags', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-id',
        'tone': 'Sarcastic',
        'analysis_timestamp': 1234567890,
        'context_flags': {
          'sarcasm_detected': true,
          'tone_indicator_present': true,
          'ambiguous': false,
          'figurative_language': true,
        },
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.contextFlags?['sarcasm_detected'], true);
      expect(analysis.contextFlags?['tone_indicator_present'], true);
      expect(analysis.contextFlags?['ambiguous'], false);
      expect(analysis.contextFlags?['figurative_language'], true);
    });

    test('parses anxiety assessment with suggestions', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-id',
        'tone': 'Urgent',
        'analysis_timestamp': 1234567890,
        'anxiety_assessment': {
          'risk_level': 'high',
          'mitigation_suggestions': [
            'Urgent tone detected. Consider asking for a specific timeline.',
            'Take a deep breath before responding.',
          ],
        },
      };

      final analysis = AIAnalysis.fromJson(json);

      expect(analysis.anxietyAssessment?['risk_level'], 'high');
      final suggestions = analysis.anxietyAssessment?['mitigation_suggestions'] as List;
      expect(suggestions.length, 2);
      expect(suggestions[0], contains('Urgent tone'));
    });
  });
}

