import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/models/follow_up_item.dart';
import 'package:messageai/services/follow_up_service.dart';
import 'package:messageai/features/followups/widgets/follow_up_card.dart';

/// Dashboard showing all pending follow-ups
class FollowUpDashboardScreen extends ConsumerStatefulWidget {
  const FollowUpDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FollowUpDashboardScreen> createState() => 
      _FollowUpDashboardScreenState();
}

class _FollowUpDashboardScreenState extends ConsumerState<FollowUpDashboardScreen> {
  final followUpService = FollowUpService();
  
  List<FollowUpItem>? followUps;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  Future<void> _loadFollowUps() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final items = await followUpService.getPendingFollowUps();
      setState(() {
        followUps = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-ups'),
        actions: [
          if (followUps != null && followUps!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${followUps!.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFollowUps,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFollowUps,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : followUps == null || followUps!.isEmpty
                  ? _buildEmptyState()
                  : _buildFollowUpsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending follow-ups',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpsList() {
    // Group by type
    final actionItems = followUps!
        .where((f) => f.itemType == FollowUpItemType.actionItem)
        .toList();
    final questions = followUps!
        .where((f) => f.itemType == FollowUpItemType.unansweredQuestion)
        .toList();
    final pending = followUps!
        .where((f) => f.itemType == FollowUpItemType.pendingResponse)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadFollowUps,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary stats
          _buildSummaryCard(),
          const SizedBox(height: 16),

          // Overdue items first
          ...followUps!.where((f) => f.isOverdue).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FollowUpCard(
              item: item,
              onComplete: () => _handleComplete(item),
              onSnooze: () => _handleSnooze(item),
              onDismiss: () => _handleDismiss(item),
            ),
          )),

          // Due soon
          if (followUps!.any((f) => f.isDueSoon && !f.isOverdue)) ...[
            const SizedBox(height: 8),
            _buildSectionHeader('Due Soon'),
            ...followUps!
                .where((f) => f.isDueSoon && !f.isOverdue)
                .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FollowUpCard(
                    item: item,
                    onComplete: () => _handleComplete(item),
                    onSnooze: () => _handleSnooze(item),
                    onDismiss: () => _handleDismiss(item),
                  ),
                )),
          ],

          // Action items
          if (actionItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionHeader('Action Items (${actionItems.length})'),
            ...actionItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FollowUpCard(
                item: item,
                onComplete: () => _handleComplete(item),
                onSnooze: () => _handleSnooze(item),
                onDismiss: () => _handleDismiss(item),
              ),
            )),
          ],

          // Unanswered questions
          if (questions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionHeader('Unanswered Questions (${questions.length})'),
            ...questions.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FollowUpCard(
                item: item,
                onComplete: () => _handleComplete(item),
                onSnooze: () => _handleSnooze(item),
                onDismiss: () => _handleDismiss(item),
              ),
            )),
          ],

          // Other pending
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionHeader('Pending Responses (${pending.length})'),
            ...pending.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FollowUpCard(
                item: item,
                onComplete: () => _handleComplete(item),
                onSnooze: () => _handleSnooze(item),
                onDismiss: () => _handleDismiss(item),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final overdueCount = followUps!.where((f) => f.isOverdue).length;
    final dueSoonCount = followUps!.where((f) => f.isDueSoon && !f.isOverdue).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              '${followUps!.length}',
              'Total',
              Colors.blue,
            ),
            if (overdueCount > 0)
              _buildStat(
                '$overdueCount',
                'Overdue',
                Colors.red,
              ),
            if (dueSoonCount > 0)
              _buildStat(
                '$dueSoonCount',
                'Due Soon',
                Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Future<void> _handleComplete(FollowUpItem item) async {
    try {
      await followUpService.completeFollowUp(item.id);
      _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as complete')),
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

  Future<void> _handleSnooze(FollowUpItem item) async {
    final duration = await _showSnoozeDurationPicker();
    if (duration == null) return;

    try {
      await followUpService.snoozeFollowUp(item.id, duration);
      _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snoozed for ${duration.inHours}h')),
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

  Future<void> _handleDismiss(FollowUpItem item) async {
    try {
      await followUpService.dismissFollowUp(item.id);
      _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dismissed')),
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

  Future<Duration?> _showSnoozeDurationPicker() async {
    return showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze for how long?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1 hour'),
              onTap: () => Navigator.pop(context, const Duration(hours: 1)),
            ),
            ListTile(
              title: const Text('3 hours'),
              onTap: () => Navigator.pop(context, const Duration(hours: 3)),
            ),
            ListTile(
              title: const Text('Tomorrow'),
              onTap: () => Navigator.pop(context, const Duration(days: 1)),
            ),
            ListTile(
              title: const Text('Next week'),
              onTap: () => Navigator.pop(context, const Duration(days: 7)),
            ),
          ],
        ),
      ),
    );
  }
}
