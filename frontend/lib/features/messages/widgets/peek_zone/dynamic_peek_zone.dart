import 'package:flutter/material.dart';
import 'package:messageai/features/messages/widgets/peek_zone/height_controller.dart';
import 'package:messageai/features/messages/widgets/peek_zone/ai_insights_background.dart';
import 'package:messageai/models/peek_content.dart';

/// Custom compact app bar height (40px instead of standard 56px)
const double kCompactAppBarHeight = 40.0;

/// Wrapper that isolates background from height changes - only rebuilds on mode change
class _StaticModeBackground extends StatefulWidget {
  final HeightController controller;
  final Widget Function(BuildContext, ViewMode, PeekContent?) builder;

  const _StaticModeBackground({
    required this.controller,
    required this.builder,
  });

  @override
  State<_StaticModeBackground> createState() => _StaticModeBackgroundState();
}

class _StaticModeBackgroundState extends State<_StaticModeBackground> {
  late ViewMode _currentMode;
  late PeekContent? _currentContent;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.controller.currentMode;
    _currentContent = widget.controller.currentContent;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final newMode = widget.controller.currentMode;
    final newContent = widget.controller.currentContent;
    
    // Only rebuild if mode or content changed, NOT height
    if (newMode != _currentMode || newContent != _currentContent) {
      setState(() {
        _currentMode = newMode;
        _currentContent = newContent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: widget.builder(context, _currentMode, _currentContent),
    );
  }
}

/// ============================================================================
/// DYNAMIC PEEK ZONE - Main draggable panel widget
/// ============================================================================
///
/// Orchestrates the complete peek zone system with:
/// - 2-layer Stack (messaging layer, AI features layer)
/// - Static background that only rebuilds on mode change
/// - Height-based view mode selection
/// - Drag gesture handling with snap points
/// - Velocity-based fast swipe snapping
/// - Smooth height animations
///
/// Architecture:
/// ```
/// Stack (back to front)
/// ├─ Layer 2: Background (AI features, static per mode)
/// └─ Layer 1: Message Panel + Compose Bar (frontmost, slides to reveal)
/// ```
class DynamicPeekZone extends StatefulWidget {
  final Widget Function(BuildContext context, ViewMode currentMode, PeekContent? currentContent) backgroundBuilder;
  final Widget composeBar;
  final Widget messagePanel;
  final HeightController heightController;
  final String conversationId;
  final void Function(double newHeight)? onHeightChanged;
  final void Function(ViewMode newMode)? onViewModeChanged;

  const DynamicPeekZone({super.key,
    required this.backgroundBuilder,
    required this.composeBar,
    required this.messagePanel,
    required this.heightController,
    required this.conversationId,
    this.onHeightChanged,
    this.onViewModeChanged,
  });

  @override
  State<DynamicPeekZone> createState() => _DynamicPeekZoneState();
}

class _DynamicPeekZoneState extends State<DynamicPeekZone> with TickerProviderStateMixin {
  Widget? _staticBackground;

  // Measure compose bar so the peek panel sits above it
  final GlobalKey _composeKey = GlobalKey();
  // Provisional default to avoid 0 availableHeight on first frame
  double _composeHeight = 56.0;
  
