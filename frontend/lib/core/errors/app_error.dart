/// Application error types and models
/// Provides structured error handling across the app

/// Error categories for classification
enum ErrorCategory {
  auth,
  network,
  database,
  messaging,
  storage,
  permission,
  validation,
  unknown,
}

/// Error severity levels
enum ErrorSeverity {
  info,     // Informational, no action required
  warning,  // Warning, user should be aware
  error,    // Error, user action may help
  critical, // Critical, likely requires app restart or support
}

/// Structured application error
class AppError implements Exception {
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String code;
  final String message;
  final String? userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final bool isRetryable;

  const AppError({
    required this.category,
    required this.severity,
    required this.code,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
    this.context,
    this.isRetryable = false,
  });

  /// Get user-friendly error message
  String get displayMessage => userMessage ?? message;

  /// Check if error requires user action
  bool get requiresUserAction => 
      severity == ErrorSeverity.error || 
      severity == ErrorSeverity.critical;

  @override
  String toString() {
    return 'AppError($category.$code): $message';
  }

  /// Copy with modifications
  AppError copyWith({
    ErrorCategory? category,
    ErrorSeverity? severity,
    String? code,
    String? message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    bool? isRetryable,
  }) {
    return AppError(
      category: category ?? this.category,
      severity: severity ?? this.severity,
      code: code ?? this.code,
      message: message ?? this.message,
      userMessage: userMessage ?? this.userMessage,
      originalError: originalError ?? this.originalError,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }
}

/// Authentication errors
class AuthError extends AppError {
  AuthError({
    required String code,
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
    bool isRetryable = false,
  }) : super(
          category: ErrorCategory.auth,
          severity: ErrorSeverity.error,
          code: code,
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );

  factory AuthError.invalidCredentials() => AuthError(
        code: 'AUTH001',
        message: 'Invalid email or password',
        userMessage: 'The email or password you entered is incorrect. Please try again.',
      );

  factory AuthError.emailAlreadyExists() => AuthError(
        code: 'AUTH002',
        message: 'Email already registered',
        userMessage: 'An account with this email already exists. Try signing in instead.',
      );

  factory AuthError.weakPassword() => AuthError(
        code: 'AUTH003',
        message: 'Password too weak',
        userMessage: 'Please choose a stronger password (at least 6 characters).',
      );

  factory AuthError.invalidEmail() => AuthError(
        code: 'AUTH004',
        message: 'Invalid email format',
        userMessage: 'Please enter a valid email address.',
      );

  factory AuthError.sessionExpired() => AuthError(
        code: 'AUTH005',
        message: 'Session expired',
        userMessage: 'Your session has expired. Please sign in again.',
      );

  factory AuthError.networkError() => AuthError(
        code: 'AUTH006',
        message: 'Network error during authentication',
        userMessage: 'Unable to connect. Please check your internet connection and try again.',
        isRetryable: true,
      );

  factory AuthError.unknown(dynamic error) => AuthError(
        code: 'AUTH999',
        message: 'Unknown authentication error',
        userMessage: 'Something went wrong during authentication. Please try again.',
        originalError: error,
        isRetryable: true,
      );
}

/// Network errors
class NetworkError extends AppError {
  NetworkError({
    required String code,
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          category: ErrorCategory.network,
          severity: ErrorSeverity.warning,
          code: code,
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: true,
        );

  factory NetworkError.noConnection() => NetworkError(
        code: 'NET001',
        message: 'No internet connection',
        userMessage: 'No internet connection. Please check your network settings.',
      );

  factory NetworkError.timeout() => NetworkError(
        code: 'NET002',
        message: 'Request timeout',
        userMessage: 'The request took too long. Please try again.',
      );

  factory NetworkError.serverError() => NetworkError(
        code: 'NET003',
        message: 'Server error',
        userMessage: 'Server is temporarily unavailable. Please try again later.',
      );
}

/// Message sending errors
class MessageError extends AppError {
  MessageError({
    required String code,
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
    bool isRetryable = true,
  }) : super(
          category: ErrorCategory.messaging,
          severity: ErrorSeverity.error,
          code: code,
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );

