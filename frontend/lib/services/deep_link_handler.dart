import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles deep linking and navigation from notifications
class DeepLinkHandler {
  final WidgetRef ref;
  final NavigatorState? navigatorState;

  DeepLinkHandler({
    required this.ref,
    this.navigatorState,
  });

  /// Handle notification tap - navigate to conversation
  Future<void> handleNotificationTap(String conversationId) async {
    try {
      // Navigate to conversation detail screen
      navigatorState?.pushNamed(
        '/conversation/$conversationId',
      );
      print('Navigated to conversation: $conversationId');
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  /// Handle initial message (app terminated)
  Future<void> handleInitialMessage(String conversationId) async {
    try {
      // Wait for app to fully initialize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate to conversation
      navigatorState?.pushNamedAndRemoveUntil(
        '/conversation/$conversationId',
        ModalRoute.withName('/conversations'),
      );
      print('Navigated from initial message to: $conversationId');
    } catch (e) {
      print('Error handling initial message: $e');
    }
  }

  /// Handle background message (app in background)
  Future<void> handleBackgroundMessage(String conversationId) async {
    try {
      // Just navigate normally
      navigatorState?.pushNamed('/conversation/$conversationId');
      print('Navigated from background message to: $conversationId');
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  /// Parse notification payload to extract conversation ID
  String? extractConversationId(Map<String, dynamic> data) {
    return data['conversation_id'] as String?;
  }

  /// Parse notification payload to extract message metadata
  Map<String, dynamic> extractMessageMetadata(Map<String, dynamic> data) {
    return {
      'conversation_id': data['conversation_id'],
      'sender_id': data['sender_id'],
      'message_id': data['message_id'],
      'sender_name': data['sender_name'],
    };
  }
}

/// Notification route arguments
class NotificationRouteArgs {
  final String conversationId;
  final String? senderId;
  final String? messageId;
  final String? senderName;

  NotificationRouteArgs({
    required this.conversationId,
    this.senderId,
    this.messageId,
    this.senderName,
  });

  factory NotificationRouteArgs.fromPayload(Map<String, dynamic> payload) {
    return NotificationRouteArgs(
      conversationId: payload['conversation_id'] as String,
      senderId: payload['sender_id'] as String?,
      messageId: payload['message_id'] as String?,
      senderName: payload['sender_name'] as String?,
    );
  }
}

/// Generate named route for conversation
String conversationRoute(String conversationId) => '/conversation/$conversationId';

/// Parse conversation ID from route
String? parseConversationIdFromRoute(String route) {
  if (route.startsWith('/conversation/')) {
    return route.replaceFirst('/conversation/', '');
  }
  return null;
}
