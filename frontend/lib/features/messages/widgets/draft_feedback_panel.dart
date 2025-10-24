import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/draft_analysis.dart';
import 'package:messageai/features/messages/widgets/template_picker.dart';
import 'package:messageai/features/messages/widgets/message_formatter_panel.dart';

/// Collapsible feedback panel for draft message analysis
/// Shows confidence score prominently with progressive disclosure
class DraftFeedbackPanel extends StatefulWidget {
  final DraftAnalysis? analysis;
  final bool isLoading;
  final String? draftMessage; // NEW: For formatting long messages
  final Function(String)? onApplySuggestion;
  final Function(String)? onTemplateSelected; // NEW: For templates
  final VoidCallback? onClose;

  const DraftFeedbackPanel({
    Key? key,
    required this.analysis,
    this.isLoading = false,
    this.draftMessage,
    this.onApplySuggestion,
    this.onTemplateSelected,
    this.onClose,
  }) : super(key: key);

  @override
  State<DraftFeedbackPanel> createState() => _DraftFeedbackPanelState();
}

class _DraftFeedbackPanelState extends State<DraftFeedbackPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState(context);
    }

    if (widget.analysis == null) {
      return const SizedBox.shrink();
    }

    if (!_isExpanded) {
      return _buildCollapsedState(context, widget.analysis!);
    }

    return _buildExpandedState(context, widget.analysis!);
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkGray200 : AppTheme.gray100),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Checking message...',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedState(BuildContext context, DraftAnalysis analysis) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confidenceColor = analysis.getConfidenceColor();

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: confidenceColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: confidenceColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              analysis.getAppropriatenessIcon(),
              color: confidenceColor,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${analysis.confidenceScore}% Confidence',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: confidenceColor,
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                  Text(
                    analysis.getStatusMessage(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more,
              color: isDark ? AppTheme.gray500 : AppTheme.gray600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedState(BuildContext context, DraftAnalysis analysis) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final confidenceColor = analysis.getConfidenceColor();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: confidenceColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with confidence score and collapse button
          Row(
            children: [
              Icon(
                analysis.getAppropriatenessIcon(),
                color: confidenceColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${analysis.confidenceScore}% Confidence',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: confidenceColor,
                        fontWeight: AppTheme.fontWeightBold,
                      ),
                    ),
                    Text(
                      '${analysis.tone} • ${analysis.appropriateness.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_less, size: 20),
                onPressed: () => setState(() => _isExpanded = false),
                tooltip: 'Minimize',
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  tooltip: 'Close',
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Strengths (always show if present)
          if (analysis.strengths.isNotEmpty) ...[
            _buildSection(
              context,
              '✅ Strengths',
              analysis.strengths,
              Colors.green,
              showApplyButton: false,
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // Warnings (show if present)
          if (analysis.warnings.isNotEmpty) ...[
            _buildSection(
              context,
              '⚠️ Watch Out',
              analysis.warnings,
              Colors.orange,
              showApplyButton: false,
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // Suggestions with Apply buttons
          if (analysis.suggestions.isNotEmpty) ...[
            _buildSection(
              context,
              '💡 Suggestions',
              analysis.suggestions,
              Colors.blue,
              showApplyButton: widget.onApplySuggestion != null,
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // ✅ NEW: Situation Detection
          if (analysis.situationDetection != null) ...[
            _buildSituationSection(context, analysis),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // ✅ NEW: Suggested Templates
          if (analysis.suggestedTemplates != null &&
              analysis.suggestedTemplates!.isNotEmpty) ...[
            _buildTemplatesSection(context, analysis),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // ✅ NEW: Message Too Long Warning
          if (widget.draftMessage != null && widget.draftMessage!.length > 500) ...[
            _buildFormattingSection(context),
            const SizedBox(height: AppTheme.spacingS),
          ],

          // Reasoning (collapsible)
          if (analysis.reasoning != null && analysis.reasoning!.isNotEmpty) ...[
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Why this score?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: AppTheme.fontWeightMedium,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Text(
                      analysis.reasoning!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    Color color, {
    required bool showApplyButton,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: AppTheme.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXXS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• ',
                      style: TextStyle(
                        color: color,
                        fontSize: AppTheme.fontSizeS,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (showApplyButton && widget.onApplySuggestion != null) ...[
                    const SizedBox(width: AppTheme.spacingXS),
                    TextButton(
                      onPressed: () => widget.onApplySuggestion!(item),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXXS,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Apply',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXS,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  // ✅ NEW: Build situation detection section
  Widget _buildSituationSection(BuildContext context, DraftAnalysis analysis) {
    final detection = analysis.situationDetection!;
    final color = detection.situationType.getColor();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(detection.situationType.icon, size: 18, color: color),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Detected: ${detection.situationType.displayName}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${(detection.confidence * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXXS),
          Text(
            detection.reasoning,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build templates section
  Widget _buildTemplatesSection(BuildContext context, DraftAnalysis analysis) {
    final theme = Theme.of(context);
    final templates = analysis.suggestedTemplates!.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, size: 18, color: Colors.blue),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Suggested Templates',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXS),
          ...templates.map((template) => Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXXS),
            child: InkWell(
              onTap: () {
                showTemplatePicker(
                  context,
                  analysis.situationDetection?.situationType,
                  (selectedText) {
                    if (widget.onTemplateSelected != null) {
                      widget.onTemplateSelected!(selectedText);
                    }
                  },
                );
              },
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                  const SizedBox(width: AppTheme.spacingXXS),
                  Expanded(
                    child: Text(
                      template.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: AppTheme.spacingS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showTemplatePicker(
                  context,
                  analysis.situationDetection?.situationType,
                  (selectedText) {
                    if (widget.onTemplateSelected != null) {
                      widget.onTemplateSelected!(selectedText);
                    }
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXS,
                ),
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text(
                'Browse All Templates',
                style: TextStyle(fontSize: AppTheme.fontSizeXS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build formatting warning section
  Widget _buildFormattingSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                'Long Message Detected',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXXS),
          Text(
            'This message might be overwhelming. Consider formatting it.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppTheme.spacingS),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: MessageFormatterPanel(
                      originalMessage: widget.draftMessage!,
                      onFormatted: (formatted) {
                        if (widget.onTemplateSelected != null) {
                          widget.onTemplateSelected!(formatted);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXS,
                ),
                side: const BorderSide(color: Colors.orange),
              ),
              child: const Text(
                'Format Message',
                style: TextStyle(fontSize: AppTheme.fontSizeXS),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

