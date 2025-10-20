import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/state/repository_providers.dart';

/// Message to send
class SendableMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String? mediaUrl;

  SendableMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.mediaUrl,
  });
}

/// Manages sending messages with optimistic updates
class SendQueue {
  final Ref ref;
  
  SendQueue({required this.ref});

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    String? mediaUrl,
  }) async {
    // Generate unique ID
    const uuid = Uuid();
    final messageId = uuid.v4();
    
    // Get repository
    final messageRepo = ref.watch(messageRepositoryProvider);
    
    // Send optimistically (local first)
    final message = await messageRepo.sendMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      mediaUrl: mediaUrl,
    );
    
    // Queue background sync
    _scheduleSyncIfNeeded();
    
    return message;
  }

  /// Drain the send queue (sync pending messages)
  Future<void> drainQueue() async {
    final messageRepo = ref.watch(messageRepositoryProvider);
    final receiptRepo = ref.watch(receiptRepositoryProvider);
    
    try {
      // Sync messages
      await messageRepo.syncUnsyncedMessages();
      
      // Sync receipts
      await receiptRepo.syncUnsyncedReceipts();
    } catch (e) {
      print('Error draining send queue: $e');
      rethrow;
    }
  }

  /// Schedule sync if there are pending operations
  void _scheduleSyncIfNeeded() {
    // In a real app, this would use a periodic timer or background service
    // For now, we'll just sync immediately for demo purposes
    _syncInBackground();
  }

  /// Sync in background
  void _syncInBackground() {
    // Run sync without awaiting (fire and forget)
    drainQueue().catchError((e) {
      print('Background sync error: $e');
    });
  }

  /// Get pending message count
  Future<int> getPendingCount() async {
    final messageRepo = ref.watch(messageRepositoryProvider);
    return messageRepo.getPendingMessageCount();
  }
}

/// Provider for send queue
final sendQueueProvider = Provider<SendQueue>((ref) {
  return SendQueue(ref: ref);
});

/// State notifier for managing message sends
class SendMessageNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SendMessageNotifier({required this.ref}) : super(const AsyncValue.data(null));

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    String? mediaUrl,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final sendQueue = ref.watch(sendQueueProvider);
      final message = await sendQueue.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
        mediaUrl: mediaUrl,
      );
      
      state = const AsyncValue.data(null);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Retry pending messages
  Future<void> retryPending() async {
    state = const AsyncValue.loading();
    
    try {
      final sendQueue = ref.watch(sendQueueProvider);
      await sendQueue.drainQueue();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// State notifier provider for sending messages
final sendMessageNotifierProvider = 
    StateNotifierProvider<SendMessageNotifier, AsyncValue<void>>((ref) {
  return SendMessageNotifier(ref: ref);
});

/// Get pending message count
final pendingMessageCountProvider = FutureProvider<int>((ref) async {
  final sendQueue = ref.watch(sendQueueProvider);
  return sendQueue.getPendingCount();
});
