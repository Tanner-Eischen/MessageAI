import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/core/env.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/state/notification_providers.dart';
import 'package:messageai/app.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Validate environment configuration
  Env.validate();

  // Initialize Supabase client
  await SupabaseClientProvider.initialize();

  // Initialize Drift database
  final db = AppDb.instance;
  
  // Run the app with Riverpod provider scope
  runApp(
    ProviderScope(
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
    ref.watch(notificationInitializerProvider);

    return const MessageAIApp();
  }
}
