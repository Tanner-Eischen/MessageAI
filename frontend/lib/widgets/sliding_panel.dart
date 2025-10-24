import 'package:flutter/material.dart';
import 'package:messageai/core/theme/app_theme.dart';

/// A sliding panel widget that can be dragged up and down
/// Used for the message screen to slide over AI insights
class SlidingPanel extends StatefulWidget {
  /// The content to display in the sliding panel
  final Widget child;
  
  /// Called when the panel position changes (0.0 = collapsed, 1.0 = fully expanded)
  final ValueChanged<double>? onSlide;
  
  /// Minimum height as a fraction of screen (0.0 - 1.0)
  final double minHeight;
  
  /// Maximum height as a fraction of screen (0.0 - 1.0)
  final double maxHeight;
  
  /// Initial height as a fraction of screen (0.0 - 1.0)
  final double initialHeight;
  
  /// Snap positions for the panel (as fractions of screen height)
  final List<double> snapSizes;
  
  /// Background color of the panel
  final Color? backgroundColor;
  
  /// Border radius for the top corners
  final double borderRadius;
  
  /// Whether to show the drag handle
  final bool showDragHandle;

  const SlidingPanel({
    Key? key,
    required this.child,
    this.onSlide,
    this.minHeight = 0.2,
    this.maxHeight = 0.95,
    this.initialHeight = 0.8,
    this.snapSizes = const [0.2, 0.5, 0.8, 0.95],
    this.backgroundColor,
    this.borderRadius = 16.0,
    this.showDragHandle = true,
  }) : super(key: key);

  @override
  State<SlidingPanel> createState() => _SlidingPanelState();
}

class _SlidingPanelState extends State<SlidingPanel> {
  final DraggableScrollableController _controller = DraggableScrollableController();
  
  @override
  void initState() {
    super.initState();
    // Add listener to track position changes
    _controller.addListener(_onPositionChanged);
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onPositionChanged);
    _controller.dispose();
    super.dispose();
  }
  
  void _onPositionChanged() {
    if (_controller.isAttached) {
      final size = _controller.size;
      // Normalize the size to 0.0 - 1.0 range
      final normalizedPosition = (size - widget.minHeight) / (widget.maxHeight - widget.minHeight);
      widget.onSlide?.call(normalizedPosition.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? 
                    (isDark ? AppTheme.black : AppTheme.white);
    
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialHeight,
      minChildSize: widget.minHeight,
      maxChildSize: widget.maxHeight,
      snap: true,
      snapSizes: widget.snapSizes,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadius),
              topRight: Radius.circular(widget.borderRadius),
            ),
            boxShadow: isDark ? AppTheme.shadow2Dark : AppTheme.shadow3Light,
          ),
          child: Column(
            children: [
              // Drag handle area
              if (widget.showDragHandle)
                GestureDetector(
                  onTap: () => _snapToNextPosition(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingS,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.gray600 : AppTheme.gray400,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Panel content
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Snaps the panel to the next position in the snapSizes list
  void _snapToNextPosition() {
    if (!_controller.isAttached) return;
    
    final currentSize = _controller.size;
    final sortedSnaps = List<double>.from(widget.snapSizes)..sort();
    
    // Find the next snap position
    final nextSnap = sortedSnaps.firstWhere(
      (snap) => snap > currentSize + 0.05, // Add small buffer for floating point
      orElse: () => sortedSnaps.first, // Wrap around to first
    );
    
    _controller.animateTo(
      nextSnap,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

/// Extension to provide convenience methods for sliding panel
extension SlidingPanelController on DraggableScrollableController {
  /// Animate to a specific size
  Future<void> animateToSize(
    double size, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return animateTo(
      size,
      duration: duration,
      curve: curve,
    );
  }
  
  /// Jump to a specific size without animation
  void jumpToSize(double size) {
    jumpTo(size);
  }
  
  /// Get current size
  double get currentSize => isAttached ? size : 0.0;
}

