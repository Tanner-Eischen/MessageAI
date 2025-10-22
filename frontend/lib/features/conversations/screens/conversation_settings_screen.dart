import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/services/group_service.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ConversationSettingsScreen extends StatefulWidget {
  final String conversationId;

  const ConversationSettingsScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ConversationSettingsScreen> createState() => _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState extends State<ConversationSettingsScreen> {
  final _groupService = GroupService();
  final _conversationService = ConversationService();
  final _supabase = SupabaseClientProvider.client;
  final _db = AppDb.instance;

  Conversation? _conversation;
  List<Participant> _participants = [];
  bool _isLoading = true;
  bool _isCurrentUserAdmin = false;
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final conv = await _db.conversationDao.getConversationById(widget.conversationId);
      final parts = await _groupService.getGroupMembers(widget.conversationId);
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId != null) {
        final isAdmin = await _groupService.isAdmin(widget.conversationId, currentUserId);
        setState(() {
          _isCurrentUserAdmin = isAdmin;
        });
      }

      if (mounted) {
        setState(() {
          _conversation = conv;
          _participants = parts;
          _inviteCode = conv?.inviteCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateInviteLink() async {
    try {
      final code = await _groupService.generateInviteCode(widget.conversationId);
      setState(() => _inviteCode = code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link generated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _copyInviteLink() async {
    if (_inviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: _inviteCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied to clipboard')),
      );
    }
  }

  Future<void> _editGroupInfo() async {
    final titleController = TextEditingController(text: _conversation?.title);
    final descController = TextEditingController(text: _conversation?.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'title': titleController.text,
                'description': descController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _groupService.updateGroupInfo(
          conversationId: widget.conversationId,
          title: result['title'],
          description: result['description'],
        );

        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group info updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final avatarUrl = 'https://via.placeholder.com/150';

      await _groupService.updateGroupInfo(
        conversationId: widget.conversationId,
        avatarUrl: avatarUrl,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You will need an invite link to rejoin.',
        ),
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.leaveGroup(widget.conversationId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the group')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleAdmin(Participant participant) async {
    try {
      if (participant.isAdmin) {
        await _groupService.demoteFromAdmin(
          conversationId: widget.conversationId,
          userId: participant.userId,
        );
      } else {
        await _groupService.promoteToAdmin(
          conversationId: widget.conversationId,
          userId: participant.userId,
        );
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              participant.isAdmin ? 'Admin removed' : 'Promoted to admin',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(Participant participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this member?'),
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

    try {
      await _groupService.removeMember(
        conversationId: widget.conversationId,
        userId: participant.userId,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Settings')),
        body: const Center(child: Text('Conversation not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Settings'),
      ),
      body: ListView(
        children: [
          _buildGroupHeader(),
          const Divider(),
          if (_isCurrentUserAdmin) ...[
            _buildInviteLinkSection(),
            const Divider(),
          ],
          _buildMembersSection(),
          const Divider(),
          _buildLeaveGroupButton(),
        ],
      ),
    );
  }

  Widget _buildGroupHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isCurrentUserAdmin ? _changeAvatar : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: _conversation?.avatarUrl != null
                      ? NetworkImage(_conversation!.avatarUrl!)
                      : null,
                  child: _conversation?.avatarUrl == null
                      ? Text(
                          _conversation!.title[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40),
                        )
                      : null,
                ),
                if (_isCurrentUserAdmin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _conversation!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_conversation!.description != null) ...[
            const SizedBox(height: 8),
            Text(
              _conversation!.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          if (_isCurrentUserAdmin) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _editGroupInfo,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Group Info'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInviteLinkSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Link',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_inviteCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteCode!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyInviteLink,
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _generateInviteLink,
              icon: const Icon(Icons.link),
              label: const Text('Generate Invite Link'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members (${_participants.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._participants.map((p) => _buildMemberTile(p)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Participant participant) {
    final currentUserId = _supabase.auth.currentUser?.id;
    final isCurrentUser = participant.userId == currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(participant.userId.substring(0, 2).toUpperCase()),
      ),
      title: Text(
        isCurrentUser ? 'You' : participant.userId,
        style: TextStyle(
          fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: participant.isAdmin ? const Text('Admin') : null,
      trailing: _isCurrentUserAdmin && !isCurrentUser
          ? PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _toggleAdmin(participant),
                  ),
                  child: Text(
                    participant.isAdmin ? 'Remove Admin' : 'Make Admin',
                  ),
                ),
                PopupMenuItem(
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 100),
                    () => _removeMember(participant),
                  ),
                  child: const Text(
                    'Remove from Group',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildLeaveGroupButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _leaveGroup,
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Leave Group'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
