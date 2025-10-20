/// Environment configuration for Supabase connection.
/// 
/// Reads SUPABASE_URL and SUPABASE_ANON_KEY from:
/// 1. Dart defines (via --dart-define-from-file=.env.dev.json)
/// 2. Environment variables as fallback

class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // Validate that required config is present
  static void validate() {
    assert(
      supabaseUrl != 'https://your-project.supabase.co',
      'SUPABASE_URL not configured',
    );
    assert(
      supabaseAnonKey != 'your-anon-key',
      'SUPABASE_ANON_KEY not configured',
    );
  }
}
