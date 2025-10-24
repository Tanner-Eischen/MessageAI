import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// Background panel for AI insights that appears behind the sliding message panel
/// Users can swipe down the message panel to reveal this content
class AIInsightsBackground extends StatelessWidget {
  final String conversationId;
  final double panelPosition;

  const AIInsightsBackground({
    Key? key,
    required this.conversationId,
    this.panelPosition = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calculate opacity based on panel position
    // When panel is fully up (position = 1.0), fade out insights
    // When panel is down (position = 0.0), show insights fully
    final opacity = 1.0 - panelPosition;
    
    return Container(
      color: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: SafeArea(
        child: Opacity(
          opacity: opacity.clamp(0.3, 1.0), // Keep minimum visibility
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
              
              // Placeholder content
              _buildPlaceholderCard(
                context,
                icon: Icons.insights,
                title: 'Tone Analysis',
                description: 'Pull down to see how messages are being interpreted',
                isDark: isDark,
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              _buildPlaceholderCard(
                context,
                icon: Icons.lightbulb_outline,
                title: 'Smart Suggestions',
                description: 'AI-powered response recommendations coming soon',
                isDark: isDark,
              ),
              
              const SizedBox(height: AppTheme.spacingM),
              
              _buildPlaceholderCard(
                context,
                icon: Icons.analytics_outlined,
                title: 'Conversation Health',
                description: 'Monitor communication patterns and insights',
                isDark: isDark,
              ),
              
              const Spacer(),
              
              // Hint text
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
                      'Pull down messages to view insights',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.gray600 : AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
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
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: isDark 
                ? AppTheme.darkGray300 
                : AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? AppTheme.white : AppTheme.black,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTheme.fontWeightSemibold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXS),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


