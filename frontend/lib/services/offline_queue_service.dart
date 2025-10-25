import 'dart:async';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/services/network_connectivity_service.dart';
import 'package:messageai/services/retry_service.dart';
import 'package:messageai/core/errors/app_error.dart';

/// Service for managing offline message queue and auto-sync
class OfflineQueueService {
  static final OfflineQueueService _instance =
      OfflineQueueService._internal();

  factory OfflineQueueService() {
    return _instance;
  }

  OfflineQueueService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;
  final _connectivityService = NetworkConnectivityService();
  final _retryService = RetryService();

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isMonitoring = false;

  /// Start monitoring and auto-syncing
  void startMonitoring() {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;

    // Listen for connectivity changes - only sync when coming back online
    _connectivitySubscription = _connectivityService.onStatusChange.listen((status) {
      if (status == ConnectivityStatus.online) {
        syncPendingMessages();
      }
    });

    // No periodic polling - sync only happens:
    // 1. When connectivity is restored
    // 2. When explicitly requested (e.g., after sending a message)
  }

  /// Stop monitoring
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _isMonitoring = false;
    print('📦 Stopped offline queue monitoring');
  }

  /// Get count of pending messages
  Future<int> getPendingMessageCount() async {
    try {
      final messages = await _db.messageDao.getUnsyncedMessages();
      return messages.length;
    } catch (e) {
      print('❌ Error getting pending message count: $e');
      return 0;
    }
  }

  /// Sync all pending messages
  Future<SyncResult> syncPendingMessages() async {
    if (_isSyncing) {
      return SyncResult.alreadyRunning();
    }

    if (_connectivityService.isOffline) {
      return SyncResult.offline();
    }

    _isSyncing = true;
    int successCount = 0;
    int failureCount = 0;
    final List<String> failedMessageIds = [];

    try {
      final pendingMessages = await _db.messageDao.getUnsyncedMessages();

      if (pendingMessages.isEmpty) {
        return SyncResult.noMessages();
      }

      for (final message in pendingMessages) {
        final result = await _syncSingleMessage(message);
        if (result) {
          successCount++;
        } else {
          failureCount++;
          failedMessageIds.add(message.id);
        }
      }

      if (failureCount > 0) {
        print('⚠️ Sync: $successCount succeeded, $failureCount failed');
      }

      return SyncResult(
        totalMessages: pendingMessages.length,
        successCount: successCount,
        failureCount: failureCount,
        failedMessageIds: failedMessageIds,
      );
    } catch (e) {
      print('❌ Error syncing: $e');
      return SyncResult.error(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single message with retry
  Future<bool> _syncSingleMessage(Message message) async {
    try {
      final result = await _retryService.execute(
        operation: () => _sendMessageToBackend(message),
        operationName: 'Sync Message ${message.id.substring(0, 8)}',
        config: RetryConfig.defaultConfig,
      );

      if (result.succeeded) {
        await _db.messageDao.markMessageAsSynced(message.id);
        return true;
      } else {
        final error = result.error;
        
        // If error is non-retryable, delete the message from queue
        if (error != null && !error.isRetryable) {
          print('🗑️ Removed invalid message: ${error.code}');
          await _db.messageDao.deleteMessage(message.id);
          return true;
        }
        
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Send message to backend
  Future<void> _sendMessageToBackend(Message message) async {
    final payload = {
      'id': message.id,
      'conversation_id': message.conversationId,
      'sender_id': message.senderId,
      'body': message.body,
      'media_url': message.mediaUrl,
      'created_at': DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000)
          .toIso8601String(),
      'updated_at': DateTime.fromMillisecondsSinceEpoch(message.updatedAt * 1000)
          .toIso8601String(),
    };

    await _supabase.from('messages').insert(payload);
    
    // Send push notification (don't wait for it)
    _sendPushNotification(message).catchError((e) {
      // Silently fail - push notifications are not critical
    });
  }

  /// Send push notification for message
  Future<void> _sendPushNotification(Message message) async {
    try {
      // Get sender profile (use maybeSingle to handle missing profile)
      final profile = await _supabase
          .from('profiles')
          .select('username, email')
          .eq('user_id', message.senderId)
          .maybeSingle();

      final senderName = profile?['username'] as String? ?? 
                         profile?['email'] as String? ?? 
                         'Someone';

      // Call push notification edge function with auth header
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) return;
      
      await _supabase.functions.invoke(
        'push_notify',
        body: {
          'message_id': message.id,
          'conversation_id': message.conversationId,
          'sender_id': message.senderId,
          'sender_name': senderName,
          'title': senderName,
          'body': message.body,
        },
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }

  /// Force sync now (called by user action)
  Future<SyncResult> forceSyncNow() async {
    print('🔄 Force sync requested');
    return await syncPendingMessages();
  }

  /// Check if any messages are pending
  Future<bool> hasPendingMessages() async {
    final count = await getPendingMessageCount();
    return count > 0;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Result of sync operation
class SyncResult {
  final int totalMessages;
  final int successCount;
  final int failureCount;
  final List<String> failedMessageIds;
  final String? errorMessage;
  final SyncStatus status;

  SyncResult({
    required this.totalMessages,
    required this.successCount,
    required this.failureCount,
    this.failedMessageIds = const [],
    this.errorMessage,
    this.status = SyncStatus.completed,
  });

  SyncResult.noMessages()
      : this(
          totalMessages: 0,
          successCount: 0,
          failureCount: 0,
          status: SyncStatus.noMessages,
        );

  SyncResult.offline()
      : this(
          totalMessages: 0,
          successCount: 0,
          failureCount: 0,
          status: SyncStatus.offline,
        );

  SyncResult.alreadyRunning()
      : this(
          totalMessages: 0,
          successCount: 0,
          failureCount: 0,
          status: SyncStatus.alreadyRunning,
        );

  SyncResult.error(String message)
      : this(
          totalMessages: 0,
          successCount: 0,
          failureCount: 0,
          errorMessage: message,
          status: SyncStatus.error,
        );

  bool get hasErrors => failureCount > 0 || errorMessage != null;
  bool get isSuccess => failureCount == 0 && errorMessage == null;
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;
}

/// Status of sync operation
enum SyncStatus {
  completed,
  noMessages,
  offline,
  alreadyRunning,
  error,
}


