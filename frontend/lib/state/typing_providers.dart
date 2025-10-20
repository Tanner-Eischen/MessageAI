import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/state/providers.dart';

/// User typing information
class TypingUser {
  final String userId;
  final DateTime startedAt;
  final Duration timeout;

  TypingUser({
    required this.userId,
    required this.startedAt,
    this.timeout = const Duration(seconds: 3),
  });

  /// Check if typing indicator has expired
  bool get isExpired {
    return DateTime.now().difference(startedAt) > timeout;
  }
}

/// Manages typing indicators for a conversation
class TypingManager {
  final Ref ref;
  final String conversationId;
  final String userId;
  
  final Map<String, TypingUser> _typingUsers = {};
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  DateTime? _lastTypingSent;

  TypingManager({
    required this.ref,
    required this.conversationId,
    required this.userId,
  });

  /// Broadcast that user is typing
  Future<void> sendTypingIndicator() async {
    final now = DateTime.now();
    
    // Debounce: only send every 300ms
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!) < _debounceDelay) {
      return;
    }
    
    _lastTypingSent = now;
    
    final supabase = ref.watch(supabaseClientProvider);
    
    // Send typing indicator through presence
    final presence = supabase.channel('typing:$conversationId');
    
    try {
      await presence.subscribe(
        (status, [err]) {
          print('Typing subscription: $status - $err');
        },
      );
      
      await presence.track({
        'user_id': userId,
        'typing': true,
        'timestamp': now.toIso8601String(),
      });
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  /// Stop broadcasting typing
  Future<void> stopTypingIndicator() async {
    final supabase = ref.watch(supabaseClientProvider);
    
    final presence = supabase.channel('typing:$conversationId');
    
    try {
      await presence.track({
        'user_id': userId,
        'typing': false,
      });
      
      await presence.unsubscribe();
    } catch (e) {
      print('Error stopping typing indicator: $e');
    }
  }

  /// Add a typing user (received from server)
  void addTypingUser(String otherUserId) {
    _typingUsers[otherUserId] = TypingUser(userId: otherUserId, startedAt: DateTime.now());
  }

  /// Remove a typing user
  void removeTypingUser(String otherUserId) {
    _typingUsers.remove(otherUserId);
  }

  /// Get list of currently typing users (excluding expired ones)
  List<TypingUser> getTypingUsers() {
    // Remove expired entries
    _typingUsers.removeWhere((_, user) => user.isExpired);
    return _typingUsers.values.toList();
  }

  /// Get typing users display text
  String getTypingText() {
    final typingUsers = getTypingUsers();
    
    if (typingUsers.isEmpty) return '';
    if (typingUsers.length == 1) return '${typingUsers.first.userId} is typing...';
    if (typingUsers.length == 2) {
      return '${typingUsers[0].userId} and ${typingUsers[1].userId} are typing...';
    }
    
    return '${typingUsers.length} people are typing...';
  }

  /// Check if anyone is typing
  bool get anyoneTyping => getTypingUsers().isNotEmpty;
}

/// Provider for typing manager
final typingManagerProvider =
    Provider.family<TypingManager, (String, String)>((ref, args) {
  final (conversationId, userId) = args;
  return TypingManager(
    ref: ref,
    conversationId: conversationId,
    userId: userId,
  );
});

/// Stream of typing users in a conversation
final conversationTypingProvider = StreamProvider.autoDispose
    .family<List<TypingUser>, String>((ref, conversationId) async* {
  // This would typically subscribe to realtime typing updates
  // For now, we'll yield an empty list
  yield [];
  
  // TODO: Set up realtime typing stream
});

/// Get typing status text for display
final typingStatusTextProvider = StreamProvider.autoDispose
    .family<String, String>((ref, conversationId) async* {
  yield* ref.watch(conversationTypingProvider(conversationId)).when(
        data: (typingUsers) async* {
          if (typingUsers.isEmpty) {
            yield '';
          } else if (typingUsers.length == 1) {
            yield '${typingUsers.first.userId} is typing...';
          } else {
            yield '${typingUsers.length} people are typing...';
          }
        },
        loading: () async* {
          yield '';
        },
        error: (err, st) async* {
          yield '';
        },
      );
});
