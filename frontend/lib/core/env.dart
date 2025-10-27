/// Environment configuration for Supabase connection.
/// 
/// Reads SUPABASE_URL and SUPABASE_ANON_KEY from dart-define
/// Pass your .env.dev.json file when running:
///   flutter run --dart-define-from-file=.env.dev.json
library;

class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Validate that required config is present
  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print('⚠️ ════════════════════════════════════════════════════════════');
      print('⚠️  SUPABASE NOT CONFIGURED!');
      print('⚠️  Run with: flutter run --dart-define-from-file=.env.dev.json');
      print('⚠️  Or ensure .env.dev.json has SUPABASE_URL and SUPABASE_ANON_KEY');
      print('⚠️ ════════════════════════════════════════════════════════════');
    } else {
      print('✅ Connected to Supabase: $supabaseUrl');
    }
  }
}
