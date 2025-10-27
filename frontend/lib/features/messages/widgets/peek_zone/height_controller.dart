import 'package:flutter/foundation.dart';
import 'package:messageai/models/peek_content.dart';

/// View modes for the peek zone panel
enum ViewMode {
  HIDDEN,    // AI panel hidden - just messages
  SPLIT,     // 50/50 split - both scrollable
  FULL,      // AI panel full - messages hidden
}

/// Controls the height and view mode of the peek zone panel
class HeightController extends ChangeNotifier {
  double _panelHeight = 0.0;  // Default: 0% (hidden, messages only)
  ViewMode _currentMode = ViewMode.HIDDEN;  // Default mode
  PeekContent? _currentContent;  // Active content for current mode
  
  // Snap points - only 3 states
  static const double HIDDEN = 0.0;     // 0% - Messages only
  static const double SPLIT = 0.50;     // 50% - Split view
  static const double FULL = 0.95;      // 95% - AI only
  
  HeightController({PeekContent? defaultContent}) : _currentContent = defaultContent;
  
  /// Switch to a different view mode
  void setMode(ViewMode newMode) {
    if (_currentMode != newMode) {
      print('');
      print('🔄 HEIGHT_CTRL: Mode switch');
      print('   From: ${_currentMode.name}');
      print('   To: ${newMode.name}');
      
      _currentMode = newMode;
      _panelHeight = _getModeHeight(newMode);  // Set height based on mode
      
      print('   Panel set to: ${(_panelHeight * 100).toStringAsFixed(0)}%');
      print('');
      
      notifyListeners();
    }
  }
  
  /// Update panel height (called when user drags)
  void onHeightChanged(double height) {
    if ((_panelHeight - height).abs() > 0.01) {  // Only notify if significant change
      _panelHeight = height;
      notifyListeners();
    }
  }
  
  /// Update mode based on current height (no snapping)
  void updateModeFromHeight() {
    final newMode = _getModeFromHeight(_panelHeight);
    if (_currentMode != newMode) {
      _currentMode = newMode;
      notifyListeners();
    }
  }
  
  /// Determine which mode we're in based on height
  ViewMode _getModeFromHeight(double height) {
    if (height < 0.25) return ViewMode.HIDDEN;
    if (height < 0.75) return ViewMode.SPLIT;
    return ViewMode.FULL;
  }
  
  /// Set default/background content without opening the panel
  void setDefaultContent(PeekContent content) {
    print('📝 HEIGHT_CTRL: setDefaultContent');
    print('   Content type: ${content.contentType}');
    _currentContent = content;
    // Don't change mode or notify - just update the background content
  }
  
  /// Show content in the peek zone - ALWAYS goes to 50/50 SPLIT
  void showInPeekZone(PeekContent content) {
    print('');
    print('📍 HEIGHT_CTRL: showInPeekZone called');
    print('   Content type: ${content.contentType}');
    
    _currentContent = content;
    
    // ALWAYS go to SPLIT mode (50/50) when tapping a mode button
    _currentMode = ViewMode.SPLIT;
    _panelHeight = SPLIT;
    
    print('   Opening in SPLIT mode (50/50)');
    print('');
    
    notifyListeners();
  }
  
  /// Get height for a specific mode
  double _getModeHeight(ViewMode mode) {
    switch (mode) {
      case ViewMode.HIDDEN:
        return HIDDEN;
      case ViewMode.SPLIT:
        return SPLIT;
      case ViewMode.FULL:
        return FULL;
    }
  }
  
  /// Getters
  ViewMode get currentMode => _currentMode;
  double get panelHeight => _panelHeight;
  PeekContent? get currentContent => _currentContent;
  bool get hasActiveContent => _currentContent != null;
  
  /// Calculate peek zone height from available screen height
  double getPeekZoneHeight(double availableHeight) {
    return availableHeight * _panelHeight;
  }
  
  /// Get user-friendly description of current state
  String get stateDescription {
    final modeStr = currentMode.name;
    final heightPct = (_panelHeight * 100).toStringAsFixed(0);
    return '$modeStr - $heightPct% panel';
  }
  
  /// Get mode name with percentage
  String getModeName() {
    switch (currentMode) {
      case ViewMode.HIDDEN:
        return 'HIDDEN (Messages only)';
      case ViewMode.SPLIT:
        return 'SPLIT (50/50)';
      case ViewMode.FULL:
        return 'FULL (AI only)';
    }
  }
}

