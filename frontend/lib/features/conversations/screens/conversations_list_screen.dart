import 'package:flutter/material.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/features/messages/screens/message_screen.dart';
import 'package:messageai/features/settings/screens/settings_screen.dart';
import 'package:messageai/widgets/network_status_banner.dart';
import 'package:messageai/widgets/user_avatar.dart';

/// Screen showing list of conversations
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final _conversationService = ConversationService();
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _conversationService.getAllConversations();
  }
  
  // Add pull-to-refresh
  Future<void> _refreshConversations() async {
    setState(() {
      _conversationsFuture = _conversationService.getAllConversations(syncFirst: true);
    });
  }

  void _showNewConversationDialog() {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Conversation title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }

              try {
                await _conversationService.createConversation(
                  title: titleController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    // Don't re-sync from backend (keeps deleted convos deleted)
                    _conversationsFuture =
                        _conversationService.getAllConversations(syncFirst: false);
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MessageAI'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshConversations,
              child: FutureBuilder<List<Conversation>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 80,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation to begin messaging',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showNewConversationDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('New Conversation'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Dismissible(
                key: Key(conv.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Conversation'),
                        content: Text(
                          'Are you sure you want to delete "${conv.title}"? This cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await _conversationService.deleteConversation(conv.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted "${conv.title}"')),
                      );
                      setState(() {
                        // Refresh from local DB only (don't re-sync from backend)
                        _conversationsFuture = _conversationService.getAllConversations(syncFirst: false);
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting conversation: $e')),
                      );
                      setState(() {
                        // Re-sync to refresh the list
                        _conversationsFuture = _conversationService.getAllConversations(syncFirst: true);
                      });
                    }
                  }
                },
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageScreen(
                          conversationId: conv.id,
                          conversationTitle: conv.title,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        UserAvatar(
                          fallbackText: conv.title,
                          radius: 28,
                          isGroup: conv.isGroup,
                          // Note: We don't have userId for conversation participant here
                          // In a full implementation, we'd fetch the other user's ID
                          // For now, fallback to initials
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<Message?>(
                              future: _conversationService.getLatestMessage(conv.id),
                              builder: (context, snapshot) {
                                String previewText = 'Tap to start messaging';
                                
                                if (snapshot.hasData && snapshot.data != null) {
                                  final message = snapshot.data!;
                                  if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) {
                                    previewText = '📷 ${message.body}';
                                  } else {
                                    previewText = message.body;
                                  }
                                }
                                
                                return Text(
                                  previewText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(conv.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          );
          },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
