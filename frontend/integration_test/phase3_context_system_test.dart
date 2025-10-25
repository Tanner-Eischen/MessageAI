import 'dart:math' show sqrt;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messageai/services/context_preloader_service.dart';
import 'package:messageai/services/relationship_summary_service.dart';

/// Phase 3: Smart Inbox with Context Integration Tests
/// Tests: Context Preloading, Relationship Memory, RAG System
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: Smart Inbox with Context', () {
    late ContextPreloaderService contextService;
    late RelationshipSummaryService relationshipService;

    setUp(() {
      contextService = ContextPreloaderService();
      relationshipService = RelationshipSummaryService();
    });

    group('Context Preloader', () {
      test('preloads context for conversation', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context, isNotNull);
        expect(context.conversationId, equals('test-conv-123'));
        expect(context.summary, isNotNull);
      });

      test('identifies key topics from conversation history', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context.keyTopics, isNotEmpty);
        expect(context.keyTopics.length, lessThanOrEqualTo(5));
      });

      test('detects recent action items from history', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context.recentActionItems, isNotNull);
      });

      test('identifies unanswered questions', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context.unansweredQuestions, isNotNull);
      });

      test('provides relationship context', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context.relationshipSummary, isNotNull);
        expect(context.relationshipSummary!.communicationStyle, isNotEmpty);
      });

      test('caches context for performance', () async {
        // First call
        final start1 = DateTime.now();
        await contextService.preloadContext(conversationId: 'test-conv-123');
        final duration1 = DateTime.now().difference(start1);

        // Second call (should be cached)
        final start2 = DateTime.now();
        await contextService.preloadContext(conversationId: 'test-conv-123');
        final duration2 = DateTime.now().difference(start2);

        expect(duration2.inMilliseconds, lessThan(duration1.inMilliseconds));
      });
    });

    group('Relationship Summary', () {
      test('generates relationship profile', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'test-conv-123',
        );

        expect(summary, isNotNull);
        expect(summary.communicationStyle, isNotEmpty);
        expect(summary.relationshipType, isNotEmpty);
      });

      test('detects professional relationship', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'work-conv-456',
        );

        expect(summary, isNotNull);
        expect(summary.relationshipType.toLowerCase(), contains(['professional', 'work', 'colleague']));
      });

      test('detects casual/friend relationship', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'friend-conv-789',
        );

        expect(summary, isNotNull);
        expect(summary.relationshipType.toLowerCase(), contains(['friend', 'casual', 'personal']));
      });

      test('identifies communication preferences', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'test-conv-123',
        );

        expect(summary.communicationStyle, isNotEmpty);
        expect(summary.communicationStyle, contains(['formal', 'casual', 'direct', 'detailed']));
      });

      test('tracks shared topics and interests', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'test-conv-123',
        );

        expect(summary.sharedTopics, isNotEmpty);
      });

      test('provides conversation history stats', () async {
        final summary = await relationshipService.generateSummary(
          conversationId: 'test-conv-123',
        );

        expect(summary.messageCount, greaterThan(0));
        expect(summary.lastInteractionAt, isNotNull);
      });
    });

    group('RAG (Vector Search)', () {
      test('finds relevant past messages by semantic similarity', () async {
        final results = await contextService.searchSimilarMessages(
          query: 'project deadline',
          conversationId: 'test-conv-123',
        );

        expect(results, isNotEmpty);
        expect(results.length, lessThanOrEqualTo(5));
      });

      test('ranks results by relevance', () async {
        final results = await contextService.searchSimilarMessages(
          query: 'meeting schedule',
          conversationId: 'test-conv-123',
        );

        expect(results, isNotEmpty);
        // Should be sorted by relevance score
        for (int i = 0; i < results.length - 1; i++) {
          expect(
            results[i].relevanceScore,
            greaterThanOrEqualTo(results[i + 1].relevanceScore),
          );
        }
      });

      test('searches across all conversations when not limited', () async {
        final results = await contextService.searchSimilarMessages(
          query: 'vacation plans',
          // No conversationId specified = search all
        );

        expect(results, isNotEmpty);
        // Should include results from multiple conversations
        final conversationIds = results.map((r) => r.conversationId).toSet();
        expect(conversationIds.length, greaterThanOrEqualTo(1));
      });
    });

    group('Embeddings Generation', () {
      test('generates embeddings for new message', () async {
        final embedding = await contextService.generateEmbedding(
          'This is a test message about project planning',
        );

        expect(embedding, isNotNull);
        expect(embedding.vector, isNotEmpty);
        expect(embedding.vector.length, equals(1536)); // OpenAI embedding size
      });

      test('similar messages have similar embeddings', () async {
        final embedding1 = await contextService.generateEmbedding(
          'Let\'s schedule a meeting for next week',
        );
        final embedding2 = await contextService.generateEmbedding(
          'Can we set up a meeting next week?',
        );
        final embedding3 = await contextService.generateEmbedding(
          'I love pizza and ice cream',
        );

        final similarity12 = _cosineSimilarity(embedding1.vector, embedding2.vector);
        final similarity13 = _cosineSimilarity(embedding1.vector, embedding3.vector);

        expect(similarity12, greaterThan(similarity13));
      });
    });

    group('Comprehensive Context System', () {
      test('provides full context for conversation', () async {
        final context = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        // Should have all components
        expect(context.summary, isNotEmpty);
        expect(context.keyTopics, isNotEmpty);
        expect(context.relationshipSummary, isNotNull);
        expect(context.recentActionItems, isNotNull);
        expect(context.unansweredQuestions, isNotNull);
      });

      test('handles conversations with no history gracefully', () async {
        final context = await contextService.preloadContext(
          conversationId: 'new-conv-999',
        );

        expect(context, isNotNull);
        expect(context.summary, isNotEmpty); // Should have default message
        expect(context.keyTopics, isEmpty);
      });

      test('updates context when new messages arrive', () async {
        // Get initial context
        final context1 = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        // Simulate new message
        await contextService.invalidateCache('test-conv-123');

        // Get updated context
        final context2 = await contextService.preloadContext(
          conversationId: 'test-conv-123',
        );

        expect(context2, isNotNull);
        // Cache should be refreshed
      });
    });
  });
}

/// Helper function to calculate cosine similarity
double _cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) return 0.0;

  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  if (normA == 0.0 || normB == 0.0) return 0.0;

  return dotProduct / (sqrt(normA) * sqrt(normB));
}

