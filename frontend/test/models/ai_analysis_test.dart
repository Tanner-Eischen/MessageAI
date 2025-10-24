import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/models/ai_analysis.dart';

void main() {
  group('AIAnalysis Model', () {
    test('fromJson creates valid object with all fields', () {
      final json = {
        'id': 'test-id-123',
        'message_id': 'msg-456',
        'tone': 'Professional',
        'urgency_level': 'Medium',
        'intent': 'requesting information',
        'confidence_score': 0.85,
        'analysis_timestamp': 1234567890,
      };
      
      final analysis = AIAnalysis.fromJson(json);
      
      expect(analysis.id, equals('test-id-123'));
      expect(analysis.messageId, equals('msg-456'));
      expect(analysis.tone, equals('Professional'));
      expect(analysis.urgencyLevel, equals('Medium'));
      expect(analysis.intent, equals('requesting information'));
      expect(analysis.confidenceScore, equals(0.85));
      expect(analysis.analysisTimestamp, equals(1234567890));
    });
    
    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'test-id',
        'message_id': 'msg-id',
        'tone': 'Neutral',
        'analysis_timestamp': 1234567890,
      };
      
      final analysis = AIAnalysis.fromJson(json);
      
      expect(analysis.tone, equals('Neutral'));
      expect(analysis.urgencyLevel, isNull);
      expect(analysis.intent, isNull);
      expect(analysis.confidenceScore, isNull);
    });
    
    test('toJson creates correct map', () {
      final analysis = AIAnalysis(
        id: 'id-1',
        messageId: 'msg-1',
        tone: 'Friendly',
        urgencyLevel: 'Low',
        intent: 'greeting',
        confidenceScore: 0.9,
        analysisTimestamp: 9876543210,
      );
      
      final json = analysis.toJson();
      
      expect(json['id'], equals('id-1'));
      expect(json['message_id'], equals('msg-1'));
      expect(json['tone'], equals('Friendly'));
      expect(json['urgency_level'], equals('Low'));
      expect(json['intent'], equals('greeting'));
      expect(json['confidence_score'], equals(0.9));
      expect(json['analysis_timestamp'], equals(9876543210));
    });
    
    test('equality works correctly', () {
      final a1 = AIAnalysis(
        id: 'same-id',
        messageId: 'same-msg',
        tone: 'Friendly',
        analysisTimestamp: 123,
      );
      
      final a2 = AIAnalysis(
        id: 'same-id',
        messageId: 'same-msg',
        tone: 'Professional', // Different tone
        analysisTimestamp: 456, // Different timestamp
      );
      
      final a3 = AIAnalysis(
        id: 'different-id',
        messageId: 'same-msg',
        tone: 'Friendly',
        analysisTimestamp: 123,
      );
      
      expect(a1, equals(a2)); // Same ID and message ID
      expect(a1, isNot(equals(a3))); // Different ID
    });
    
    test('hashCode is consistent', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-id',
        tone: 'Casual',
        analysisTimestamp: 123,
      );
      
      final hash1 = analysis.hashCode;
      final hash2 = analysis.hashCode;
      
      expect(hash1, equals(hash2));
    });
    
    test('toString includes key information', () {
      final analysis = AIAnalysis(
        id: 'test-id',
        messageId: 'msg-id',
        tone: 'Urgent',
        urgencyLevel: 'High',
        intent: 'needs response',
        confidenceScore: 0.95,
        analysisTimestamp: 123456,
      );
      
      final str = analysis.toString();
      
      expect(str, contains('test-id'));
      expect(str, contains('msg-id'));
      expect(str, contains('Urgent'));
      expect(str, contains('High'));
    });
    
    test('handles double and int confidence scores', () {
      // Test with integer
      final json1 = {
        'id': 'id-1',
        'message_id': 'msg-1',
        'tone': 'Neutral',
        'confidence_score': 1,
        'analysis_timestamp': 123,
      };
      
      final analysis1 = AIAnalysis.fromJson(json1);
      expect(analysis1.confidenceScore, equals(1.0));
      
      // Test with double
      final json2 = {
        'id': 'id-2',
        'message_id': 'msg-2',
        'tone': 'Neutral',
        'confidence_score': 0.75,
        'analysis_timestamp': 123,
      };
      
      final analysis2 = AIAnalysis.fromJson(json2);
      expect(analysis2.confidenceScore, equals(0.75));
    });
    
    test('round-trip JSON serialization preserves data', () {
      final original = AIAnalysis(
        id: 'round-trip-id',
        messageId: 'round-trip-msg',
        tone: 'Excited',
        urgencyLevel: 'Medium',
        intent: 'celebration',
        confidenceScore: 0.88,
        analysisTimestamp: 1111111111,
      );
      
      final json = original.toJson();
      final reconstructed = AIAnalysis.fromJson(json);
      
      expect(reconstructed, equals(original));
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.messageId, equals(original.messageId));
      expect(reconstructed.tone, equals(original.tone));
      expect(reconstructed.urgencyLevel, equals(original.urgencyLevel));
      expect(reconstructed.intent, equals(original.intent));
      expect(reconstructed.confidenceScore, equals(original.confidenceScore));
      expect(reconstructed.analysisTimestamp, equals(original.analysisTimestamp));
    });
  });
}


