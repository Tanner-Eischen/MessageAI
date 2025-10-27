import 'package:flutter/material.dart';
import 'package:messageai/services/contact_service.dart';
import 'package:messageai/services/conversation_service.dart';

/// Dialog for creating a new conversation (single or group)
class CreateConversationDialog extends StatefulWidget {
  const CreateConversationDialog({super.key});

  @override
  State<CreateConversationDialog> createState() => _CreateConversationDialogState();
}

class _CreateConversationDialogState extends State<CreateConversationDialog> {
  final _contactService = ContactService();
  final _conversationService = ConversationService();
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  
  String? _conversationType; // 'single' or 'group'
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((contact) {
          return contact.displayLabel.toLowerCase().contains(query) ||
                 (contact.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactService.getAllContacts();
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _createConversation() async {
    if (_conversationType == null) return;

    // Validation
    if (_conversationType == 'group' && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate title for single chats
      String title = _titleController.text;
      if (_conversationType == 'single' && _selectedUserIds.length == 1) {
        final contact = _allContacts.firstWhere(
          (c) => c.userId == _selectedUserIds.first,
        );
        title = contact.displayLabel;
      }

      // Create conversation
      await _conversationService.createConversation(
        title: title,
        participantUserIds: _selectedUserIds.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'New Conversation',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Choose type (if not selected yet)
            if (_conversationType == null) ...[
              _buildTypeSelection(),
            ] else ...[
              // Step 2: Select contacts and enter title
              _buildContactSelection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose conversation type:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),

        // Single Chat Button
        _buildTypeCard(
          icon: Icons.person,
          title: 'Single Chat',
          subtitle: 'Chat with one person',
          onTap: () {
            setState(() => _conversationType = 'single');
            _loadContacts();
          },
        ),

        const SizedBox(height: 12),

        // Group Chat Button
        _buildTypeCard(
          icon: Icons.group,
          title: 'Group Chat',
          subtitle: 'Chat with multiple people',
          onTap: () {
            setState(() => _conversationType = 'group');
            _loadContacts();
          },
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSelection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => setState(() {
              _conversationType = null;
              _selectedUserIds.clear();
            }),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(_conversationType == 'group' ? 'Group Chat' : 'Single Chat'),
          ),

          const SizedBox(height: 12),

          // Group name (only for groups)
          if (_conversationType == 'group') ...[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Selected count
          if (_selectedUserIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedUserIds.length} selected',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Contact list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final isSelected = _selectedUserIds.contains(contact.userId);

                          // For single chat, only allow one selection
                          final canSelect = _conversationType == 'group' || _selectedUserIds.isEmpty;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: canSelect || isSelected
                                ? (value) {
                                    setState(() {
                                      if (value == true) {
                                        if (_conversationType == 'single') {
                                          _selectedUserIds.clear();
                                        }
                                        _selectedUserIds.add(contact.userId);
                                      } else {
                                        _selectedUserIds.remove(contact.userId);
                                      }
                                    });
                                  }
                                : null,
                            title: Text(contact.displayLabel),
                            subtitle: Text(contact.email ?? contact.username ?? ''),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                contact.initials,
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 16),

          // Create button
          ElevatedButton(
            onPressed: _isLoading ? null : _createConversation,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create Conversation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

