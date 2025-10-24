import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';

/// Diagnostic information about a Realtime channel
class RealtimeChannelDiagnostics {
  final String channelName;
  final String status;
  final DateTime subscribedAt;
  final DateTime? lastMessageAt;
  final int messagesReceived;
  final List<String> errors;
  final Duration? latency;

  RealtimeChannelDiagnostics({
    required this.channelName,
    required this.status,
    required this.subscribedAt,
    this.lastMessageAt,
    this.messagesReceived = 0,
    this.errors = const [],
    this.latency,
  });

  bool get isHealthy => status == 'SUBSCRIBED' && errors.isEmpty;
  
  Duration get timeSinceLastMessage => 
      lastMessageAt != null 
          ? DateTime.now().difference(lastMessageAt!)
          : Duration.zero;
}

/// Service for diagnosing and monitoring Realtime connections
class RealtimeDiagnosticService {
  static final RealtimeDiagnosticService _instance =
      RealtimeDiagnosticService._internal();

  factory RealtimeDiagnosticService() {
    return _instance;
  }

  RealtimeDiagnosticService._internal();

  final _supabase = SupabaseClientProvider.client;
  final Map<String, RealtimeChannelDiagnostics> _channelDiagnostics = {};
  final Map<String, DateTime> _messageTimestamps = {};
  Timer? _healthCheckTimer;
  bool _isMonitoring = false;

  /// Start monitoring Realtime health
  void startMonitoring({Duration checkInterval = const Duration(seconds: 5)}) {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;
    _healthCheckTimer = Timer.periodic(checkInterval, (_) {
      _performHealthCheck();
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _isMonitoring = false;
  }

  /// Register a channel for monitoring
  void registerChannel(String channelName, RealtimeChannel channel) {
    _channelDiagnostics[channelName] = RealtimeChannelDiagnostics(
      channelName: channelName,
      status: 'SUBSCRIBING',
      subscribedAt: DateTime.now(),
    );
  }

  /// Update channel status
  void updateChannelStatus(String channelName, String status) {
    final current = _channelDiagnostics[channelName];
    if (current != null) {
      _channelDiagnostics[channelName] = RealtimeChannelDiagnostics(
        channelName: channelName,
        status: status,
        subscribedAt: current.subscribedAt,
        lastMessageAt: current.lastMessageAt,
        messagesReceived: current.messagesReceived,
        errors: current.errors,
        latency: current.latency,
      );
    }
  }

  /// Record message received
  void recordMessageReceived(String channelName) {
    final current = _channelDiagnostics[channelName];
    if (current != null) {
      final now = DateTime.now();
      
      // Calculate latency if we have a timestamp
      Duration? latency;
      if (_messageTimestamps.containsKey(channelName)) {
        latency = now.difference(_messageTimestamps[channelName]!);
      }

      _channelDiagnostics[channelName] = RealtimeChannelDiagnostics(
        channelName: channelName,
        status: current.status,
        subscribedAt: current.subscribedAt,
        lastMessageAt: now,
        messagesReceived: current.messagesReceived + 1,
        errors: current.errors,
        latency: latency,
      );
    }
  }

  /// Record error
  void recordError(String channelName, String error) {
    final current = _channelDiagnostics[channelName];
    if (current != null) {
      final newErrors = List<String>.from(current.errors)..add(error);
      
      _channelDiagnostics[channelName] = RealtimeChannelDiagnostics(
        channelName: channelName,
        status: current.status,
        subscribedAt: current.subscribedAt,
        lastMessageAt: current.lastMessageAt,
        messagesReceived: current.messagesReceived,
        errors: newErrors,
        latency: current.latency,
      );

      print('❌ Error on $channelName: $error');
    }
  }

  /// Mark message send timestamp (for latency calculation)
  void markMessageSent(String channelName) {
    _messageTimestamps[channelName] = DateTime.now();
  }

  /// Perform health check on all channels
  void _performHealthCheck() {
    print('🏥 Realtime Health Check');
    print('━' * 60);

    if (_channelDiagnostics.isEmpty) {
      print('   No active channels');
      return;
    }

    for (final entry in _channelDiagnostics.entries) {
      final channel = entry.key;
      final diag = entry.value;

      final healthEmoji = diag.isHealthy ? '✅' : '⚠️';
      final statusEmoji = _getStatusEmoji(diag.status);

      print('$healthEmoji $channel');
      print('   $statusEmoji Status: ${diag.status}');
      print('   📊 Messages: ${diag.messagesReceived}');
      
      if (diag.lastMessageAt != null) {
        final timeSince = DateTime.now().difference(diag.lastMessageAt!);
        print('   ⏱️  Last message: ${timeSince.inSeconds}s ago');
      }

      if (diag.latency != null) {
        print('   🚀 Latency: ${diag.latency!.inMilliseconds}ms');
      }

      if (diag.errors.isNotEmpty) {
        print('   ❌ Errors: ${diag.errors.length}');
        for (final error in diag.errors.take(3)) {
          print('      - $error');
        }
      }

      final uptime = DateTime.now().difference(diag.subscribedAt);
      print('   ⏰ Uptime: ${_formatDuration(uptime)}');
      print('');
    }

    print('━' * 60);
  }

  /// Get emoji for status
  String _getStatusEmoji(String status) {
    switch (status) {
      case 'SUBSCRIBED':
        return '✅';
      case 'SUBSCRIBING':
        return '🔄';
      case 'CLOSED':
        return '⏸️';
      case 'CHANNEL_ERROR':
        return '❌';
      case 'TIMED_OUT':
        return '⏰';
      default:
        return '❓';
    }
  }

  /// Format duration nicely
  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  /// Get diagnostics for a channel
  RealtimeChannelDiagnostics? getDiagnostics(String channelName) {
    return _channelDiagnostics[channelName];
  }

  /// Get all diagnostics
  Map<String, RealtimeChannelDiagnostics> getAllDiagnostics() {
    return Map.from(_channelDiagnostics);
  }

  /// Test Realtime connection
  Future<RealtimeTestResult> testConnection() async {
    print('🧪 Testing Realtime connection...');
    
    final startTime = DateTime.now();
    final testChannel = _supabase.realtime.channel('test_${startTime.millisecondsSinceEpoch}');
    
    try {
      final completer = Completer<RealtimeTestResult>();
      var subscribeStatus = 'UNKNOWN';

      testChannel.subscribe(
        (status, [error]) {
          subscribeStatus = status;
          
          if (status == 'SUBSCRIBED') {
            final latency = DateTime.now().difference(startTime);
            completer.complete(RealtimeTestResult(
              success: true,
              latency: latency,
              status: status,
            ));
          } else if (status == 'CHANNEL_ERROR' || status == 'TIMED_OUT') {
            completer.complete(RealtimeTestResult(
            success: false,
            status: status,
            error: error?.toString(),
          ));
        }
      },
      const Duration(seconds: 30), // Test with 30s timeout
      );

      // Timeout after 10 seconds
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return RealtimeTestResult(
            success: false,
            status: 'TIMEOUT',
            error: 'Connection test timed out after 10 seconds',
          );
        },
      );

      // Clean up
      await testChannel.unsubscribe();

      return result;
    } catch (e) {
      return RealtimeTestResult(
        success: false,
        status: 'ERROR',
        error: e.toString(),
      );
    }
  }

