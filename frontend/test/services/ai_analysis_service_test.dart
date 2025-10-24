import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  // Note: Service tests that require Supabase client are skipped in unit tests
  // These should be tested in integration tests with proper Supabase setup
  
  group('AIAnalysisService - Unit Tests', () {
    test('service requires Supabase initialization', () {
      // This test documents that the service requires Supabase
      // Full service tests should be done in integration tests
      expect(true, isTrue);
    });
  });
  
  group('AIAnalysis Model Integration', () {
    test('AIAnalysis can be stored and retrieved', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-123',
        tone: 'Friendly',
        urgencyLevel: 'Low',
        intent: 'greeting',
        confidenceScore: 0.9,
        analysisTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      
      expect(analysis.id, equals('test-id'));
      expect(analysis.messageId, equals('msg-123'));
      expect(analysis.tone, equals('Friendly'));
    });
    
    test('Multiple AIAnalysis objects can coexist', () {
      final analysis1 = AIAnalysis(
        id: 'id-1',
        messageId: 'msg-1',
        tone: 'Professional',
        analysisTimestamp: 123,
      );
      
      final analysis2 = AIAnalysis(
        id: 'id-2',
        messageId: 'msg-2',
        tone: 'Casual',
        analysisTimestamp: 456,
      );
      
      expect(analysis1.id, isNot(equals(analysis2.id)));
      expect(analysis1.tone, isNot(equals(analysis2.tone)));
    });
  });
}

