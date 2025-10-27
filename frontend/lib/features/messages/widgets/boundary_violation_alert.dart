import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/services/boundary_violation_service.dart';

/// Widget displaying boundary violations with explanation and suggested responses
class BoundaryViolationAlert extends StatefulWidget {
  final BoundaryViolationData violation;
  final String senderName;
  final bool isRepeatOffender;
  final VoidCallback? onResponseSelected;

  const BoundaryViolationAlert({
    super.key,
    required this.violation,
    required this.senderName,
    this.isRepeatOffender = false,
    this.onResponseSelected,
  });

  @override
  State<BoundaryViolationAlert> createState() => _BoundaryViolationAlertState();
}

class _BoundaryViolationAlertState extends State<BoundaryViolationAlert> {
  bool _expandedEvidence = false;
  String? _selectedResponse;
  bool _copied = false;

  Color _getSeverityColor() {
    switch (widget.violation.severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getViolationTitle() {
    return widget.violation.type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _copyToClipboard(String text) {
    // In production, use: Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Header with severity indicator
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusS),
                topRight: Radius.circular(AppTheme.radiusS),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🛡️ ${_getViolationTitle()}',
                        style: TextStyle(
                          fontWeight: AppTheme.fontWeightBold,
                          fontSize: 14,
                          color: severityColor,
                        ),
                      ),
                      if (widget.isRepeatOffender)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '⚠️ Repeat boundary violation from ${widget.senderName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: AppTheme.fontWeightMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Explanation
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.violation.explanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray700,
                    height: 1.5,
                  ),
                ),

                // Evidence section
                const SizedBox(height: AppTheme.spacingM),
                Material(
                  child: InkWell(
                    onTap: () => setState(() => _expandedEvidence = !_expandedEvidence),
                    child: Row(
                      children: [
                        Icon(
                          _expandedEvidence ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: AppTheme.gray600,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'Evidence (${widget.violation.evidence.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: AppTheme.fontWeightMedium,
                            color: AppTheme.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_expandedEvidence) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  ...widget.violation.evidence.map((evidence) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '•',
                            style: TextStyle(
                              color: severityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              evidence,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Response templates
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Suggested Responses (Tap to copy)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTheme.fontWeightMedium,
                    color: AppTheme.gray700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),

                // Gentle response
                _buildResponseOption(
                  'gentle',
                  '😊 Gentle',
                  widget.violation.suggestedGentle,
                  Colors.green,
                ),
                const SizedBox(height: AppTheme.spacingS),

                // Moderate response
                _buildResponseOption(
                  'moderate',
                  '⚖️ Moderate',
                  widget.violation.suggestedModerate,
                  Colors.amber,
                ),
                const SizedBox(height: AppTheme.spacingS),

                // Firm response
                _buildResponseOption(
                  'firm',
                  '💪 Firm',
                  widget.violation.suggestedFirm,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseOption(
    String level,
    String label,
    String text,
    Color color,
  ) {
    final isSelected = _selectedResponse == level;

    return Material(
      child: InkWell(
        onTap: () {
          setState(() => _selectedResponse = level);
          _copyToClipboard(text);
          widget.onResponseSelected?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: AppTheme.fontWeightMedium,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.content_copy,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.gray700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
