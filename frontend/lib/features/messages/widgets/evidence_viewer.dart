import 'package:flutter/material.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// Widget showing evidence that supports the tone analysis (Feature 3: Evidence-Based Tone Analysis)
/// Includes "Teach Me" mode and tone mini-lessons
class EvidenceViewer extends StatefulWidget {
  final List<Evidence> evidence;
  final String tone; // 🆕 NEW: Pass tone to provide mini-lessons
  final String messageBody; // 🆕 NEW: For highlighting evidence in context

  const EvidenceViewer({
    super.key,
    required this.evidence,
    required this.tone,
    required this.messageBody,
  });

  @override
  State<EvidenceViewer> createState() => _EvidenceViewerState();
}

class _EvidenceViewerState extends State<EvidenceViewer> {
  bool _expanded = false;
  bool _teachMode = false; // 🆕 NEW: Toggle teach mode
  String? _selectedEvidenceForLesson; // 🆕 NEW: Which evidence is selected for detail view

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.evidence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                'No specific evidence found in message',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Teach Me toggle
          Row(
            children: [
              const Icon(Icons.search, color: Colors.teal, size: 20),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Text(
                  'Evidence (${widget.evidence.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              // 🆕 NEW: Teach Me toggle button
              Tooltip(
                message: 'Show reasoning chain',
                child: IconButton(
                  icon: Icon(
                    _teachMode ? Icons.school : Icons.school_outlined,
                    size: 20,
                    color: _teachMode ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () => setState(() => _teachMode = !_teachMode),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          
          // 🆕 NEW: Teach Mode banner
          if (_teachMode) ...[
            const SizedBox(height: AppTheme.spacingS),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Click any evidence to understand the reasoning',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_expanded) ...[
            const SizedBox(height: AppTheme.spacingM),
            if (!_teachMode)
              const Text(
                'Specific evidence supporting this analysis:',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              )
            else
              const Text(
                'Learn how we reached this conclusion:',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: AppTheme.spacingS),
            
            // Evidence items
            ..._selectedEvidenceForLesson != null && _teachMode
                ? [_buildDetailedLessonView(context, isDark)]
                : widget.evidence.map((evidence) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: _teachMode
                      ? _EvidenceItemTeachMode(
                          evidence: evidence,
                          messageBody: widget.messageBody,
                          onTap: () => setState(
                            () => _selectedEvidenceForLesson = evidence.quote,
                          ),
                        )
                      : _EvidenceItem(evidence: evidence),
                )).toList(),
          ],
        ],
      ),
    );
  }

  // 🆕 NEW: Build detailed lesson view for selected evidence
  Widget _buildDetailedLessonView(BuildContext context, bool isDark) {
    final selectedEvidence = widget.evidence.firstWhere(
      (e) => e.quote == _selectedEvidenceForLesson,
      orElse: () => widget.evidence.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to all evidence'),
          onPressed: () => setState(() => _selectedEvidenceForLesson = null),
        ),
        const SizedBox(height: AppTheme.spacingM),
        
        // Detailed explanation card
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why This Evidence Matters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                selectedEvidence.reasoning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              // Mini-lesson
              _buildMiniLesson(context, selectedEvidence.type),
            ],
          ),
        ),
      ],
    );
  }

  // 🆕 NEW: Build mini-lessons for each evidence type
  Widget _buildMiniLesson(BuildContext context, String type) {
    final lessons = <String, String>{
      'keyword': '''**How to Spot Keywords:**
Certain words reliably indicate emotion or urgency:
• Positive: "love", "excited", "amazing", "wonderful"
• Negative: "hate", "terrible", "awful", "disgusted"
• Urgent: "ASAP", "immediately", "now", "emergency"
• Uncertain: "maybe", "perhaps", "might", "could"

Look for these emotion words - they're usually reliable tone indicators.''',
      'punctuation': '''**Understanding Punctuation:**
Punctuation changes the entire meaning:
• !!!  = Very strong emotion
• ???  = Confusion or urgency
• ... = Uncertainty or trailing off
• CAPS = Shouting or strong emphasis
• :) = Friendly, softens tone
• :( = Sad or disappointed

One ! = Normal. Three !!! = Very intense.''',
      'emoji': '''**Emoji Signals:**
Emojis are explicit tone markers:
• 😊😂😍 = Friendly, happy, warm
• 😡😤😠 = Angry or frustrated
• 😬😰😟 = Worried or anxious
• 🙄😒🤐 = Sarcasm or dismissal
• ❤️💙🫂 = Caring, supportive

Emojis help clarify when text is ambiguous.''',
      'length': '''**What Message Length Reveals:**
Very short messages (≤5 words):
• Can be dismissive: "ok", "k", "sure"
• Or just busy: "on it!"

Very long messages (≥100 words):
• Show engagement and enthusiasm
• Or anxiety/info-dumping

Compare to their normal message length.''',
      'pattern': '''**Recognizing Patterns:**
Patterns across multiple messages reveal intent:
• Always short = Might be their normal style
• Suddenly very short = Might indicate upset
• Enthusiastic usually, short now = Change in tone
• Consistent patterns = More reliable than one message

Track how someone usually communicates.''',
      'timing': '''**Timing Context:**
When a message is sent matters:
• Late night urgent: boundary-pushing
• Early morning routine: normal for them?
• Delayed response: They might be busy
• Immediate response: Engaged/urgent

Timing + content = fuller picture.''',
    };

    final lesson = lessons[type] ?? 'Learn more about this evidence type.';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Mini-Lesson',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.amber.shade700,
              fontWeight: AppTheme.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            lesson,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Original Evidence Item widget
class _EvidenceItem extends StatelessWidget {
  final Evidence evidence;

  const _EvidenceItem({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(evidence.type);
    final typeIcon = _getTypeIcon(evidence.type);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and quote
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(typeIcon, size: 16, color: typeColor),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        evidence.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: AppTheme.fontWeightBold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Text(
                        '"${evidence.quote}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: AppTheme.fontWeightSemibold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          
          // What it supports
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              const SizedBox(width: AppTheme.spacingXS),
              Expanded(
                child: Text(
                  'Supports: ${evidence.supports}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: AppTheme.fontWeightSemibold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXXS),
          
          // Reasoning
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              evidence.reasoning,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'keyword':
        return Colors.blue;
      case 'punctuation':
        return Colors.orange;
      case 'emoji':
        return Colors.pink;
      case 'length':
        return Colors.purple;
      case 'pattern':
        return Colors.teal;
      case 'timing':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'keyword':
        return Icons.text_fields;
      case 'punctuation':
        return Icons.format_quote;
      case 'emoji':
        return Icons.emoji_emotions;
      case 'length':
        return Icons.straighten;
      case 'pattern':
        return Icons.pattern;
      case 'timing':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}

// 🆕 NEW: Evidence Item for Teach Mode with interactive features
class _EvidenceItemTeachMode extends StatelessWidget {
  final Evidence evidence;
  final String messageBody;
  final VoidCallback onTap;

  const _EvidenceItemTeachMode({
    required this.evidence,
    required this.messageBody,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(evidence.type);
    final typeIcon = _getTypeIcon(evidence.type);
    final isHighlightedInMessage = messageBody.contains(evidence.quote);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: typeColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, size: 18, color: typeColor),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    evidence.quote,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: AppTheme.fontWeightBold,
                      color: typeColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: typeColor.withOpacity(0.6),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              evidence.supports,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (!isHighlightedInMessage) ...[
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                '(Tap to learn more)',
                style: TextStyle(
                  fontSize: 11,
                  color: typeColor,
                  fontWeight: AppTheme.fontWeightMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'keyword':
        return Colors.blue;
      case 'punctuation':
        return Colors.orange;
      case 'emoji':
        return Colors.pink;
      case 'length':
        return Colors.purple;
      case 'pattern':
        return Colors.teal;
      case 'timing':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'keyword':
        return Icons.text_fields;
      case 'punctuation':
        return Icons.format_quote;
      case 'emoji':
        return Icons.emoji_emotions;
      case 'length':
        return Icons.straighten;
      case 'pattern':
        return Icons.pattern;
      case 'timing':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}

