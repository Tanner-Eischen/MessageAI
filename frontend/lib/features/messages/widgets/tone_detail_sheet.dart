import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/features/messages/widgets/rsd_alert_card.dart';
import 'package:messageai/features/messages/widgets/interpretation_options.dart';
import 'package:messageai/features/messages/widgets/evidence_viewer.dart';

/// Bottom sheet showing detailed tone analysis
class ToneDetailSheet extends StatelessWidget {
  final AIAnalysis analysis;
  final String messageBody;

  const ToneDetailSheet({
    Key? key,
    required this.analysis,
    required this.messageBody,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Header
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 28,
                  color: isDark ? AppTheme.white : AppTheme.black,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'AI Analysis',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Message preview
            _buildSection(
              context,
              'Message',
              messageBody.length > 100
                  ? '${messageBody.substring(0, 100)}...'
                  : messageBody,
              Icons.chat_bubble_outline,
              isDark,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // ✅ PHASE 1: RSD Alert
            if (analysis.rsdTriggers != null && analysis.rsdTriggers!.isNotEmpty) ...[
              RSDAlertCard(triggers: analysis.rsdTriggers!),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // Tone
            _buildSection(
              context,
              'Tone',
              analysis.tone,
              Icons.sentiment_satisfied,
              isDark,
              highlight: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Urgency
            if (analysis.urgencyLevel != null)
              _buildSection(
                context,
                'Urgency Level',
                analysis.urgencyLevel!,
                Icons.priority_high,
                isDark,
                color: _getUrgencyColor(analysis.urgencyLevel),
              ),
            
            if (analysis.urgencyLevel != null)
              const SizedBox(height: AppTheme.spacingM),
            
            // Intent
            if (analysis.intent != null)
              _buildSection(
                context,
                'Intent',
                analysis.intent!,
                Icons.lightbulb_outline,
                isDark,
              ),
            
            if (analysis.intent != null)
              const SizedBox(height: AppTheme.spacingM),
            
            // Confidence
            if (analysis.confidenceScore != null) ...[
              _buildConfidenceBar(
                context,
                analysis.confidenceScore!,
                isDark,
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // ✅ NEW: Intensity section
            if (analysis.intensity != null) ...[
              _buildSection(
                context,
                'Intensity',
                _formatIntensity(analysis.intensity!),
                Icons.trending_up,
                isDark,
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // ✅ NEW: Context flags
            if (analysis.contextFlags != null && analysis.contextFlags!.isNotEmpty) ...[
              _buildContextFlags(context, analysis.contextFlags!, isDark),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // ✅ NEW: Anxiety assessment
            if (analysis.anxietyAssessment != null) ...[
              _buildAnxietyAssessment(context, analysis.anxietyAssessment!, isDark),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // ✅ PHASE 1: Alternative Interpretations
            if (analysis.alternativeInterpretations != null && 
                analysis.alternativeInterpretations!.isNotEmpty) ...[
              InterpretationOptions(interpretations: analysis.alternativeInterpretations!),
              const SizedBox(height: AppTheme.spacingM),
            ],
            
            // ✅ PHASE 1: Evidence
            if (analysis.evidence != null) ...[
              EvidenceViewer(evidence: analysis.evidence!),
              const SizedBox(height: AppTheme.spacingL),
            ],
            
            // Feedback section
            _buildFeedbackSection(context, isDark),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark, {
    bool highlight = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: highlight
            ? (isDark ? AppTheme.darkGray200 : AppTheme.gray100)
            : (isDark ? AppTheme.darkGray200.withOpacity(0.5) : AppTheme.gray50),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color ?? (isDark ? AppTheme.darkGray300 : AppTheme.gray300),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: (color ?? (isDark ? AppTheme.darkGray300 : AppTheme.gray200))
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? (isDark ? AppTheme.white : AppTheme.black),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                    fontWeight: AppTheme.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXS),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightSemibold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(
    BuildContext context,
    double confidence,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final percentage = (confidence * 100).round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                fontWeight: AppTheme.fontWeightMedium,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: AppTheme.fontWeightBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence > 0.8
                  ? AppTheme.accentGreen
                  : confidence > 0.6
                      ? AppTheme.accentBlue
                      : AppTheme.accentOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Was this analysis helpful?',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
            fontWeight: AppTheme.fontWeightMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement feedback logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
              },
              icon: const Icon(Icons.thumb_up_outlined, size: 18),
              label: const Text('Helpful'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement feedback logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
              },
              icon: const Icon(Icons.thumb_down_outlined, size: 18),
              label: const Text('Not helpful'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                ),
              ),
            ),
          ],
        ),
      ],
    );
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

  // ✅ NEW: Helper methods for enhanced fields
  String _formatIntensity(String intensity) {
    return intensity.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Widget _buildContextFlags(BuildContext context, Map<String, dynamic> flags, bool isDark) {
    final activeFlags = flags.entries
        .where((e) => e.value == true)
        .map((e) => _formatFlag(e.key))
        .toList();
    
    if (activeFlags.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Context Flags',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeXS,
                    fontWeight: AppTheme.fontWeightBold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXS),
                Text(
                  activeFlags.join(', '),
                  style: TextStyle(fontSize: AppTheme.fontSizeXS),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFlag(String flag) {
    return flag.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Widget _buildAnxietyAssessment(BuildContext context, Map<String, dynamic> assessment, bool isDark) {
    final riskLevel = assessment['risk_level'] as String?;
    final suggestions = (assessment['mitigation_suggestions'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];
    
    if (riskLevel == null) return const SizedBox.shrink();
    
    final riskColor = _getRiskColor(riskLevel);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: riskColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 20, color: riskColor),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Response Anxiety: ${riskLevel.toUpperCase()}',
                style: TextStyle(
                  fontWeight: AppTheme.fontWeightBold,
                  color: riskColor,
                ),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXXS),
              child: Text(
                '• $s',
                style: TextStyle(fontSize: AppTheme.fontSizeXS),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static void show(
    BuildContext context,
    AIAnalysis analysis,
    String messageBody,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToneDetailSheet(
        analysis: analysis,
        messageBody: messageBody,
      ),
    );
  }
}

