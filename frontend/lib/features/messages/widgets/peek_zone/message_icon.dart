import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// MESSAGE ICON - Footer icon component for message bubbles
/// ============================================================================
/// 
/// Displays a small, tappable icon in the footer of message bubbles.
/// Triggered when AI analysis detects:
/// - RSD triggers
/// - Boundary violations
/// - Action items/commitments
///
/// When tapped, updates the Peek Zone with relevant content.
///
class MessageIcon extends StatefulWidget {
  /// The icon to display (e.g., Icons.psychology_outlined)
  final IconData icon;

  /// Label for tooltip (e.g., 'RSD', 'Boundary', 'Action')
  final String label;

  /// Color for the icon and border (e.g., Colors.amber, Colors.orange)
  final Color color;

  /// Callback when tapped
  /// Typically: controller.showInPeekZone(content)
  final VoidCallback onTap;

  /// Whether this icon is currently active/selected
  /// Shows different visual state (highlighted border)
  final bool isActive;

  /// Optional badge count (e.g., number of suggestions)
  final int? badgeCount;

  const MessageIcon({super.key, 
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
    this.badgeCount,
  });

  @override
  State<MessageIcon> createState() => _MessageIconState();
}

class _MessageIconState extends State<MessageIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Call the callback
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            // Background color
            color: widget.color.withOpacity(widget.isActive ? 0.3 : 0.08),
            // Border styling
            border: Border.all(
              color: widget.color,
              width: widget.isActive ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main icon
              Icon(
                widget.icon,
                size: 16,
                color: widget.color,
              ),

              // Badge count (optional)
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// MESSAGE ICON ROW - Container for multiple message icons
/// ============================================================================
/// 
/// Groups message icons into a horizontal row with proper spacing.
/// Handles overflow with text wrapping if too many icons.
///
class MessageIconRow extends StatelessWidget {
  /// List of message icons to display
  final List<Widget> children;

  /// Spacing between icons
  final double spacing;

  const MessageIconRow({super.key, 
    required this.children,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: spacing,
        runSpacing: 4,
        children: children,
      ),
    );
  }
}

/// ============================================================================
/// MESSAGE ICON GROUP - Semantic grouping for related icons
/// ============================================================================
/// 
/// Groups icons by type (analysis, boundary, action) for organization.
/// Can be collapsed/expanded with a header.
///
class MessageIconGroup extends StatefulWidget {
  /// Group title (e.g., 'Analysis', 'Boundaries', 'Actions')
  final String title;

  /// Icon for the group header
  final IconData headerIcon;

  /// Color for the header
  final Color color;

  /// Icons to display in this group
  final List<Widget> icons;

  /// Whether group starts expanded
  final bool initiallyExpanded;

  const MessageIconGroup({super.key, 
    required this.title,
    required this.headerIcon,
    required this.color,
    required this.icons,
    this.initiallyExpanded = true,
  });

  @override
  State<MessageIconGroup> createState() => _MessageIconGroupState();
}

class _MessageIconGroupState extends State<MessageIconGroup> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        GestureDetector(
          onTap: _toggleExpanded,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.headerIcon, size: 14, color: widget.color),
              const SizedBox(width: 4),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 14,
                height: 14,
                child: RotatedBox(
                  quarterTurns: _isExpanded ? 2 : 0,
                  child: Icon(
                    Icons.expand_more,
                    size: 14,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Icons (with animation)
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.icons,
            ),
          ),
      ],
    );
  }
}
