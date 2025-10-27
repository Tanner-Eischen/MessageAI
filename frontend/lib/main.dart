import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messageai/core/env.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/state/notification_providers.dart';
import 'package:messageai/services/network_connectivity_service.dart';
import 'package:messageai/services/offline_queue_service.dart';
import 'package:messageai/app.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler for Firebase Cloud Messaging
/// This MUST be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  print('🔔 Background message received!');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Handle the background message here if needed
  // For now, just log it - the system notification will still appear
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required before any Firebase services)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Register background message handler (must be done after Firebase init)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  // Validate environment configuration
  Env.validate();

  // Initialize Supabase client
  await SupabaseClientProvider.initialize();

  // Initialize Drift database
  final db = AppDb.instance;
  
  // Initialize network services
  final connectivityService = NetworkConnectivityService();
  connectivityService.startMonitoring();
  
  final offlineQueueService = OfflineQueueService();
  offlineQueueService.startMonitoring();
  
  print('✅ Network services initialized');
  
  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: _AppWithNotifications(),
    ),
  );
}

/// Wrapper widget to initialize notifications after ProviderScope
class _AppWithNotifications extends ConsumerWidget {
  const _AppWithNotifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notifications on app start
    final notificationInit = ref.watch(notificationInitializerProvider);
    
    notificationInit.when(
      data: (_) {
        print('🔔 Notifications fully initialized!');
      },
      loading: () {
        print('🔄 Initializing notifications...');
      },
      error: (error, stack) {
        print('❌ Notification initialization error: $error');
        print('Stack trace: $stack');
      },
    );

    return const MessageAIApp();
  }
}