  factory MessageError.sendFailed() => MessageError(
        code: 'MSG001',
        message: 'Failed to send message',
        userMessage: 'Unable to send message. Please try again.',
      );

  factory MessageError.networkError() => MessageError(
        code: 'MSG002',
        message: 'Network error while sending message',
        userMessage: 'Message saved offline. It will send when you\'re back online.',
      );

  factory MessageError.unauthorized() => MessageError(
        code: 'MSG003',
        message: 'Not authorized to send message',
        userMessage: 'You don\'t have permission to send messages to this conversation.',
        isRetryable: false,
      );

  factory MessageError.conversationNotFound() => MessageError(
        code: 'MSG004',
        message: 'Conversation not found',
        userMessage: 'This conversation no longer exists.',
        isRetryable: false,
      );

  factory MessageError.mediaTooLarge() => MessageError(
        code: 'MSG005',
        message: 'Media file too large',
        userMessage: 'The image is too large. Please choose a smaller file.',
        isRetryable: false,
      );

  factory MessageError.mediaUploadFailed() => MessageError(
        code: 'MSG006',
        message: 'Failed to upload media',
        userMessage: 'Unable to upload image. Please try again.',
      );
}

/// Storage errors
class StorageError extends AppError {
  StorageError({
    required String code,
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
    bool isRetryable = true,
  }) : super(
          category: ErrorCategory.storage,
          severity: ErrorSeverity.error,
          code: code,
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );

  factory StorageError.uploadFailed() => StorageError(
        code: 'STR001',
        message: 'Upload failed',
        userMessage: 'Unable to upload file. Please try again.',
      );

  factory StorageError.fileTooLarge() => StorageError(
        code: 'STR002',
        message: 'File too large',
        userMessage: 'The file is too large. Maximum size is 10MB.',
        isRetryable: false,
      );

  factory StorageError.unsupportedFormat() => StorageError(
        code: 'STR003',
        message: 'Unsupported file format',
        userMessage: 'This file type is not supported. Please use JPG, PNG, or GIF.',
        isRetryable: false,
      );
}

/// Database errors
class DatabaseError extends AppError {
  DatabaseError({
    required String code,
    required String message,
    String? userMessage,
    dynamic originalError,
    StackTrace? stackTrace,
    bool isRetryable = true,
  }) : super(
          category: ErrorCategory.database,
          severity: ErrorSeverity.error,
          code: code,
          message: message,
          userMessage: userMessage,
          originalError: originalError,
          stackTrace: stackTrace,
          isRetryable: isRetryable,
        );

  factory DatabaseError.queryFailed() => DatabaseError(
        code: 'DB001',
        message: 'Database query failed',
        userMessage: 'Unable to fetch data. Please try again.',
      );

  factory DatabaseError.syncFailed() => DatabaseError(
        code: 'DB002',
        message: 'Sync failed',
        userMessage: 'Unable to sync data. Your changes are saved locally.',
      );
}

/// Permission errors
class PermissionError extends AppError {
  PermissionError({
    required String code,
    required String message,
    String? userMessage,
    bool isRetryable = false,
  }) : super(
          category: ErrorCategory.permission,
          severity: ErrorSeverity.warning,
          code: code,
          message: message,
          userMessage: userMessage,
          isRetryable: isRetryable,
        );

  factory PermissionError.cameraNotGranted() => PermissionError(
        code: 'PERM001',
        message: 'Camera permission not granted',
        userMessage: 'Camera access is required. Please enable it in Settings.',
      );

  factory PermissionError.storageNotGranted() => PermissionError(
        code: 'PERM002',
        message: 'Storage permission not granted',
        userMessage: 'Storage access is required. Please enable it in Settings.',
      );

  factory PermissionError.notificationsNotGranted() => PermissionError(
        code: 'PERM003',
        message: 'Notification permission not granted',
        userMessage: 'Enable notifications to receive message alerts.',
      );
}



