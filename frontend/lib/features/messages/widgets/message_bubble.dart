import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/features/messages/widgets/tone_badge.dart';
import 'package:messageai/features/messages/widgets/tone_detail_sheet.dart';
import 'dart:async'; // Added for Timer

/// Message bubble with long-press for manual AI analysis
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isFromCurrentUser;
  final AIAnalysis? analysis;
  final bool isMostRecentReceived; // NEW: Track if this is the newest received message
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isFromCurrentUser,
    this.analysis,
    this.isMostRecentReceived = false,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _aiService = AIAnalysisService();
  bool _isAnalyzing = false;
  AIAnalysis? _analysisResult;
  
  // 🔧 FIXED: Increased timeout from 10s to 20s (backend takes 12+ seconds)
  late final Duration _analysisTimeout = const Duration(seconds: 20);
  
  // 🔔 NEW: StreamSubscription for auto-analysis completion
  late StreamSubscription<AnalysisEvent> _analysisCompletionSubscription;

  @override
  void initState() {
    super.initState();
    _analysisResult = widget.analysis;
    
    // 🔧 NEW: Check if analysis is already cached from a previous request
    _aiService.getAnalysis(widget.message.id).then((cachedAnalysis) {
      if (cachedAnalysis != null && mounted && _analysisResult == null) {
        print('✅ [BUBBLE] Found cached analysis on init: ${cachedAnalysis.tone}');
        setState(() {
          _analysisResult = cachedAnalysis;
        });
      }
    }).catchError((e) {
      print('⚠️ [BUBBLE] Error checking cache on init: $e');
    });
    
    // 🔔 NEW: Listen for auto-analysis completion events
    _analysisCompletionSubscription = _aiService.analysisEventStream.listen((event) {
      // Only update if this message's analysis event occurred
      if (event.messageId == widget.message.id && mounted) {
        if (event.isStarting) {
          // Show loading spinner when auto-analysis starts
          print('▶️ [BUBBLE] Auto-analysis starting for ${widget.message.id.substring(0, 8)}');
          setState(() {
            _isAnalyzing = true;
          });
        } else {
          // Update UI when auto-analysis completes
          print('✅ [BUBBLE] Auto-analysis completed for ${widget.message.id.substring(0, 8)}');
          
          // 🔧 FIX: Get analysis from cache directly (already stored by service)
          // This avoids recursion and works for both new analyses and cached ones
          _aiService.getAnalysis(widget.message.id).then((analysis) {
            if (analysis != null && mounted) {
              setState(() {
                _analysisResult = analysis;
                _isAnalyzing = false;
              });
            } else if (mounted) {
              // Fallback: try requestAnalysis if getAnalysis fails
              _aiService.requestAnalysis(
                widget.message.id,
                widget.message.body,
                isFromCurrentUser: widget.isFromCurrentUser,
                messageTimestamp: widget.message.createdAt,
              ).then((analysis) {
                if (analysis != null && mounted) {
                  setState(() {
                    _analysisResult = analysis;
                    _isAnalyzing = false;
                  });
                }
              });
            }
          }).catchError((e) {
            print('❌ [BUBBLE] Error getting analysis: $e');
            if (mounted) {
              setState(() => _isAnalyzing = false);
            }
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    // 🔔 NEW: Cancel subscription when widget is disposed
    _analysisCompletionSubscription.cancel();
    super.dispose();
  }

  /// Manually request AI analysis when user long-presses
  Future<void> _requestManualAnalysis() async {
    print('📋 Long press detected - showing context menu');
    _showContextMenu();
  }

  /// Show context menu with copy/paste and analysis options
  void _showContextMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Blur background
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              // Center popup
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Copy button
                      _buildContextMenuButton(
                        context,
                        icon: Icons.content_copy,
                        label: 'Copy',
                        color: Colors.blue,
                        isFirst: true,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.message.body));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      // Analyze button with sparkle icon
                      _buildContextMenuButton(
                        context,
                        icon: Icons.auto_awesome,
                        label: 'Analyze with AI',
                        color: Colors.purple,
                        isFirst: false,
                        onTap: () {
                          Navigator.pop(context);
                          _triggerAnalysis();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a context menu button
  Widget _buildContextMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isFirst,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: !isFirst
                ? BorderSide.none
                : BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE0E0E0),
                  ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trigger analysis from the context menu
  Future<void> _triggerAnalysis() async {
    print('✨ Analysis triggered from context menu');
    setState(() => _isAnalyzing = true);

    final safetyTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && _isAnalyzing) {
        print('⚠️ Force-closing analysis spinner (safety timeout)');
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏱️ Analysis took too long, cancelled automatically'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    try {
      final analysis = await _aiService.requestAnalysis(
        widget.message.id,
        widget.message.body,
        isFromCurrentUser: widget.isFromCurrentUser,
        messageTimestamp: widget.message.createdAt,
      ).timeout(
        _analysisTimeout,
        onTimeout: () {
          print('⏱️ Analysis request timed out after ${_analysisTimeout.inSeconds}s');
          return null;
        },
      );

      if (mounted) {
        safetyTimer.cancel();
        setState(() {
          _analysisResult = analysis;
          _isAnalyzing = false;
        });

        print('🔍 Analysis result: $analysis');
        print('📊 Analysis not null? ${analysis != null}');

        if (_analysisResult != null) {
          print('✅ Showing analysis sheet');
          _showAnalysisSheet();
        } else {
          print('❌ Analysis result is null, showing timeout message');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏱️ Analysis timed out. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        safetyTimer.cancel();
        setState(() => _isAnalyzing = false);
        print('❌ Analysis error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show the tone detail sheet
  void _showAnalysisSheet() {
    print('📋 _showAnalysisSheet called');
    print('   _analysisResult is null? ${_analysisResult == null}');
    print('   _analysisResult: $_analysisResult');
    
    if (_analysisResult == null) {
      print('❌ Cannot show sheet: analysis is null');
      return;
    }
    
    try {
      print('✅ Calling ToneDetailSheet.show()');
      ToneDetailSheet.show(
        context,
        _analysisResult!,
        widget.message.body,
        widget.message.id,
      );
      print('✅ ToneDetailSheet.show() completed');
    } catch (e) {
      print('❌ Error showing sheet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error showing analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: !widget.isFromCurrentUser ? _requestManualAnalysis : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: widget.isFromCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: widget.isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Main bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isFromCurrentUser
                        ? theme.colorScheme.primary
                        : (isDark ? AppTheme.darkGray200 : AppTheme.gray100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isAnalyzing
                          ? theme.colorScheme.primary.withOpacity(0.3)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message.body,
                        style: TextStyle(
                          fontSize: 15,
                          color: widget.isFromCurrentUser ? Colors.white : null,
                          height: 1.4,
                        ),
                      ),
                      
                      // Show tone badge for analyzed incoming messages
                      if (!widget.isFromCurrentUser && _analysisResult != null) ...[
                        const SizedBox(height: 8),
                        ToneBadge(
                          analysis: _analysisResult!,
                          onTap: _showAnalysisSheet,
                        ),
                      ],
                      
                      // 🟣 Sparkle indicator at bottom-right (only for most recent received message)
                      if (widget.isMostRecentReceived && !widget.isFromCurrentUser) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: _buildSparkleButton(context),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Long-press hint for incoming messages without analysis
                if (!widget.isFromCurrentUser && _analysisResult == null && !_isAnalyzing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '💡 Long-press for analysis',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(widget.message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                    ),
                  ),
                ),
              ],
            ),
            
            // 🟣 Sparkle indicator at bottom-right (only for most recent received message)
            // This line is removed as the sparkle indicator is now a child of the Column
            // if (widget.isMostRecentReceived && !widget.isFromCurrentUser)
            //   Positioned(
            //     bottom: 8,
            //     right: 12,
            //     child: _buildSparkleButton(context),
            //   ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// Build the sparkle button for the most recent received message
  Widget _buildSparkleButton(BuildContext context) {
    return StreamBuilder<AnalysisEvent>(
      stream: _aiService.analysisEventStream,
      builder: (context, snapshot) {
        // Only show spinner if this specific message is being analyzed
        final isAnalyzing = snapshot.hasData && 
            snapshot.data!.messageId == widget.message.id && 
            snapshot.data!.isStarting;
        
        return GestureDetector(
          onTap: !isAnalyzing ? () {
            // Trigger analysis on click
            _aiService.requestAnalysis(
              widget.message.id,
              widget.message.body,
              conversationContext: [],
            );
          } : null,
          child: isAnalyzing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    strokeWidth: 2.5,
                  ),
                )
              : Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Colors.purple,
                ),
        );
      },
    );
  }
}
