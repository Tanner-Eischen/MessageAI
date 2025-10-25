import 'package:flutter/material.dart';
import 'package:messageai/services/network_connectivity_service.dart';
import 'package:messageai/services/offline_queue_service.dart';

/// Banner that shows network status and pending message count
class NetworkStatusBanner extends StatefulWidget {
  const NetworkStatusBanner({Key? key}) : super(key: key);

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  final _connectivityService = NetworkConnectivityService();
  final _offlineQueueService = OfflineQueueService();
  
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  int _pendingMessages = 0;

  @override
  void initState() {
    super.initState();
    _status = _connectivityService.currentStatus;
    _loadPendingCount();
    
    // Listen to connectivity changes
    _connectivityService.onStatusChange.listen((status) {
      if (mounted) {
        setState(() => _status = status);
        _loadPendingCount();
      }
    });
  }

  Future<void> _loadPendingCount() async {
    final count = await _offlineQueueService.getPendingMessageCount();
    if (mounted) {
      setState(() => _pendingMessages = count);
    }
  }

  Future<void> _handleSyncTap() async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Syncing pending messages...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await _offlineQueueService.forceSyncNow();
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${result.successCount} messages synced'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadPendingCount();
    } else if (result.status == SyncStatus.noMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('All messages are synced'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Text('Failed to sync: ${result.errorMessage ?? "Unknown error"}'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show banner when offline or has pending messages
    if (_status == ConnectivityStatus.online && _pendingMessages == 0) {
      return const SizedBox.shrink();
    }

    return Material(
      color: _getBannerColor(),
      child: InkWell(
        onTap: _status == ConnectivityStatus.online && _pendingMessages > 0
            ? _handleSyncTap
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                _getBannerIcon(),
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getBannerText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_status == ConnectivityStatus.online && _pendingMessages > 0)
                const Icon(
                  Icons.sync,
                  size: 20,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBannerColor() {
    if (_status == ConnectivityStatus.offline) {
      return Colors.red.shade700;
    } else if (_pendingMessages > 0) {
      return Colors.orange.shade700;
    }
    return Colors.blue;
  }

  IconData _getBannerIcon() {
    if (_status == ConnectivityStatus.offline) {
      return Icons.cloud_off;
    } else if (_pendingMessages > 0) {
      return Icons.cloud_sync;
    }
    return Icons.cloud_done;
  }

  String _getBannerText() {
    if (_status == ConnectivityStatus.offline) {
      if (_pendingMessages > 0) {
        return 'Offline • $_pendingMessages message${_pendingMessages == 1 ? '' : 's'} pending';
      }
      return 'You are offline';
    } else if (_pendingMessages > 0) {
      return 'Syncing $_pendingMessages message${_pendingMessages == 1 ? '' : 's'} • Tap to sync now';
    }
    return 'All messages synced';
  }
}

/// Small inline network indicator
class NetworkStatusIndicator extends StatefulWidget {
  final bool showLabel;

  const NetworkStatusIndicator({
    Key? key,
    this.showLabel = true,
  }) : super(key: key);

  @override
  State<NetworkStatusIndicator> createState() => _NetworkStatusIndicatorState();
}

class _NetworkStatusIndicatorState extends State<NetworkStatusIndicator> {
  final _connectivityService = NetworkConnectivityService();
  ConnectivityStatus _status = ConnectivityStatus.unknown;

  @override
  void initState() {
    super.initState();
    _status = _connectivityService.currentStatus;
    
    _connectivityService.onStatusChange.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (_status) {
      case ConnectivityStatus.online:
        return Colors.green;
      case ConnectivityStatus.offline:
        return Colors.red;
      case ConnectivityStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (_status) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }
}



