import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/features/auth/screens/auth_screen.dart';
import 'package:messageai/features/conversations/screens/conversations_list_screen.dart';
import 'package:messageai/features/messages/screens/message_screen.dart';
import 'package:messageai/state/providers.dart';
import 'package:messageai/services/device_registration_service.dart';
import 'package:messageai/core/theme/app_theme.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

/// Global navigator key for deep linking and navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main application widget with lifecycle monitoring
class MessageAIApp extends ConsumerStatefulWidget {
  const MessageAIApp({super.key});

  @override
  ConsumerState<MessageAIApp> createState() => _MessageAIAppState();
}

class _MessageAIAppState extends ConsumerState<MessageAIApp> with WidgetsBindingObserver {
  final _deviceRegistration = DeviceRegistrationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Update last_seen on app launch
    _updateLastSeen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - update last_seen
      _updateLastSeen();
    }
  }

  Future<void> _updateLastSeen() async {
    try {
      print('⏰ Updating device last_seen...');
      // final token = await FirebaseMessaging.instance.getToken();
      // if (token != null) {
      //   await _deviceRegistration.updateDeviceLastSeen(token);
      //   print('✅ Device last_seen updated');
      // } else {
      //   print('⚠️ No FCM token available');
      // }
    } catch (e) {
      print('❌ Failed to update last_seen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessageAI',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/auth': (_) => AuthScreen(onAuthSuccess: () {}),
        '/conversations': (_) => const ConversationsListScreen(),
      },
      // ✅ Handle dynamic routes for deep linking (e.g., /conversation/:id)
      onGenerateRoute: (settings) {
        // Handle conversation deep links
        if (settings.name?.startsWith('/conversation/') ?? false) {
          final conversationId = settings.name!.split('/').last;
          
          print('🔗 Deep link: navigating to conversation $conversationId');
          
          return MaterialPageRoute(
            builder: (_) => MessageScreen(
              conversationId: conversationId,
              conversationTitle: 'Chat', // Will be loaded by screen
            ),
            settings: settings,
          );
        }
        
        // Return null for unknown routes (will show error page)
        return null;
      },
    );
  }
}

/// Widget that routes between auth and main screens based on session
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return isAuthenticated.when(
      data: (authenticated) {
        if (authenticated) {
          return const ConversationsListScreen();
        } else {
          return AuthScreen(
            onAuthSuccess: () {
              // Refresh auth state - this will trigger a rebuild
              // ignore: unused_result
              ref.refresh(isAuthenticatedProvider);
            },
          );
        }
      },
      loading: () {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'MessageAI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}