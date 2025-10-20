import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/state/database_provider.dart';
import 'package:messageai/state/providers.dart';
import 'package:messageai/state/repository_providers.dart';

/// Manages realtime subscriptions to conversation messages
class RealtimeManager {
  final Ref ref;
  final Map<String, dynamic> _subscriptions = {};

  RealtimeManager({required this.ref});

  /// Subscribe to messages in a conversation
  void subscribeToConversationMessages(String conversationId) {
    final supabase = ref.watch(supabaseClientProvider);
    
    final subscription = supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: FilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
        )
        .subscribe((payload, [ref]) async {
          // Handle new/updated messages
          if (payload.eventType == 'INSERT' || payload.eventType == 'UPDATE') {
            final messageData = payload.newRecord as Map<String, dynamic>;
            final message = Message(
              id: messageData['id'] as String,
              conversationId: messageData['conversation_id'] as String,
              senderId: messageData['sender_id'] as String,
              body: messageData['body'] as String,
              mediaUrl: messageData['media_url'] as String?,
              createdAt: messageData['created_at'] as int,
              updatedAt: messageData['updated_at'] as int,
              isSynced: true,
            );
            
            // Update local DB
            final messageDao = ref.watch(messageDaoProvider);
            await messageDao.insertMessage(message);
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
  
  // Watch the local messages
  yield* ref.watch(messagesStreamProvider(conversationId));
});