  /// Generate diagnostic report
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('═' * 60);
    buffer.writeln('REALTIME DIAGNOSTICS REPORT');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('═' * 60);
    buffer.writeln();

    if (_channelDiagnostics.isEmpty) {
      buffer.writeln('No active channels');
      return buffer.toString();
    }

    for (final entry in _channelDiagnostics.entries) {
      final diag = entry.value;
      
      buffer.writeln('Channel: ${diag.channelName}');
      buffer.writeln('  Status: ${diag.status} ${diag.isHealthy ? '✓' : '✗'}');
      buffer.writeln('  Messages Received: ${diag.messagesReceived}');
      buffer.writeln('  Subscribed At: ${diag.subscribedAt}');
      
      if (diag.lastMessageAt != null) {
        buffer.writeln('  Last Message: ${diag.lastMessageAt}');
        buffer.writeln('  Time Since Last: ${diag.timeSinceLastMessage.inSeconds}s');
      }
      
      if (diag.latency != null) {
        buffer.writeln('  Latency: ${diag.latency!.inMilliseconds}ms');
      }
      
      if (diag.errors.isNotEmpty) {
        buffer.writeln('  Errors: ${diag.errors.length}');
        for (final error in diag.errors) {
          buffer.writeln('    - $error');
        }
      }
      
      buffer.writeln();
    }

    buffer.writeln('═' * 60);
    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _channelDiagnostics.clear();
    _messageTimestamps.clear();
  }
}

/// Result of Realtime connection test
class RealtimeTestResult {
  final bool success;
  final Duration? latency;
  final String status;
  final String? error;

  RealtimeTestResult({
    required this.success,
    this.latency,
    required this.status,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return 'SUCCESS: Connected in ${latency?.inMilliseconds}ms (Status: $status)';
    } else {
      return 'FAILED: $status${error != null ? ' - $error' : ''}';
    }
  }
}


