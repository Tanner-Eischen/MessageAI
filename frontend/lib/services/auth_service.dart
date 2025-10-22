import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final _supabase = SupabaseClientProvider.client;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw 'Sign up failed: ${e.message}';
    } catch (e) {
      throw 'Sign up failed: ${e.toString()}';
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw 'Sign in failed: ${e.message}';
    } catch (e) {
      throw 'Sign in failed: ${e.toString()}';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }
}
