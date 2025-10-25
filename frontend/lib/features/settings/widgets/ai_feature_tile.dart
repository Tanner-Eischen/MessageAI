import 'package:flutter/material.dart';
import 'package:messageai/models/ai_feature.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// Expandable tile showing AI feature information and toggle
class AIFeatureTile extends StatefulWidget {
  final AIFeature feature;
  final Function(bool) onToggle;
  final VoidCallback? onMoreInfo;

  const AIFeatureTile({
    Key? key,
    required this.feature,
    required this.onToggle,
    this.onMoreInfo,
  }) : super(key: key);

  @override
  State<AIFeatureTile> createState() => _AIFeatureTileState();
}

class _AIFeatureTileState extends State<AIFeatureTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = widget.feature.config;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray200 : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      config.icon,
                      color: config.color,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 🆕 Color-coded checkmark instead of badge
                        Row(
                          children: [
                            Icon(
                              widget.feature.isEnabled 
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: widget.feature.isEnabled 
                                  ? config.color
                                  : (isDark ? AppTheme.gray500 : AppTheme.gray400),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.feature.isEnabled ? 'Enabled' : 'Disabled',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.feature.isEnabled
                                    ? config.color
                                    : (isDark ? AppTheme.gray500 : AppTheme.gray600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Toggle + Expand
                  Switch(
                    value: widget.feature.isEnabled,
                    onChanged: widget.onToggle,
                    activeColor: config.color,
                  ),
                  
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                    ),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable details
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: config.color.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    config.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.gray300 : AppTheme.gray700,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // What the AI does
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: config.color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: config.color.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: config.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'What the AI does:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: config.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...config.whatItDoes.map((action) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    color: config.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.gray300
                                          : AppTheme.gray700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Where it appears
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          config.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
