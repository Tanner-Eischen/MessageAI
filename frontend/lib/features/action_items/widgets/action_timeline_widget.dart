import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/action_item_extended.dart';
import 'package:messageai/services/action_item_service.dart';

/// Timeline widget displaying upcoming commitments with streak gamification
class ActionTimelineWidget extends StatefulWidget {
  final bool showStreak;
  final int maxItems;
  final VoidCallback? onItemTapped;

  const ActionTimelineWidget({
    super.key,
    this.showStreak = true,
    this.maxItems = 5,
    this.onItemTapped,
  });

  @override
  State<ActionTimelineWidget> createState() => _ActionTimelineWidgetState();
}

class _ActionTimelineWidgetState extends State<ActionTimelineWidget> {
  late final ActionItemService _service;
  List<ActionItemWithStatus> _upcomingItems = [];
  CommitmentStreak? _streak;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = ActionItemService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final upcoming = await _service.getUpcomingItems(daysAhead: 30);
    final streak = widget.showStreak ? await _service.getStreak() : null;

    setState(() {
      _upcomingItems = upcoming.take(widget.maxItems).toList();
      _streak = streak;
      _isLoading = false;
    });
  }

  Future<void> _markCompleted(ActionItemWithStatus item) async {
    final success = await _service.markCompleted(item.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Commitment marked complete!')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_upcomingItems.isEmpty && _streak == null) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak display
        if (widget.showStreak && _streak != null) ...[
          _buildStreakCard(isDark),
          const SizedBox(height: AppTheme.spacingL),
        ],

        // Timeline
        if (_upcomingItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Text(
              'Upcoming Commitments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                  ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildTimeline(isDark),
        ] else
          _buildEmptyCommitmentsState(),
      ],
    );
  }

  Widget _buildStreakCard(bool isDark) {
    final streak = _streak!;
    final isNewBest = streak.isOnTrackForNewBest();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNewBest
              ? [Colors.amber.shade600, Colors.orange.shade600]
              : [Colors.blue.shade600, Colors.cyan.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: (isNewBest ? Colors.amber : Colors.blue).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main streak number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentStreakCount}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'days keeping promises',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (isNewBest) _buildNewBestBadge(),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Motivational message
          Text(
            streak.getMotivationalMessage(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${streak.bestStreakCount}',
                'Best',
                isDark,
              ),
              _buildStatItem(
                '${streak.getCompletionPercentage()}%',
                'Complete',
                isDark,
              ),
              _buildStatItem(
                '${streak.totalCompleted}/${streak.totalCommitments}',
                'Kept',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewBestBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Text('🏆 ', style: TextStyle(fontSize: 16)),
          Text(
            'New Best!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _upcomingItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingM),
      itemBuilder: (context, index) {
        final item = _upcomingItems[index];
        return _buildTimelineItem(item, isDark, index);
      },
    );
  }

  Widget _buildTimelineItem(
    ActionItemWithStatus item,
    bool isDark,
    int index,
  ) {
    final urgencyColor = _parseColor(item.getUrgencyColor());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: urgencyColor, width: 4),
        ),
        color: isDark ? AppTheme.darkGray200 : Colors.grey[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with emoji
            Row(
              children: [
                Text(item.getActionEmoji(), style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    item.commitmentText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTheme.fontWeightBold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingS),

            // Details row
            Row(
              children: [
                // Deadline
                Icon(Icons.calendar_today, size: 14, color: urgencyColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.formatDeadline(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.getStatusLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      color: urgencyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _markCompleted(item),
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
                const SizedBox(width: AppTheme.spacingS),
                TextButton.icon(
                  onPressed: () {
                    widget.onItemTapped?.call();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.done_all, size: 64, color: Colors.grey),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No commitments yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Start making promises in your messages!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCommitmentsState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'No upcoming commitments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    final hexString = hexColor.replaceFirst('#', '');
    return Color(int.parse('FF$hexString', radix: 16));
  }
}
