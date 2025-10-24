import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/services/notification_service.dart';
import 'package:messageai/services/local_notification_service.dart';
import 'package:messageai/services/deep_link_handler.dart';
import 'package:messageai/services/device_registration_service.dart';
import 'package:messageai/app.dart' show navigatorKey;

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

/// Device registration service provider
final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService>((ref) {
  return DeviceRegistrationService();
});

/// Initialize notifications (Firebase + Local)
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  print('📢 ========================================');
  print('📢 STARTING NOTIFICATION INITIALIZATION');
  print('📢 ========================================');
  
  final fcmService = ref.watch(notificationServiceProvider);
  final localService = ref.watch(localNotificationServiceProvider);
  final deviceRegistrationService = ref.watch(deviceRegistrationServiceProvider);

  print('📱 Initializing local notifications...');
  // Initialize local notifications first
  await localService.initialize();
  print('✅ Local notifications initialized');

  print('🔥 Initializing Firebase Messaging...');
  // Initialize Firebase Messaging
  await fcmService.initialize(
    onMessageReceived: (payload) {
      // Handle foreground message
      _handleForegroundMessage(ref, payload, localService);
    },
    onTokenRefresh: (token) async {
      // Update device token state
      ref.read(deviceTokenProvider.notifier).state = token;
      print('🔄 Device token refreshed: ${token.substring(0, 20)}...');
      
      // Register refreshed token with backend
      try {
        await deviceRegistrationService.registerDeviceToken(token);
        print('✅ Refreshed token registered with backend');
      } catch (e) {
        print('❌ Failed to register refreshed token: $e');
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
      await deviceRegistrationService.registerDeviceToken(token);
      print('✅ Initial token registered with backend');
    } catch (e) {
      print('❌ Failed to register initial token: $e');
      // Don't fail initialization if registration fails
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

/// Handle notification tap
void _handleNotificationTap(Ref ref, String conversationId) {
  print('📱 Notification tapped: $conversationId');
  
  try {
    // Use the global navigator key to navigate
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      print('❌ Navigator not available');
      return;
    }
    
    // Navigate to conversation detail screen
    navigator.pushNamed(
      '/conversation/$conversationId',
      arguments: {'title': 'Conversation'},
    );
    
    print('✅ Navigated to conversation: $conversationId');
  } catch (e) {
    print('❌ Error navigating to conversation: $e');
  }
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
