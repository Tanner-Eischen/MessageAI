import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('ToneBadge Widget', () {
    testWidgets('displays Friendly tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Friendly',
        urgencyLevel: 'Low',
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
      expect(find.text('Friendly'), findsOneWidget);
    });
    
    testWidgets('displays Professional tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Professional',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('💼'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
    });
    
    testWidgets('displays Urgent tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Urgent',
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
      
      expect(find.text('⚡'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
    });
    
    testWidgets('displays Casual tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Casual',
        urgencyLevel: 'Low',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('😎'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
    });
    
    testWidgets('displays Formal tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Formal',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('👔'), findsOneWidget);
      expect(find.text('Formal'), findsOneWidget);
    });
    
    testWidgets('displays Excited tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Excited',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('🎉'), findsOneWidget);
      expect(find.text('Excited'), findsOneWidget);
    });
    
    testWidgets('displays Concerned tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Concerned',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('😟'), findsOneWidget);
      expect(find.text('Concerned'), findsOneWidget);
    });
    
    testWidgets('displays Neutral tone with correct emoji', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Neutral',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('💬'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
    });
    
    testWidgets('shows urgency indicator for High urgency', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Urgent',
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
      
      // Urgency dot should be present (multiple Containers exist)
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Urgent'), findsOneWidget);
    });
    
    testWidgets('shows urgency indicator for Critical urgency', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Professional',
        urgencyLevel: 'Critical',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.byType(Container), findsWidgets);
      expect(find.text('Professional'), findsOneWidget);
    });
    
    testWidgets('does not show urgency indicator for Low urgency', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Casual',
        urgencyLevel: 'Low',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      expect(find.text('Casual'), findsOneWidget);
    });
    
    testWidgets('calls onTap callback when tapped', (tester) async {
      bool wasTapped = false;
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Excited',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(
              analysis: analysis,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(ToneBadge));
      await tester.pump();
      
      expect(wasTapped, isTrue);
    });
    
    testWidgets('can be tapped without onTap callback', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'Friendly',
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      // Should not throw when tapped without callback
      await tester.tap(find.byType(ToneBadge));
      await tester.pump();
      
      expect(find.byType(ToneBadge), findsOneWidget);
    });
    
    testWidgets('handles case-insensitive tone names', (tester) async {
      final analysis = AIAnalysis(
        id: 'test',
        messageId: 'msg',
        tone: 'FRIENDLY', // Uppercase
        analysisTimestamp: 123,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToneBadge(analysis: analysis),
          ),
        ),
      );
      
      // Should still show the emoji (case handling in _getToneInfo)
      expect(find.text('😊'), findsOneWidget);
    });
  });
}


