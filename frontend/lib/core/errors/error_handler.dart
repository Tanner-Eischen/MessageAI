import 'package:messageai/core/errors/app_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global error handler service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  /// Convert any error to AppError
  AppError handleError(dynamic error, {StackTrace? stackTrace, String? context}) {
    AppError appError;

    if (error is AppError) {
      appError = error;
    } else if (error is AuthException) {
      appError = _handleAuthException(error);
    } else if (error is PostgrestException) {
      appError = _handlePostgrestException(error);
    } else if (error is StorageException) {
      appError = _handleStorageException(error);
    } else if (error is String) {
      appError = _handleStringError(error);
    } else {
      appError = _handleUnknownError(error);
    }

    // Log error
    _logError(appError, stackTrace, context);

    return appError;
  }

  /// Handle Supabase Auth exceptions
  AppError _handleAuthException(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return AuthError.invalidCredentials();
    } else if (message.contains('already registered') ||
               message.contains('already been registered')) {
      return AuthError.emailAlreadyExists();
    } else if (message.contains('password') && message.contains('weak')) {
      return AuthError.weakPassword();
    } else if (message.contains('invalid email')) {
      return AuthError.invalidEmail();
    } else if (message.contains('session') && 
               (message.contains('expired') || message.contains('invalid'))) {
      return AuthError.sessionExpired();
    } else if (message.contains('network') || 
               message.contains('connection') ||
               message.contains('timeout')) {
      return AuthError.networkError();
    } else {
      return AuthError.unknown(error);
    }
  }

  /// Handle Supabase Postgrest (database) exceptions
  AppError _handlePostgrestException(PostgrestException error) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    // RLS policy violations
    if (code.contains('42501') || message.contains('permission denied')) {
      return MessageError.unauthorized();
    }

    // Foreign key violations
    if (code.contains('23503') || message.contains('foreign key')) {
      return MessageError.conversationNotFound();
    }

    // Network errors
    if (message.contains('network') || 
        message.contains('timeout') ||
        message.contains('connection')) {
      return NetworkError.noConnection();
    }

    // Server errors
    if (code.startsWith('5')) {
      return NetworkError.serverError();
    }

    // Generic database error
    return DatabaseError.queryFailed();
  }

  /// Handle Supabase Storage exceptions
  AppError _handleStorageException(StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('size') || message.contains('too large')) {
      return StorageError.fileTooLarge();
    } else if (message.contains('format') || 
               message.contains('type') ||
               message.contains('invalid file')) {
      return StorageError.unsupportedFormat();
    } else {
      return StorageError.uploadFailed();
    }
  }

  /// Handle string errors (thrown as strings)
  AppError _handleStringError(String error) {
    final message = error.toLowerCase();

    // Auth errors
    if (message.contains('sign in') || message.contains('sign up')) {
      if (message.contains('failed')) {
        return AuthError.unknown(error);
      }
    }

    // Message errors
    if (message.contains('message')) {
      if (message.contains('failed') || message.contains('error')) {
        return MessageError.sendFailed();
      }
    }

    // Network errors
    if (message.contains('network') || 
        message.contains('connection') ||
        message.contains('offline') ||
        message.contains('internet')) {
      return NetworkError.noConnection();
    }

    // Generic error
    return AppError(
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.error,
      code: 'UNK001',
      message: error,
      userMessage: 'Something went wrong. Please try again.',
      isRetryable: true,
    );
  }

  /// Handle unknown errors
  AppError _handleUnknownError(dynamic error) {
    return AppError(
      category: ErrorCategory.unknown,
      severity: ErrorSeverity.error,
      code: 'UNK999',
      message: error.toString(),
      userMessage: 'An unexpected error occurred. Please try again.',
      originalError: error,
      isRetryable: true,
    );
  }

  /// Log error for debugging
  void _logError(AppError error, StackTrace? stackTrace, String? context) {
    // Only log critical errors and non-retryable errors
    if (error.severity == ErrorSeverity.critical || !error.isRetryable) {
      final emoji = _getEmojiForSeverity(error.severity);
      print('$emoji ${error.code}: ${error.userMessage ?? error.message}');
    }
  }

  /// Get emoji for severity level
  String _getEmojiForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'ℹ️';
      case ErrorSeverity.warning:
        return '⚠️';
      case ErrorSeverity.error:
        return '❌';
      case ErrorSeverity.critical:
        return '🚨';
    }
  }

  /// Check if error is network-related
  bool isNetworkError(AppError error) {
    return error.category == ErrorCategory.network ||
           (error.category == ErrorCategory.auth && error.code == 'AUTH006') ||
           (error.category == ErrorCategory.messaging && error.code == 'MSG002');
  }

  /// Check if error should trigger offline mode
  bool shouldGoOffline(AppError error) {
    return error.category == ErrorCategory.network &&
           error.code == 'NET001';
  }

  /// Get retry delay based on attempt number (exponential backoff)
  Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delaySeconds = (1 << (attemptNumber - 1)).clamp(1, 16);
    return Duration(seconds: delaySeconds);
  }

  /// Check if should retry based on attempt count
  bool shouldRetry(AppError error, int attemptNumber, {int maxAttempts = 3}) {
    return error.isRetryable && attemptNumber < maxAttempts;
  }
}

/// Extension to add error handling to Future
extension FutureErrorHandler<T> on Future<T> {
  /// Handle errors and convert to AppError
  Future<T> handleAppError({String? context}) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      throw ErrorHandler().handleError(error, stackTrace: stackTrace, context: context);
    }
  }
}


