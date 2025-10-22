import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/services/connection_service.dart';

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final service = ConnectionService();
  service.initialize();
  return service.statusStream;
});

class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStatusProvider);

    return connectionState.when(
      data: (status) {
        if (status == ConnectionStatus.connected) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: _getStatusColor(status),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (status == ConnectionStatus.connecting ||
                    status == ConnectionStatus.reconnecting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                if (status == ConnectionStatus.connecting ||
                    status == ConnectionStatus.reconnecting)
                  const SizedBox(width: 12),
                Icon(
                  _getStatusIcon(status),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status == ConnectionStatus.disconnected) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      ConnectionService().forceReconnect();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.reconnecting:
        return Colors.amber;
      case ConnectionStatus.disconnected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.connecting:
        return Icons.cloud_sync;
      case ConnectionStatus.reconnecting:
        return Icons.cloud_sync;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }
}
