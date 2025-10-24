import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/services/realtime_diagnostic_service.dart';
import 'package:messageai/services/ai_analysis_service.dart';

/// Service for real-time message synchronization
class RealTimeMessageService {
  static final RealTimeMessageService _instance =
      RealTimeMessageService._internal();

  factory RealTimeMessageService() {
    return _instance;
  }

  RealTimeMessageService._internal();

  final _supabase = SupabaseClientProvider.client;
  final _db = AppDb.instance;
  final _diagnostics = RealtimeDiagnosticService();
  final _aiAnalysis = AIAnalysisService();
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, RealtimeChannel> _receiptChannels = {};
  final Map<String, StreamController<List<Message>>> _messageControllers = {};
  final Map<String, StreamController<List<Receipt>>> _receiptControllers = {};

  /// Subscribe to real-time messages for a conversation
  Stream<List<Message>> subscribeToMessages(String conversationId) {
    if (_messageControllers.containsKey(conversationId)) {
      return _messageControllers[conversationId]!.stream;
    }

    final controller = StreamController<List<Message>>.broadcast();
    _messageControllers[conversationId] = controller;

    _setupRealtimeListener(conversationId, controller);

    return controller.stream;
  }

  void _setupRealtimeListener(
    String conversationId,
    StreamController<List<Message>> controller,
  ) {
    try {
      final channelName = 'messages:$conversationId';
      final channel = _supabase.realtime.channel(channelName);
      
      // Register channel for diagnostics
      _diagnostics.registerChannel(channelName, channel);
      
      // Listen for postgres changes using the correct API
      channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: 'conversation_id=eq.$conversationId',
        ),
        (payload, [ref]) async {
          _diagnostics.recordMessageReceived(channelName);
          print('📨 Realtime message received');
          
          try {
            final data = payload['new'] as Map<String, dynamic>;
            final timestamp = DateTime.parse(data['created_at'] as String)
                .millisecondsSinceEpoch ~/
                1000;
            
            final message = Message(
              id: data['id'] as String,
              conversationId: data['conversation_id'] as String,
              senderId: data['sender_id'] as String,
              body: data['body'] as String,
              mediaUrl: data['media_url'] as String?,
              createdAt: timestamp,
              updatedAt: DateTime.parse(data['updated_at'] as String)
                  .millisecondsSinceEpoch ~/
                  1000,
              isSynced: true,
            );
            
            await _db.messageDao.upsertMessage(message);
            
            // Refresh the stream
            final messages =
                await _db.messageDao.getMessagesByConversation(conversationId);
            controller.add(messages);
            print('✅ UI updated with ${messages.length} messages');
            
            // Create delivery receipt for received message
            final currentUser = _supabase.auth.currentUser;
            if (currentUser != null && message.senderId != currentUser.id) {
              await _createReceipt(message.id, currentUser.id, 'delivered');
              
              // Trigger AI analysis for received messages (non-blocking)
              _triggerAIAnalysis(message);
            }
          } catch (e) {
            print('❌ Error processing message: $e');
          }
        },
      );

      // Subscribe with extended timeout for slower connections
      channel.subscribe(
        (status, [err]) {
          _diagnostics.updateChannelStatus(channelName, status);
          
          // Log all status changes for debugging
          print('📡 Realtime [$conversationId]: $status');
          
          if (status == 'CHANNEL_ERROR' || status == 'TIMED_OUT' || err != null) {
            print('❌ Realtime error for $conversationId: $status ${err ?? ""}');
            if (err != null) {
              _diagnostics.recordError(channelName, err.toString());
              controller.addError(err);
            }
          }
        },
        const Duration(seconds: 30), // Increased timeout for mobile networks
      );

      _channels[conversationId] = channel;
      
