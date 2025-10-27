import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/models/ai_analysis.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/message_service.dart';
import 'package:messageai/services/reaction_service.dart';
import 'package:messageai/core/theme/app_theme.dart';
import 'package:messageai/features/messages/widgets/peek_zone/height_controller.dart';
import 'package:messageai/features/messages/widgets/peek_zone/message_icon.dart';
import 'package:messageai/services/peek_zone_service.dart';
import 'dart:async';

/// Message bubble with long-press for manual AI analysis
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isFromCurrentUser;
  final AIAnalysis? analysis;
  final bool isMostRecentReceived;
  final HeightController? heightController;
  final List<Receipt>? receipts;
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.analysis,
    this.isMostRecentReceived = false,
    this.heightController,
    this.receipts,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _aiService = AIAnalysisService();
  final _peekZoneService = PeekZoneService();
  final _messageService = MessageService();
  final _reactionService = ReactionService();
  bool _isAnalyzing = false;
  AIAnalysis? _analysisResult;
  bool _hasBoundaryViolations = false;
  bool _hasActionItems = false;
  Map<String, List<String>> _reactions = {}; // emoji -> list of user IDs
  StreamSubscription? _reactionSubscription;
  
  late final Duration _analysisTimeout = const Duration(seconds: 20);
  late StreamSubscription<AnalysisEvent> _analysisCompletionSubscription;

  @override
  void initState() {
    super.initState();
    _analysisResult = widget.analysis;
    _loadReactions();
    
    // Check if analysis is already cached
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
    
    // Listen for auto-analysis completion events
    _analysisCompletionSubscription = _aiService.analysisEventStream.listen((event) {
      if (event.messageId == widget.message.id && mounted) {
        if (event.isStarting) {
          print('▶️ [BUBBLE] Auto-analysis starting for ${widget.message.id.substring(0, 8)}');
          setState(() {
            _isAnalyzing = true;
          });
        } else {
          print('✅ [BUBBLE] Auto-analysis completed for ${widget.message.id.substring(0, 8)}');
          
          _aiService.getAnalysis(widget.message.id).then((analysis) {
            if (analysis != null && mounted) {
              setState(() {
                _analysisResult = analysis;
                _isAnalyzing = false;
              });
              
              // Check for boundary violations and action items after auto-analysis
              print('🔍 [BUBBLE] Starting boundary/action check after auto-analysis...');
              _checkForBoundariesAndActions();
            } else if (mounted) {
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
    _analysisCompletionSubscription.cancel();
    _reactionSubscription?.cancel();
    super.dispose();
  }
  
  void _loadReactions() {
    _reactionSubscription = _reactionService
        .subscribeToReactions(widget.message.id)
        .listen((reactions) {
      if (mounted) {
        setState(() => _reactions = reactions);
      }
    });
  }

  Future<void> _requestManualAnalysis() async {
    print('📋 Long press detected - showing context menu');
    _showContextMenu();
  }

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
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
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
                      _buildContextMenuButton(
                        context,
                        icon: Icons.add_reaction_outlined,
                        label: 'React',
                        color: Colors.orange,
                        isFirst: false,
                        onTap: () {
                          Navigator.pop(context);
                          _showReactionPicker(context);
                        },
                      ),
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
                      if (widget.isFromCurrentUser)
                        _buildContextMenuButton(
                          context,
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: Colors.red,
                          isFirst: false,
                          onTap: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(context);
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
  
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('How would you like to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(forEveryone: false);
            },
            child: const Text('Delete for me', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(forEveryone: true);
            },
            child: const Text('Delete for everyone', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteMessage({required bool forEveryone}) async {
    try {
      if (forEveryone) {
        await _messageService.deleteMessageForEveryone(widget.message.id);
      } else {
        await _messageService.deleteMessage(widget.message.id);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              forEveryone 
                ? 'Message deleted for everyone' 
                : 'Message deleted for you',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $e')),
        );
      }
    }
  }
  
  void _showReactionPicker(BuildContext context) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '🎉'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'React with',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _reactionService.toggleReaction(widget.message.id, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkGray200
                          : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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

        if (_analysisResult != null) {
          print('✅ Analysis complete');
          
          // Check for boundary violations and action items
          _checkForBoundariesAndActions();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Analysis complete'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('❌ Analysis result is null');
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

  /// Check for boundary violations and action items after analysis
  Future<void> _checkForBoundariesAndActions() async {
    try {
      print('🔍 Checking for boundaries and action items...');
      print('   Message ID: ${widget.message.id}');
      print('   Message body: ${widget.message.body.substring(0, widget.message.body.length.clamp(0, 50))}...');
      print('   Sender ID: ${widget.message.senderId}');
      
      // Check boundary violations
      print('🔍 Step 1: Checking boundary violations...');
      final boundaryContent = await _peekZoneService.createBoundaryContent(widget.message);
      final hasBoundaries = boundaryContent != null;
      print('   Boundary result: ${hasBoundaries ? "FOUND violations" : "none found"}');
      
      // Check action items
      print('🔍 Step 2: Checking action items...');
      final sender = Participant(
        id: widget.message.senderId,
        conversationId: widget.message.conversationId,
        userId: widget.message.senderId,
        joinedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isAdmin: false,
        isSynced: true,
      );
      final actionContent = await _peekZoneService.createActionContent(widget.message, sender);
      final hasActions = actionContent != null;
      print('   Action result: ${hasActions ? "FOUND action items" : "none found"}');
      
      if (mounted) {
        setState(() {
          _hasBoundaryViolations = hasBoundaries;
          _hasActionItems = hasActions;
        });
        
        print('✅ Detection complete:');
        print('   - Boundaries: $hasBoundaries');
        print('   - Actions: $hasActions');
      }
    } catch (e, stackTrace) {
      print('❌ Error checking boundaries/actions: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: _requestManualAnalysis,  // Enable long-press for all messages
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
                      // Display image if mediaUrl exists
                      if (widget.message.mediaUrl != null && widget.message.mediaUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.message.mediaUrl!,
                            width: 250,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 250,
                                height: 250,
                                color: isDark ? AppTheme.darkGray300 : AppTheme.gray200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 250,
                                height: 150,
                                color: isDark ? AppTheme.darkGray300 : AppTheme.gray200,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48),
                                ),
                              );
                            },
                          ),
                        ),
                        if (widget.message.body.isNotEmpty && widget.message.body != '📷 Photo')
                          const SizedBox(height: 8),
                      ],
                      
                      // Display text if it exists and isn't just the photo placeholder
                      if (widget.message.body.isNotEmpty && widget.message.body != '📷 Photo')
                        Text(
                          widget.message.body,
                          style: TextStyle(
                            fontSize: 15,
                            color: widget.isFromCurrentUser ? Colors.white : null,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                
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
                
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.gray500 : AppTheme.gray600,
                        ),
                      ),
                      if (widget.isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        _buildReceiptStatus(isDark),
                      ],
                    ],
                  ),
                ),
                
                // Reactions display
                if (_reactions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _reactions.entries.map((entry) {
                      final emoji = entry.key;
                      final count = entry.value.length;
                      final currentUserId = _messageService.getCurrentUserId();
                      final userReacted = entry.value.contains(currentUserId);
                      
                      return GestureDetector(
                        onTap: () => _reactionService.toggleReaction(widget.message.id, emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: userReacted 
                                ? Colors.blue.withOpacity(0.2)
                                : (isDark ? AppTheme.darkGray200 : AppTheme.gray200),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: userReacted ? Colors.blue : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 14)),
                              if (count > 1) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                if (!widget.isFromCurrentUser && _analysisResult != null) ...[
                  const SizedBox(height: 8),
                  _buildFooterIcons(context, theme),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptStatus(bool isDark) {
    if (widget.receipts == null || widget.receipts!.isEmpty) {
      // No receipts - message sent but not delivered
      return Icon(
        Icons.check,
        size: 14,
        color: isDark ? AppTheme.gray500 : AppTheme.gray600,
      );
    }
    
    // Check if any receipt has 'read' status
    final hasRead = widget.receipts!.any((r) => r.status == 'read');
    
    if (hasRead) {
      // Double check - blue (read)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all,
            size: 14,
            color: Colors.blue,
          ),
        ],
      );
    }
    
    // Double check - gray (delivered but not read)
    return Icon(
      Icons.done_all,
      size: 14,
      color: isDark ? AppTheme.gray500 : AppTheme.gray600,
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

  Widget _buildFooterIcons(BuildContext context, ThemeData theme) {
    final controller = widget.heightController;
    
    // Check what was actually detected - only show RSD icon if actual RSD triggers exist
    final hasRSDTriggers = _analysisResult?.rsdTriggers != null && 
                          _analysisResult!.rsdTriggers!.isNotEmpty;
    
    // Build list of icons to show
    final List<Widget> icons = [];
    
    // RSD Icon - only if RSD triggers detected
    if (hasRSDTriggers) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: 12));
      icons.add(
        MessageIcon(
          icon: Icons.psychology_outlined,
          label: 'RSD',
          color: AppTheme.rsdColor,
          onTap: () async {
            if (controller == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Peek zone not available')),
              );
              return;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Loading RSD analysis...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            final sender = Participant(
              id: widget.message.senderId,
              conversationId: widget.message.conversationId,
              userId: widget.message.senderId,
              joinedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              isAdmin: false,
              isSynced: true,
            );
            
            final rsdContent = await _peekZoneService.createRSDContent(
              widget.message,
              sender,
              _analysisResult,
            );
            
            if (rsdContent != null && mounted) {
              controller.showInPeekZone(rsdContent);
              HapticFeedback.mediumImpact();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No RSD analysis available')),
              );
            }
          },
        ),
      );
    }
    
    // Boundary Icon - only if boundary violations detected
    if (_hasBoundaryViolations) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: 12));
      icons.add(
        MessageIcon(
          icon: Icons.shield_outlined,
          label: 'Boundary',
          color: AppTheme.boundaryColor,
          onTap: () async {
            if (controller == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Peek zone not available')),
              );
              return;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Analyzing boundaries...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            final boundaryContent = await _peekZoneService.createBoundaryContent(
              widget.message,
            );
            
            if (boundaryContent != null && mounted) {
              controller.showInPeekZone(boundaryContent);
              HapticFeedback.mediumImpact();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No boundary concerns detected')),
              );
            }
          },
        ),
      );
    }
    
    // Action Icon - only if action items detected
    if (_hasActionItems) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: 12));
      icons.add(
        MessageIcon(
          icon: Icons.bolt_outlined,
          label: 'Action',
          color: AppTheme.actionColor,
          onTap: () async {
            if (controller == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Peek zone not available')),
              );
              return;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Extracting action items...'),
                duration: Duration(seconds: 1),
              ),
            );
            
            final sender = Participant(
              id: widget.message.senderId,
              conversationId: widget.message.conversationId,
              userId: widget.message.senderId,
              joinedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              isAdmin: false,
              isSynced: true,
            );
            
            final actionContent = await _peekZoneService.createActionContent(
              widget.message,
              sender,
            );
            
            if (actionContent != null && mounted) {
              controller.showInPeekZone(actionContent);
              HapticFeedback.mediumImpact();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No action items detected')),
              );
            }
          },
        ),
      );
    }
    
    // Return row with only the icons that should appear
    if (icons.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,  // Changed from .end to .start - icons now appear close to message
      children: icons,
    );
  }
}

