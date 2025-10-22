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
    // Blueish slate grey with burnt yellow accents
    const slateBlue = Color(0xFF475569); // Slate grey-blue
    const darkSlate = Color(0xFF334155); // Darker slate
    const lightSlate = Color(0xFF64748b); // Lighter slate
    const burntYellow = Color(0xFFD97706); // Burnt yellow/amber
    const accentYellow = Color(0xFFF59E0B); // Brighter yellow accent
    
    return MaterialApp(
      title: 'MessageAI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: slateBlue,
          primary: slateBlue,
          secondary: burntYellow,
          brightness: Brightness.light,
        ).copyWith(
          primaryContainer: lightSlate,
          secondaryContainer: const Color(0xFFFEF3C7), // Light yellow
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSlate,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: burntYellow,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: slateBlue,
          primary: slateBlue,
          secondary: burntYellow,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1e293b), // Dark slate
          surfaceContainer: const Color(0xFF334155),
          primaryContainer: darkSlate,
          secondaryContainer: const Color(0xFF92400E), // Dark burnt yellow
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1e293b),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: burntYellow,
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
