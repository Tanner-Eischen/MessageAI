import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';

/// Service for tracking user presence and online status
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();

  factory PresenceService() {
    return _instance;
  }

  PresenceService._internal();

  final _supabase = SupabaseClientProvider.client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Set<String>> _onlineUsers = {};

  /// Subscribe to presence updates for a conversation
  Future<void> subscribeToPresence(String conversationId) async {
    if (_channels.containsKey(conversationId)) {
      return; // Already subscribed
    }

    final channel = _supabase.realtime.channel('presence:$conversationId');

    // Listen for presence events using the 'on' method
    channel.on(RealtimeListenTypes.presence, ChannelFilter(event: 'sync'), (payload, [ref]) {
      print('👥 Presence sync for $conversationId');
      _updateOnlineUsers(conversationId, channel);
    });

    channel.on(RealtimeListenTypes.presence, ChannelFilter(event: 'join'), (payload, [ref]) {
      print('👋 User joined: ${payload['user_id'] ?? 'unknown'}');
      _updateOnlineUsers(conversationId, channel);
    });

    channel.on(RealtimeListenTypes.presence, ChannelFilter(event: 'leave'), (payload, [ref]) {
      print('👋 User left: ${payload['user_id'] ?? 'unknown'}');
      _updateOnlineUsers(conversationId, channel);
    });

    channel.subscribe((status, [err]) {
      print('Presence subscription status: $status');
      if (status == 'SUBSCRIBED') {
        _updateOnlineUsers(conversationId, channel);
        // Periodically update to catch any missed events
        Future.delayed(const Duration(seconds: 1), () {
          _updateOnlineUsers(conversationId, channel);
        });
      }
      if (err != null) {
        print('Error subscribing to presence: $err');
      }
    });

    _channels[conversationId] = channel;
  }

  /// Unsubscribe from presence updates
  Future<void> unsubscribeFromPresence(String conversationId) async {
    final channel = _channels.remove(conversationId);
    if (channel != null) {
      await channel.unsubscribe();
    }
    _onlineUsers.remove(conversationId);
  }

  /// Broadcast user presence
  Future<void> setPresenceStatus(String conversationId, bool isOnline) async {
    final channel = _channels[conversationId];
    if (channel == null) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await channel.track({
        'user_id': currentUser.id,
        'online': isOnline,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting presence: $e');
    }
  }

  /// Get online users for a conversation
  Set<String> getOnlineUsers(String conversationId) {
    return _onlineUsers[conversationId] ?? {};
  }

  /// Check if a user is online
  bool isUserOnline(String conversationId, String userId) {
    return _onlineUsers[conversationId]?.contains(userId) ?? false;
  }

  void _updateOnlineUsers(String conversationId, RealtimeChannel channel) {
    try {
      final presences = channel.presenceState().values.expand((list) => list).toList();
      final onlineSet = <String>{};

      for (final presence in presences) {
        if (presence['online'] == true) {
          final userId = presence['user_id'] as String?;
          if (userId != null) {
            onlineSet.add(userId);
          }
        }
      }

      _onlineUsers[conversationId] = onlineSet;
    } catch (e) {
      print('Error updating online users: $e');
    }
  }

  /// Clean up all subscriptions
  Future<void> dispose() async {
    for (final channel in _channels.values) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        print('Error unsubscribing: $e');
      }
    }
    _channels.clear();
    _onlineUsers.clear();
  }
}
