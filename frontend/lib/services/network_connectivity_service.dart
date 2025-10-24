import 'dart:async';
import 'package:flutter/foundation.dart';

/// Network connectivity states
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

/// Service for monitoring network connectivity
/// Note: For production, consider using connectivity_plus package
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();

  factory NetworkConnectivityService() {
    return _instance;
  }

  NetworkConnectivityService._internal();

  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  Timer? _pingTimer;
  bool _isMonitoring = false;

  /// Get current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  /// Check if currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Start monitoring connectivity
  void startMonitoring({Duration checkInterval = const Duration(seconds: 10)}) {
    if (_isMonitoring) {
      print('⚠️  Connectivity monitoring already started');
      return;
    }

    _isMonitoring = true;
    print('🌐 Starting connectivity monitoring (every ${checkInterval.inSeconds}s)');

    // Check immediately
    _checkConnectivity();

    // Then check periodically
    _pingTimer = Timer.periodic(checkInterval, (_) {
      _checkConnectivity();
    });
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _isMonitoring = false;
    print('🌐 Stopped connectivity monitoring');
  }

  /// Check connectivity status
  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check
      // In production, use connectivity_plus package for better detection
      final previousStatus = _currentStatus;
      final newStatus = await _performConnectivityCheck();

      if (newStatus != previousStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
        _logStatusChange(previousStatus, newStatus);
      }
    } catch (e) {
      print('❌ Error checking connectivity: $e');
    }
  }

  /// Perform actual connectivity check
  /// Override this method to use connectivity_plus or other packages
  Future<ConnectivityStatus> _performConnectivityCheck() async {
    try {
      // For now, we assume online unless explicitly set offline
      // In production, use connectivity_plus to check actual network state
      
      // You can enhance this by:
      // 1. Using connectivity_plus package
      // 2. Pinging a known endpoint
      // 3. Checking platform-specific APIs
      
      return ConnectivityStatus.online;
    } catch (e) {
      return ConnectivityStatus.offline;
    }
  }

  /// Manually set connectivity status (useful for testing)
  void setStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      final previousStatus = _currentStatus;
      _currentStatus = status;
      _statusController.add(_currentStatus);
      _logStatusChange(previousStatus, status);
    }
  }

  /// Force a connectivity check now
  Future<ConnectivityStatus> checkNow() async {
    final status = await _performConnectivityCheck();
    if (status != _currentStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = status;
      _statusController.add(_currentStatus);
      _logStatusChange(previousStatus, status);
    }
    return _currentStatus;
  }

  /// Log status changes
  void _logStatusChange(
    ConnectivityStatus previous,
    ConnectivityStatus current,
  ) {
    final emoji = current == ConnectivityStatus.online ? '✅' : '📴';
    print('$emoji Connectivity: ${previous.name} → ${current.name}');
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _statusController.close();
  }
}

/// Extension for convenience methods
extension ConnectivityStatusExtension on ConnectivityStatus {
  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isUnknown => this == ConnectivityStatus.unknown;
}



