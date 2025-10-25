import 'package:flutter/material.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/services/conversation_filter_service.dart';
import 'package:messageai/models/conversation_filter.dart';
import 'package:messageai/models/conversation_with_metadata.dart';
import 'package:messageai/features/conversations/widgets/conversation_filter_chips.dart';
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
  final _filterService = ConversationFilterService();
  late Future<List<Conversation>> _conversationsFuture;
  Set<ConversationFilter> _activeFilters = {};
  Map<ConversationFilter, int>? _filterCounts;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _conversationService.getAllConversations();
    _updateFilterCounts();
  }
  
  Future<void> _refreshConversations() async {
    setState(() {
      _conversationsFuture = _conversationService.getAllConversations(syncFirst: true);
    });
    await _updateFilterCounts();
  }
  
  /// Update filter badge counts
  Future<void> _updateFilterCounts() async {
    try {
      final conversations = await _conversationsFuture;
      final allMeta = await Future.wait(
        conversations.map((c) => _filterService.getConversationMetadata(c)),
      );
      
      final counts = await _filterService.getFilterCounts(allMeta);
      
      if (mounted) {
        setState(() {
          _filterCounts = counts;
        });
      }
    } catch (e) {
      print('❌ Error updating filter counts: $e');
    }
  }
  
  /// Handle filter toggle
  void _handleFilterToggle(ConversationFilter filter) {
    setState(() {
      if (filter == ConversationFilter.all) {
        _activeFilters.clear();
      } else {
        if (_activeFilters.contains(filter)) {
          _activeFilters.remove(filter);
        } else {
          _activeFilters.add(filter);
        }
      }
    });
  }
  
  /// Get filtered conversations
  Future<List<ConversationWithMetadata>> _getFilteredConversations() async {
    final conversations = await _conversationsFuture;
    return await _filterService.filterConversations(
      conversations,
      _activeFilters,
    );
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
          
          // 🆕 ADD: Filter chips
          ConversationFilterChips(
            activeFilters: _activeFilters,
            onFilterToggled: _handleFilterToggle,
            badgeCounts: _filterCounts,
          ),
          
          // Conversation list (filtered)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshConversations,
              child: FutureBuilder<List<ConversationWithMetadata>>(
          future: _getFilteredConversations(),
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

          final conversationsWithMeta = snapshot.data ?? [];

          if (conversationsWithMeta.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: conversationsWithMeta.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              final convMeta = conversationsWithMeta[index];
              return _buildConversationTile(convMeta);
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
  
  /// 🆕 Build empty state (with filter awareness)
  Widget _buildEmptyState() {
    if (_activeFilters.isNotEmpty) {
      // Filtered empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations match these filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() => _activeFilters.clear());
              },
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }
    
    // Default empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
  
  /// 🆕 Build conversation tile with metadata badges
  Widget _buildConversationTile(ConversationWithMetadata convMeta) {
    final conv = convMeta.conversation;
    
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
              _conversationsFuture = _conversationService.getAllConversations(
                syncFirst: false,
              );
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting conversation: $e'),
                backgroundColor: Colors.red,
              ),
            );
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 🆕 ADD: Priority/status badges
                        if (convMeta.hasUrgentMessages)
                          _buildIconBadge(
                            Icons.priority_high,
                            Colors.red,
                            'Urgent',
                          ),
                        if (convMeta.hasRSDTriggers)
                          _buildIconBadge(
                            Icons.warning_amber,
                            Colors.orange,
                            'RSD Trigger',
                          ),
                        if (convMeta.hasBoundaryViolations)
                          _buildIconBadge(
                            Icons.shield_outlined,
                            Colors.purple,
                            'Boundary Issue',
                          ),
                      ],
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
  }
  
  /// 🆕 ADD: Icon badge helper
  Widget _buildIconBadge(IconData icon, Color color, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
