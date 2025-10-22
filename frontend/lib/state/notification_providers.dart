import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/services/notification_service.dart';
import 'package:messageai/services/local_notification_service.dart';
import 'package:messageai/services/deep_link_handler.dart';
import 'package:messageai/services/device_token_service.dart';

/// Device token state
final deviceTokenProvider = StateProvider<String?>((ref) {
  return null;
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Local notification service provider
final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

/// Device token service provider
final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService();
});

/// Initialize notifications (Firebase + Local)
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  final fcmService = ref.watch(notificationServiceProvider);
  final localService = ref.watch(localNotificationServiceProvider);
  final deviceTokenService = ref.watch(deviceTokenServiceProvider);

  // Initialize local notifications first
  await localService.initialize();

  // Initialize Firebase Messaging
  await fcmService.initialize(
    onMessageReceived: (payload) {
      // Handle foreground message
      _handleForegroundMessage(ref, payload, localService);
    },
    onTokenRefresh: (token) async {
      // Update device token in state
      ref.read(deviceTokenProvider.notifier).state = token;
      print('Device token updated: $token');

      // Register token with backend
      try {
        await deviceTokenService.registerDeviceToken(token);
      } catch (e) {
        print('Failed to register refreshed token: $e');
      }
    },
  );

  // Setup notification tap handler
  await fcmService.setupNotificationTapHandler(
    onNotificationTapped: (conversationId) {
      _handleNotificationTap(ref, conversationId);
    },
  );

  // Get initial device token
  final token = await fcmService.getDeviceToken();
  if (token != null) {
    ref.read(deviceTokenProvider.notifier).state = token;

    // Register token with backend
    try {
      await deviceTokenService.registerDeviceToken(token);
      print('Device token registered with backend');
    } catch (e) {
      print('Failed to register initial token: $e');
    }
  }

  print('Notifications initialized successfully');
});

/// Handle foreground notification message
void _handleForegroundMessage(
  Ref ref,
  NotificationPayload payload,
  LocalNotificationService localService,
) async {
  try {
    final conversationId = payload.conversationId;
    final senderName = payload.data['sender_name'] as String? ?? 'New Message';
    final messageBody = payload.messageBody ?? payload.body ?? '';

    if (conversationId != null && messageBody.isNotEmpty) {
      await localService.showMessageNotification(
        conversationId: conversationId,
        senderName: senderName,
        messageBody: messageBody,
      );
    }
  } catch (e) {
    print('Error handling foreground message: $e');
  }
}

/// Notification tap state - used to trigger navigation from UI
final notificationTapProvider = StateProvider<String?>((ref) => null);

/// Handle notification tap
void _handleNotificationTap(Ref ref, String conversationId) {
  print('Notification tapped: $conversationId');
  // Update state to trigger navigation from UI layer
  ref.read(notificationTapProvider.notifier).state = conversationId;
}

/// Notification permission state
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final fcmService = ref.watch(notificationServiceProvider);
  return fcmService.areNotificationsEnabled();
});

/// Subscribe to conversation topic for group notifications
final subscribeToConversationTopicProvider = FutureProvider.autoDispose
    .family<void, String>((ref, conversationId) async {
  final fcmService = ref.watch(notificationServiceProvider);
  await fcmService.subscribeToTopic('conversation_$conversationId');
});

/// Unsubscribe from conversation topic
final unsubscribeFromConversationTopicProvider = FutureProvider.autoDispose
    .family<void, String>((ref, conversationId) async {
  final fcmService = ref.watch(notificationServiceProvider);
  await fcmService.unsubscribeFromTopic('conversation_$conversationId');
});

/// Subscribe to user topic for direct messages
final subscribeToUserTopicProvider = FutureProvider<void>((ref) async {
  final fcmService = ref.watch(notificationServiceProvider);
  // Subscribe to user's personal notification topic
  // (would use current user ID in real app)
  await fcmService.subscribeToTopic('user_direct_messages');
});

/// Notification state for UI
final notificationStateProvider = StateProvider<NotificationState>((ref) {
  return const NotificationState();
});

/// Notification state model
class NotificationState {
  final bool isInitialized;
  final bool hasPermission;
  final String? deviceToken;
  final int unreadCount;
  final List<String> subscribedTopics;

  const NotificationState({
    this.isInitialized = false,
    this.hasPermission = false,
    this.deviceToken,
    this.unreadCount = 0,
    this.subscribedTopics = const [],
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? hasPermission,
    String? deviceToken,
    int? unreadCount,
    List<String>? subscribedTopics,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      deviceToken: deviceToken ?? this.deviceToken,
      unreadCount: unreadCount ?? this.unreadCount,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
    );
  }
}

/// Initialize notification system
final notificationInitializerProvider = FutureProvider<void>((ref) async {
  try {
    // Initialize notifications
    await ref.watch(initializeNotificationsProvider.future);

    // Check permissions
    final hasPermission = await ref.watch(notificationPermissionProvider.future);

    // Get device token
    final deviceToken = ref.watch(deviceTokenProvider);

    // Update state
    ref.read(notificationStateProvider.notifier).state =
        ref.read(notificationStateProvider).copyWith(
          isInitialized: true,
          hasPermission: hasPermission,
          deviceToken: deviceToken,
        );

    print('Notification system initialized');
  } catch (e) {
    print('Error initializing notification system: $e');
    rethrow;
  }
});
