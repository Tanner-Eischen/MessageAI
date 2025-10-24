import 'dart:async';
import 'dart:math';
import 'package:messageai/core/errors/app_error.dart';
import 'package:messageai/core/errors/error_handler.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool useJitter;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });

  /// Aggressive retry (more attempts, faster)
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 15),
  );

  /// Conservative retry (fewer attempts, slower)
  static const conservative = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 60),
  );

  /// Default retry configuration
  static const defaultConfig = RetryConfig();
}

/// Result of a retry operation
class RetryResult<T> {
  final T? data;
  final AppError? error;
  final int attempts;
  final bool succeeded;

  RetryResult({
    this.data,
    this.error,
    required this.attempts,
    required this.succeeded,
  });

  RetryResult.success(T data, int attempts)
      : this(
          data: data,
          succeeded: true,
          attempts: attempts,
        );

  RetryResult.failure(AppError error, int attempts)
      : this(
          error: error,
          succeeded: false,
          attempts: attempts,
        );
}

/// Service for handling retries with exponential backoff
class RetryService {
  static final RetryService _instance = RetryService._internal();

  factory RetryService() {
    return _instance;
  }

  RetryService._internal();

  final _errorHandler = ErrorHandler();
  final _random = Random();

  /// Execute operation with retry logic
  Future<RetryResult<T>> execute<T>({
    required Future<T> Function() operation,
    required String operationName,
    RetryConfig config = RetryConfig.defaultConfig,
    bool Function(AppError)? shouldRetry,
  }) async {
    int attemptNumber = 0;
    AppError? lastError;

    while (attemptNumber < config.maxAttempts) {
      attemptNumber++;

      try {
        final result = await operation();
        return RetryResult.success(result, attemptNumber);
      } catch (error, stackTrace) {
        // Convert to AppError
        final appError = error is AppError
            ? error
            : _errorHandler.handleError(
                error,
                stackTrace: stackTrace,
                context: operationName,
              );

        lastError = appError;

        // Check if we should retry
        final shouldRetryThis = shouldRetry?.call(appError) ??
            _errorHandler.shouldRetry(appError, attemptNumber, maxAttempts: config.maxAttempts);

        if (!shouldRetryThis) {
          return RetryResult.failure(appError, attemptNumber);
        }

        // Calculate delay before next attempt
        if (attemptNumber < config.maxAttempts) {
          final delay = _calculateDelay(
            attemptNumber,
            config: config,
          );
          await Future.delayed(delay);
        }
      }
    }

    return RetryResult.failure(
      lastError ?? AppError(
        category: ErrorCategory.unknown,
        severity: ErrorSeverity.error,
        code: 'RETRY001',
        message: 'Max retry attempts exceeded',
        userMessage: 'Operation failed after multiple attempts',
      ),
      attemptNumber,
    );
  }

  /// Calculate delay for next retry attempt (exponential backoff with jitter)
  Duration _calculateDelay(int attemptNumber, {required RetryConfig config}) {
    // Calculate base delay: initialDelay * (backoffMultiplier ^ attemptNumber)
    final exponentialDelay = config.initialDelay.inMilliseconds *
        pow(config.backoffMultiplier, attemptNumber - 1);

    // Cap at max delay
    final cappedDelay = min(exponentialDelay, config.maxDelay.inMilliseconds.toDouble());

    // Add jitter to avoid thundering herd
    final delayWithJitter = config.useJitter
        ? _addJitter(cappedDelay.toDouble())
        : cappedDelay.toDouble();

    return Duration(milliseconds: delayWithJitter.round());
  }

  /// Add random jitter to delay (±25%)
  double _addJitter(double delay) {
    final jitterRange = delay * 0.25; // ±25%
    final jitter = (_random.nextDouble() * 2 - 1) * jitterRange;
    return delay + jitter;
  }

  /// Execute with simple retry (no configuration)
  Future<T> executeSimple<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
  }) async {
    final result = await execute(
      operation: operation,
      operationName: 'Operation',
      config: RetryConfig(maxAttempts: maxAttempts),
    );

    if (result.succeeded) {
      return result.data as T;
    } else {
      throw result.error!;
    }
  }

  /// Execute with timeout and retry
  Future<RetryResult<T>> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required String operationName,
    Duration timeout = const Duration(seconds: 30),
    RetryConfig config = RetryConfig.defaultConfig,
  }) async {
    return execute<T>(
      operation: () async {
        return await operation().timeout(
          timeout,
          onTimeout: () {
            throw AppError(
              category: ErrorCategory.network,
              severity: ErrorSeverity.warning,
              code: 'NET002',
              message: 'Operation timeout',
              userMessage: 'The operation took too long. Please try again.',
              isRetryable: true,
            );
          },
        );
      },
      operationName: operationName,
      config: config,
    );
  }
}

/// Extension to add retry capability to Future
extension RetryExtension<T> on Future<T> {
  /// Retry this future with exponential backoff
  Future<T> withRetry({
    String operationName = 'Operation',
    int maxAttempts = 3,
  }) async {
    final retryService = RetryService();
    return retryService.executeSimple(
      operation: () => this,
      maxAttempts: maxAttempts,
    );
  }

  /// Retry with full configuration
  Future<RetryResult<T>> withRetryConfig({
    required String operationName,
    RetryConfig config = RetryConfig.defaultConfig,
  }) async {
    final retryService = RetryService();
    return retryService.execute(
      operation: () => this,
      operationName: operationName,
      config: config,
    );
  }
}


