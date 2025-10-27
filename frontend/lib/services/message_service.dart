import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/core/errors/error_handler.dart';
import 'package:messageai/core/errors/app_error.dart';
import 'package:messageai/services/ai_analysis_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();

  factory MessageService() {
    return _instance;
  }

  MessageService._internal();

  final _db = AppDb.instance;
  final _supabase = SupabaseClientProvider.client;
  final _errorHandler = ErrorHandler();
  final _aiAnalysis = AIAnalysisService();
  
  // Callback for when message is successfully sent (for triggering push notifications)
  void Function(String conversationId, String messageId)? onMessageSent;

  /// Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
    String? mediaUrl,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw AuthError.sessionExpired();
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final messageId = const Uuid().v4();
      
      final message = Message(
        id: messageId,
        conversationId: conversationId,
        senderId: currentUser.id,
        body: body,
        mediaUrl: mediaUrl,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      // Save to local database first (optimistic UI)
      try {
        await _db.messageDao.upsertMessage(message);
        await _db.conversationDao.updateLastMessageTime(conversationId);
      } catch (error, stackTrace) {
        // Critical: Can't even save locally
        throw _errorHandler.handleError(
          error, 
          stackTrace: stackTrace, 
          context: 'Save Message Locally',
        );
      }

      // Sync to backend
      try {
        final payload = {
          'id': messageId,
          'conversation_id': conversationId,
          'sender_id': currentUser.id,
          'body': body,
          'media_url': mediaUrl,
          'created_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
          'updated_at': DateTime.fromMillisecondsSinceEpoch(now * 1000).toIso8601String(),
        };
        
        await _supabase.from('messages').insert(payload);
        await _db.messageDao.markMessageAsSynced(messageId);
        
        // Trigger push notifications (don't wait for it)
        _sendPushNotification(conversationId, messageId, body).catchError((e) {
          print('⚠️ Push notification failed: $e');
        });
        
        // Trigger AI analysis for sent messages (don't wait for it)
        _triggerAIAnalysis(messageId, body).catchError((e) {
          print('⚠️ AI analysis failed: $e');
        });
      } catch (error, stackTrace) {
        // Convert to AppError
        final appError = _errorHandler.handleError(
          error, 
          stackTrace: stackTrace, 
          context: 'Send Message',
        );
        
        // If it's a network error, message is saved locally for retry
        if (_errorHandler.isNetworkError(appError)) {
          // Don't throw - message will sync later
        } else if (!appError.isRetryable) {
          // For non-retryable errors (like unauthorized), delete the local message
          await _db.messageDao.deleteMessage(messageId);
          throw appError;
        } else {
          // For other errors, throw so UI can handle
          throw appError;
        }
      }

      return message;
    } catch (error, stackTrace) {
      if (error is AppError) {
        rethrow;
      }
      throw _errorHandler.handleError(
        error, 
        stackTrace: stackTrace, 
        context: 'Send Message',
      );
    }
  }

  /// Sync messages from backend for a conversation
  Future<void> syncMessages(String conversationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw AuthError.sessionExpired();
      }

      // Fetch messages from backend ordered by created_at
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      // Save to local database with proper timestamps
      for (final msgData in response as List) {
        final createdAt = DateTime.parse(msgData['created_at'] as String);
        final updatedAt = DateTime.parse(msgData['updated_at'] as String);
        
        final message = Message(
          id: msgData['id'] as String,
          conversationId: msgData['conversation_id'] as String,
          senderId: msgData['sender_id'] as String,
          body: msgData['body'] as String,
          mediaUrl: msgData['media_url'] as String?,
          createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
          updatedAt: updatedAt.millisecondsSinceEpoch ~/ 1000,
          isSynced: true,
        );

        // Use upsert to avoid duplicates
        await _db.messageDao.upsertMessage(message);
      }
    } catch (error, stackTrace) {
      if (error is AppError) {
        rethrow;
      }
      throw _errorHandler.handleError(
        error, 
        stackTrace: stackTrace, 
        context: 'Sync Messages',
      );
    }
  }

  /// Get messages for a conversation (with optional sync)
  Future<List<Message>> getMessagesByConversation(
    String conversationId, {
    bool syncFirst = false,
  }) async {
    if (syncFirst) {
      await syncMessages(conversationId);
    }
    return _db.messageDao.getMessagesByConversation(conversationId);
  }

  /// Get recent messages for a conversation
  Future<List<Message>> getRecentMessages(String conversationId, {int limit = 50}) async {
    return _db.messageDao.getRecentMessages(conversationId, limit: limit);
  }

  /// Get message by ID
  Future<Message?> getMessageById(String id) async {
    return _db.messageDao.getMessageById(id);
  }

  /// Delete message
  /// Delete message locally only ("Delete for me")
  Future<void> deleteMessage(String id) async {
    await _db.messageDao.deleteMessage(id);
  }
  
  /// Delete message for everyone (from backend + local)
  Future<void> deleteMessageForEveryone(String id) async {
    try {
      // Delete from backend
      await _supabase
          .from('messages')
          .delete()
          .eq('id', id);
      
      // Delete locally
      await _db.messageDao.deleteMessage(id);
    } catch (e) {
      print('Error deleting message for everyone: $e');
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Send push notification for new message
  Future<void> _sendPushNotification(
    String conversationId,
    String messageId,
    String messageBody,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get sender profile for notification (use maybeSingle to handle missing profile)
      final profile = await _supabase
          .from('profiles')
          .select('username, email')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      final senderName = profile?['username'] as String? ?? 
                         profile?['email'] as String? ?? 
                         currentUser.email ?? 
                         'Someone';

      // Call push notification edge function with auth header
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) return;
      
      print('🔔 Sending push notification for message: ${messageId.substring(0, 8)}');
      final response = await _supabase.functions.invoke(
        'push_notify',
        body: {
          'message_id': messageId,
          'conversation_id': conversationId,
          'sender_id': currentUser.id,
          'sender_name': senderName,
          'title': senderName,
          'body': messageBody,
        },
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      print('✅ Push notification sent: ${response.data}');
    } catch (e) {
      print('❌ Failed to send push notification: $e');
    }
  }
  
  /// Trigger AI analysis for a message (non-blocking)
  Future<void> _triggerAIAnalysis(String messageId, String messageBody) async {
    try {
      final analysis = await _aiAnalysis.requestAnalysis(messageId, messageBody);
      if (analysis != null) {
        print('✨ AI analysis completed for ${messageId.substring(0, 8)}: ${analysis.tone}');
      }
    } catch (e) {
      print('⚠️ AI analysis failed for ${messageId.substring(0, 8)}: $e');
    }
  }
}

