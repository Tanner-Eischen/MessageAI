import 'package:flutter/material.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'package:messageai/services/conversation_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _supabase = SupabaseClientProvider.client;
  final _conversationService = ConversationService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('profiles')
          .select('user_id, display_name, email, avatar_url, bio')
          .neq('user_id', currentUserId)
          .or('display_name.ilike.%$query%,email.ilike.%$query%')
          .limit(20);

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response);
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    }
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final otherUserId = user['user_id'] as String;

      final existingConv = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', currentUserId);

      String? conversationId;

      for (final conv in existingConv) {
        final cid = conv['conversation_id'] as String;

        final participants = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', cid);

        if (participants.length == 2) {
          final userIds = participants.map((p) => p['user_id'] as String).toList();
          if (userIds.contains(currentUserId) && userIds.contains(otherUserId)) {
            conversationId = cid;
            break;
          }
        }
      }

      if (conversationId == null) {
        final displayName = user['display_name'] as String? ?? user['email'] as String;
        conversationId = await _conversationService.createConversation(
          title: displayName,
          participantIds: [otherUserId],
        );
      }

      if (mounted && conversationId != null) {
        Navigator.pop(context, conversationId);
      }
    } catch (e) {
      print('Error starting conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Users'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _searchUsers(value);
              },
            ),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users to start a conversation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final displayName = user['display_name'] as String?;
    final email = user['email'] as String;
    final avatarUrl = user['avatar_url'] as String?;
    final bio = user['bio'] as String?;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: avatarUrl == null
            ? Text(
                (displayName ?? email)[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              )
            : null,
      ),
      title: Text(displayName ?? email),
      subtitle: bio != null && bio.isNotEmpty
          ? Text(
              bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: ElevatedButton(
        onPressed: () => _startConversation(user),
        child: const Text('Message'),
      ),
    );
  }
}
