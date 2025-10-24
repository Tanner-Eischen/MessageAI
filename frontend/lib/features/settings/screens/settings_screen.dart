import 'package:flutter/material.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/features/auth/screens/auth_screen.dart';
import 'package:messageai/services/avatar_service.dart';
import 'package:messageai/core/errors/app_error.dart';
import 'package:messageai/core/errors/error_ui.dart';

/// User settings and account management screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with ErrorHandlerMixin {
  final _supabase = SupabaseClientProvider.client;
  final _avatarService = AvatarService();
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _avatarUrl = response['avatar_url'] as String?;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final email = user?.email ?? 'Not logged in';
    final userId = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 1,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Column(
              children: [
                Stack(
                  children: [
                    _isUploadingAvatar
                        ? const CircleAvatar(
                            radius: 50,
                            child: CircularProgressIndicator(),
                          )
                        : CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null
                                ? Text(
                                    email[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _isUploadingAvatar ? null : _showAvatarOptions,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${userId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Account Settings
          _buildSectionTitle('Account'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Display Name',
            subtitle: email.split('@')[0],
            onTap: () => _showEditDisplayNameDialog(),
          ),
          _buildSettingsTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: email,
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () => _showComingSoonDialog('Change Password'),
          ),

          const Divider(height: 1),

          // Notifications
          _buildSectionTitle('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive message notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Notifications enabled' : 'Notifications disabled',
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.volume_up,
            title: 'Notification Sound',
            subtitle: 'Default',
            onTap: () => _showComingSoonDialog('Notification Sounds'),
          ),

          const Divider(height: 1),

          // Privacy & Security
          _buildSectionTitle('Privacy & Security'),
          _buildSettingsTile(
            icon: Icons.shield,
            title: 'Blocked Users',
            onTap: () => _showComingSoonDialog('Blocked Users'),
          ),
          _buildSettingsTile(
            icon: Icons.visibility,
            title: 'Online Status',
            subtitle: 'Visible to everyone',
            onTap: () => _showComingSoonDialog('Online Status Settings'),
          ),
          _buildSettingsTile(
            icon: Icons.check_circle,
            title: 'Read Receipts',
            subtitle: 'Enabled',
            onTap: () => _showComingSoonDialog('Read Receipts Settings'),
          ),

          const Divider(height: 1),

          // Storage
          _buildSectionTitle('Storage'),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Storage Usage',
            subtitle: 'Calculate storage...',
            onTap: () => _showComingSoonDialog('Storage Management'),
          ),
          _buildSettingsTile(
            icon: Icons.delete_sweep,
            title: 'Clear Cache',
            onTap: () => _showClearCacheDialog(),
          ),

          const Divider(height: 1),

          // About
          _buildSectionTitle('About'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0 (MVP)',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () => _showComingSoonDialog('Privacy Policy'),
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () => _showComingSoonDialog('Terms of Service'),
          ),

          const SizedBox(height: 16),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogout,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// Show avatar options (Gallery, Camera, Delete)
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadAvatarFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadAvatarFromCamera();
                },
              ),
              if (_avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Upload avatar from gallery
  Future<void> _uploadAvatarFromGallery() async {
    try {
      final image = await _avatarService.pickImage();
      if (image == null) return;

      await _uploadAvatar(image);
    } on AppError catch (error) {
      if (mounted) {
        showError(error);
      }
    }
  }

  /// Upload avatar from camera
  Future<void> _uploadAvatarFromCamera() async {
    try {
      final image = await _avatarService.pickImageFromCamera();
      if (image == null) return;

      await _uploadAvatar(image);
    } on AppError catch (error) {
      if (mounted) {
        showError(error);
      }
    }
  }

  /// Upload avatar to server
  Future<void> _uploadAvatar(image) async {
    if (mounted) {
      setState(() => _isUploadingAvatar = true);
    }

    try {
      final url = await _avatarService.uploadAvatar(image);

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isUploadingAvatar = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile picture updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on AppError catch (error) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        showError(error);
      }
    }
  }

  /// Delete avatar
  Future<void> _deleteAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploadingAvatar = true);

    try {
      await _avatarService.deleteAvatar();

      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _isUploadingAvatar = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed')),
        );
      }
    } on AppError catch (error) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        showError(error);
      }
    }
  }

  void _showEditDisplayNameDialog() {
    final controller = TextEditingController();
    final user = _supabase.auth.currentUser;
    controller.text = user?.email?.split('@')[0] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Display name updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached images and files. Your messages will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        await _supabase.auth.signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => AuthScreen(onAuthSuccess: () {}),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }
}

