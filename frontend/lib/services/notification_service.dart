import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification payload model
class NotificationPayload {
  final String? title;
  final String? body;
  final Map<String, dynamic> data;
  final String? messageId;

  NotificationPayload({
    this.title,
    this.body,
    required this.data,
    this.messageId,
  });

  /// Extract conversation ID from payload
  String? get conversationId => data['conversation_id'] as String?;

  /// Extract sender ID from payload
  String? get senderId => data['sender_id'] as String?;

  /// Extract message ID from payload
  String? get messageIdFromPayload => data['message_id'] as String?;

  /// Extract message body from payload
  String? get messageBody => data['message_body'] as String?;
}

/// Firebase Cloud Messaging service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static const String _channelId = 'messages';
  static const String _channelName = 'Message Notifications';

  /// Initialize Firebase Messaging
  Future<void> initialize({
    required Function(NotificationPayload) onMessageReceived,
    required Function(String) onTokenRefresh,
  }) async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carryForward: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted notification permission: ${settings.authorizationStatus}');

      // Get initial token
      final token = await getDeviceToken();
      print('FCM Token: $token');

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        onTokenRefresh(newToken);
      });

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        final payload = NotificationPayload(
          title: message.notification?.title,
          body: message.notification?.body,
          data: message.data,
          messageId: message.messageId,
        );

        onMessageReceived(payload);
      });

      // Handle background message (top-level function)
      // This should be registered before the app starts
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  /// Get device token for sending notifications
  Future<String?> getDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('Error checking notification settings: $e');
      return false;
    }
  }

  /// Handle notification tap
  Future<void> setupNotificationTapHandler({
    required Function(String) onNotificationTapped,
  }) async {
    try {
      // When the app is in foreground and user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification tapped: ${message.data}');
        final conversationId = message.data['conversation_id'] as String?;
        if (conversationId != null) {
          onNotificationTapped(conversationId);
        }
      });

      // Check if app was opened from a notification when app was terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.data}');
        final conversationId = initialMessage.data['conversation_id'] as String?;
        if (conversationId != null) {
          onNotificationTapped(conversationId);
        }
      }
    } catch (e) {
      print('Error setting up notification tap handler: $e');
    }
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Store device token
final deviceTokenProvider = StateProvider<String?>((ref) {
  return null;
});

/// Handle notification reception
final notificationHandlerProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  
  // This would be called after the service is initialized
  // Placeholder for notification setup
});