      // Load initial messages
      Future.delayed(Duration.zero, () async {
        try {
          final messages =
              await _db.messageDao.getMessagesByConversation(conversationId);
          controller.add(messages);
        } catch (e) {
          controller.addError(e);
        }
      });
    } catch (e) {
      print('Error setting up realtime listener: $e');
      controller.addError(e);
    }
  }

  /// Trigger AI analysis for a message (non-blocking)
  void _triggerAIAnalysis(Message message) {
    // Run in background, don't await
    _aiAnalysis.requestAnalysis(message.id, message.body).then((analysis) {
      if (analysis != null) {
        print('✨ AI analysis completed for ${message.id.substring(0, 8)}: ${analysis.tone}');
      }
    }).catchError((error) {
      print('⚠️ AI analysis failed for ${message.id.substring(0, 8)}: $error');
    });
  }

  Future<void> _createReceipt(String messageId, String userId, String status) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final receiptId = const Uuid().v4();
      
      await _db.receiptDao.addReceipt(Receipt(
        id: receiptId,
        messageId: messageId,
        userId: userId,
        status: status,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      ));
      
      // Note: message_receipts table uses 'at' column, not 'created_at'
      await _supabase.from('message_receipts').insert({
        'id': receiptId,
        'message_id': messageId,
        'user_id': userId,
        'status': status,
        'at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      });
      
      await _db.receiptDao.markReceiptAsSynced(receiptId);
    } catch (e) {
      // Silently fail - receipts are not critical
    }
  }

  /// Subscribe to real-time receipts for a conversation
  Stream<List<Receipt>> subscribeToReceipts(String conversationId) {
    if (_receiptControllers.containsKey(conversationId)) {
      return _receiptControllers[conversationId]!.stream;
    }

    final controller = StreamController<List<Receipt>>.broadcast();
    _receiptControllers[conversationId] = controller;

    _setupReceiptListener(conversationId, controller);

    return controller.stream;
  }

  void _setupReceiptListener(
    String conversationId,
    StreamController<List<Receipt>> controller,
  ) {
    try {
      final channelName = 'receipts:$conversationId';
      final channel = _supabase.realtime.channel(channelName);
      
      // Listen for receipt changes
      channel.on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',  // All events (INSERT, UPDATE)
          schema: 'public',
          table: 'message_receipts',
        ),
        (payload, [ref]) async {
          print('📨 Receipt change received');
          
          try {
            // Reload all receipts for this conversation
            final receipts = await _db.receiptDao.getReceiptsByConversation(conversationId);
            controller.add(receipts);
          } catch (e) {
            print('❌ Error processing receipt: $e');
          }
        },
      );

      channel.subscribe(
        (status, [err]) {
          print('📡 Receipts [$conversationId]: $status');
          if (err != null) {
            controller.addError(err);
          }
        },
        const Duration(seconds: 30),
      );

      _receiptChannels[conversationId] = channel;
      
      // Load initial receipts
      Future.delayed(Duration.zero, () async {
        try {
          final receipts = await _db.receiptDao.getReceiptsByConversation(conversationId);
          controller.add(receipts);
        } catch (e) {
          controller.addError(e);
        }
      });
    } catch (e) {
      print('Error setting up receipt listener: $e');
      controller.addError(e);
    }
  }

  /// Unsubscribe from real-time messages
  Future<void> unsubscribeFromMessages(String conversationId) async {
    final controller = _messageControllers.remove(conversationId);
    controller?.close();

    final channel = _channels.remove(conversationId);
    if (channel != null) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        // Ignore unsubscribe errors
      }
    }
  }

  /// Unsubscribe from real-time receipts
  Future<void> unsubscribeFromReceipts(String conversationId) async {
    final controller = _receiptControllers.remove(conversationId);
    controller?.close();

    final channel = _receiptChannels.remove(conversationId);
    if (channel != null) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        // Ignore unsubscribe errors
      }
    }
  }

  /// Clean up all subscriptions
  Future<void> dispose() async {
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();

    for (final controller in _receiptControllers.values) {
      controller.close();
    }
    _receiptControllers.clear();

    for (final channel in _channels.values) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        // Ignore unsubscribe errors
      }
    }
    _channels.clear();

    for (final channel in _receiptChannels.values) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        // Ignore unsubscribe errors
      }
    }
    _receiptChannels.clear();
    
    _diagnostics.dispose();
  }

  /// Get diagnostic report
  String getDiagnosticsReport() {
    return _diagnostics.generateReport();
  }

  /// Start diagnostic monitoring
  void startDiagnostics() {
    _diagnostics.startMonitoring();
  }

  /// Stop diagnostic monitoring
  void stopDiagnostics() {
    _diagnostics.stopMonitoring();
  }

  /// Test Realtime connection
  Future<RealtimeTestResult> testConnection() {
    return _diagnostics.testConnection();
  }
}
