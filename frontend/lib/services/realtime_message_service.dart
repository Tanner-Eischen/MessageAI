import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';

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
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<List<Message>>> _messageControllers = {};

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
      final channel = _supabase.realtime.channel('messages:$conversationId');
      
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
          print('📥 New message received from realtime!');
          print('📥 Payload: $payload');
          try {
            // Save incoming message to local DB
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
            
            // Create delivery receipt for received message
            final currentUser = _supabase.auth.currentUser;
            if (currentUser != null && message.senderId != currentUser.id) {
              await _createReceipt(message.id, currentUser.id, 'delivered');
            }
          } catch (e) {
            print('Error processing incoming message: $e');
          }
        },
      );

      channel.subscribe((status, [err]) {
        print('📡 Realtime subscription status for $conversationId: $status');
        
        if (status == 'SUBSCRIBED') {
          print('✅ Successfully subscribed to messages for conversation: $conversationId');
          print('   Listening for INSERT events on messages table');
          print('   Filter: conversation_id=eq.$conversationId');
        } else if (status == 'CLOSED') {
          print('❌ Connection CLOSED for $conversationId');
          print('   Possible reasons:');
          print('   1. User navigated away from message screen');
          print('   2. Widget was disposed');
          print('   3. Network connection lost');
          print('   4. Supabase realtime quota exceeded');
        } else if (status == 'CHANNEL_ERROR') {
          print('❌ CHANNEL_ERROR for $conversationId');
          print('   Check Supabase dashboard → Database → Replication');
          print('   Make sure messages table has INSERT replication enabled');
        } else if (status == 'TIMED_OUT') {
          print('⏰ Connection TIMED_OUT for $conversationId');
        } else {
          print('ℹ️ Unhandled status: $status');
        }
        
        if (err != null) {
          print('❌ Subscription error: $err');
          controller.addError(err);
        }
      });

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

  Future<void> _createReceipt(String messageId, String userId, String status) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final receiptId = const Uuid().v4();
      
      // Save to local DB
      await _db.receiptDao.addReceipt(Receipt(
        id: receiptId,
        messageId: messageId,
        userId: userId,
        status: status,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      ));
      
      // Sync to backend
      await _supabase.from('message_receipts').insert({
        'id': receiptId,
        'message_id': messageId,
        'user_id': userId,
        'status': status,
        'created_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        'updated_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
      });
      
      await _db.receiptDao.markReceiptAsSynced(receiptId);
      print('Receipt created: $status for message $messageId');
    } catch (e) {
      print('Error creating receipt: $e');
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
        print('Error unsubscribing: $e');
      }
    }
  }

  /// Clean up all subscriptions
  Future<void> dispose() async {
    for (final controller in _messageControllers.values) {
      try {
        controller.close();
      } catch (e) {
        print('Error closing controller: $e');
      }
    }
    _messageControllers.clear();

    for (final channel in _channels.values) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        print('Error unsubscribing: $e');
      }
    }
    _channels.clear();
  }
}
