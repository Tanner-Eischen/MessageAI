import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/state/ai_providers.dart';

/// Simplified tone detail sheet with progressive disclosure
/// Designed for neurodivergent users - calm, clear, less overwhelming
class ToneDetailSheetSimplified extends ConsumerStatefulWidget {
  final AIAnalysis analysis;
  final String messageBody;
  final String messageId;

  const ToneDetailSheetSimplified({
    Key? key,
    required this.analysis,
    required this.messageBody,
    required this.messageId,
  }) : super(key: key);

  @override
  ConsumerState<ToneDetailSheetSimplified> createState() => _ToneDetailSheetSimplifiedState();

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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ToneDetailSheetSimplified(
          analysis: analysis,
          messageBody: messageBody,
          messageId: messageId,
        ),
      ),
    );
  }
}

class _ToneDetailSheetSimplifiedState extends ConsumerState<ToneDetailSheetSimplified> {
  String? _expandedSection;
  bool _isLoadingInterpretation = false;
  AIAnalysis? _enhancedAnalysis;

  @override
  void initState() {
    super.initState();
    _enhancedAnalysis = widget.analysis;
  }

  /// Trigger deeper interpretation
  Future<void> _interpretMessage() async {
    if (_isLoadingInterpretation) return;

    setState(() => _isLoadingInterpretation = true);

    try {
      final service = ref.read(messageInterpreterServiceProvider);
      final analysis = await service.interpretMessage(
        widget.messageId,
        widget.messageBody,
      );

      if (mounted) {
        setState(() {
          _enhancedAnalysis = analysis;
          _isLoadingInterpretation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInterpretation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.gray600 : AppTheme.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              children: [
                // Quick summary (always visible)
                _buildQuickSummary(analysis, isDark),
                
                const SizedBox(height: AppTheme.spacingL),
                
                // RSD Alert (if present - always visible, high priority)
                if (analysis.rsdTriggers != null && analysis.rsdTriggers!.isNotEmpty)
                  _buildRSDAlert(analysis.rsdTriggers!, isDark),
                
                // Deeper interpretation button
                if (analysis.alternativeInterpretations == null ||
                    analysis.alternativeInterpretations!.isEmpty)
                  _buildInterpretButton(isDark),
                
                const SizedBox(height: AppTheme.spacingM),
                
                // Expandable sections (progressive disclosure)
                _buildExpandableSection(
                  'details',
                  'More Details',
                  Icons.info_outline_rounded,
                  isDark,
                  () => _buildDetailsSection(analysis, isDark),
                ),
                
                if (analysis.alternativeInterpretations != null &&
                    analysis.alternativeInterpretations!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  _buildExpandableSection(
                    'interpretations',
                    'Other Meanings',
                    Icons.lightbulb_outline_rounded,
                    isDark,
                    () => _buildInterpretationsSection(analysis.alternativeInterpretations!, isDark),
                  ),
                ],
                
                if (analysis.evidence != null && analysis.evidence!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  _buildExpandableSection(
                    'evidence',
                    'Why AI Thinks This',
                    Icons.checklist_rounded,
                    isDark,
                    () => _buildEvidenceSection(analysis.evidence!, isDark),
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkGray300 : AppTheme.gray200,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick summary - always visible, easy to scan
  Widget _buildQuickSummary(AIAnalysis analysis, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: _getToneColor(analysis.tone).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getToneColor(analysis.tone).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tone (primary info)
          Row(
            children: [
              Icon(
                _getToneIcon(analysis.tone),
                color: _getToneColor(analysis.tone),
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  analysis.tone,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.white : AppTheme.darkGray100,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingS),
          
          // Key stats (urgency, intensity)
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingXS,
            children: [
              if (analysis.urgencyLevel != null)
                _buildChip(
                  analysis.urgencyLevel!,
                  _getUrgencyColor(analysis.urgencyLevel),
                  isDark,
                ),
              if (analysis.intensity != null)
                _buildChip(
                  'Intensity: ${analysis.intensity}/10',
                  Colors.blue,
                  isDark,
                ),
              if (analysis.intent != null)
                _buildChip(
                  analysis.intent!,
                  Colors.purple,
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// RSD alert - high priority, always visible
  Widget _buildRSDAlert(List<RSDTrigger> triggers, bool isDark) {
    final highSeverity = triggers.where((t) => t.severity == 'high').toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEC4899).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFEC4899),
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'RSD Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.white : AppTheme.darkGray100,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            highSeverity.isNotEmpty
                ? highSeverity.first.explanation
                : triggers.first.explanation,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.gray400 : AppTheme.gray700,
            ),
          ),
        ],
      ),
    );
  }

  /// Interpret button
  Widget _buildInterpretButton(bool isDark) {
    return FilledButton.icon(
      onPressed: _isLoadingInterpretation ? null : _interpretMessage,
      icon: _isLoadingInterpretation
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.psychology_outlined, size: 20),
      label: Text(
        _isLoadingInterpretation
            ? 'Analyzing...'
            : 'Get Deeper Interpretation',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF7C3AED),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: 12,
        ),
      ),
    );
  }

  /// Expandable section with progressive disclosure
  Widget _buildExpandableSection(
    String id,
    String title,
    IconData icon,
    bool isDark,
    Widget Function() contentBuilder,
  ) {
    final isExpanded = _expandedSection == id;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSection = isExpanded ? null : id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.white : AppTheme.darkGray100,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingM,
                0,
                AppTheme.spacingM,
                AppTheme.spacingM,
              ),
              child: contentBuilder(),
            ),
        ],
      ),
    );
  }

  /// Details section content
  Widget _buildDetailsSection(AIAnalysis analysis, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (analysis.confidenceScore != null) ...[
          _buildDetailItem(
            'Confidence',
            '${(analysis.confidenceScore! * 100).toStringAsFixed(0)}%',
            isDark,
          ),
          const SizedBox(height: AppTheme.spacingS),
        ],
        if (analysis.contextFlags != null && analysis.contextFlags!.isNotEmpty)
          ...analysis.contextFlags!.entries
              .where((e) => e.value == true)
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                    child: _buildDetailItem(
                      _formatFlag(e.key),
                      '✓',
                      isDark,
                    ),
                  )),
      ],
    );
  }

  /// Interpretations section content
  Widget _buildInterpretationsSection(List<MessageInterpretation> interps, bool isDark) {
    return Column(
      children: interps.map((interp) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkGray100 : AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLikelihoodColor(interp.likelihood).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${interp.likelihood}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getLikelihoodColor(interp.likelihood),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXS),
                  Expanded(
                    child: Text(
                      interp.interpretation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.white : AppTheme.darkGray100,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Evidence section content
  Widget _buildEvidenceSection(List<Evidence> evidence, bool isDark) {
    return Column(
      children: evidence.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingXS),
          padding: const EdgeInsets.all(AppTheme.spacingS),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkGray100 : AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Expanded(
                child: Text(
                  e.quote,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.white : AppTheme.darkGray100,
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getToneColor(String tone) {
    final lower = tone.toLowerCase();
    if (lower.contains('urgent') || lower.contains('critical')) return Colors.red;
    if (lower.contains('sad') || lower.contains('disappointed')) return Colors.blue;
    if (lower.contains('angry') || lower.contains('frustrated')) return Colors.orange;
    if (lower.contains('happy') || lower.contains('excited')) return Colors.green;
    return const Color(0xFF7C3AED);
  }

  IconData _getToneIcon(String tone) {
    final lower = tone.toLowerCase();
    if (lower.contains('urgent') || lower.contains('critical')) return Icons.error_rounded;
    if (lower.contains('sad')) return Icons.sentiment_dissatisfied_rounded;
    if (lower.contains('angry')) return Icons.sentiment_very_dissatisfied_rounded;
    if (lower.contains('happy')) return Icons.sentiment_satisfied_rounded;
    return Icons.sentiment_neutral_rounded;
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency?.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getLikelihoodColor(int likelihood) {
    if (likelihood >= 70) return Colors.green;
    if (likelihood >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatFlag(String flag) {
    return flag.replaceAll('_', ' ').split(' ').map((w) => 
      w[0].toUpperCase() + w.substring(1)
    ).join(' ');
  }
}

