import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/models/conversation_context.dart';

/// Service for loading conversation context
class ContextPreloaderService {
  static final ContextPreloaderService _instance =
      ContextPreloaderService._internal();
  factory ContextPreloaderService() => _instance;
  ContextPreloaderService._internal();

  static String get baseUrl {
    final supabaseUrl = SupabaseClientProvider.client.supabaseUrl;
    return '$supabaseUrl/functions/v1';
  }

  // In-memory cache
  final Map<String, ConversationContext> _cache = {};

  /// Load context for a conversation
  Future<ConversationContext> loadContext(String conversationId) async {
    // Check in-memory cache first
    if (_cache.containsKey(conversationId)) {
      final cached = _cache[conversationId]!;
      // Return if less than 5 minutes old
      if (cached.cacheAge != null && cached.cacheAge! < 300) {
        return cached;
      }
    }

    try {
      final token =
          SupabaseClientProvider.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ai-context-preloader'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final context = ConversationContext.fromJson({
            'conversation_id': conversationId,
            ...data['context'],
            'from_cache': data['from_cache'],
          });

          // Update in-memory cache
          _cache[conversationId] = context;

          return context;
        } else {
          throw Exception(data['error'] ?? 'Failed to load context');
        }
      } else {
        // Log more details for 400+ errors
        print('❌ Context preloader error: HTTP ${response.statusCode}');
        print('   Response body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading context: $e');
      rethrow;
    }
  }

  /// Preload context for multiple conversations
  Future<void> preloadContexts(List<String> conversationIds) async {
    // Load in parallel with rate limiting
    final futures = conversationIds.take(5).map((id) => loadContext(id));
    await Future.wait(futures, eagerError: false);
  }

  /// Preload context for a conversation (alias for loadContext)
  Future<ConversationContext> preloadContext(String conversationId) async {
    return loadContext(conversationId);
  }

  /// Search for similar messages using semantic search
  Future<List<Map<String, dynamic>>> searchSimilarMessages({
    required String query,
    String? conversationId,
    int limit = 5,
  }) async {
    try {
      final token =
          SupabaseClientProvider.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ai-generate-embeddings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'conversation_id': conversationId,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['results'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'Search failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error searching similar messages: $e');
      return [];
    }
  }

  /// Generate embedding for text
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final token =
          SupabaseClientProvider.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ai-generate-embeddings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['embedding'] != null) {
          return List<double>.from(data['embedding']);
        } else {
          throw Exception(data['error'] ?? 'Embedding generation failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error generating embedding: $e');
      return [];
    }
  }

  /// Invalidate cache for a conversation
  void invalidateCache([String? conversationId]) {
    if (conversationId != null) {
      _cache.remove(conversationId);
    } else {
      _cache.clear();
    }
  }

  /// Clear cache (alias for backwards compatibility)
  void clearCache() {
    _cache.clear();
  }
}

