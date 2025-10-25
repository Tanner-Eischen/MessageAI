import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/conversation_context.dart';

/// Displays relationship context and conversation history
/// Uses RAG search results to show relevant information
class ContextPanel extends StatefulWidget {
  final String conversationId;
  final ConversationContext? context;
  
  const ContextPanel({
    Key? key,
    required this.conversationId,
    this.context,
  }) : super(key: key);
  
  @override
  State<ContextPanel> createState() => _ContextPanelState();
}

class _ContextPanelState extends State<ContextPanel> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (widget.context == null) {
      return _buildLoadingState(isDark);
    }
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildContextContent(isDark),
          ],
        ],
      ),
    );
  }
  
  Widget _buildHeader(bool isDark) {
    final theme = Theme.of(context);
    
    
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // 🟢 GREEN: Sparkle for RAG Context Panel
            Icon(
              Icons.auto_awesome,
              size: 20,
              color: Colors.green,
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversation Context',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.white : AppTheme.darkGray100,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getContextSummary(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContextContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last discussed
          _buildSection(
            icon: Icons.chat_bubble_outline,
            title: 'Last Discussed',
            content: widget.context!.lastDiscussed,
            isDark: isDark,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Key points
          if (widget.context!.keyPoints.isNotEmpty)
            _buildKeyPointsSection(isDark),
          
          if (widget.context!.keyPoints.isNotEmpty)
            const SizedBox(height: AppTheme.spacingM),
          
          // Pending questions
          if (widget.context!.pendingQuestions.isNotEmpty)
            _buildPendingQuestionsSection(isDark),
          
          if (widget.context!.pendingQuestions.isNotEmpty)
            const SizedBox(height: AppTheme.spacingM),
          
          // Safe topics
          if (widget.context!.safeTopics != null &&
              widget.context!.safeTopics!.isNotEmpty)
            _buildSafeTopicsSection(isDark),
          
          if (widget.context!.safeTopics != null &&
              widget.context!.safeTopics!.isNotEmpty)
            const SizedBox(height: AppTheme.spacingM),
          
          // Relationship type
          if (widget.context!.relationshipType != null)
            _buildRelationshipSection(isDark),
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.white : AppTheme.darkGray100,
            height: 1.4,
          ),
        ),
      ],
    );
  }
  
  Widget _buildKeyPointsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            const SizedBox(width: 6),
            Text(
              'Recent Topics',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.context!.keyPoints.take(5).map((point) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  point.getTimeAgo(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.gray500 : AppTheme.gray500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildPendingQuestionsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Unanswered Questions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.context!.pendingQuestions.map((question) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $question',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange[900],
                  height: 1.4,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSafeTopicsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.topic_outlined,
              size: 16,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
            const SizedBox(width: 6),
            Text(
              'Safe Topics',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.context!.safeTopics!.map((topic) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    topic.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    topic.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildRelationshipSection(bool isDark) {
    final relationship = widget.context!.relationshipType!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_outline,
            size: 18,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relationship',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF6366F1).withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relationship,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading conversation context...',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.gray400 : AppTheme.gray600,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getContextSummary() {
    if (widget.context == null) {
      return 'Loading...';
    }
    
    final parts = <String>[];
    
    if (widget.context!.pendingQuestions.isNotEmpty) {
      parts.add('${widget.context!.pendingQuestions.length} unanswered');
    }
    
    if (widget.context!.keyPoints.isNotEmpty) {
      parts.add('${widget.context!.keyPoints.length} recent topics');
    }
    
    if (parts.isEmpty) {
      return 'View conversation history';
    }
    
    return parts.join(' • ');
  }
}
