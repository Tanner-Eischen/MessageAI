import 'dart:async';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/services/connection_service.dart';
import 'dart:convert';

/// Service that handles background synchronization of offline messages and operations
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();

  factory BackgroundSyncService() {
    return _instance;
  }

  BackgroundSyncService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;
  final _connectionService = ConnectionService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  static const _syncInterval = Duration(seconds: 30);
  static const _maxRetries = 3;

  /// Initialize the background sync service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('BackgroundSyncService already initialized');
      return;
    }

    print('Initializing BackgroundSyncService...');

    // Initialize connection service
    _connectionService.initialize();

    // Listen to connection status changes
    _connectionService.statusStream.listen((status) {
      if (status == ConnectionStatus.connected) {
        print('Connection restored - triggering sync');
        syncPendingOperations();
      }
    });

    // Start periodic sync timer
    _startPeriodicSync();

    // Do initial sync if connected
    if (_connectionService.currentStatus == ConnectionStatus.connected) {
      syncPendingOperations();
    }

    _isInitialized = true;
    print('BackgroundSyncService initialized');
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_connectionService.currentStatus == ConnectionStatus.connected) {
        syncPendingOperations();
      }
    });
  }

  /// Sync all pending operations
  Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      print('Sync already in progress, skipping...');
      return;
    }

    if (_connectionService.currentStatus != ConnectionStatus.connected) {
      print('Not connected, skipping sync');
      return;
    }

    _isSyncing = true;

    try {
      print('Starting background sync...');

      // Sync unsynced messages
      await _syncMessages();

      // Sync unsynced receipts
      await _syncReceipts();

      // Process pending outbox operations
      await _processPendingOutbox();

      print('Background sync completed successfully');
    } catch (e) {
      print('Error during background sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync unsynced messages to the backend
  Future<void> _syncMessages() async {
    try {
      // Get all unsynced messages
      final unsyncedMessages = await _db.messageDao.getUnsyncedMessages();

      if (unsyncedMessages.isEmpty) {
        print('No unsynced messages to sync');
        return;
      }

      print('Syncing ${unsyncedMessages.length} unsynced messages...');

      for (final message in unsyncedMessages) {
        try {
          // Send message to backend
          await _supabase.from('messages').insert({
            'id': message.id,
            'conversation_id': message.conversationId,
            'sender_id': message.senderId,
            'body': message.body,
            'media_url': message.mediaUrl,
            'reply_to_id': message.replyToId,
            'created_at': DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000).toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(message.updatedAt * 1000).toIso8601String(),
            'edited_at': message.editedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(message.editedAt! * 1000).toIso8601String()
                : null,
          });

          // Mark as synced
          await _db.messageDao.markMessageAsSynced(message.id);
          print('Message ${message.id} synced successfully');
        } catch (e) {
          print('Error syncing message ${message.id}: $e');
          // Continue with next message
        }
      }
    } catch (e) {
      print('Error in _syncMessages: $e');
    }
  }

  /// Sync unsynced receipts to the backend
  Future<void> _syncReceipts() async {
    try {
      // Get all unsynced receipts
      final unsyncedReceipts = await _db.receiptDao.getUnsyncedReceipts();

      if (unsyncedReceipts.isEmpty) {
        print('No unsynced receipts to sync');
        return;
      }

      print('Syncing ${unsyncedReceipts.length} unsynced receipts...');

      for (final receipt in unsyncedReceipts) {
        try {
          // Send receipt to backend
          await _supabase.from('message_receipts').insert({
            'id': receipt.id,
            'message_id': receipt.messageId,
            'user_id': receipt.userId,
            'status': receipt.status,
            'created_at': DateTime.fromMillisecondsSinceEpoch(receipt.createdAt * 1000).toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(receipt.updatedAt * 1000).toIso8601String(),
          });

          // Mark as synced
          await _db.receiptDao.markReceiptAsSynced(receipt.id);
          print('Receipt ${receipt.id} synced successfully');
        } catch (e) {
          print('Error syncing receipt ${receipt.id}: $e');
          // Continue with next receipt
        }
      }
    } catch (e) {
      print('Error in _syncReceipts: $e');
    }
  }

  /// Process pending outbox operations
  Future<void> _processPendingOutbox() async {
    try {
      // Get retryable operations
      final pendingOps = await _db.pendingOutboxDao.getRetryableOperations(maxRetries: _maxRetries);

      if (pendingOps.isEmpty) {
        print('No pending operations to process');
        return;
      }

      print('Processing ${pendingOps.length} pending operations...');

      for (final operation in pendingOps) {
        try {
          await _processOperation(operation);

          // Remove from outbox after successful processing
          await _db.pendingOutboxDao.removePendingOperation(operation.id);
          print('Operation ${operation.id} processed successfully');
        } catch (e) {
          print('Error processing operation ${operation.id}: $e');

          // Update retry count
          final newRetryCount = operation.retryCount + 1;
          await _db.pendingOutboxDao.updateRetryInfo(
            operation.id,
            newRetryCount,
            e.toString(),
          );

          // If max retries reached, log and keep in DB for manual inspection
          if (newRetryCount >= _maxRetries) {
            print('Max retries reached for operation ${operation.id}');
          }
        }
      }
    } catch (e) {
      print('Error in _processPendingOutbox: $e');
    }
  }

  /// Process a single pending operation
  Future<void> _processOperation(PendingOutboxItem operation) async {
    final payload = jsonDecode(operation.payload);

    switch (operation.operation) {
      case 'send_message':
        await _processSendMessage(payload);
        break;
      case 'ack_receipt':
        await _processAckReceipt(payload);
        break;
      case 'update_message':
        await _processUpdateMessage(payload);
        break;
      case 'delete_message':
        await _processDeleteMessage(payload);
        break;
      default:
        print('Unknown operation type: ${operation.operation}');
    }
  }

  /// Process send message operation
  Future<void> _processSendMessage(Map<String, dynamic> payload) async {
    await _supabase.from('messages').insert(payload);
  }

  /// Process acknowledge receipt operation
  Future<void> _processAckReceipt(Map<String, dynamic> payload) async {
    await _supabase.from('message_receipts').insert(payload);
  }

  /// Process update message operation
  Future<void> _processUpdateMessage(Map<String, dynamic> payload) async {
    final messageId = payload['id'];
    await _supabase.from('messages')
        .update(payload)
        .eq('id', messageId);
  }

  /// Process delete message operation
  Future<void> _processDeleteMessage(Map<String, dynamic> payload) async {
    final messageId = payload['id'];
    await _supabase.from('messages')
        .delete()
        .eq('id', messageId);
  }

  /// Retry a specific message
  Future<void> retryMessage(String messageId) async {
    try {
      print('Retrying message: $messageId');

      // Get the message
      final message = await _db.messageDao.getMessageById(messageId);

      if (message == null) {
        print('Message not found: $messageId');
        return;
      }

      if (message.isSynced) {
        print('Message already synced: $messageId');
        return;
      }

      // Try to sync the message
      await _supabase.from('messages').insert({
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'body': message.body,
        'media_url': message.mediaUrl,
        'reply_to_id': message.replyToId,
        'created_at': DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(message.updatedAt * 1000).toIso8601String(),
        'edited_at': message.editedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(message.editedAt! * 1000).toIso8601String()
            : null,
      });

      // Mark as synced
      await _db.messageDao.markMessageAsSynced(message.id);
      print('Message retried successfully: $messageId');
    } catch (e) {
      print('Error retrying message $messageId: $e');
      rethrow;
    }
  }

  /// Clean up old failed operations (older than 7 days)
  Future<void> cleanupOldOperations() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
      final deletedCount = await _db.pendingOutboxDao.cleanupOldOperations(cutoffTime);
      print('Cleaned up $deletedCount old operations');
    } catch (e) {
      print('Error cleaning up old operations: $e');
    }
  }

  /// Manually trigger a sync
  Future<void> triggerManualSync() async {
    print('Manual sync triggered');
    await syncPendingOperations();
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;
  bool get isInitialized => _isInitialized;

  /// Dispose the service
  Future<void> dispose() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
    _isInitialized = false;
    print('BackgroundSyncService disposed');
  }
}
