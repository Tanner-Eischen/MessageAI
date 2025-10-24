import 'package:flutter/material.dart';
import 'package:messageai/services/avatar_service.dart';

/// Reusable widget for displaying user avatars
/// Fetches avatar from backend or shows fallback initial
class UserAvatar extends StatefulWidget {
  final String? userId;
  final String? avatarUrl;
  final String fallbackText;
  final double radius;
  final bool isGroup;

  const UserAvatar({
    Key? key,
    this.userId,
    this.avatarUrl,
    required this.fallbackText,
    this.radius = 20,
    this.isGroup = false,
  }) : super(key: key);

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  final _avatarService = AvatarService();
  String? _fetchedAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if userId changed
    if (oldWidget.userId != widget.userId || oldWidget.avatarUrl != widget.avatarUrl) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    // If avatarUrl is directly provided, use it
    if (widget.avatarUrl != null) {
      setState(() {
        _fetchedAvatarUrl = widget.avatarUrl;
      });
      return;
    }

    // If userId provided, fetch avatar
    if (widget.userId != null) {
      setState(() => _isLoading = true);
      
      try {
        final url = await _avatarService.getAvatarUrl(widget.userId!);
        if (mounted) {
          setState(() {
            _fetchedAvatarUrl = url;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        // Silently fail - fallback will be shown
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading indicator
    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        child: SizedBox(
          width: widget.radius,
          height: widget.radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Show avatar image if available
    if (_fetchedAvatarUrl != null && _fetchedAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.primary,
        backgroundImage: NetworkImage(_fetchedAvatarUrl!),
        // Error handling: show fallback if image fails to load
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading avatar: $exception');
        },
        child: Container(), // Empty container as placeholder
      );
    }

    // Fallback: Show initial or group icon
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: theme.colorScheme.primary,
      child: widget.isGroup
          ? Icon(
              Icons.group,
              color: Colors.white,
              size: widget.radius * 1.2,
            )
          : Text(
              _getInitial(widget.fallbackText),
              style: TextStyle(
                fontSize: widget.radius * 0.9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  /// Get first letter of name for fallback
  String _getInitial(String text) {
    if (text.isEmpty) return '?';
    return text[0].toUpperCase();
  }
}


