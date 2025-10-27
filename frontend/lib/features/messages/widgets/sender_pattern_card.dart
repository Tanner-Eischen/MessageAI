import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/services/ai_sender_pattern_service.dart';

/// Card that displays what we've learned about this sender's communication style
class SenderPatternCard extends StatelessWidget {
  final SenderPatternData pattern;

  const SenderPatternCard({
    super.key,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.cyan,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              const Expanded(
                child: Text(
                  'Sender Profile',
                  style: TextStyle(
                    fontWeight: AppTheme.fontWeightMedium,
                    color: Colors.cyan,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${pattern.totalMessages} msgs',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: AppTheme.fontWeightMedium,
                    color: Colors.cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Communication style
          _buildStyleRow(
            'Style',
            _prettifyStyle(pattern.communicationStyle),
            _getStyleIcon(pattern.communicationStyle),
          ),
          const SizedBox(height: AppTheme.spacingS),

          // Helpfulness rate
          _buildStyleRow(
            'Analysis Accuracy',
            '${(pattern.averageHelpfulness * 100).toStringAsFixed(0)}% helpful',
            Icons.check_circle_outline,
            color: _getHelpfulnessColor(pattern.averageHelpfulness),
          ),
          const SizedBox(height: AppTheme.spacingS),

          // What this means
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            ),
            child: Text(
              _getInsight(pattern),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.gray700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettifyStyle(String style) {
    return style
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  IconData _getStyleIcon(String style) {
    switch (style) {
      case 'brief_and_direct':
        return Icons.flash_on_outlined;
      case 'warm_and_verbose':
        return Icons.favorite_outline;
      default:
        return Icons.equalizer_outlined;
    }
  }

  Color _getHelpfulnessColor(double rate) {
    if (rate > 0.75) return Colors.green;
    if (rate > 0.5) return Colors.amber;
    return Colors.orange;
  }

  String _getInsight(SenderPatternData pattern) {
    if (!pattern.hasData) {
      return "Still learning their communication style. Send a few more messages to get better insights.";
    }

    final style = pattern.communicationStyle;
    final helpful = pattern.averageHelpfulness;

    if (style == 'brief_and_direct' && helpful > 0.7) {
      return "This person tends to be brief. Short replies usually mean they're busy, not upset.";
    } else if (style == 'warm_and_verbose' && helpful > 0.7) {
      return "This person is typically warm and detailed. Any perceived coldness is likely just brevity.";
    } else if (helpful > 0.7) {
      return "Our interpretations have been accurate with this sender. Trust the analysis.";
    } else {
      return "Keep providing feedback to help us understand their unique communication style better.";
    }
  }

  Widget _buildStyleRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    color ??= Colors.cyan;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.gray600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: AppTheme.fontWeightMedium,
            color: color,
          ),
        ),
      ],
    );
  }
}
