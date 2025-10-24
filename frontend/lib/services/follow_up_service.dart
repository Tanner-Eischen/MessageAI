// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/models/follow_up_item.dart';

/// Service for managing follow-up items
class FollowUpService {
  static final FollowUpService _instance = FollowUpService._internal();
  factory FollowUpService() => _instance;
  FollowUpService._internal();

  final _supabase = SupabaseClientProvider.client;

  String get _baseUrl {
    final supabaseUrl = _supabase.supabaseUrl;
    return '$supabaseUrl/functions/v1';
  }

  /// Extract follow-ups from conversation
  Future<void> extractFollowUps(String conversationId, {bool scanAll = false}) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      await http.post(
        Uri.parse('$_baseUrl/ai-extract-followups'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'scan_recent_messages': scanAll,
        }),
      );
    } catch (e) {
      print('Error extracting follow-ups: $e');
      rethrow;
    }
  }

  /// Get all pending follow-ups for user
  Future<List<FollowUpItem>> getPendingFollowUps() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_pending_followups', params: {
        'p_user_id': userId,
        'p_limit': 50,
      });

      if (response == null) return [];

      return (response as List)
          .map((data) => FollowUpItem.fromJson({
                'user_id': userId,
                ...data as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error getting pending follow-ups: $e');
      return [];
    }
  }

  /// Get follow-ups for specific conversation
  Future<List<FollowUpItem>> getConversationFollowUps(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase.rpc('get_conversation_followups', params: {
        'p_user_id': userId,
        'p_conversation_id': conversationId,
      });

      if (response == null) return [];

      return (response as List)
          .map((data) => FollowUpItem.fromJson({
                'user_id': userId,
                'conversation_id': conversationId,
                ...data as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      print('Error getting conversation follow-ups: $e');
      return [];
    }
  }

  /// Mark follow-up as completed
  Future<void> completeFollowUp(String itemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('complete_followup', params: {
        'p_user_id': userId,
        'p_item_id': itemId,
      });
    } catch (e) {
      print('Error completing follow-up: $e');
      rethrow;
    }
  }

  /// Snooze follow-up
  Future<void> snoozeFollowUp(String itemId, Duration duration) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.rpc('snooze_followup', params: {
        'p_user_id': userId,
        'p_item_id': itemId,
        'p_snooze_duration': duration.inSeconds,
      });
    } catch (e) {
      print('Error snoozing follow-up: $e');
      rethrow;
    }
  }

  /// Dismiss follow-up
  Future<void> dismissFollowUp(String itemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _supabase.from('follow_up_items').update({
        'status': 'dismissed',
        'updated_at': now,
      }).eq('id', itemId).eq('user_id', userId);
    } catch (e) {
      print('Error dismissing follow-up: $e');
      rethrow;
    }
  }
}

