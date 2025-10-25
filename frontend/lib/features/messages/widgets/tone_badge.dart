import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/ai_analysis.dart';

/// A small badge widget that displays tone analysis for a message
/// Appears at the bottom-right of message bubbles
class ToneBadge extends StatelessWidget {
  final AIAnalysis analysis;
  final VoidCallback? onTap;

  const ToneBadge({
    Key? key,
    required this.analysis,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final toneInfo = _getToneInfo(analysis.tone);
    final urgencyColor = _getUrgencyColor(analysis.urgencyLevel);
    final hasBoundary = analysis.boundaryAnalysis?.hasViolation == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXS,
          vertical: AppTheme.spacingXXS,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.darkGray200 : AppTheme.gray100)
              .withOpacity(0.9),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: (hasBoundary 
                ? _getBoundaryColor(analysis.boundaryAnalysis!.severity)
                : urgencyColor).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              toneInfo.emoji,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: AppTheme.spacingXXS),
            Text(
              toneInfo.label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeXXS,
                fontWeight: AppTheme.fontWeightMedium,
                color: isDark ? AppTheme.white : AppTheme.black,
              ),
            ),
            // 🆕 PHASE 1: Boundary violation indicator
            if (hasBoundary) ...[
              const SizedBox(width: AppTheme.spacingXXS),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getBoundaryColor(analysis.boundaryAnalysis!.severity),
                  shape: BoxShape.circle,
                ),
              ),
            ],
            // ✅ NEW: Show intensity dot
            if (analysis.intensity != null) ...[
              const SizedBox(width: AppTheme.spacingXXS),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getIntensityColor(analysis.intensity!),
                  shape: BoxShape.circle,
                ),
              ),
            ],
            // Existing urgency dot
            if (analysis.urgencyLevel != null && analysis.urgencyLevel != 'Low' && !hasBoundary) ...[
              const SizedBox(width: AppTheme.spacingXXS),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ToneInfo _getToneInfo(String tone) {
    switch (tone.toLowerCase()) {
      // Original 8
      case 'friendly':
        return ToneInfo(emoji: '😊', label: 'Friendly');
      case 'professional':
        return ToneInfo(emoji: '💼', label: 'Professional');
      case 'urgent':
        return ToneInfo(emoji: '⚠️', label: 'Urgent');
      case 'casual':
        return ToneInfo(emoji: '😎', label: 'Casual');
      case 'formal':
        return ToneInfo(emoji: '🎩', label: 'Formal');
      case 'concerned':
        return ToneInfo(emoji: '😟', label: 'Concerned');
      case 'excited':
        return ToneInfo(emoji: '🎉', label: 'Excited');
      case 'neutral':
        return ToneInfo(emoji: '😐', label: 'Neutral');
      
      // ✅ NEW: 15 additional tones
      case 'apologetic':
        return ToneInfo(emoji: '🙏', label: 'Apologetic');
      case 'appreciative':
        return ToneInfo(emoji: '🙌', label: 'Appreciative');
      case 'frustrated':
        return ToneInfo(emoji: '😤', label: 'Frustrated');
      case 'playful':
        return ToneInfo(emoji: '😜', label: 'Playful');
      case 'sarcastic':
        return ToneInfo(emoji: '🙄', label: 'Sarcastic');
      case 'empathetic':
        return ToneInfo(emoji: '🤗', label: 'Empathetic');
      case 'inquisitive':
        return ToneInfo(emoji: '🤔', label: 'Inquisitive');
      case 'assertive':
        return ToneInfo(emoji: '💪', label: 'Assertive');
      case 'tentative':
        return ToneInfo(emoji: '😬', label: 'Tentative');
      case 'defensive':
        return ToneInfo(emoji: '🛡️', label: 'Defensive');
      case 'encouraging':
        return ToneInfo(emoji: '💚', label: 'Encouraging');
      case 'disappointed':
        return ToneInfo(emoji: '😞', label: 'Disappointed');
      case 'overwhelmed':
        return ToneInfo(emoji: '😵', label: 'Overwhelmed');
      case 'relieved':
        return ToneInfo(emoji: '😌', label: 'Relieved');
      case 'confused':
        return ToneInfo(emoji: '😕', label: 'Confused');
      
      default:
        return ToneInfo(emoji: '💬', label: 'Neutral');
    }
  }

  Color _getUrgencyColor(String? urgencyLevel) {
    if (urgencyLevel == null) return AppTheme.gray500;
    
    switch (urgencyLevel.toLowerCase()) {
      case 'critical':
        return AppTheme.accentRed;
      case 'high':
        return AppTheme.accentOrange;
      case 'medium':
        return AppTheme.accentBlue;
      case 'low':
      default:
        return AppTheme.accentGreen;
    }
  }

  // ✅ NEW: Helper for intensity colors
  Color _getIntensityColor(int intensity) {
    // Map intensity (1-10) to colors
    if (intensity >= 8) {
      return Colors.red;
    } else if (intensity >= 6) {
      return Colors.orange;
    } else if (intensity >= 4) {
      return Colors.blue;
    } else if (intensity >= 2) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  // ✅ NEW: Helper for boundary colors
  Color _getBoundaryColor(int severity) {
    switch (severity) {
      case 3:
        return AppTheme.accentRed;
      case 2:
        return AppTheme.accentOrange;
      case 1:
      default:
        return AppTheme.accentBlue;
    }
  }
}

class ToneInfo {
  final String emoji;
  final String label;

  ToneInfo({required this.emoji, required this.label});
}

