import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/models/relationship_profile.dart';
import 'package:messageai/models/safe_topic.dart';
import 'package:messageai/services/relationship_service.dart';

/// Bottom sheet showing relationship profile
class RelationshipSummarySheet extends ConsumerStatefulWidget {
  final String conversationId;

  const RelationshipSummarySheet({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  ConsumerState<RelationshipSummarySheet> createState() =>
      _RelationshipSummarySheetState();
}

class _RelationshipSummarySheetState
    extends ConsumerState<RelationshipSummarySheet> {
  final relationshipService = RelationshipService();

  RelationshipProfile? profile;
  List<SafeTopic>? safeTopics;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        relationshipService.getProfile(widget.conversationId),
        relationshipService.getSafeTopics(widget.conversationId),
      ]);

      setState(() {
        profile = results[0] as RelationshipProfile?;
        safeTopics = results[1] as List<SafeTopic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text('No profile available'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text(
                            profile!.getRelationshipEmoji(),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile!.participantName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (profile!.relationshipType != null)
                                  Text(
                                    profile!.relationshipType!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      if (profile!.conversationSummary != null) ...[
                        _buildSection('About This Relationship', [
                          Text(
                            profile!.conversationSummary!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Communication style
                      if (profile!.communicationStyle != null) ...[
                        _buildSection('Communication Style', [
                          Text(
                            profile!.communicationStyle!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Response time
                      if (profile!.typicalResponseTime != null) ...[
                        _buildSection('Typical Response Time', [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                profile!.formatResponseTime(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Safe topics
                      if (profile!.safeTopics.isNotEmpty) ...[
                        _buildSection('Safe Topics', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile!.safeTopics.map((topic) {
                              return Chip(
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green.withOpacity(0.1),
                                side: BorderSide(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Topics to avoid
                      if (profile!.topicsToAvoid.isNotEmpty) ...[
                        _buildSection('Topics to Avoid', [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile!.topicsToAvoid.map((topic) {
                              return Chip(
                                label: Text(
                                  topic,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.red.withOpacity(0.1),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              );
                            }).toList(),
                          ),
                        ]),
                        const SizedBox(height: 16),
                      ],

                      // Detailed safe topics
                      if (safeTopics != null && safeTopics!.isNotEmpty) ...[
                        _buildSection('Topic Engagement', [
                          ...safeTopics!.map((topic) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: topic.getTopicColor(),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        topic.topicName,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      topic.getEngagementLabel(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: topic.getTopicColor(),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ]),
                      ],

                      // Stats
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                              '${profile!.totalMessages}',
                              'messages',
                            ),
                            if (profile!.firstMessageAt != null)
                              _buildStat(
                                _getTimeSince(profile!.firstMessageAt!),
                                'talking',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getTimeSince(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - timestamp;

    final days = diff ~/ 86400;
    if (days < 30) return '${days}d';

    final months = days ~/ 30;
    if (months < 12) return '${months}mo';

    final years = months ~/ 12;
    return '${years}yr';
  }
}

/// Show relationship summary sheet
void showRelationshipSummary(BuildContext context, String conversationId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: RelationshipSummarySheet(conversationId: conversationId),
    ),
  );
}

