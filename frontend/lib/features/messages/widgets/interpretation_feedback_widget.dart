import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// Widget for users to rate how helpful the interpretation was
class InterpretationFeedbackWidget extends StatefulWidget {
  final String messageId;
  final String analysisId;
  final String senderId;
  final List<String>? interpretationOptions;
  final VoidCallback? onFeedbackSubmitted;

  const InterpretationFeedbackWidget({
    super.key,
    required this.messageId,
    required this.analysisId,
    required this.senderId,
    this.interpretationOptions,
    this.onFeedbackSubmitted,
  });

  @override
  State<InterpretationFeedbackWidget> createState() =>
      _InterpretationFeedbackWidgetState();
}

class _InterpretationFeedbackWidgetState
    extends State<InterpretationFeedbackWidget> {
  String? _selectedInterpretation;
  bool? _wasHelpful;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  Future<void> _submitFeedback() async {
    if (_selectedInterpretation == null && _wasHelpful == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch ~/ 1000;

      // Call the ai-save-interpretation-feedback Edge Function
      final response = await Future.delayed(
        const Duration(milliseconds: 500), // Simulate API call
        () async {
          // In production, call the actual Edge Function
          // For now, we'll just simulate success
          return {'success': true};
        },
      );

      if (response['success'] == true) {
        setState(() {
          _hasSubmitted = true;
          _isSubmitting = false;
        });

        widget.onFeedbackSubmitted?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thanks! This helps us learn.'),
            duration: Duration(seconds: 2),
          ),
        );

        // Auto-hide after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _hasSubmitted = false);
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_hasSubmitted) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                'Feedback recorded! 🎉',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            '📊 Was this helpful?',
            style: TextStyle(
              fontWeight: AppTheme.fontWeightBold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Interpretation selector (if options provided)
          if (widget.interpretationOptions != null &&
              widget.interpretationOptions!.isNotEmpty) ...[
            const Text(
              'Which interpretation was correct?',
              style: TextStyle(fontSize: 12, color: AppTheme.gray600),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ...widget.interpretationOptions!.map((interpretation) {
              final isSelected = _selectedInterpretation == interpretation;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                child: Material(
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedInterpretation = interpretation;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXS),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => setState(() {
                              _selectedInterpretation = interpretation;
                            }),
                          ),
                          Expanded(
                            child: Text(
                              interpretation,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.blue
                                    : AppTheme.gray700,
                                fontWeight: isSelected
                                    ? AppTheme.fontWeightMedium
                                    : AppTheme.fontWeightRegular,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: AppTheme.spacingM),
          ],

          // Helpful rating
          const Text(
            'Was the analysis helpful?',
            style: TextStyle(fontSize: 12, color: AppTheme.gray600),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildFeedbackButton(
                  '👍 Yes',
                  _wasHelpful == true,
                  () => setState(() => _wasHelpful = true),
                  Colors.green,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildFeedbackButton(
                  '👎 No',
                  _wasHelpful == false,
                  () => setState(() => _wasHelpful = false),
                  Colors.red,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: _buildFeedbackButton(
                  '😐 Neutral',
                  _wasHelpful == null && (_selectedInterpretation != null || _wasHelpful != null),
                  () => setState(() => _wasHelpful = null),
                  Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusXS),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected
                    ? AppTheme.fontWeightMedium
                    : AppTheme.fontWeightRegular,
                color: isSelected ? color : AppTheme.gray700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
