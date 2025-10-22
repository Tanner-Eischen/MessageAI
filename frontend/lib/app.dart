import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/features/auth/screens/auth_screen.dart';
import 'package:messageai/features/conversations/screens/conversations_list_screen.dart';
import 'package:messageai/state/providers.dart';

/// Main application widget
class MessageAIApp extends ConsumerWidget {
  const MessageAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Darker burnt yellow/orange primary
    const slateBlue = Color(0xFF475569); // Slate grey-blue
    const darkSlate = Color(0xFF334155); // Darker slate
    const lightSlate = Color(0xFF64748b); // Lighter slate
    const burntOrange = Color(0x99C77506); // Darker burnt orange with transparency (60% opacity)
    const burntOrangeSolid = Color(0xFFC77506); // Solid burnt orange for seeding
    const lightBurntOrange = Color(0x4DC77506); // Very transparent burnt orange (30% opacity)
    const mediumBurntOrange = Color(0x80C77506); // Medium transparent (50% opacity)
    
    return MaterialApp(
      title: 'MessageAI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: burntOrangeSolid,
          primary: burntOrange,
          secondary: burntOrange, // Same as primary now
          brightness: Brightness.light,
        ).copyWith(
          primaryContainer: lightBurntOrange,
          secondaryContainer: lightBurntOrange,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: burntOrangeSolid,
          primary: burntOrange,
          secondary: burntOrange, // Same as primary now
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1e293b), // Dark slate
          surfaceContainer: const Color(0xFF334155),
          primaryContainer: mediumBurntOrange, // Medium transparent burnt orange (50% opacity)
          secondaryContainer: mediumBurntOrange,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: burntOrange,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      routes: {
        '/auth': (_) => AuthScreen(onAuthSuccess: () {}),
        '/conversations': (_) => const ConversationsListScreen(),
      },
    );
  }
}

/// Widget that routes between auth and main screens based on session
class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

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
