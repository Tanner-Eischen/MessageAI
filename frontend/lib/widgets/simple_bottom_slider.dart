import 'package:flutter/material.dart';

/// SimpleBottomSlider
/// - A minimal floating panel fixed to the bottom that can be dragged upward
///   to a maximum of 95% of the available vertical space.
/// - Content is optional; uses a basic placeholder if none provided.
///
/// Usage example:
/// Stack(
///   children: [
///     Positioned.fill(child: AnyBackgroundWidget()),
///     SimpleBottomSlider(),
///   ],
/// )
class SimpleBottomSlider extends StatefulWidget {
  /// Minimum height in pixels when collapsed
  final double minHeight;

  /// Maximum height factor of available height (0..1)
  final double maxHeightFactor;

  /// Optional initial height factor (0..1 of available height)
  final double initialHeightFactor;

  /// Optional child content for the panel
  final Widget? child;

  /// Space at the top that the slider should not overlap (e.g., header/AppBar)
  final double topInset;

  /// Space at the bottom that the slider should stop above (e.g., message bar)
  final double bottomInset;

  /// Optional footer pinned to the bottom of the panel (e.g., message bar)
  final Widget? footer;

  /// Emits the current heightFactor (0..1 of available height) when dragging
  final ValueChanged<double>? onHeightChanged;

  const SimpleBottomSlider({super.key,
    this.minHeight = 64.0,
    this.maxHeightFactor = 0.95,
    this.initialHeightFactor = 0.10,
    this.child,
    this.topInset = 0.0,
    this.bottomInset = 0.0,
    this.footer,
    this.onHeightChanged,
  });

  @override
  State<SimpleBottomSlider> createState() => _SimpleBottomSliderState();
}

class _SimpleBottomSliderState extends State<SimpleBottomSlider> {
  late double _heightFactor; // 0..1 of available height
  late double _dragStartDy;
  late double _dragStartHeight;

  @override
  void initState() {
    super.initState();
    _heightFactor = widget.initialHeightFactor.clamp(0.0, widget.maxHeightFactor);
    // Notify initial height factor so parent can compute background region
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHeightChanged?.call(_heightFactor);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final available = (screenHeight - widget.topInset - widget.bottomInset).clamp(0.0, screenHeight);
    final maxHeight = (available * widget.maxHeightFactor).clamp(widget.minHeight, available);
    final currentHeight = (_heightFactor * available).clamp(widget.minHeight, maxHeight);

    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.bottomInset,
      height: currentHeight,
      child: _buildPanel(context, available, maxHeight),
    );
  }

  Widget _buildPanel(BuildContext context, double available, double maxHeight) {
    // Capture drags that start near the top of the panel so users can pull
    // it from anywhere, but keep list scrolling intact when starting deeper.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        if (details.localPosition.dy <= 40) {
          _dragStartDy = details.globalPosition.dy;
          _dragStartHeight = _heightFactor * available;
        } else {
          _dragStartDy = double.nan; // ignore, let child scroll
        }
      },
      onVerticalDragUpdate: (details) {
        if (_dragStartDy.isNaN) return;
        final dy = details.globalPosition.dy - _dragStartDy; // down is +
        final newHeight = (_dragStartHeight - dy).clamp(widget.minHeight, maxHeight);
        final newFactor = (newHeight / available).clamp(0.0, widget.maxHeightFactor);
        if ((newFactor - _heightFactor).abs() > 0.0001) {
          setState(() => _heightFactor = newFactor);
          widget.onHeightChanged?.call(_heightFactor);
        }
      },
      onVerticalDragEnd: (_) {
        if (_dragStartDy.isNaN) return;
        // Snap to nearest common points: 10%, 30%, 50%, 80%
        final points = <double>[0.10, 0.30, 0.50, 0.80];
        double nearest = points.first;
        double best = (points.first - _heightFactor).abs();
        for (final p in points) {
          final d = (p - _heightFactor).abs();
          if (d < best) { best = d; nearest = p; }
        }
        setState(() => _heightFactor = nearest);
        widget.onHeightChanged?.call(_heightFactor);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [Color(0xFF202432), Color(0xFF1A1E2A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFDFBFF), Color(0xFFF2F5FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle area (still captures drag)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (details) {
                _dragStartDy = details.globalPosition.dy;
                _dragStartHeight = _heightFactor * available;
              },
              onVerticalDragUpdate: (details) {
                final dy = details.globalPosition.dy - _dragStartDy; // down is +
                final newHeight = (_dragStartHeight - dy).clamp(widget.minHeight, maxHeight);
                final newFactor = (newHeight / available).clamp(0.0, widget.maxHeightFactor);
                if ((newFactor - _heightFactor).abs() > 0.0001) {
                  setState(() => _heightFactor = newFactor);
                  widget.onHeightChanged?.call(_heightFactor);
                }
              },
              onVerticalDragEnd: (_) {
                final points = <double>[0.10, 0.30, 0.50, 0.80];
                double nearest = points.first;
                double best = (points.first - _heightFactor).abs();
                for (final p in points) {
                  final d = (p - _heightFactor).abs();
                  if (d < best) { best = d; nearest = p; }
                }
                setState(() => _heightFactor = nearest);
                widget.onHeightChanged?.call(_heightFactor);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF4C5DFF)
                        : const Color(0xFF5363FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Placeholder content (caller can supply their own)
            Expanded(
              child: widget.child ??
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    alignment: Alignment.center,
                    child: Text(
                      'Simple Bottom Slider',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
            ),

            // Footer pinned to bottom (e.g., message bar)
            if (widget.footer != null)
              SafeArea(top: false, child: widget.footer!),
          ],
        ),
      ),
    );
  }
}
