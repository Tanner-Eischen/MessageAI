import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';

/// Service to handle typing indicators using Supabase Realtime
class TypingIndicatorService {
  static final TypingIndicatorService _instance = TypingIndicatorService._internal();
  factory TypingIndicatorService() => _instance;
  TypingIndicatorService._internal();

  final _supabase = SupabaseClientProvider.client;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, Set<String>> _typingUsers = {}; // conversationId -> Set of userIds
  final Map<String, StreamController<Set<String>>> _typingControllers = {};
  final Map<String, Timer?> _typingTimeouts = {}; // userId -> Timer

  static const _typingTimeout = Duration(seconds: 3);

  /// Subscribe to typing events for a conversation
  Stream<Set<String>> subscribeToTyping(String conversationId) {
    // Return existing stream if already subscribed
    if (_typingControllers.containsKey(conversationId)) {
      return _typingControllers[conversationId]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<Set<String>>.broadcast();
    _typingControllers[conversationId] = controller;
    _typingUsers[conversationId] = {};

    // Create channel for this conversation
    final channel = _supabase.channel('typing:$conversationId');
    _channels[conversationId] = channel;

    // Listen for typing events using on() method
    channel.on(
      RealtimeListenTypes.broadcast,
      ChannelFilter(event: 'typing'),
      (payload, [ref]) {
        final data = payload as Map<String, dynamic>;
        final userId = data['user_id'] as String?;
        final isTyping = data['is_typing'] as bool? ?? false;
        final currentUserId = _supabase.auth.currentUser?.id;

        // Ignore own typing events
        if (userId == null || userId == currentUserId) return;

        final typingSet = _typingUsers[conversationId] ?? {};

        if (isTyping) {
          typingSet.add(userId);
          
          // Clear existing timeout for this user
          _typingTimeouts['$conversationId:$userId']?.cancel();
          
          // Set timeout to remove user from typing after inactivity
          _typingTimeouts['$conversationId:$userId'] = Timer(_typingTimeout, () {
            typingSet.remove(userId);
            _typingUsers[conversationId] = typingSet;
            if (!controller.isClosed) {
              controller.add(Set.from(typingSet));
            }
          });
        } else {
          typingSet.remove(userId);
          _typingTimeouts['$conversationId:$userId']?.cancel();
        }

        _typingUsers[conversationId] = typingSet;
        if (!controller.isClosed) {
          controller.add(Set.from(typingSet));
        }
      },
    );

    // Subscribe to channel
    channel.subscribe();

    return controller.stream;
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(String conversationId, bool isTyping) async {
    final channel = _channels[conversationId];
    if (channel == null) return;

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      channel.send(
        type: RealtimeListenTypes.broadcast,
        event: 'typing',
        payload: {
          'user_id': currentUserId,
          'is_typing': isTyping,
        },
      );
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  /// Unsubscribe from typing events for a conversation
  Future<void> unsubscribeFromTyping(String conversationId) async {
    final channel = _channels[conversationId];
    if (channel != null) {
      await channel.unsubscribe();
      _channels.remove(conversationId);
    }

    final controller = _typingControllers[conversationId];
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    _typingControllers.remove(conversationId);
    _typingUsers.remove(conversationId);

    // Clear all timeouts for this conversation
    final keysToRemove = _typingTimeouts.keys
        .where((key) => key.startsWith('$conversationId:'))
        .toList();
    for (final key in keysToRemove) {
      _typingTimeouts[key]?.cancel();
      _typingTimeouts.remove(key);
    }
  }

  /// Get current typing users for a conversation
  Set<String> getTypingUsers(String conversationId) {
    return Set.from(_typingUsers[conversationId] ?? {});
  }

  /// Clean up all subscriptions
  Future<void> dispose() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();

    for (final controller in _typingControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _typingControllers.clear();
    _typingUsers.clear();

    for (final timer in _typingTimeouts.values) {
      timer?.cancel();
    }
    _typingTimeouts.clear();
  }
}

