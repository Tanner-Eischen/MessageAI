import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async'; // 🔧 Added for TimeoutException
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/features/messages/widgets/rsd_alert_card.dart';
import 'package:messageai/features/messages/widgets/interpretation_options.dart';
import 'package:messageai/features/messages/widgets/evidence_viewer.dart';
import 'package:messageai/state/ai_providers.dart';

/// Bottom sheet showing detailed tone analysis
class ToneDetailSheet extends ConsumerStatefulWidget {
  final AIAnalysis analysis;
  final String messageBody;
  final String messageId;

  const ToneDetailSheet({
    Key? key,
    required this.analysis,
    required this.messageBody,
    required this.messageId,
  }) : super(key: key);

  @override
  ConsumerState<ToneDetailSheet> createState() => _ToneDetailSheetState();

  /// Static method to show the sheet
  static void show(
    BuildContext context,
    AIAnalysis analysis,
    String messageBody,
    String messageId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: ToneDetailSheet(
            analysis: analysis,
            messageBody: messageBody,
            messageId: messageId,
          ),
        ),
      ),
    );
  }
}

class _ToneDetailSheetState extends ConsumerState<ToneDetailSheet> {
  bool _isLoadingInterpretation = false;
  AIAnalysis? _enhancedAnalysis;
  bool _boundaryExpanded = false; // NEW: Track boundary section expansion

  @override
  void initState() {
    super.initState();
    _enhancedAnalysis = widget.analysis;
  }

