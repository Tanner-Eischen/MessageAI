import 'dart:async';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/models/ai_analysis.dart';

/// Simple AI Analysis Service - Supabase only, no local persistence
/// Uses in-memory cache for current session to reduce API calls
class AIAnalysisService {
  final _supabase = SupabaseClientProvider.client;
  
  /// In-memory cache (cleared on app restart)
  final Map<String, AIAnalysis> _sessionCache = {};
  
  /// Pending requests to avoid duplicate API calls
  final Map<String, Future<AIAnalysis?>> _pendingRequests = {};
  
  /// Request AI analysis for a message
  /// Returns cached result if available, otherwise calls Edge Function
  Future<AIAnalysis?> requestAnalysis(
    String messageId,
    String messageBody, {
    List<String>? conversationContext,
  }) async {
    // Check session cache first
    if (_sessionCache.containsKey(messageId)) {
      print('📊 Using cached analysis for $messageId');
      return _sessionCache[messageId];
    }
    
    // Check if request is already in progress
    if (_pendingRequests.containsKey(messageId)) {
      print('⏳ Analysis already in progress for $messageId');
      return _pendingRequests[messageId];
    }
    
    // Make new request
    print('🤖 Requesting new analysis for $messageId');
    final future = _callAnalysisAPI(messageId, messageBody, conversationContext);
    _pendingRequests[messageId] = future;
    
    try {
      final result = await future;
      if (result != null) {
        _sessionCache[messageId] = result;
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
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'ai_analyze_tone',
        body: {
          'message_id': messageId,
          'message_body': messageBody,
          if (conversationContext != null)
            'conversation_context': conversationContext,
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
