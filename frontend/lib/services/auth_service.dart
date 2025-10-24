import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/services/device_registration_service.dart';
import 'package:messageai/services/notification_service.dart';
import 'package:messageai/core/errors/error_handler.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final _supabase = SupabaseClientProvider.client;
  final _deviceRegistrationService = DeviceRegistrationService();
  final _notificationService = NotificationService();
  final _errorHandler = ErrorHandler();

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Attempting sign up for: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      print('✅ Sign up successful: ${response.user?.id}');
      return response;
    } catch (error, stackTrace) {
      print('❌ Sign up failed: $error');
      throw _errorHandler.handleError(error, stackTrace: stackTrace, context: 'Sign Up');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting sign in for: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful: ${response.user?.id}');
      return response;
    } catch (error, stackTrace) {
      print('❌ Sign in failed: $error');
      throw _errorHandler.handleError(error, stackTrace: stackTrace, context: 'Sign In');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      print('👋 Attempting sign out');
      
      // Unregister device token before signing out
      final token = await _notificationService.getDeviceToken();
      if (token != null) {
        try {
          await _deviceRegistrationService.unregisterDeviceToken(token);
          print('✅ Device token unregistered on sign out');
        } catch (e) {
          print('⚠️  Failed to unregister device token: $e');
          // Continue with sign out even if unregistration fails
        }
      }
      
      await _supabase.auth.signOut();
      print('✅ Sign out successful');
    } catch (error, stackTrace) {
      print('❌ Sign out failed: $error');
      throw _errorHandler.handleError(error, stackTrace: stackTrace, context: 'Sign Out');
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
