import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:messageai/data/remote/supabase_client.dart';

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  reconnecting,
}

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();

  factory ConnectionService() {
    return _instance;
  }

  ConnectionService._internal();

  final _supabase = SupabaseClientProvider.client;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  RealtimeChannel? _statusChannel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 10;
  static const _baseDelay = Duration(seconds: 1);

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get currentStatus => _currentStatus;

  void initialize() {
    if (_statusChannel != null) return;

    _statusChannel = _supabase.channel('connection-status');

    _statusChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _updateStatus(ConnectionStatus.connected);
        _reconnectAttempts = 0;
        _reconnectTimer?.cancel();
      } else if (status == RealtimeSubscribeStatus.closed) {
        _updateStatus(ConnectionStatus.disconnected);
        _attemptReconnect();
      } else if (status == RealtimeSubscribeStatus.channelError) {
        _updateStatus(ConnectionStatus.disconnected);
        _attemptReconnect();
      }

      if (error != null) {
        print('Connection error: $error');
        _updateStatus(ConnectionStatus.disconnected);
        _attemptReconnect();
      }
    });
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
      print('Connection status changed: $newStatus');
    }
  }

  void _attemptReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      _updateStatus(ConnectionStatus.disconnected);
      return;
    }

    _reconnectAttempts++;
    final delay = _calculateBackoff(_reconnectAttempts);

    print('Attempting reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _updateStatus(ConnectionStatus.reconnecting);

    _reconnectTimer = Timer(delay, () {
      _reconnect();
    });
  }

  Duration _calculateBackoff(int attempt) {
    final delaySeconds = _baseDelay.inSeconds * (1 << (attempt - 1));
    final maxDelaySeconds = 60;
    final actualDelay = delaySeconds > maxDelaySeconds ? maxDelaySeconds : delaySeconds;
    return Duration(seconds: actualDelay);
  }

  Future<void> _reconnect() async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      await _statusChannel?.unsubscribe();
      _statusChannel = _supabase.channel('connection-status-${DateTime.now().millisecondsSinceEpoch}');

      _statusChannel!.subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _updateStatus(ConnectionStatus.connected);
          _reconnectAttempts = 0;
          print('Reconnection successful');
        } else if (status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.channelError) {
          _attemptReconnect();
        }

        if (error != null) {
          print('Reconnection error: $error');
          _attemptReconnect();
        }
      });
    } catch (e) {
      print('Error during reconnect: $e');
      _attemptReconnect();
    }
  }

  Future<void> forceReconnect() async {
    _reconnectAttempts = 0;
    await _reconnect();
  }

  Future<void> dispose() async {
    _reconnectTimer?.cancel();
    await _statusChannel?.unsubscribe();
    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }
}
