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
  bool _strengthsExpanded = true; // Always show strengths
  bool _warningsExpanded = true; // Always show warnings
  bool _suggestionsExpanded = false;
  bool _situationExpanded = false;
  bool _templatesExpanded = false;
  bool _formattingExpanded = false;
  bool _reasoningExpanded = false;

  /// Initialize state with better defaults for calming disclosure
  @override
  void initState() {
    super.initState();
    _strengthsExpanded = false; // Start collapsed for calm disclosure
    _warningsExpanded = false; // Start collapsed
    _suggestionsExpanded = false; // Start collapsed
    _situationExpanded = false;
    _templatesExpanded = false;
    _formattingExpanded = false;
    _reasoningExpanded = false;
  }

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
    const primaryBlue = Color(0xFF2196F3);
    const lightBlue = Color(0xFFE3F2FD);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? AppTheme.darkGray300 : const Color(0xFFE0E7FF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue header with just the title
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: isDark ? primaryBlue.withOpacity(0.15) : lightBlue,
              border: Border(
                bottom: BorderSide(
                  color: primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Message Check',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                    color: primaryBlue,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.expand_less, size: 20),
                      onPressed: () => setState(() => _isExpanded = false),
                      tooltip: 'Collapse',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: AppTheme.spacingXS),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: widget.onClose,
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Scrollable content - works with constrained height from parent
          Scrollbar(
            thumbVisibility: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confidence Summary
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              analysis.getAppropriatenessIcon(),
                              color: primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${analysis.confidenceScore}% Confidence',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: primaryBlue,
                                    fontWeight: AppTheme.fontWeightBold,
                                  ),
                                ),
                                Text(
                                  analysis.getStatusMessage(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text(
                          '${analysis.tone} • ${analysis.appropriateness.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Strengths (START COLLAPSED)
                  if (analysis.strengths.isNotEmpty) ...[
                    _buildCollapsibleSection(
                      context,
                      '✅ Strengths',
                      analysis.strengths,
                      Colors.green,
                      _strengthsExpanded,
                      (expanded) => setState(() => _strengthsExpanded = expanded),
                      showApplyButton: false,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Warnings (START COLLAPSED)
                  if (analysis.warnings.isNotEmpty) ...[
                    _buildCollapsibleSection(
                      context,
                      '⚠️ Things to Consider',
                      analysis.warnings,
                      Colors.orange.withOpacity(0.8),
                      _warningsExpanded,
                      (expanded) => setState(() => _warningsExpanded = expanded),
                      showApplyButton: false,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Suggestions (START COLLAPSED - BLUE)
                  if (analysis.suggestions.isNotEmpty) ...[
                    _buildCollapsibleSection(
                      context,
                      '💡 Suggestions',
                      analysis.suggestions,
                      primaryBlue,
                      _suggestionsExpanded,
                      (expanded) => setState(() => _suggestionsExpanded = expanded),
                      showApplyButton: widget.onApplySuggestion != null,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Situation Detection (START COLLAPSED)
                  if (analysis.situationDetection != null) ...[
                    _buildCollapsibleSituationSection(context, analysis),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Suggested Templates (START COLLAPSED)
                  if (analysis.suggestedTemplates != null &&
                      analysis.suggestedTemplates!.isNotEmpty) ...[
                    _buildCollapsibleTemplatesSection(context, analysis),
                    const SizedBox(height: AppTheme.spacingL),
                  ] else ...[
                    // Placeholder when no templates
                    _buildEmptyState(
                      context,
                      icon: Icons.note_alt_outlined,
                      title: 'No Templates',
                      description: 'Templates will appear based on your message context',
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Message Formatting (START COLLAPSED)
                  if (widget.draftMessage != null && widget.draftMessage!.length > 500) ...[
                    _buildCollapsibleFormattingSection(context),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Reasoning (START COLLAPSED)
                  if (analysis.reasoning != null && analysis.reasoning!.isNotEmpty) ...[
                    _buildCollapsibleReasoningSection(context, analysis),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state placeholder
  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkGray200 : AppTheme.gray100),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isDark ? AppTheme.gray500 : AppTheme.gray400,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXS),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray600 : AppTheme.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Collapsible section for list items
  Widget _buildCollapsibleSection(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
    bool isExpanded,
    Function(bool) onExpansionChanged, {
    required bool showApplyButton,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.spacingS,
            right: AppTheme.spacingS,
            bottom: AppTheme.spacingS,
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Icon(Icons.verified_outlined, size: 16, color: color),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? AppTheme.gray300 : AppTheme.gray800,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                ),
                child: Text(
                  '${items.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          children: items.map((item) => Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXXS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXS),
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
          )).toList(),
        ),
      ),
    );
  }

  // Collapsible situation detection section
  Widget _buildCollapsibleSituationSection(BuildContext context, DraftAnalysis analysis) {
    final detection = analysis.situationDetection!;
    final color = detection.situationType.getColor();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.spacingS,
            right: AppTheme.spacingS,
            bottom: AppTheme.spacingS,
          ),
          initiallyExpanded: _situationExpanded,
          onExpansionChanged: (expanded) => setState(() => _situationExpanded = expanded),
          leading: Icon(detection.situationType.icon, size: 16, color: color),
          title: Text(
            '${detection.situationType.displayName} Detected',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray800,
              fontWeight: AppTheme.fontWeightBold,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                ),
                child: Text(
                  '${(detection.confidence * 100).toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ),
              Icon(
                _situationExpanded ? Icons.expand_less : Icons.expand_more,
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
            ],
          ),
          children: [
            Text(
              detection.reasoning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Collapsible templates section
  Widget _buildCollapsibleTemplatesSection(BuildContext context, DraftAnalysis analysis) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Colors.blue;
    final templates = analysis.suggestedTemplates!;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.spacingS,
            right: AppTheme.spacingS,
            bottom: AppTheme.spacingS,
          ),
          initiallyExpanded: _templatesExpanded,
          onExpansionChanged: (expanded) => setState(() => _templatesExpanded = expanded),
          leading: const Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Response Templates',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? AppTheme.gray300 : AppTheme.gray800,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                ),
                child: Text(
                  '${templates.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
              ),
            ],
          ),
          children: [
            ...templates.take(3).map((template) => Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXXS),
              child: InkWell(
                onTap: () {
                  if (widget.onTemplateSelected != null) {
                    widget.onTemplateSelected!(template.template);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXS),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkGray300 : AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: AppTheme.spacingXS),
                      Expanded(
                        child: Text(
                          template.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: AppTheme.fontWeightMedium,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: color,
                      ),
                    ],
                  ),
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
                  side: BorderSide(color: color),
                ),
                child: const Text(
                  'Browse All Templates',
                  style: TextStyle(fontSize: AppTheme.fontSizeXS),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Collapsible formatting section
  Widget _buildCollapsibleFormattingSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.spacingS,
            right: AppTheme.spacingS,
            bottom: AppTheme.spacingS,
          ),
          initiallyExpanded: _formattingExpanded,
          onExpansionChanged: (expanded) => setState(() => _formattingExpanded = expanded),
          leading: const Icon(Icons.format_list_bulleted, size: 16, color: Colors.orange),
          title: Text(
            'Message Formatting',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.gray300 : AppTheme.gray800,
              fontWeight: AppTheme.fontWeightBold,
            ),
          ),
          children: [
            Text(
              'This message is quite long (${widget.draftMessage!.length} characters). Consider breaking it into sections or using bullet points to make it easier to read.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingS,
                  ),
                ),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text(
                  'Auto-Format Message',
                  style: TextStyle(fontSize: AppTheme.fontSizeS),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Collapsible reasoning section
  Widget _buildCollapsibleReasoningSection(BuildContext context, DraftAnalysis analysis) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkGray300 : AppTheme.gray100),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: isDark ? AppTheme.darkGray400 : AppTheme.gray300,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXXS,
          ),
          childrenPadding: const EdgeInsets.only(
            left: AppTheme.spacingS,
            right: AppTheme.spacingS,
            bottom: AppTheme.spacingS,
          ),
          initiallyExpanded: _reasoningExpanded,
          onExpansionChanged: (expanded) => setState(() => _reasoningExpanded = expanded),
          leading: Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
          ),
          title: Text(
            'Why This Score?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? AppTheme.gray400 : AppTheme.gray700,
              fontWeight: AppTheme.fontWeightMedium,
            ),
          ),
          children: [
            Text(
              analysis.reasoning!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.gray500 : AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

