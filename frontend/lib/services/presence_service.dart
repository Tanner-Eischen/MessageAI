import 'dart:async';
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
  final Map<String, StreamController<Set<String>>> _presenceControllers = {};

  /// Subscribe to presence updates for a conversation
  Stream<Set<String>> subscribeToPresence(String conversationId) {
    if (_presenceControllers.containsKey(conversationId)) {
      return _presenceControllers[conversationId]!.stream;
    }

    final controller = StreamController<Set<String>>.broadcast();
    _presenceControllers[conversationId] = controller;

    final channel = _supabase.realtime.channel('presence:$conversationId');

    // Listen for presence state changes
    channel.onPresenceSync(() {
      _updateOnlineUsers(conversationId, channel);
      if (!controller.isClosed) {
        controller.add(getOnlineUsers(conversationId));
      }
    });

    channel.onPresenceJoin((payload) {
      print('User joined: $payload');
      _updateOnlineUsers(conversationId, channel);
      if (!controller.isClosed) {
        controller.add(getOnlineUsers(conversationId));
      }
    });

    channel.onPresenceLeave((payload) {
      print('User left: $payload');
      _updateOnlineUsers(conversationId, channel);
      if (!controller.isClosed) {
        controller.add(getOnlineUsers(conversationId));
      }
    });

    channel.subscribe((status, [err]) {
      print('Presence subscription status: $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        _updateOnlineUsers(conversationId, channel);
        if (!controller.isClosed) {
          controller.add(getOnlineUsers(conversationId));
        }
      }
      if (err != null) {
        print('Error subscribing to presence: $err');
        if (!controller.isClosed) {
          controller.addError(err);
        }
      }
    });

    _channels[conversationId] = channel;

    return controller.stream;
  }

  /// Unsubscribe from presence updates
  Future<void> unsubscribeFromPresence(String conversationId) async {
    final channel = _channels.remove(conversationId);
    if (channel != null) {
      await channel.unsubscribe();
    }

    final controller = _presenceControllers.remove(conversationId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
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
    for (final controller in _presenceControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _presenceControllers.clear();

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
