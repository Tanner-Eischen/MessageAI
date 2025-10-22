import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/core/env.dart';

/// Singleton Supabase client for the application.
/// 
/// Initialize with [initializeSupabase] before accessing the client.
class SupabaseClientProvider {
  static late final Supabase _instance;

  /// Get the initialized Supabase client instance
  static Supabase get instance => _instance;

  /// Get the Supabase client for convenience
  static SupabaseClient get client => _instance.client;

  /// Initialize the Supabase client with environment config
  static Future<void> initialize() async {
    Env.validate();
    
    _instance = await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // Enable realtime
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }
}
