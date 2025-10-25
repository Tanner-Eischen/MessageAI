import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/models/draft_analysis.dart';

/// Simple dialog for selecting relationship type
class RelationshipTypeSelector extends StatelessWidget {
  final RelationshipType currentType;
  final Function(RelationshipType) onSelected;

  const RelationshipTypeSelector({
    Key? key,
    required this.currentType,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Set Relationship Type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: RelationshipType.values.map((type) {
          final isSelected = type == currentType;
          return ListTile(
            leading: Icon(
              type.icon,
              color: isSelected ? AppTheme.accentBlue : null,
            ),
            title: Text(
              type.displayName,
              style: isSelected
                  ? TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: AppTheme.fontWeightBold,
                    )
                  : null,
            ),
            trailing: isSelected
                ? const Icon(Icons.check, color: AppTheme.accentBlue)
                : null,
            onTap: () {
              onSelected(type);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context,
    RelationshipType currentType,
    Function(RelationshipType) onSelected,
  ) {
    return showDialog(
      context: context,
      builder: (context) => RelationshipTypeSelector(
        currentType: currentType,
        onSelected: onSelected,
      ),
    );
  }
}

