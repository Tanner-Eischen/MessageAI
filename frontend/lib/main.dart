import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/core/env.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/data/drift/app_db.dart';
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
  
  // Run migrations (create tables if needed)
  await db.migration.onCreate(db.executor as dynamic);

  // Run the app with Riverpod provider scope
  runApp(
    const ProviderScope(
      child: MessageAIApp(),
    ),
  );
}
