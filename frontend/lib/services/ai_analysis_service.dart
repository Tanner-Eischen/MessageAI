import 'dart:async';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/models/ai_analysis.dart';

/// 🔔 Event emitted when analysis starts or completes
class AnalysisEvent {
  final String messageId;
  final bool isStarting;
  
  AnalysisEvent({required this.messageId, required this.isStarting});
  
  @override
  String toString() => '${isStarting ? '▶️ Starting' : '✅ Completed'} analysis for $messageId';
}

/// Simple AI Analysis Service - Supabase only, no local persistence
/// Uses in-memory cache for current session to reduce API calls
class AIAnalysisService {
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  
  final _supabase = SupabaseClientProvider.client;
  
  /// In-memory cache (cleared on app restart)
  final Map<String, AIAnalysis> _sessionCache = {};
  
  /// Pending requests to avoid duplicate API calls
  final Map<String, Future<AIAnalysis?>> _pendingRequests = {};
  
  /// 🔔 NEW: Stream controller for analysis completion events
  final _analysisCompletionController = StreamController<AnalysisEvent>.broadcast();
  
  /// Public stream that notifies when an analysis starts or completes
  /// Emits AnalysisEvent with messageId and whether it's starting or completed
  Stream<AnalysisEvent> get analysisEventStream => _analysisCompletionController.stream;

  AIAnalysisService._internal();
  
  factory AIAnalysisService() {
    return _instance;
  }
  
  void dispose() {
    _analysisCompletionController.close();
  }
  
  /// Request AI analysis for a message
  /// Returns cached result if available, otherwise calls Edge Function
  /// Set [skipDatabaseStorage] to true for auto-analysis (caches locally only, no DB write)
  Future<AIAnalysis?> requestAnalysis(
    String messageId,
    String messageBody, {
    List<String>? conversationContext,
    bool isFromCurrentUser = false,
    int? messageTimestamp,
    bool skipDatabaseStorage = false, // 🆕 ADDED
  }) async {
    // Check session cache first
    if (_sessionCache.containsKey(messageId)) {
      print('📊 Using cached analysis for $messageId');
      final cachedAnalysis = _sessionCache[messageId];
      
      // 🔔 FIX: Emit completion event for cached analyses too!
      // Schedule the event to be emitted after return to avoid race conditions
      Future.microtask(() {
        print('🔔 [SERVICE] Emitting completion event for cached: $messageId');
        _analysisCompletionController.add(AnalysisEvent(messageId: messageId, isStarting: false));
        print('✅ [SERVICE] Event emitted! Stream has ${_analysisCompletionController.stream} listeners');
      });
      
      return cachedAnalysis;
    }
    
    // Check if request is already in progress
    if (_pendingRequests.containsKey(messageId)) {
      print('⏳ Analysis already in progress for $messageId');
      return _pendingRequests[messageId];
    }
    
    // Make new request
    print('🤖 Requesting new analysis for $messageId');
    
    // 🔔 NEW: Emit starting event
    print('🔔 [SERVICE] Emitting starting event for: $messageId');
    _analysisCompletionController.add(AnalysisEvent(messageId: messageId, isStarting: true));
    print('✅ [SERVICE] Starting event emitted!');
    
    final future = _callAnalysisAPI(
      messageId,
      messageBody,
      conversationContext,
      isFromCurrentUser,
      messageTimestamp,
      skipDatabaseStorage, // 🆕 PASS THROUGH
    );
    _pendingRequests[messageId] = future;
    
    try {
      final result = await future;
      if (result != null) {
        _sessionCache[messageId] = result;
        // 🔔 NEW: Emit completion event for listeners
        print('🔔 [SERVICE] Emitting completion event for: $messageId');
        _analysisCompletionController.add(AnalysisEvent(messageId: messageId, isStarting: false));
        print('✅ [SERVICE] Completion event emitted!');
      }
      return result;
    } finally {
      _pendingRequests.remove(messageId);
    }
  }
  
  /// Call the Edge Function to analyze a message
  Future<AIAnalysis?> _callAnalysisAPI(
    String messageId,
    String messageBody,
    List<String>? conversationContext,
    bool isFromCurrentUser,
    int? messageTimestamp,
    bool skipDatabaseStorage, // 🆕 ADDED
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'ai_analyze_tone', // 🔧 FIXED: Added missing function name
        body: {
          'message_id': messageId,
          'message_body': messageBody,
          if (conversationContext != null)
            'conversation_context': conversationContext,
          'isFromCurrentUser': isFromCurrentUser,
          // 🆕 PHASE 1: Include boundary detection for incoming messages
          if (!isFromCurrentUser && messageTimestamp != null)
            'timestamp': DateTime.fromMillisecondsSinceEpoch(messageTimestamp * 1000).toIso8601String(),
          'includeBoundaryAnalysis': !isFromCurrentUser,
          'skipDatabaseStorage': skipDatabaseStorage, // 🆕 NEW FLAG
        },
      );
      
      if (response.status != 200) {
        throw Exception('API returned status ${response.status}');
      }
      
      final data = response.data;
      if (data == null || !data['success']) {
        throw Exception(data?['error'] ?? 'Unknown error');
      }
      
      return AIAnalysis.fromJson(data['analysis']);
    } catch (e) {
      print('❌ Analysis request failed: $e');
      return null;
    }
  }
  
  /// Fetch existing analysis from Supabase
  Future<AIAnalysis?> getAnalysis(String messageId) async {
    // Check cache
    if (_sessionCache.containsKey(messageId)) {
      return _sessionCache[messageId];
    }
    
    try {
      final response = await _supabase.rpc(
        'get_message_ai_analysis',
        params: {'p_message_id': messageId},
      );
      
      if (response == null || (response as List).isEmpty) {
        return null;
      }
      
      final analysis = AIAnalysis.fromJson(response[0]);
      _sessionCache[messageId] = analysis;
      return analysis;
    } catch (e) {
      print('❌ Failed to fetch analysis: $e');
      return null;
    }
  }
  
  /// Fetch all analyses for a conversation
  Future<Map<String, AIAnalysis>> getConversationAnalyses(
    String conversationId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_conversation_ai_analysis',
        params: {'p_conversation_id': conversationId},
      );
      
      if (response == null || (response as List).isEmpty) {
        return {};
      }
      
      final Map<String, AIAnalysis> analyses = {};
      for (final item in response) {
        final analysis = AIAnalysis.fromJson(item);
        analyses[analysis.messageId] = analysis;
        _sessionCache[analysis.messageId] = analysis; // Cache it
      }
      
      return analyses;
    } catch (e) {
      print('❌ Failed to fetch conversation analyses: $e');
      return {};
    }
  }
  
  /// Clear the session cache
  void clearCache() {
    _sessionCache.clear();
    print('🧹 Analysis cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_count': _sessionCache.length,
      'pending_count': _pendingRequests.length,
    };
  }
}