  // Animation controller for smooth spring physics
  late AnimationController _dragAnimationController;
  Animation<double>? _dragAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with fast duration for responsiveness
    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Measure compose bar once after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureComposeBar());
  }
  
  /// Lazy getter for static background - creates once and caches
  Widget get staticBackground {
    return _staticBackground ??= _StaticModeBackground(
      controller: widget.heightController,
      builder: widget.backgroundBuilder,
    );
  }

  /// Measure compose bar height once after layout
  void _measureComposeBar() {
    final ctx = _composeKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      final h = box?.size.height ?? 0;
      
      if ((h - _composeHeight).abs() > 1.0) {
        setState(() => _composeHeight = h);
      }
    }
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    super.dispose();
  }

  // ============================= Drag handling =============================
  
  void _onDragStart(DragStartDetails details, HeightController controller) {
    // Cancel any ongoing animation when user starts dragging
    if (_dragAnimation != null) {
      _dragAnimationController.stop();
      _dragAnimation = null;
    }
  }

  void _onDragUpdate(DragUpdateDetails details, HeightController controller,
      double availableHeight) {
    // Smooth continuous dragging - update height as user drags
    // Negative delta because drag down = increase panel height
    final delta = -details.primaryDelta! / availableHeight;
    final newHeight = (controller.panelHeight + delta).clamp(0.0, 1.0);
    controller.onHeightChanged(newHeight);
    controller.updateModeFromHeight();
  }

  void _onDragEnd(DragEndDetails details, HeightController controller) {
    // Get velocity for momentum-based behavior
    final velocity = details.primaryVelocity ?? 0.0;
    final currentHeight = controller.panelHeight;
    
    // If fast swipe detected, animate to nearest major position
    if (velocity.abs() > 500) {
      double targetHeight;
      if (velocity < 0) {
        // Swiping up - go toward full
        targetHeight = currentHeight > 0.5 ? HeightController.FULL : HeightController.SPLIT;
      } else {
        // Swiping down - go toward hidden
        targetHeight = currentHeight < 0.5 ? HeightController.HIDDEN : HeightController.SPLIT;
      }
      
      // Animate to target with spring physics
      _animateToHeight(controller, targetHeight);
    }
    
    // Update the mode based on final position
    widget.onViewModeChanged?.call(controller.currentMode);
  }
  
  /// Animate panel to target height with smooth spring physics
  void _animateToHeight(HeightController controller, double targetHeight) {
    final currentHeight = controller.panelHeight;
    
    _dragAnimation = Tween<double>(
      begin: currentHeight,
      end: targetHeight,
    ).animate(CurvedAnimation(
      parent: _dragAnimationController,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
      controller.onHeightChanged(_dragAnimation!.value);
      controller.updateModeFromHeight();
    });
    
    _dragAnimationController.reset();
    _dragAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final controller = widget.heightController;

    return Stack(
      children: [
        // Layer 0: COMPLETELY STATIC BACKGROUND - outside AnimatedBuilder!
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: ClipRect(
              child: staticBackground,
            ),
          ),
        ),
        
        // Layer 1+: Animated content (updates on height changes)
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // Calculate available height: screen - status bar - app bar - compose bar
            // This gives us the actual usable space for messages + peek zone
            final totalAvailableHeight = screenHeight - statusBarHeight - kCompactAppBarHeight - _composeHeight;
            final availableHeight = totalAvailableHeight.clamp(0.0, screenHeight);
            
            final peekPanelHeight = controller.getPeekZoneHeight(availableHeight);
            final messagePanelHeight = availableHeight - peekPanelHeight;

            return Stack(
              children: [

            // Layer 2: Peek panel (static content, AI features/context)
            if (peekPanelHeight > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: _composeHeight + messagePanelHeight.clamp(0.0, availableHeight),
              height: peekPanelHeight.clamp(0.0, availableHeight),
              child: _buildPeekPanel(
                context: context,
                controller: controller,
                availableHeight: availableHeight,
              ),
            ),

            // Layer 1: Compose bar (fixed at bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: KeyedSubtree(key: _composeKey, child: widget.composeBar),
            ),

            // Layer 3: Message panel (bottom, scrollable)
            Positioned(
              left: 0,
              right: 0,
              bottom: _composeHeight,
              height: messagePanelHeight.clamp(0.0, availableHeight),
              child: Stack(
                children: [
                  // Message list fills the panel
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: widget.messagePanel,
                    ),
                  ),
                  // Drag grab area over the top of the message list - larger hit area
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 48, // Increased from 32 to 48 for easier grabbing
                    child: GestureDetector(
                      onVerticalDragStart: (details) => _onDragStart(details, controller),
                      onVerticalDragUpdate: (details) => _onDragUpdate(details, controller, availableHeight),
                      onVerticalDragEnd: (details) => _onDragEnd(details, controller),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                              Theme.of(context).scaffoldBackgroundColor.withOpacity(0),
                            ],
                          ),
                        ),
                        child: _buildDragHandle(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPeekPanel({
    required BuildContext context,
    required HeightController controller,
    required double availableHeight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onVerticalDragStart: (details) => _onDragStart(details, controller),
      onVerticalDragUpdate: (details) =>
          _onDragUpdate(details, controller, availableHeight),
      onVerticalDragEnd: (details) => _onDragEnd(details, controller),
      behavior: HitTestBehavior.opaque,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  _buildDragHandle(context),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: AIInsightsBackground(
                        conversationId: widget.conversationId,
                        heightController: controller,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Additional drag area at the very top for when panel is fully up
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragStart: (details) => _onDragStart(details, controller),
                  onVerticalDragUpdate: (details) => _onDragUpdate(details, controller, availableHeight),
                  onVerticalDragEnd: (details) => _onDragEnd(details, controller),
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    height: 48,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[600] : Colors.grey[350],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
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

  Widget _buildDragHandle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 32,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[600] : Colors.grey[350],
            borderRadius: BorderRadius.circular(2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




