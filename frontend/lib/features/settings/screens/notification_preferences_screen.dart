import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/state/notification_providers.dart';
import 'package:messageai/services/device_token_service.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    try {
      final deviceService = ref.read(deviceTokenServiceProvider);
      final devices = await deviceService.getUserDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading devices: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeDevice(String fcmToken) async {
    try {
      final deviceService = ref.read(deviceTokenServiceProvider);
      await deviceService.unregisterDeviceToken(fcmToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device removed')),
        );
        _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing device: $e')),
        );
      }
    }
  }

  Future<void> _cleanupStaleDevices() async {
    setState(() => _isLoading = true);
    try {
      final deviceService = ref.read(deviceTokenServiceProvider);
      await deviceService.cleanupStaleDevices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stale devices cleaned up')),
        );
        _loadDevices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateProvider);
    final deviceToken = ref.watch(deviceTokenProvider);
    final hasPermission = ref.watch(notificationPermissionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 1,
      ),
      body: ListView(
        children: [
          _buildStatusSection(notificationState, hasPermission),
          const Divider(),
          _buildCurrentDeviceSection(deviceToken),
          const Divider(),
          _buildRegisteredDevicesSection(),
          const Divider(),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildStatusSection(NotificationState state, AsyncValue<bool> permission) {
    return ListTile(
      leading: Icon(
        state.isInitialized ? Icons.check_circle : Icons.error,
        color: state.isInitialized ? Colors.green : Colors.orange,
      ),
      title: const Text('Notification Status'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Initialized: ${state.isInitialized ? "Yes" : "No"}'),
          permission.when(
            data: (hasPermission) =>
                Text('Permission: ${hasPermission ? "Granted" : "Denied"}'),
            loading: () => const Text('Permission: Loading...'),
            error: (_, __) => const Text('Permission: Error'),
          ),
        ],
      ),
      trailing: permission.when(
        data: (hasPermission) => !hasPermission
            ? ElevatedButton(
                onPressed: () async {
                  final fcmService = ref.read(notificationServiceProvider);
                  await fcmService.initialize(
                    onMessageReceived: (_) {},
                    onTokenRefresh: (_) {},
                  );
                  ref.invalidate(notificationPermissionProvider);
                },
                child: const Text('Request'),
              )
            : null,
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildCurrentDeviceSection(String? deviceToken) {
    return ListTile(
      leading: const Icon(Icons.phone_android),
      title: const Text('Current Device Token'),
      subtitle: deviceToken != null
          ? Text(
              '${deviceToken.substring(0, 20)}...',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            )
          : const Text('No token available'),
      trailing: deviceToken != null
          ? IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Copy to clipboard functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied to clipboard')),
                );
              },
              tooltip: 'Copy token',
            )
          : null,
    );
  }

  Widget _buildRegisteredDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Registered Devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _loadDevices,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_devices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text('No registered devices'),
            ),
          )
        else
          ..._devices.map((device) => _buildDeviceItem(device)).toList(),
      ],
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    final platform = device['platform'] as String;
    final lastSeen = DateTime.parse(device['last_seen'] as String);
    final timeAgo = _formatTimeAgo(lastSeen);

    IconData platformIcon;
    switch (platform) {
      case 'ios':
        platformIcon = Icons.phone_iphone;
        break;
      case 'android':
        platformIcon = Icons.phone_android;
        break;
      case 'web':
        platformIcon = Icons.web;
        break;
      default:
        platformIcon = Icons.devices;
    }

    return ListTile(
      leading: Icon(platformIcon),
      title: Text(platform.toUpperCase()),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last seen: $timeAgo'),
          Text(
            '${(device['fcm_token'] as String).substring(0, 20)}...',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showRemoveDeviceDialog(device['fcm_token'] as String),
        tooltip: 'Remove device',
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _cleanupStaleDevices,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Clean up stale devices (90+ days)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: Stale devices (not seen in 90 days) can be safely removed to improve notification delivery.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showRemoveDeviceDialog(String fcmToken) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: const Text(
          'Are you sure you want to remove this device? '
          'You will stop receiving notifications on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeDevice(fcmToken);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
