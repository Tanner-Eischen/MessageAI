import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/state/providers.dart';

/// User presence status
enum PresenceStatus {
  online,
  away,
  offline,
}

/// User presence information
class UserPresence {
  final String userId;
  final String conversationId;
  final PresenceStatus status;
  final DateTime lastSeen;

  UserPresence({
    required this.userId,
    required this.conversationId,
    required this.status,
    required this.lastSeen,
  });
}

/// Manages user presence for a conversation
class PresenceManager {
  final Ref ref;
  final String conversationId;
  final String userId;
  
  PresenceManager({
    required this.ref,
    required this.conversationId,
    required this.userId,
  });

  /// Join presence channel (user is viewing conversation)
  Future<void> joinPresence() async {
    final supabase = ref.watch(supabaseClientProvider);
    
    // Subscribe to presence channel
    final presence = supabase.channel('presence:$conversationId').onPresenceSync(
      (_) {
        print('Presence synced for $conversationId');
      },
    ).onPresenceChange(
      PresenceAction.sync,
      (_) {
        print('Presence state changed for $conversationId');
      },
    );

    // Subscribe to presence channel
    await presence.subscribe(
      (status, [err]) {
        print('Presence subscription: $status - $err');
      },
    );

    // Track this user's presence
    await presence.track({
      'user_id': userId,
      'status': 'online',
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  /// Leave presence channel (user is no longer viewing)
  Future<void> leavePresence() async {
    final supabase = ref.watch(supabaseClientProvider);
    
    final presence = supabase.channel('presence:$conversationId');
    await presence.unsubscribe();
  }

  /// Update user status
  Future<void> updateStatus(PresenceStatus status) async {
    final supabase = ref.watch(supabaseClientProvider);
    
    final presence = supabase.channel('presence:$conversationId');
    await presence.track({
      'user_id': userId,
      'status': status.name,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  /// Get all users' presence in conversation
  Future<List<UserPresence>> getConversationPresence() async {
    final supabase = ref.watch(supabaseClientProvider);
    
    final presence = supabase.channel('presence:$conversationId');
    final state = presence.presenceState();
    
    final presences = <UserPresence>[];
    
    for (final entry in state.entries) {
      for (final presence in entry.value) {
        final presenceMap = presence as Map<String, dynamic>;
        presences.add(UserPresence(
          userId: presenceMap['user_id'] as String,
          conversationId: conversationId,
          status: PresenceStatus.values.firstWhere(
            (s) => s.name == (presenceMap['status'] as String),
            orElse: () => PresenceStatus.offline,
          ),
          lastSeen: DateTime.parse(presenceMap['last_seen'] as String),
        ));
      }
    }
    
    return presences;
  }

  /// Check if user is online
  Future<bool> isUserOnline(String otherUserId) async {
    final presences = await getConversationPresence();
    return presences.any((p) =>
        p.userId == otherUserId && p.status == PresenceStatus.online);
  }
}

/// Provider for presence manager
final presenceManagerProvider = Provider.family<PresenceManager, (String, String)>((ref, args) {
  final (conversationId, userId) = args;
  return PresenceManager(
    ref: ref,
    conversationId: conversationId,
    userId: userId,
  );
});

/// Stream of user presence in a conversation
final conversationPresenceProvider =
    StreamProvider.autoDispose.family<List<UserPresence>, String>((ref, conversationId) async* {
  // This would typically subscribe to realtime presence updates
  // For now, we'll yield an empty list
  yield [];
  
  // TODO: Set up realtime presence stream
});

/// Check if a specific user is online
final userOnlineProvider = FutureProvider.autoDispose
    .family<bool, (String, String)>((ref, args) async {
  final (conversationId, userId) = args;
  final manager = ref.watch(presenceManagerProvider((conversationId, userId)));
  return manager.isUserOnline(userId);
});
