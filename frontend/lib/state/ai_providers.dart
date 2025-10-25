import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/models/draft_analysis.dart';
import 'package:messageai/models/relationship_profile.dart';
import 'package:messageai/models/follow_up_item.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/draft_analysis_service.dart';
import 'package:messageai/services/message_interpreter_service.dart';
import 'package:messageai/services/response_template_service.dart';
import 'package:messageai/services/message_formatter_service.dart';
import 'package:messageai/services/relationship_service.dart';
import 'package:messageai/services/relationship_summary_service.dart';
import 'package:messageai/services/context_preloader_service.dart';
import 'package:messageai/services/follow_up_service.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/state/providers.dart';

/// Provider for AI Analysis Service singleton
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

/// Provider for Message Interpreter Service (Phase 1: Smart Message Interpreter)
final messageInterpreterServiceProvider = Provider<MessageInterpreterService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MessageInterpreterService(supabase);
});

// =============================================================================
// PHASE 2: Adaptive Response Assistant Providers
// =============================================================================

/// Provider for Response Template Service (Phase 2)
final responseTemplateServiceProvider = Provider<ResponseTemplateService>((ref) {
  final service = ResponseTemplateService();
  // Initialize templates on first access
  service.loadTemplates();
  return service;
});

/// Provider for Message Formatter Service (Phase 2)
final messageFormatterServiceProvider = Provider<MessageFormatterService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MessageFormatterService(supabase);
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

// =============================================================================
// PHASE 3: Smart Inbox with Context Providers
// =============================================================================

/// Provider for Relationship Service (Phase 3)
final relationshipServiceProvider = Provider<RelationshipService>((ref) {
  return RelationshipService();
});

/// Provider for Relationship Summary Service (Phase 3)
final relationshipSummaryServiceProvider = Provider<RelationshipSummaryService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RelationshipSummaryService(supabase);
});

/// Provider for Context Preloader Service (Phase 3)
final contextPreloaderServiceProvider = Provider<ContextPreloaderService>((ref) {
  return ContextPreloaderService();
});

/// Provider to fetch relationship profile for a conversation
final relationshipProfileProvider = FutureProvider.family<RelationshipProfile?, String>(
  (ref, conversationId) async {
    final service = ref.watch(relationshipServiceProvider);
    return await service.getProfile(conversationId);
  },
);

/// Provider to generate/refresh relationship summary
/// This is a manual trigger - call ref.refresh(generateRelationshipSummaryProvider(conversationId))
final generateRelationshipSummaryProvider = FutureProvider.family<RelationshipProfile, String>(
  (ref, conversationId) async {
    final service = ref.watch(relationshipSummaryServiceProvider);
    return await service.generateSummary(conversationId: conversationId);
  },
);

// =============================================================================
// PHASE 4: Smart Follow-up System Providers
// =============================================================================

/// Provider for Follow-Up Service (Phase 4)
final followUpServiceProvider = Provider<FollowUpService>((ref) {
  return FollowUpService();
});

/// Provider to get all pending follow-ups for the user
final pendingFollowUpsProvider = FutureProvider<List<FollowUpItem>>((ref) async {
  final service = ref.watch(followUpServiceProvider);
  return await service.getPendingFollowUps();
});

/// Provider to get follow-ups for a specific conversation
final conversationFollowUpsProvider = FutureProvider.family<List<FollowUpItem>, String>(
  (ref, conversationId) async {
    final service = ref.watch(followUpServiceProvider);
    return await service.getConversationFollowUps(conversationId);
  },
);

/// State notifier for managing follow-up extraction
class FollowUpExtractionNotifier extends StateNotifier<AsyncValue<void>> {
  final FollowUpService _service;

  FollowUpExtractionNotifier(this._service) : super(const AsyncValue.data(null));

  /// Extract follow-ups from a conversation
  Future<void> extractFollowUps(String conversationId, {bool scanAll = false}) async {
    state = const AsyncValue.loading();
    
    try {
      await _service.extractFollowUps(conversationId, scanAll: scanAll);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for follow-up extraction (manual trigger)
final followUpExtractionProvider = StateNotifierProvider<FollowUpExtractionNotifier, AsyncValue<void>>(
  (ref) {
    final service = ref.watch(followUpServiceProvider);
    return FollowUpExtractionNotifier(service);
  },
);
