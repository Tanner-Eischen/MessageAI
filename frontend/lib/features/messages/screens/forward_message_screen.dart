import 'package:flutter/material.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/services/conversation_service.dart';
import 'package:messageai/services/message_service.dart';

class ForwardMessageScreen extends StatefulWidget {
  final Message message;

  const ForwardMessageScreen({
    super.key,
    required this.message,
  });

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  final _conversationService = ConversationService();
  final _messageService = MessageService();

  List<Conversation> _conversations = [];
  Set<String> _selectedConversations = {};
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await _conversationService.getAllConversations();
      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  Future<void> _forwardMessage() async {
    if (_selectedConversations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one conversation')),
      );
      return;
    }

    setState(() => _isSending = true);

    int successCount = 0;
    int failCount = 0;

    for (final convId in _selectedConversations) {
      try {
        await _messageService.sendMessage(
          conversationId: convId,
          body: widget.message.body,
          mediaUrl: widget.message.mediaUrl,
        );
        successCount++;
      } catch (e) {
        print('Error forwarding to $convId: $e');
        failCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Forwarded to $successCount conversation(s)' +
                (failCount > 0 ? ', $failCount failed' : ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward Message'),
        actions: [
          if (_selectedConversations.isNotEmpty)
            TextButton(
              onPressed: _isSending ? null : _forwardMessage,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Send (${_selectedConversations.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select conversations to forward this message',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.message.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _conversations.isEmpty
                      ? const Center(
                          child: Text('No conversations available'),
                        )
                      : ListView.builder(
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final isSelected = _selectedConversations.contains(conv.id);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedConversations.add(conv.id);
                                  } else {
                                    _selectedConversations.remove(conv.id);
                                  }
                                });
                              },
                              title: Text(conv.title),
                              subtitle: conv.description != null
                                  ? Text(
                                      conv.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              secondary: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  conv.title[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
