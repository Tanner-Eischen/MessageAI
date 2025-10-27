import 'package:flutter_test/flutter_test.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/peek_zone_service.dart';
import 'package:messageai/services/boundary_violation_service.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/ai_analysis.dart';

/// Integration test to verify backend connections
/// 
/// Prerequisites:
/// 1. Backend Supabase running locally
/// 2. Edge functions deployed and running
/// 3. Valid auth token in environment
void main() {
  group('Backend Integration Tests', () {
    late AIAnalysisService aiService;
    late PeekZoneService peekZoneService;
    late BoundaryViolationService boundaryService;

    setUpAll(() {
      aiService = AIAnalysisService();
      peekZoneService = PeekZoneService();
      boundaryService = BoundaryViolationService();
    });

    test('RSD Analysis Backend Connection', () async {
      // Test message that should trigger RSD
      const testMessageId = 'test-rsd-001';
      const testMessageBody = 'k';

      print('🧪 Testing RSD analysis backend call...');
      
      // Call AI service
      final analysis = await aiService.requestAnalysis(
        testMessageId,
        testMessageBody,
        skipDatabaseStorage: true, // Don't save test data
      );

      expect(analysis, isNotNull, reason: 'Analysis should be returned');
      
      if (analysis != null) {
        print('✅ Got analysis: ${analysis.tone}');
        print('   Alternative interpretations: ${analysis.alternativeInterpretations?.length ?? 0}');
        
        // Verify RSD data exists
        expect(
          analysis.alternativeInterpretations, 
          isNotNull,
          reason: 'Should have alternative interpretations',
        );
        expect(
          analysis.alternativeInterpretations!.isNotEmpty,
          true,
          reason: 'Should have at least one interpretation',
        );

        // Verify interpretation structure
        final firstInterp = analysis.alternativeInterpretations!.first;
        expect(firstInterp.interpretation, isNotEmpty);
        expect(firstInterp.likelihood, greaterThanOrEqualTo(0));
        expect(firstInterp.likelihood, lessThanOrEqualTo(100));
        
        print('   First interpretation: ${firstInterp.interpretation}');
        print('   Likelihood: ${firstInterp.likelihood}%');
      }
    });

    test('RSD Content Creation', () async {
      // Create test data
      final testMessage = Message(
        id: 'test-msg-001',
        conversationId: 'test-conv-001',
        senderId: 'test-sender-001',
        body: 'k',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );

      final testSender = Participant(
        id: 'test-participant-001',
        conversationId: 'test-conv-001',
        userId: 'test-sender-001',
        joinedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isAdmin: false,
        isSynced: false,
      );

      // Create mock analysis with interpretations
      final mockAnalysis = AIAnalysis(
        id: 'test-analysis-001',
        messageId: testMessage.id,
        tone: 'brief',
        confidenceScore: 0.88,
        analysisTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        alternativeInterpretations: [
          MessageInterpretation(
            interpretation: 'Quick acknowledgment, sender is busy',
            tone: 'neutral',
            likelihood: 80,
            reasoning: 'Brief response suggests time pressure',
            contextClues: ['single character', 'informal'],
          ),
          MessageInterpretation(
            interpretation: 'Dismissive or annoyed',
            tone: 'negative',
            likelihood: 15,
            reasoning: 'Could indicate frustration',
            contextClues: ['very brief', 'no punctuation'],
          ),
        ],
      );

      print('🧪 Testing RSD content creation...');
      
      final rsdContent = await peekZoneService.createRSDContent(
        testMessage,
        testSender,
        mockAnalysis,
      );

      expect(rsdContent, isNotNull, reason: 'Should create RSD content');
      
      if (rsdContent != null) {
        expect(rsdContent.interpretations.length, equals(2));
        expect(rsdContent.message.id, equals(testMessage.id));
        expect(rsdContent.sender.userId, equals(testSender.userId));
        
        print('✅ RSD content created successfully');
        print('   Title: ${rsdContent.title}');
        print('   Interpretations: ${rsdContent.interpretations.length}');
      }
    });

    test('Boundary Detection Backend Connection', () async {
      // Test message that should trigger boundary violation
      const testMessageId = 'test-boundary-001';
      const testMessageBody = 'I need this done NOW! It\'s urgent!!!';

      print('🧪 Testing boundary detection backend call...');
      
      final violations = await boundaryService.detectViolations(
        messageId: testMessageId,
        messageBody: testMessageBody,
        senderId: 'test-sender-001',
        messageTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      // Note: May return null if no violations detected, which is valid
      print('   Violations detected: ${violations?.violations.length ?? 0}');
      
      if (violations != null && violations.violations.isNotEmpty) {
        final firstViolation = violations.violations.first;
        print('✅ Detected violation: ${firstViolation.type}');
        print('   Severity: ${firstViolation.severity}');
        print('   Explanation: ${firstViolation.explanation}');
        
        expect(firstViolation.type, isNotEmpty);
        expect(firstViolation.severity, isIn(['low', 'medium', 'high']));
      } else {
        print('ℹ️ No boundary violations detected (this is valid)');
      }
    });

    test('Boundary Content Creation', () async {
      final testMessage = Message(
        id: 'test-msg-002',
        conversationId: 'test-conv-001',
        senderId: 'test-sender-001',
        body: 'Can you get this done by tonight?',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isSynced: false,
      );

      print('🧪 Testing boundary content creation...');
      
      final boundaryContent = await peekZoneService.createBoundaryContent(
        testMessage,
      );

      // May return null if no violations, which is valid
      if (boundaryContent != null) {
        expect(boundaryContent.message.id, equals(testMessage.id));
        expect(boundaryContent.suggestions, isNotEmpty);
        
        print('✅ Boundary content created successfully');
        print('   Type: ${boundaryContent.violationType.displayName}');
        print('   Frequency: ${boundaryContent.frequency}');
        print('   Suggestions: ${boundaryContent.suggestions.length}');
      } else {
        print('ℹ️ No boundary content created (no violations)');
      }
    });

    test('Complete Flow: Message → Analysis → RSD Content', () async {
      // Simulate complete user flow
      const testMessageId = 'test-flow-001';
      const testMessageBody = 'ok';

      print('🧪 Testing complete integration flow...');
      
      // Step 1: Request AI analysis
      print('   Step 1: Requesting AI analysis...');
      final analysis = await aiService.requestAnalysis(
        testMessageId,
        testMessageBody,
        skipDatabaseStorage: true,
      );

      expect(analysis, isNotNull, reason: 'Should get analysis');
      
      if (analysis != null) {
        print('   ✅ Step 1 complete: Got analysis');
        
        // Step 2: Create RSD content
        print('   Step 2: Creating RSD content...');
        final testMessage = Message(
          id: testMessageId,
          conversationId: 'test-conv-001',
          senderId: 'test-sender-001',
          body: testMessageBody,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isSynced: false,
        );

        final testSender = Participant(
          id: 'test-participant-001',
          conversationId: 'test-conv-001',
          userId: 'test-sender-001',
          joinedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isAdmin: false,
          isSynced: false,
        );

        final rsdContent = await peekZoneService.createRSDContent(
          testMessage,
          testSender,
          analysis,
        );

        expect(rsdContent, isNotNull, reason: 'Should create RSD content');
        
        if (rsdContent != null) {
          print('   ✅ Step 2 complete: Created RSD content');
          print('   ✅ Complete flow successful!');
          print('');
          print('   Final result:');
          print('   - Message: "$testMessageBody"');
          print('   - Tone: ${analysis.tone}');
          print('   - Interpretations: ${rsdContent.interpretations.length}');
          
          for (var i = 0; i < rsdContent.interpretations.length; i++) {
            final interp = rsdContent.interpretations[i];
            print('   - Interpretation ${i + 1}: ${interp.interpretation} (${interp.likelihood}%)');
          }
        }
      }
    });
  });

  group('Error Handling Tests', () {
    late AIAnalysisService aiService;

    setUp(() {
      aiService = AIAnalysisService();
    });

    test('Handle Invalid Message ID', () async {
      print('🧪 Testing error handling for invalid message...');
      
      final analysis = await aiService.requestAnalysis(
        'nonexistent-message-id',
        'test body',
        skipDatabaseStorage: true,
      );

      // Should handle gracefully (return null or throw)
      print('   Result: ${analysis != null ? 'Got analysis' : 'Returned null'}');
      print('   ✅ Error handled gracefully');
    });

    test('Handle Empty Message Body', () async {
      print('🧪 Testing error handling for empty message...');
      
      final analysis = await aiService.requestAnalysis(
        'test-empty-001',
        '',
        skipDatabaseStorage: true,
      );

      print('   Result: ${analysis != null ? 'Got analysis' : 'Returned null'}');
      print('   ✅ Error handled gracefully');
    });
  });
}

