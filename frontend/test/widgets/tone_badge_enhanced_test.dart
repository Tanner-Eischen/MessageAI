import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('ToneBadge Enhanced Features', () {
    testWidgets('displays all 23 tones with correct emojis', (tester) async {
      final toneEmojiMap = {
        'Friendly': '😊',
        'Professional': '💼',
        'Urgent': '⚠️',
        'Casual': '😎',
        'Formal': '🎩',
        'Concerned': '😟',
        'Excited': '🎉',
        'Neutral': '😐',
        'Apologetic': '🙏',
        'Appreciative': '🙌',
        'Frustrated': '😤',
        'Playful': '😜',
        'Sarcastic': '🙄',
        'Empathetic': '🤗',
        'Inquisitive': '🤔',
        'Assertive': '💪',
        'Tentative': '😬',
        'Defensive': '🛡️',
        'Encouraging': '💚',
        'Disappointed': '😞',
        'Overwhelmed': '😵',
        'Relieved': '😌',
        'Confused': '😕',
      };

      for (final entry in toneEmojiMap.entries) {
        final analysis = AIAnalysis(
          id: 'test',
          messageId: 'msg',
          tone: entry.key,
          analysisTimestamp: 123,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ToneBadge(analysis: analysis),
            ),
          ),
        );

        expect(find.text(entry.value), findsOneWidget, reason: 'Emoji for ${entry.key}');
        expect(find.text(entry.key), findsOneWidget, reason: 'Label for ${entry.key}');
      }
    });

    testWidgets('displays intensity indicator dot', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Friendly',
        intensity: 'high',
        analysisTimestamp: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      // Should have 2 containers: main badge container + intensity dot
      expect(find.byType(Container), findsWidgets);
      
      // Verify the intensity dot exists (6x6 size)
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final hasDot = containers.any((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(hasDot, true, reason: 'Should have intensity dot');
    });

    testWidgets('displays both intensity and urgency dots', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Overwhelmed',
        intensity: 'very_high',
        urgencyLevel: 'High',
        analysisTimestamp: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      // Should have circular indicators for both intensity and urgency
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final circleDots = containers.where((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      }).toList();
      
      expect(circleDots.length, greaterThanOrEqualTo(2), reason: 'Should have both dots');
    });

    testWidgets('does not show intensity dot when intensity is null', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Neutral',
        urgencyLevel: 'High',
        analysisTimestamp: 123,
        // intensity is null
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      // Should only have urgency dot, not intensity
      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      final circleDots = containers.where((container) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      }).toList();
      
      expect(circleDots.length, 1, reason: 'Should only have urgency dot');
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool tapped = false;
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Friendly',
        analysisTimestamp: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(
              analysis: analysis,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ToneBadge));
      expect(tapped, true);
    });

    testWidgets('handles case-insensitive tone matching', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'FRIENDLY', // uppercase
        analysisTimestamp: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      expect(find.text('😊'), findsOneWidget);
    });

    testWidgets('uses default emoji for unknown tone', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'UnknownTone',
        analysisTimestamp: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );

      expect(find.text('💬'), findsOneWidget, reason: 'Default emoji');
    });
  });
}