  /// Trigger deeper interpretation with RSD detection and alternatives
  Future<void> _interpretMessage() async {
    if (_isLoadingInterpretation) return;

    setState(() {
      _isLoadingInterpretation = true;
    });

    try {
      final service = ref.read(messageInterpreterServiceProvider);
      
      // 🔧 Add timeout here too, with a 20s total timeout (15s from service + buffer)
      final analysis = await service.interpretMessage(
        widget.messageId,
        widget.messageBody,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Deeper interpretation took too long');
        },
      );

      if (mounted) {
        setState(() {
          _enhancedAnalysis = analysis;
          _isLoadingInterpretation = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Deeper interpretation complete!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInterpretation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to interpret message: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final analysis = _enhancedAnalysis ?? widget.analysis;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
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
              
              // 🟣 PRIMARY: Tone - The headline
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    analysis.tone,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.purple,
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingXS),
              
              // Subtle secondary info
              if (analysis.urgencyLevel != null)
                Text(
                  'Urgency: ${analysis.urgencyLevel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                  ),
                ),
              
              if (analysis.intent != null) ...[
                const SizedBox(height: AppTheme.spacingXXS),
                Text(
                  analysis.intent!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: AppTheme.spacingL),
              
              // ⚠️ WARNINGS FIRST (RSD, Boundary Issues) - Always visible
              if (analysis.rsdTriggers != null && analysis.rsdTriggers!.isNotEmpty) ...[
                RSDAlertCard(triggers: analysis.rsdTriggers!),
                const SizedBox(height: AppTheme.spacingM),
              ],
              
              // 🔍 COLLAPSIBLE ACCORDION SECTIONS
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    // Boundary Alert Section (collapsed by default)
                    if (analysis.boundaryAnalysis?.hasViolation == true) ...[
                      _buildAccordionSection(
                        context,
                        'Boundary Alert',
                        Icons.shield_outlined,
                        isDark,
                        showWarning: true,
                        children: [
                          _buildBoundarySection(context, analysis.boundaryAnalysis!, isDark),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                    ],
                    
                    // Details Section
                    _buildAccordionSection(
                      context,
                      'Details',
                      Icons.info_outline,
                      isDark,
                      children: [
                        if (analysis.confidenceScore != null) ...[
                          _buildConfidenceBar(context, analysis.confidenceScore!, isDark),
                          const SizedBox(height: AppTheme.spacingM),
                        ],
                        
                        if (analysis.intensity != null) ...[
                          _buildSubtleRow(
                            'Intensity',
                            _formatIntensity(analysis.intensity!),
                            isDark,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                        ],
                        
                        if (analysis.secondaryTones != null && analysis.secondaryTones!.isNotEmpty) ...[
                          _buildSubtleRow(
                            'Secondary Tones',
                            analysis.secondaryTones!.join(', '),
                            isDark,
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                        ],
                      ],
                    ),
                    
                    // Context Flags Section
                    if (analysis.contextFlags != null && analysis.contextFlags!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      _buildAccordionSection(
                        context,
                        'Context',
                        Icons.tag_outlined,
                        isDark,
                        children: [
                          _buildContextFlags(context, analysis.contextFlags!, isDark),
                        ],
                      ),
                    ],
                    
                    // Anxiety Assessment Section
                    if (analysis.anxietyAssessment != null) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      _buildAccordionSection(
                        context,
                        'Anxiety Assessment',
                        Icons.psychology_outlined,
                        isDark,
                        children: [
                          _buildAnxietyAssessment(context, analysis.anxietyAssessment!, isDark),
                        ],
                      ),
                    ],
                    
                    // Interpretations Section
                    if (analysis.alternativeInterpretations != null ||
                        !_isLoadingInterpretation) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      _buildAccordionSection(
                        context,
                        'Deeper Interpretation',
                        Icons.lightbulb_outlined,
                        isDark,
                        children: [
                          if (analysis.alternativeInterpretations == null ||
                              analysis.alternativeInterpretations!.isEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingInterpretation ? null : _interpretMessage,
                                icon: _isLoadingInterpretation
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isLoadingInterpretation ? 'Analyzing...' : 'Analyze'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            )
                          else
                            InterpretationOptions(interpretations: analysis.alternativeInterpretations!),
                        ],
                      ),
                    ],
                    
                    // Evidence Section
                    if (analysis.evidence != null && analysis.evidence!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingS),
                      _buildAccordionSection(
                        context,
                        'Evidence',
                        Icons.dataset_outlined,
                        isDark,
                        children: [
                          EvidenceViewer(evidence: analysis.evidence!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build an accordion section with subtle styling like context panel
  Widget _buildAccordionSection(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark, {
    required List<Widget> children,
    bool showWarning = false,
  }) {
    final theme = Theme.of(context);
    
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingS, vertical: 0),
      childrenPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingM,
      ),
      title: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray700,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
          if (showWarning) ...[
            const SizedBox(width: AppTheme.spacingXS),
            Icon(
              Icons.warning_outlined,
              size: 16,
              color: AppTheme.accentOrange,
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.expand_more,
        size: 20,
        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
      ),
      children: children,
    );
  }

  /// Build a subtle row for simple text info
  Widget _buildSubtleRow(
    String label,
    String value,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: AppTheme.fontWeightMedium,
            color: isDark ? AppTheme.gray300 : AppTheme.gray800,
          ),
        ),
      ],
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
  String _formatIntensity(int intensity) {
    // Convert number (1-10) to descriptive text
    if (intensity >= 9) {
      return 'Very High';
    } else if (intensity >= 7) {
      return 'High';
    } else if (intensity >= 5) {
      return 'Medium';
    } else if (intensity >= 3) {
      return 'Low';
    } else {
      return 'Very Low';
    }
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

  Widget _buildBoundarySection(BuildContext context, BoundaryAnalysis boundary, bool isDark) {
    final color = _getBoundaryColor(boundary.severity);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: color,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                '⚠️ Boundary Alert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: AppTheme.fontWeightBold,
                  color: color,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getBoundaryTypeLabel(boundary.type),
              style: TextStyle(
                fontSize: 12,
                fontWeight: AppTheme.fontWeightBold,
                color: color,
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Explanation
          Text(
            boundary.explanation,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppTheme.gray300 : AppTheme.gray800,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Suggested responses
          Text(
            'Boundary-Respecting Responses:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: AppTheme.fontWeightBold,
              color: isDark ? AppTheme.gray200 : AppTheme.gray800,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          ...boundary.suggestedResponses.asMap().entries.map((entry) {
            final index = entry.key;
            final response = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: response));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Response copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkGray200 : AppTheme.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: AppTheme.fontWeightBold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          response,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.gray300 : AppTheme.gray800,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.copy,
                        size: 16,
                        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
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
  
  String _getBoundaryTypeLabel(BoundaryViolationType type) {
    switch (type) {
      case BoundaryViolationType.afterHours:
        return 'After Hours';
      case BoundaryViolationType.urgentPressure:
        return 'Urgent Pressure';
      case BoundaryViolationType.guiltTripping:
        return 'Guilt Trip';
      case BoundaryViolationType.overstepping:
        return 'Overstepping';
      case BoundaryViolationType.repeated:
        return 'Repeated Pattern';
      default:
        return 'Boundary Issue';
    }
  }

  /// Highlight card for the main tone
  Widget _buildHighlightCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Small info card for secondary info
  Widget _buildSmallCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

