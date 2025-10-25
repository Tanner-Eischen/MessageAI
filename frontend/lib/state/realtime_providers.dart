import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/state/database_provider.dart';
import 'package:messageai/state/providers.dart';

/// Manages realtime subscriptions to conversation messages
class RealtimeManager {
  final Ref ref;
  final Map<String, dynamic> _subscriptions = {};

  RealtimeManager({required this.ref});

  /// Subscribe to messages in a conversation
  void subscribeToConversationMessages(String conversationId) {
    final supabase = ref.watch(supabaseClientProvider);
    
    // Create a channel for this conversation's messages
    final subscription = supabase.channel('public:messages:$conversationId');
    
    // Subscribe to the channel
    subscription.subscribe((status, [error]) async {
      if (status == 'SUBSCRIBED') {
        // Successfully subscribed
        // Note: In Supabase v1.x, realtime postgres changes work differently
        // This is a placeholder - the actual message sync happens through
        // the existing realtime message service
      }
    });
    
    _subscriptions[conversationId] = subscription;
  }

  /// Unsubscribe from conversation messages
  Future<void> unsubscribeFromConversation(String conversationId) async {
    final subscription = _subscriptions.remove(conversationId);
    if (subscription != null) {
      await subscription.unsubscribe();
    }
  }

  /// Cleanup all subscriptions
  Future<void> cleanup() async {
    for (final subscription in _subscriptions.values) {
      await subscription.unsubscribe();
    }
    _subscriptions.clear();
  }
}

/// Provider for realtime manager
final realtimeManagerProvider = Provider.autoDispose<RealtimeManager>((ref) {
  return RealtimeManager(ref: ref);
});

/// Subscribe to messages in a conversation
final conversationMessagesRealtimeProvider = 
    FutureProvider.autoDispose.family<void, String>((ref, conversationId) async {
  final manager = ref.watch(realtimeManagerProvider);
  manager.subscribeToConversationMessages(conversationId);
  
  // Cleanup on dispose
  ref.onDispose(() {
    manager.unsubscribeFromConversation(conversationId);
  });
});

/// Watch for realtime message updates in a conversation
final realtimeConversationMessagesProvider = 
    StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) async* {
  // Enable realtime subscription
  await ref.watch(conversationMessagesRealtimeProvider(conversationId).future);
  
  // Watch the local messages - use .stream instead
  yield* ref.watch(messagesStreamProvider(conversationId).stream);
});
