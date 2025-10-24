import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Enhanced Tone Analysis Integration Tests', () {
    testWidgets('Full flow: Parse analysis -> Display badge -> Show detail sheet',
        (tester) async {
      // Simulate API response with enhanced fields
      final apiResponse = {
        'id': 'analysis-123',
        'message_id': 'msg-456',
        'tone': 'Overwhelmed',
        'urgency_level': 'High',
        'intent': 'expressing severe stress about deadline',
        'confidence_score': 0.95,
        'analysis_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
            'Urgent tone detected. Consider asking for a specific timeline.',
            'Take a moment before responding to reduce pressure.',
          ],
        },
      };

      // 1. Parse the analysis
      final analysis = AIAnalysis.fromJson(apiResponse);
      expect(analysis.tone, 'Overwhelmed');
      expect(analysis.intensity, 'very_high');
      expect(analysis.contextFlags?['tone_indicator_present'], true);
      expect(analysis.anxietyAssessment?['risk_level'], 'high');

      // 2. Display in ToneBadge
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(
              analysis: analysis,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('😵'), findsOneWidget, reason: 'Overwhelmed emoji');
      expect(find.text('Overwhelmed'), findsOneWidget);
      
      // Should have intensity and urgency dots
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final circleDots = containers.where((c) {
        final d = c.decoration;
        return d is BoxDecoration && d.shape == BoxShape.circle;
      }).length;
      expect(circleDots, greaterThanOrEqualTo(2));

      // 3. Show detail sheet
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ToneDetailSheet.show(
                    context,
                    analysis,
                    "I'm SO stressed about this deadline /srs",
                  );
                },
                child: const Text('Show Details'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Details'));
      await tester.pumpAndSettle();

      // Verify detail sheet content
      expect(find.text('AI Analysis'), findsOneWidget);
      expect(find.text('Overwhelmed'), findsOneWidget);
      expect(find.text('High'), findsOneWidget, reason: 'Urgency level');
      expect(find.text('Very High'), findsOneWidget, reason: 'Intensity formatted');
      
      // Check for anxiety assessment
      expect(find.textContaining('Response Anxiety'), findsOneWidget);
      expect(find.textContaining('HIGH'), findsOneWidget);
    });

    testWidgets('Playful tone with tone indicator /j', (tester) async {
      final apiResponse = {
        'id': 'analysis-789',
        'message_id': 'msg-012',
        'tone': 'Playful',
        'urgency_level': 'Low',
        'intent': 'joking about suggestion',
        'confidence_score': 0.92,
        'analysis_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'intensity': 'medium',
        'context_flags': {
          'tone_indicator_present': true,
          'sarcasm_detected': false,
        },
        'anxiety_assessment': {
          'risk_level': 'low',
          'mitigation_suggestions': [],
        },
      };

      final analysis = AIAnalysis.fromJson(apiResponse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      expect(find.text('😜'), findsOneWidget, reason: 'Playful emoji');
      expect(find.text('Playful'), findsOneWidget);
    });

    testWidgets('Sarcastic tone detection', (tester) async {
      final apiResponse = {
        'id': 'analysis-sarcasm',
        'message_id': 'msg-sarcasm',
        'tone': 'Sarcastic',
        'urgency_level': 'Low',
        'intent': 'expressing frustration sarcastically',
        'confidence_score': 0.88,
        'analysis_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'intensity': 'high',
        'context_flags': {
          'sarcasm_detected': true,
          'tone_indicator_present': true,
        },
        'anxiety_assessment': {
          'risk_level': 'medium',
          'mitigation_suggestions': [
            'Sarcasm detected. Literal meaning may differ.',
          ],
        },
      };

      final analysis = AIAnalysis.fromJson(apiResponse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      expect(find.text('🙄'), findsOneWidget, reason: 'Sarcastic emoji');
      expect(analysis.contextFlags?['sarcasm_detected'], true);
      expect(analysis.anxietyAssessment?['risk_level'], 'medium');
    });

    testWidgets('All 5 intensity levels display correctly', (tester) async {
      final intensities = ['very_low', 'low', 'medium', 'high', 'very_high'];

      for (final intensity in intensities) {
        final analysis = AIAnalysis(
          id: 'test-$intensity',
          messageId: 'msg-$intensity',
          tone: 'Friendly',
          intensity: intensity,
          analysisTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ToneBadge(analysis: analysis),
            ),
          ),
        );

        // Should display intensity dot
        final containers = tester.widgetList<Container>(find.byType(Container));
        final hasIntensityDot = containers.any((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.shape == BoxShape.circle;
        });
        
        expect(hasIntensityDot, true, reason: 'Intensity dot for $intensity');
      }
    });

    testWidgets('Backward compatibility: Analysis without enhanced fields', (tester) async {
      // Old API response without enhanced fields
      final oldApiResponse = {
        'id': 'old-analysis',
        'message_id': 'old-msg',
        'tone': 'Friendly',
        'urgency_level': 'Low',
        'intent': 'greeting',
        'confidence_score': 0.85,
        'analysis_timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };

      final analysis = AIAnalysis.fromJson(oldApiResponse);
      expect(analysis.intensity, null);
      expect(analysis.contextFlags, null);

      // Should still display correctly
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
      expect(find.text('Friendly'), findsOneWidget);
    });
  });
}

