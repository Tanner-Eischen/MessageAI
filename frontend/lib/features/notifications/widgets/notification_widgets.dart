import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/state/notification_providers.dart';
import 'package:messageai/services/notification_service.dart';

/// Widget to request notification permissions
class NotificationPermissionRequest extends ConsumerWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const NotificationPermissionRequest({
    Key? key,
    this.onPermissionGranted,
    this.onPermissionDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(notificationPermissionProvider);

    return hasPermission.when(
      data: (hasPermission) {
        if (hasPermission) {
          return const SizedBox.shrink();
        }
        return _PermissionBanner(
          onGranted: onPermissionGranted,
          onDenied: onPermissionDenied,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, st) => const SizedBox.shrink(),
    );
  }
}

/// Permission request banner
class _PermissionBanner extends ConsumerWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const _PermissionBanner({
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none,
            color: Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enable Notifications',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Get notified when you receive messages',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  onDenied?.call();
                },
                child: const Text('Not Now'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final service = ref.read(notificationServiceProvider);
                  final granted = await service.areNotificationsEnabled();
                  if (granted) {
                    onGranted?.call();
                  } else {
                    onDenied?.call();
                  }
                },
                child: const Text('Enable'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Notification status indicator
class NotificationStatusIndicator extends ConsumerWidget {
  const NotificationStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);

    if (!notificationState.isInitialized) {
      return const SizedBox.shrink();
    }

    final hasPermission = notificationState.hasPermission;

    return Tooltip(
      message: hasPermission ? 'Notifications enabled' : 'Notifications disabled',
      child: Icon(
        hasPermission ? Icons.notifications_active : Icons.notifications_off,
        color: hasPermission ? Colors.green : Colors.grey,
        size: 24,
      ),
    );
  }
}

/// Notification settings tile
class NotificationSettingsTile extends ConsumerWidget {
  final VoidCallback? onPressed;

  const NotificationSettingsTile({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);
    final hasPermission = notificationState.hasPermission;

    return ListTile(
      leading: Icon(
        hasPermission ? Icons.notifications_active : Icons.notifications_off,
        color: hasPermission ? Colors.green : Colors.grey,
      ),
      title: const Text('Notifications'),
      subtitle: Text(
        hasPermission ? 'Enabled' : 'Disabled',
        style: TextStyle(
          color: hasPermission ? Colors.green : Colors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).dividerColor,
      ),
      onTap: onPressed,
    );
  }
}

/// Unread notification badge
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.backgroundColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);
    final unreadCount = notificationState.unreadCount;

    if (unreadCount == 0) {
      return child;
    }

    return Badge(
      label: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: textStyle,
      ),
      backgroundColor: backgroundColor ?? Colors.red,
      child: child,
    );
  }
}

/// Notification bottom sheet
class NotificationSettingsBottomSheet extends ConsumerWidget {
  const NotificationSettingsBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);
    final hasPermission = notificationState.hasPermission;
    final deviceToken = notificationState.deviceToken;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Notification Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Permission status
          ListTile(
            leading: Icon(
              hasPermission ? Icons.check_circle : Icons.error_circle,
              color: hasPermission ? Colors.green : Colors.red,
            ),
            title: const Text('Notifications'),
            subtitle: Text(
              hasPermission ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: hasPermission ? Colors.green : Colors.red,
              ),
            ),
          ),
          const Divider(),

          // Device token info
          if (deviceToken != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Token',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deviceToken.substring(0, 20) + '...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}
