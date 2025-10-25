import 'package:flutter/material.dart';
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
    setState(() => _isAnalyzing = true);
    
    // 🔧 Safety net: Force close spinner after 25 seconds (20s API + 5s buffer)
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
      // 🔧 Add timeout to prevent infinite loading (20 seconds for backend processing)
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
        safetyTimer.cancel(); // Cancel safety timer if request completed
        setState(() {
          _analysisResult = analysis;
          _isAnalyzing = false;
        });
        
        // Show detail sheet with analysis
        if (_analysisResult != null) {
          _showAnalysisSheet();
        } else {
          // Timeout or failed
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
    if (_analysisResult == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToneDetailSheet(
        analysis: _analysisResult!,
        messageBody: widget.message.body,
        messageId: widget.message.id,
      ),
    );
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
