import 'package:flutter/material.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/peek_content.dart';

/// ============================================================================
/// RELATIONSHIP CONTEXT CARD - Default Peek Zone Display
/// ============================================================================
///
/// Shows sender information and conversation patterns.
/// Displays:
/// - Sender name & avatar
/// - Relationship type & duration
/// - Communication style summary
/// - Last message timestamp
/// - Reliability/responsiveness score (star rating)
///
/// Typically shown at 80% (PEEK mode) when no interventions active.
///
class RelationshipContextCard extends StatelessWidget {
  /// The participant/sender
  final Participant sender;

  /// Relationship description (e.g., "Friend, 8 months")
  final String relationship;

  /// Communication pattern summary (e.g., "88% of 'k' messages are neutral")
  final String communicationStyle;

  /// Last message timing (e.g., "2 hours ago")
  final String lastMessage;

  /// Reliability score (0-100)
  /// Used to calculate star rating
  final double reliabilityScore;
  final ConversationTraits? traits;

  /// Optional callback when card is tapped
  /// Could trigger expansion or navigation
  final VoidCallback? onTap;

  /// Whether to show a "tap to expand" hint
  final bool showExpandHint;

  const RelationshipContextCard({super.key, 
    required this.sender,
    required this.relationship,
    required this.communicationStyle,
    required this.lastMessage,
    required this.reliabilityScore,
    this.traits,
    this.onTap,
    this.showExpandHint = true,
  });

  /// Calculate star rating from reliability score (0-100 → 0-5 stars)
  int get _starCount {
    return (reliabilityScore / 20).round().clamp(0, 5);
  }

  /// Get sender initials for avatar
  String get _senderInitials {
    final parts = sender.userId.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Determine reliability status color
  Color get _reliabilityColor {
    if (reliabilityScore >= 80) return Colors.green;
    if (reliabilityScore >= 60) return Colors.blue;
    if (reliabilityScore >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(isDark ? 0.15 : 0.05),
              Colors.indigo.withOpacity(isDark ? 0.12 : 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(isDark ? 0.3 : 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Header: Sender Info =====
            Row(
              children: [
                // Avatar (smaller)
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.withOpacity(0.3),
                  child: Text(
                    _senderInitials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Relationship
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sender.userId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        relationship,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ===== Info Rows =====
            _buildInfoRow(
              icon: Icons.message_outlined,
              label: 'Style',
              value: communicationStyle,
              isDark: isDark,
            ),
            const SizedBox(height: 6),

            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Last seen',
              value: lastMessage,
              isDark: isDark,
            ),

            const SizedBox(height: 8),

            // ===== Traits & Safety (if available) =====
            if (traits != null) ...[
              _buildTraits(traits!, isDark),
              const SizedBox(height: 8),
            ],

            // ===== Reliability Score =====
            _buildReliabilityScore(isDark),

            // ===== Expand Hint =====
            if (showExpandHint) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Pull up for more →',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTraits(ConversationTraits t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, size: 12, color: Colors.blue.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              'Traits & Safety',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Icon(Icons.timer, size: 12, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              '${t.avgResponseMinutes.toStringAsFixed(0)}m avg',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _TraitMeter(label: 'Sarcasm', value: t.sarcasm, color: Colors.purple),
        const SizedBox(height: 4),
        _TraitMeter(label: 'RSD triggers', value: t.rsdTriggers, color: Colors.amber),
        const SizedBox(height: 4),
        _TraitMeter(label: 'Literalness', value: t.literalness, color: Colors.blue),
        const SizedBox(height: 4),
        _TraitMeter(label: 'Humor', value: t.humor, color: Colors.green),
        const SizedBox(height: 4),
        _TraitMeter(label: 'Reciprocity', value: t.reciprocity, color: Colors.teal),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.blue.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReliabilityScore(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _reliabilityColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _reliabilityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 12,
            color: _reliabilityColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Reliability',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _reliabilityColor,
            ),
          ),
          const SizedBox(width: 6),
          ..._buildStarRow(),
          const SizedBox(width: 6),
          Text(
            '${reliabilityScore.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _reliabilityColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStarRow() {
    return List.generate(5, (index) {
      final isFilled = index < _starCount;
      return Icon(
        isFilled ? Icons.star : Icons.star_outline,
        size: 11,
        color: isFilled ? Colors.amber : Colors.grey[400],
      );
    });
  }
}

class _TraitMeter extends StatelessWidget {
  final String label;
  final double value; // 0-100
  final Color color;

  const _TraitMeter({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: clamped / 100.0,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            '${clamped.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

/// ============================================================================
/// RELATIONSHIP CONTEXT COMPACT - Minimal version for tight spaces
/// ============================================================================
///
/// Condensed version showing only essential information.
/// Used when space is limited (e.g., during COMPARE mode).
///
class RelationshipContextCompact extends StatelessWidget {
  final Participant sender;
  final String relationship;
  final double reliabilityScore;
  final VoidCallback? onTap;

  const RelationshipContextCompact({super.key, 
    required this.sender,
    required this.relationship,
    required this.reliabilityScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.3),
              child: Text(
                sender.userId.isNotEmpty
                    ? sender.userId.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sender.userId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    relationship,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.star,
              size: 12,
              color: Colors.amber,
            ),
            const SizedBox(width: 2),
            Text(
              '${(reliabilityScore / 20).round()}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// RELATIONSHIP CONTEXT SKELETON - Loading state
/// ============================================================================
///
/// Shows a placeholder skeleton while loading relationship context.
///
class RelationshipContextSkeleton extends StatelessWidget {
  const RelationshipContextSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar skeleton
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 150,
                      color: Colors.grey[200],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 12,
            width: double.infinity,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}
