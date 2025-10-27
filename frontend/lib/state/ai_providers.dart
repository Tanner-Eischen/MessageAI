
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/models/peek_content.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/message_interpreter_service.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/state/providers.dart';

// =============================================================================
// FEATURE #1: Smart Message Interpreter - Core Providers
// =============================================================================

/// Provider for AI Analysis Service singleton
/// Handles in-memory caching and deduplication of analyses
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

/// Provider for Message Interpreter Service
/// Calls ai-interpret-message Edge Function for RSD trigger detection
/// and alternative interpretation generation
final messageInterpreterServiceProvider = Provider<MessageInterpreterService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MessageInterpreterService(supabase);
});

/// StateNotifier to trigger refreshes when new analyses arrive via realtime
class AnalysisRefreshNotifier extends StateNotifier<int> {
  AnalysisRefreshNotifier() : super(0);
  
  void refresh() {
    state++;
  }
}

/// Provider for refresh state (auto-triggers on realtime updates)
final analysisRefreshProvider = StateNotifierProvider<AnalysisRefreshNotifier, int>((ref) {
  final notifier = AnalysisRefreshNotifier();
  
  // Listen to realtime updates on ai_analysis table
  final supabase = SupabaseClientProvider.client;
  final channel = supabase.realtime.channel('ai_analysis_updates');
  
  channel.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'ai_analysis',
    ),
    (payload, [ref]) {
      print('🔄 AI analysis updated, refreshing providers...');
      notifier.refresh();
    },
  );
  
  channel.subscribe(
    (status, [error]) {
      if (status == 'SUBSCRIBED') {
        print('✅ Feature #1 analysis realtime listener subscribed');
      } else if (error != null) {
        print('❌ Feature #1 analysis realtime error: $error');
      }
    },
  );
  
  ref.onDispose(() {
    channel.unsubscribe();
  });
  
  return notifier;
});

/// Fetch analysis for a single message (auto-refreshes on realtime updates)
final messageAnalysisProvider = FutureProvider.family<AIAnalysis?, String>(
  (ref, messageId) async {
    // Watch the refresh notifier to trigger rebuilds when new analyses arrive
    ref.watch(analysisRefreshProvider);
    
    final service = ref.watch(aiAnalysisServiceProvider);
    return await service.getAnalysis(messageId);
  },
);

/// Fetch all analyses for a conversation (auto-refreshes on realtime updates)
final conversationAnalysisProvider = FutureProvider.family<Map<String, AIAnalysis>, String>(
  (ref, conversationId) async {
    // Watch the refresh notifier to trigger rebuilds
    ref.watch(analysisRefreshProvider);
    
    final service = ref.watch(aiAnalysisServiceProvider);
    return await service.getConversationAnalyses(conversationId);
  },
);

/// Provider for triggering analysis requests
/// Used when user long-presses a message to analyze it
final requestAnalysisProvider = Provider((ref) {
  final service = ref.watch(aiAnalysisServiceProvider);
  return (String messageId, String messageBody) => 
      service.requestAnalysis(messageId, messageBody);
});

/// Stream of analysis events (when analyses start/complete)
final analysisEventStreamProvider = StreamProvider<dynamic>((ref) {
  final aiService = ref.watch(aiAnalysisServiceProvider);
  return aiService.analysisEventStream;
});

// =============================================================================
// PLACEHOLDER: Phase 2-5 Providers
// These will be added when implementing Features 2-5
// =============================================================================

// TODO: Feature #2 - Boundary Detection Providers
// TODO: Feature #3 - Evidence-Based Analysis Providers  
// TODO: Feature #4 - Action Item Tracking Providers
// TODO: Feature #5 - Catch Me Up Summaries Providers

// ============================================================================
// PEEK ZONE CONTENT PROVIDERS
// ============================================================================
/// Providers for managing content displayed in the peek zone across all 4 view modes
/// These are template providers - integrate with your backend services

/// Generate RSD analysis content for a specific message
/// Used to populate the peek zone when an RSD-triggering message is detected
/// 
/// TODO: Implement by fetching message + AI analysis from backend
/// Should return RSDAnalysis with message, sender, and interpretations
final rsdAnalysisForMessageProvider = FutureProvider.family<RSDAnalysis?, String>((ref, messageId) async {
  // Placeholder - integrate with your message/analysis data sources
  // Example implementation:
  /*
  final messageAsync = ref.watch(messageProvider(messageId));
  final analysisAsync = ref.watch(messageAnalysisProvider(messageId));
  
  return messageAsync.when(
    data: (message) => analysisAsync.when(
      data: (analysis) {
        if (message == null || analysis == null || analysis.alternativeInterpretations == null) {
          return null;
        }
        
        return RSDAnalysis(
          message: message,
          sender: message.sender,
          interpretations: analysis.alternativeInterpretations!,
        );
      },
      loading: () => null,
      error: (_, __) => null,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
  */
  return null;
});

/// Generate boundary violation analysis for a message
/// Used when boundary patterns are detected in incoming messages
/// 
/// TODO: Integrate with backend boundary detection service
final boundaryAnalysisForMessageProvider = FutureProvider.family<BoundaryAnalysis?, String>((ref, messageId) async {
  // Placeholder - integrate with boundary detection from backend
  return null;
});

/// Generate action item details for a specific action
/// Used to populate the peek zone with action tracking information
/// 
/// TODO: Integrate with backend action item service
final actionItemDetailsProvider = FutureProvider.family<ActionItemDetails?, String>((ref, actionId) async {
  // Placeholder - integrate with action items from backend
  return null;
});

/// Get relationship context for a specific participant
/// Default content shown when no interventions are active (80% PEEK mode)
/// 
/// TODO: Implement by fetching participant patterns and reliability data
final relationshipContextForParticipantProvider = FutureProvider.family<RelationshipContextPeek?, String>(
  (ref, participantId) async {
    // Placeholder - integrate with participant communication patterns
    // This should fetch:
    // - Tone analysis over recent messages
    // - Response time statistics
    // - Reliability/follow-through score
    // - Boundary violation history
    
    return null;
  },
);