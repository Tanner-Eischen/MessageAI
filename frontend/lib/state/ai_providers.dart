import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/models/draft_analysis.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/draft_analysis_service.dart';
import 'package:messageai/data/remote/supabase_client.dart';

/// Provider for AI Analysis Service singleton
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

/// StateNotifier to track when to refresh analysis
class AnalysisRefreshNotifier extends StateNotifier<int> {
  AnalysisRefreshNotifier() : super(0);
  
  void refresh() {
    state++;
  }
}

final analysisRefreshProvider = StateNotifierProvider<AnalysisRefreshNotifier, int>((ref) {
  final notifier = AnalysisRefreshNotifier();
  
  // Listen to realtime updates on message_ai_analysis table
  final supabase = SupabaseClientProvider.client;
  final channel = supabase.realtime.channel('ai_analysis_updates');
  
  channel.on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(
      event: 'INSERT',
      schema: 'public',
      table: 'message_ai_analysis',
    ),
    (payload, [ref]) {
      print('🔄 AI analysis updated, refreshing providers...');
      notifier.refresh();
    },
  );
  
  channel.subscribe(
    (status, [error]) {
      if (status == 'SUBSCRIBED') {
        print('✅ AI analysis realtime listener subscribed');
      } else if (error != null) {
        print('❌ AI analysis realtime error: $error');
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
    // Watch the refresh notifier to trigger rebuilds
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
final requestAnalysisProvider = Provider((ref) {
  final service = ref.watch(aiAnalysisServiceProvider);
  return (String messageId, String messageBody) => 
      service.requestAnalysis(messageId, messageBody);
});

// =============================================================================
// DRAFT ANALYSIS PROVIDERS (for outgoing messages)
// =============================================================================

/// Provider for Draft Analysis Service
final draftAnalysisServiceProvider = Provider<DraftAnalysisService>((ref) {
  final supabase = SupabaseClientProvider.client;
  return DraftAnalysisService(supabase);
});

/// State notifier for managing draft analysis state (manual trigger)
class DraftAnalysisNotifier extends StateNotifier<AsyncValue<DraftAnalysis?>> {
  final DraftAnalysisService _service;

  DraftAnalysisNotifier(this._service) : super(const AsyncValue.data(null));

  /// Analyze a draft (called when user clicks "Check Message" button)
  Future<void> analyzeDraft({
    required String draftMessage,
    String? conversationId,
    RelationshipType? relationshipType,
    List<String>? conversationHistory,
  }) async {
    // Clear if draft is empty
    if (draftMessage.trim().isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }

    // Set loading state
    state = const AsyncValue.loading();

    try {
      final analysis = await _service.analyzeDraft(
        draftMessage: draftMessage,
        conversationId: conversationId,
        relationshipType: relationshipType,
        conversationHistory: conversationHistory,
      );
      state = AsyncValue.data(analysis);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear current analysis
  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for draft analysis state (manual trigger)
final draftAnalysisProvider =
    StateNotifierProvider<DraftAnalysisNotifier, AsyncValue<DraftAnalysis?>>(
  (ref) {
    final service = ref.watch(draftAnalysisServiceProvider);
    return DraftAnalysisNotifier(service);
  },
);
