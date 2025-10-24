import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/state/ai_providers.dart';

/// Enhanced AI insights panel that displays conversation-level analysis
/// Replaces the placeholder background when user pulls down the message panel
class AIInsightsPanel extends ConsumerWidget {
  final String conversationId;
  final List<Message> messages;
  final double panelPosition;

  const AIInsightsPanel({
    Key? key,
    required this.conversationId,
    required this.messages,
    this.panelPosition = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate opacity based on panel position
    final opacity = 1.0 - panelPosition;
    
    // Fetch analyses for the conversation
    final analysisAsync = ref.watch(
      conversationAnalysisProvider(conversationId),
    );

    return Container(
      color: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: SafeArea(
        child: Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 28,
                    color: isDark ? AppTheme.white : AppTheme.black,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'AI Insights',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: AppTheme.fontWeightBold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingXL),
              
              // Analysis content
              Expanded(
                child: analysisAsync.when(
                  data: (analyses) {
                    if (analyses.isEmpty) {
                      return _buildEmptyState(context, isDark);
                    }
                    return _buildAnalysisCards(context, analyses, isDark);
                  },
                  loading: () => _buildLoadingState(context, isDark),
                  error: (error, stack) => _buildErrorState(context, error, isDark),
                ),
              ),
              
              // Hint text
              if (panelPosition > 0.5)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 32,
                        color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        'Pull down to view insights',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCards(
    BuildContext context,
    Map<String, AIAnalysis> analyses,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    // Calculate summary statistics
    final toneDistribution = <String, int>{};
    int urgentCount = 0;
    double avgConfidence = 0.0;
    
    for (final analysis in analyses.values) {
      toneDistribution[analysis.tone] = (toneDistribution[analysis.tone] ?? 0) + 1;
      if (analysis.urgencyLevel == 'High' || analysis.urgencyLevel == 'Critical') {
        urgentCount++;
      }
      avgConfidence += analysis.confidenceScore ?? 0.0;
    }
    
    if (analyses.isNotEmpty) {
      avgConfidence /= analyses.length;
    }
    
    final mostCommonTone = toneDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall tone card
          _buildInsightCard(
            context,
            icon: Icons.psychology,
            title: 'Overall Tone',
            value: mostCommonTone,
            description: '${analyses.length} messages analyzed',
            color: AppTheme.accentBlue,
            isDark: isDark,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Urgency indicator card
          if (urgentCount > 0)
            _buildInsightCard(
              context,
              icon: Icons.warning_amber,
              title: 'Urgent Messages',
              value: urgentCount.toString(),
              description: 'Requires attention',
              color: AppTheme.accentOrange,
              isDark: isDark,
            ),
          
          if (urgentCount > 0) const SizedBox(height: AppTheme.spacingM),
          
          // Confidence indicator
          _buildInsightCard(
            context,
            icon: Icons.thumb_up_outlined,
            title: 'Analysis Quality',
            value: '${(avgConfidence * 100).round()}%',
            description: 'Average confidence',
            color: avgConfidence > 0.8
                ? AppTheme.accentGreen
                : avgConfidence > 0.6
                    ? AppTheme.accentBlue
                    : AppTheme.accentOrange,
            isDark: isDark,
          ),
          
          const SizedBox(height: AppTheme.spacingM),
          
          // Recent analysis
          if (analyses.isNotEmpty) ...[
            Text(
              'Recent Analysis',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: AppTheme.fontWeightBold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ...analyses.entries.take(3).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: _buildRecentAnalysisItem(
                  context,
                  entry.value,
                  isDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray100 : AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXS),
                Text(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: AppTheme.fontWeightBold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysisItem(
    BuildContext context,
    AIAnalysis analysis,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkGray100 : AppTheme.white).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
          color: isDark ? AppTheme.darkGray300 : AppTheme.gray300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            _getToneEmoji(analysis.tone),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.tone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: AppTheme.fontWeightSemibold,
                  ),
                ),
                if (analysis.intent != null)
                  Text(
                    analysis.intent!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: isDark ? AppTheme.gray600 : AppTheme.gray400,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No AI analysis yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: AppTheme.fontWeightSemibold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Send messages to see AI-powered insights',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.gray500 : AppTheme.gray600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, bool isDark) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.accentRed,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Error loading insights',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getToneEmoji(String tone) {
    switch (tone.toLowerCase()) {
      case 'friendly':
        return '😊';
      case 'professional':
        return '💼';
      case 'urgent':
        return '⚡';
      case 'casual':
        return '😎';
      case 'formal':
        return '👔';
      case 'concerned':
        return '😟';
      case 'excited':
        return '🎉';
      case 'neutral':
      default:
        return '💬';
    }
  }
}

