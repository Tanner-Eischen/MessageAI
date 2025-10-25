import 'package:flutter/material.dart';
import 'package:messageai/models/conversation_filter.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// Collapsible filter button and expandable filter chips
class ConversationFilterChips extends StatefulWidget {
  final Set<ConversationFilter> activeFilters;
  final Function(ConversationFilter) onFilterToggled;
  final Map<ConversationFilter, int>? badgeCounts;
  
  const ConversationFilterChips({
    Key? key,
    required this.activeFilters,
    required this.onFilterToggled,
    this.badgeCounts,
  }) : super(key: key);

  @override
  State<ConversationFilterChips> createState() => _ConversationFilterChipsState();
}

class _ConversationFilterChipsState extends State<ConversationFilterChips> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Count active filters
    final activeCount = widget.activeFilters.isEmpty 
        ? 0 
        : widget.activeFilters.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Filter button (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkGray200 : AppTheme.gray100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: activeCount > 0 
                      ? const Color(0xFF6366F1)
                      : (isDark ? AppTheme.darkGray300 : AppTheme.gray300),
                  width: activeCount > 0 ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 🔵 INDIGO: Sparkle for Smart Inbox Filters
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activeCount == 0
                          ? 'Filters'
                          : '$activeCount filter${activeCount > 1 ? 's' : ''} active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: activeCount > 0 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        color: activeCount > 0
                            ? const Color(0xFF6366F1)
                            : (isDark ? AppTheme.gray500 : AppTheme.gray600),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable filter chips
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkGray200 : AppTheme.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkGray300 : AppTheme.gray200,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // "All" filter chip
                  _buildFilterChip(
                    context,
                    ConversationFilterConfig.configs[ConversationFilter.all]!,
                    widget.activeFilters.isEmpty,
                    null,
                    isDark,
                  ),
                  
                  // Other filter chips
                  ...ConversationFilter.values
                      .where((f) => f != ConversationFilter.all)
                      .map((filter) {
                    final config = ConversationFilterConfig.configs[filter]!;
                    final isSelected = widget.activeFilters.contains(filter);
                    final count = widget.badgeCounts?[filter];
                    
                    return _buildFilterChip(
                      context,
                      config,
                      isSelected,
                      count,
                      isDark,
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(
    BuildContext context,
    ConversationFilterConfig config,
    bool isSelected,
    int? count,
    bool isDark,
  ) {
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 16,
            color: isSelected ? config.color : (isDark ? AppTheme.gray500 : AppTheme.gray600),
          ),
          const SizedBox(width: 6),
          Text(config.label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: config.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: (selected) {
        widget.onFilterToggled(config.filter);
      },
      backgroundColor: isDark ? AppTheme.darkGray200 : AppTheme.gray100,
      selectedColor: config.color.withOpacity(0.15),
      checkmarkColor: config.color,
      labelStyle: TextStyle(
        color: isSelected ? config.color : (isDark ? AppTheme.gray500 : AppTheme.gray700),
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? config.color : (isDark ? AppTheme.darkGray300 : AppTheme.gray300),
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }
}
