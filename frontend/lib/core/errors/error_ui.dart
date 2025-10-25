import 'package:flutter/material.dart';
import 'package:messageai/core/errors/app_error.dart';

/// UI utilities for displaying errors to users
class ErrorUI {
  /// Show error as snackbar (for non-critical errors)
  static void showErrorSnackbar(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIconForError(error),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.displayMessage,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: _getColorForSeverity(error.severity),
      behavior: SnackBarBehavior.floating,
      action: error.isRetryable && onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: Duration(
        seconds: error.severity == ErrorSeverity.critical ? 6 : 4,
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  /// Show error as dialog (for critical errors or when user action required)
  static Future<bool?> showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    String? actionLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          _getIconForError(error),
          color: _getColorForSeverity(error.severity),
          size: 48,
        ),
        title: Text(_getTitleForError(error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.displayMessage),
            if (error.code.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Error Code: ${error.code}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!error.requiresUserAction)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Dismiss'),
            ),
          if (error.isRetryable && onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRetry();
              },
              child: Text(actionLabel ?? 'Retry'),
            ),
          if (!error.isRetryable || onRetry == null)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  /// Show permission error with option to open settings
  static Future<void> showPermissionError(
    BuildContext context,
    PermissionError error,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.security,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Permission Required'),
        content: Text(error.displayMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Open app settings
              // OpenSettings.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show loading indicator with cancellation
  static Future<T?> showLoadingDialog<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String message = 'Loading...',
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      ),
    );

    try {
      final result = await action();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return result;
    } catch (error) {
      if (context.mounted) {
        Navigator.of(context).pop();
        if (error is AppError) {
          showErrorDialog(context, error);
        }
      }
      return null;
    }
  }

  /// Get icon for error
  static IconData _getIconForError(AppError error) {
    switch (error.category) {
      case ErrorCategory.auth:
        return Icons.lock_outline;
      case ErrorCategory.network:
        return Icons.wifi_off;
      case ErrorCategory.database:
        return Icons.storage_outlined;
      case ErrorCategory.messaging:
        return Icons.message_outlined;
      case ErrorCategory.storage:
        return Icons.cloud_upload_outlined;
      case ErrorCategory.permission:
        return Icons.security;
      case ErrorCategory.validation:
        return Icons.error_outline;
      case ErrorCategory.unknown:
        return Icons.warning_amber;
    }
  }

  /// Get color for severity
  static Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  /// Get title for error dialog
  static String _getTitleForError(AppError error) {
    switch (error.category) {
      case ErrorCategory.auth:
        return 'Authentication Error';
      case ErrorCategory.network:
        return 'Connection Problem';
      case ErrorCategory.database:
        return 'Data Error';
      case ErrorCategory.messaging:
        return 'Message Error';
      case ErrorCategory.storage:
        return 'Upload Error';
      case ErrorCategory.permission:
        return 'Permission Required';
      case ErrorCategory.validation:
        return 'Invalid Input';
      case ErrorCategory.unknown:
        return 'Error';
    }
  }
}

/// Mixin for widgets that need error handling
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  /// Show error to user
  void showError(AppError error, {VoidCallback? onRetry}) {
    if (!mounted) return;

    if (error.severity == ErrorSeverity.critical || error.requiresUserAction) {
      ErrorUI.showErrorDialog(context, error, onRetry: onRetry);
    } else {
      ErrorUI.showErrorSnackbar(context, error, onRetry: onRetry);
    }
  }

  /// Handle error from async operation
  Future<T?> handleAsyncError<T>(
    Future<T> Function() operation, {
    String? context,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } on AppError catch (error) {
      showError(error, onRetry: onRetry);
      return null;
    } catch (error) {
      final appError = AppError(
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.error,
        code: 'UNK001',
        message: error.toString(),
        userMessage: 'An unexpected error occurred.',
      );
      showError(appError, onRetry: onRetry);
      return null;
    }
  }
}



