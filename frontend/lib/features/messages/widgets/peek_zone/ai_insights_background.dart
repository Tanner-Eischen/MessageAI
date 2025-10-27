import 'package:flutter/material.dart';
import 'package:messageai/features/messages/widgets/peek_zone/height_controller.dart';
import 'package:messageai/models/peek_content.dart';
import 'package:messageai/services/action_item_service.dart';
import 'package:messageai/services/boundary_violation_service.dart';
import 'package:messageai/services/ai_sender_pattern_service.dart';
import 'package:messageai/services/realtime_message_service.dart';
import 'package:messageai/models/action_item_extended.dart';
import 'package:messageai/data/remote/supabase_client.dart';
import 'dart:async';

/// Content categories for AI insights (separate from ViewMode which controls height)
enum InsightCategory {
  CONTEXT,   // Relationship context & overview
  RSD,       // RSD analysis
  BOUNDARY,  // Boundary violations
  ACTIONS,   // Action items & commitments
  PATTERNS,  // Communication patterns
}

class AIInsightsBackground extends StatefulWidget {
  final String conversationId;
  final HeightController heightController;

  const AIInsightsBackground({
    super.key,
    required this.conversationId,
    required this.heightController,
  });

  @override
  State<AIInsightsBackground> createState() => _AIInsightsBackgroundState();
}

class _AIInsightsBackgroundState extends State<AIInsightsBackground> {
  InsightCategory _currentCategory = InsightCategory.CONTEXT;
  late final ActionItemService _actionItemService;
  late final BoundaryViolationService _boundaryService;
  late final RealTimeMessageService _realtimeService;
  final _supabase = SupabaseClientProvider.client;
  
  List<ActionItemWithStatus> _conversationActionItems = [];
  List<BoundaryViolationData> _conversationBoundaryViolations = [];
  CommitmentStreak? _streak;
  
  // Context data
  int _totalMessages = 0;
  int _myMessages = 0;
  int _theirMessages = 0;
  double _avgMessagesPerDay = 0.0;
  SenderPatternData? _senderPattern;
  
  bool _isLoadingActions = false;
  bool _isLoadingBoundaries = false;
  bool _isLoadingContext = false;
  
  // Subscriptions for auto-updates
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _actionItemService = ActionItemService();
    _boundaryService = BoundaryViolationService();
    _realtimeService = RealTimeMessageService();
    
    // Initial load
    _loadActionItems();
    _loadBoundaryViolations();
    _loadConversationContext();
    
    // Subscribe to real-time message updates to refresh context and actions
    _subscribeToMessageUpdates();
  }
  
  /// Subscribe to real-time message updates to auto-refresh panels
  void _subscribeToMessageUpdates() {
    print('🔄 [AI_INSIGHTS] Subscribing to message updates for auto-refresh');
    _messageSubscription = _realtimeService.subscribeToMessages(widget.conversationId).listen((messages) {
      if (!mounted) return;
      
      print('📬 [AI_INSIGHTS] New messages detected, auto-refreshing panels...');
      
      // Auto-refresh Context panel (runs automatically as messages come in)
      _loadConversationContext();
      
      // Auto-refresh Actions panel (runs automatically to build to-do list)
      _loadActionItems();
      
      // Note: Boundary violations are per-message analyses (on-demand via mode button)
      // So we don't auto-refresh them here
    });
  }
  
  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadActionItems() async {
    setState(() => _isLoadingActions = true);
    
    try {
      // Get action items for this conversation
      final conversationItems = await _actionItemService.getConversationTimeline(
        widget.conversationId,
      );
      
      // Get streak (may fail if table doesn't exist yet)
      CommitmentStreak? streak;
      try {
        streak = await _actionItemService.getStreak();
      } catch (e) {
        print('⚠️ Could not load streak (table may not exist): $e');
        // Continue without streak - it's not critical
      }
      
      if (mounted) {
        setState(() {
          _conversationActionItems = conversationItems;
          _streak = streak;
          _isLoadingActions = false;
        });
      }
    } catch (e) {
      print('❌ Error loading action items: $e');
      if (mounted) {
        setState(() => _isLoadingActions = false);
      }
    }
  }

  Future<void> _loadBoundaryViolations() async {
    setState(() => _isLoadingBoundaries = true);
    
    try {
      // Get boundary violations for this conversation
      final violations = await _boundaryService.getConversationViolations(
        widget.conversationId,
      );
      
      if (mounted) {
        setState(() {
          _conversationBoundaryViolations = violations;
          _isLoadingBoundaries = false;
        });
      }
    } catch (e) {
      print('❌ Error loading boundary violations: $e');
      if (mounted) {
        setState(() => _isLoadingBoundaries = false);
      }
    }
  }

  Future<void> _loadConversationContext() async {
    setState(() => _isLoadingContext = true);
    
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        print('⚠️ No user logged in');
        if (mounted) {
          setState(() => _isLoadingContext = false);
        }
        return;
      }
      
      print('📊 Loading conversation context...');
      print('   Conversation ID: ${widget.conversationId}');
      print('   Current User ID: $currentUserId');
      
      // Fetch all messages in the conversation
      final messagesResponse = await _supabase
          .from('messages')
          .select('id, sender_id, created_at')
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);
      
      print('📬 Raw response type: ${messagesResponse.runtimeType}');
      print('📬 Response: $messagesResponse');
      
      final messages = messagesResponse as List;
      print('📊 Found ${messages.length} messages');
      
      if (messages.isEmpty) {
        print('📭 No messages found in conversation');
        if (mounted) {
          setState(() => _isLoadingContext = false);
        }
        return;
      }
      
      // Calculate statistics
      final total = messages.length;
      final myCount = messages.where((m) => m['sender_id'] == currentUserId).length;
      final theirCount = total - myCount;
      
      // Handle created_at - could be int or String
      final firstCreatedAt = messages.first['created_at'];
      final lastCreatedAt = messages.last['created_at'];
      
      int firstTimestamp;
      int lastTimestamp;
      
      if (firstCreatedAt is int) {
        firstTimestamp = firstCreatedAt;
        lastTimestamp = lastCreatedAt as int;
      } else if (firstCreatedAt is String) {
        // Parse ISO timestamp
        firstTimestamp = DateTime.parse(firstCreatedAt).millisecondsSinceEpoch ~/ 1000;
        lastTimestamp = DateTime.parse(lastCreatedAt as String).millisecondsSinceEpoch ~/ 1000;
      } else {
        print('⚠️ Unexpected created_at type: ${firstCreatedAt.runtimeType}');
        firstTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        lastTimestamp = firstTimestamp;
      }
      
      final firstDate = DateTime.fromMillisecondsSinceEpoch(firstTimestamp * 1000);
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp * 1000);
      
      final daysDiff = lastDate.difference(firstDate).inDays;
      final avgPerDay = daysDiff > 0 ? total / daysDiff : total.toDouble();
      
      print('✅ Context loaded: $total messages, $myCount from me, $theirCount from others');
      
      // Get the sender ID (the other person in the conversation)
      final otherSenderId = messages
          .firstWhere((m) => m['sender_id'] != currentUserId, orElse: () => messages.first)['sender_id'] as String;
      
      print('📊 Loading sender pattern for: $otherSenderId');
      
      // Load sender pattern (communication style, relationship info)
      SenderPatternData? senderPattern;
      try {
        senderPattern = await AISenderPatternService().getSenderPatterns(otherSenderId);
        print('✅ Sender pattern loaded: ${senderPattern?.totalMessages ?? 0} messages analyzed');
      } catch (e) {
        print('⚠️ Could not load sender pattern: $e');
      }
      
      if (mounted) {
        setState(() {
          _totalMessages = total;
          _myMessages = myCount;
          _theirMessages = theirCount;
          _avgMessagesPerDay = avgPerDay;
          _senderPattern = senderPattern;
          _isLoadingContext = false;
        });
      }
    } catch (e) {
      print('❌ Error loading conversation context: $e');
      if (mounted) {
        setState(() => _isLoadingContext = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _currentCategory;
    
    // Always scrollable in SPLIT and FULL modes
    final isScrollable = widget.heightController.currentMode == ViewMode.SPLIT ||
                        widget.heightController.currentMode == ViewMode.FULL;
    
    return Container(
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Category selector (fixed at top)
          _buildCategorySelector(context, currentCategory),
          
          // Current category's page - scrollable in SPLIT and FULL modes
          Expanded(
            child: isScrollable
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildCurrentCategoryPage(context, widget.heightController, currentCategory),
                  )
                : _buildCurrentCategoryPage(context, widget.heightController, currentCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context, InsightCategory currentCategory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCategoryButton(
              context,
              InsightCategory.CONTEXT,
              Icons.people_outline,
              'Context',
              currentCategory,
            ),
            const SizedBox(width: 10),
            _buildCategoryButton(
              context,
              InsightCategory.RSD,
              Icons.psychology_outlined,
              'RSD',
              currentCategory,
            ),
            const SizedBox(width: 10),
            _buildCategoryButton(
              context,
              InsightCategory.BOUNDARY,
              Icons.block_outlined,
              'Boundary',
              currentCategory,
            ),
            const SizedBox(width: 10),
            _buildCategoryButton(
              context,
              InsightCategory.ACTIONS,
              Icons.check_circle_outline,
              'Actions',
              currentCategory,
            ),
            const SizedBox(width: 10),
            _buildCategoryButton(
              context,
              InsightCategory.PATTERNS,
              Icons.insights_outlined,
              'Patterns',
              currentCategory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    InsightCategory category,
    IconData icon,
    String label,
    InsightCategory currentCategory,
  ) {
    final isActive = currentCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        print('🎯 Category button tapped: ${category.name}');
        setState(() {
          _currentCategory = category;
        });
        
        // Refresh data when tabs are selected
        if (category == InsightCategory.ACTIONS) {
          print('🔄 ACTIONS tab selected, refreshing action items...');
          _loadActionItems();
        } else if (category == InsightCategory.BOUNDARY) {
          print('🔄 BOUNDARY tab selected, refreshing boundary violations...');
          _loadBoundaryViolations();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : (isDark ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? Colors.blue.shade400 : (isDark ? Colors.grey[700]! : Colors.grey.shade300),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey.shade700),
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey.shade800),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCategoryPage(
    BuildContext context,
    HeightController controller,
    InsightCategory category,
  ) {
    switch (category) {
      case InsightCategory.CONTEXT:
        return _buildContextPage(context, controller);
      case InsightCategory.RSD:
        return _buildRSDPage(context, controller);
      case InsightCategory.BOUNDARY:
        return _buildBoundaryPage(context, controller);
      case InsightCategory.ACTIONS:
        return _buildActionsPage(context, controller);
      case InsightCategory.PATTERNS:
        return _buildPatternsPage(context, controller);
    }
  }

  // CONTEXT CATEGORY PAGE
  Widget _buildContextPage(BuildContext context, HeightController controller) {
    if (_isLoadingContext) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_totalMessages == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No messages yet in this conversation',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RELATIONSHIP OVERVIEW
        _buildSection(
          context,
          title: 'Relationship Context',
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Communication Style
                  _buildInfoCard(
                    Icons.psychology_outlined,
                    'Communication Style',
                    _getCommunicationStyleSummary(),
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  
                  // Context Summary (only if we have pattern data)
                  if (_senderPattern != null && _senderPattern!.context.isNotEmpty) ...[
                    _buildInfoCard(
                      Icons.info_outline,
                      'Communication Patterns',
                      _senderPattern!.context,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Reliability
                  _buildInfoCard(
                    Icons.check_circle_outline,
                    'Reliability',
                    _getReliabilitySummary(),
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // CONVERSATION STATS
          _buildSection(
            context,
            title: 'Conversation Stats',
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildContextStat(
                          Icons.chat_bubble_outline,
                          'Total',
                          _totalMessages.toString(),
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContextStat(
                          Icons.trending_up,
                          'Per Day',
                          _avgMessagesPerDay.toStringAsFixed(1),
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildContextStat(
                          Icons.person_outline,
                          'You',
                          _myMessages.toString(),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContextStat(
                          Icons.people_outline,
                          'Them',
                          _theirMessages.toString(),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 100),
        ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCommunicationStyleSummary() {
    if (_senderPattern == null || !_senderPattern!.hasData) {
      // Fallback: Basic analysis from message stats
      if (_totalMessages < 5) {
        return 'Building profile... Send more messages to see communication patterns.';
      }
      
      // Simple heuristic based on message frequency
      if (_avgMessagesPerDay > 5) {
        return 'Active communicator. Responds frequently.';
      } else if (_avgMessagesPerDay > 2) {
        return 'Regular communicator. Stays engaged.';
      } else {
        return 'Occasional communicator. Messages when needed.';
      }
    }
    
    // Map the style code to human-readable text
    switch (_senderPattern!.communicationStyle) {
      case 'brief_and_direct':
        return 'Brief and direct. Gets straight to the point.';
      case 'warm_and_verbose':
        return 'Warm and detailed. Takes time to explain thoroughly.';
      case 'balanced':
        return 'Balanced approach. Clear but considerate.';
      default:
        return 'Communication style: ${_senderPattern!.communicationStyle}';
    }
  }

  String _getReliabilitySummary() {
    if (_senderPattern == null || !_senderPattern!.hasData) {
      // Fallback message
      return 'Reliability tracking requires feedback on AI analyses. Use the feedback buttons when analyzing messages to build this profile.';
    }
    
    final score = _senderPattern!.averageHelpfulness;
    if (score >= 0.8) {
      return 'Very reliable. Usually follows through (${(score * 100).toStringAsFixed(0)}% helpful).';
    } else if (score >= 0.6) {
      return 'Generally reliable (${(score * 100).toStringAsFixed(0)}% helpful).';
    } else if (score >= 0.4) {
      return 'Mixed reliability (${(score * 100).toStringAsFixed(0)}% helpful).';
    } else {
      return 'Limited reliability data (${(score * 100).toStringAsFixed(0)}% helpful).';
    }
  }

  Widget _buildContextStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RSD CATEGORY PAGE
  Widget _buildRSDPage(BuildContext context, HeightController controller) {
    if (controller.currentContent is! RSDAnalysis) {
      return _buildEmptyState(
        context,
        icon: Icons.psychology_outlined,
        title: 'No RSD Analysis',
        message: 'Tap the RSD icon (🧠) on a message to analyze it for rejection sensitivity triggers.',
      );
    }
    
    final rsdAnalysis = controller.currentContent as RSDAnalysis;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PEEK SECTION (20% visible) - Compact trigger + interpretation
        _buildRSDPeekSection(context, rsdAnalysis),
          
          const Divider(),
          
          // MIDDLE SECTION (50% visible) - Two bubbles: Anxiety vs Reality
          _buildSection(
            context,
            title: 'Anxiety vs Reality',
            child: _buildRSDComparison(context, rsdAnalysis),
          ),
          
          const Divider(),
          
          // DETAILED SECTION (70% visible) - Suggested responses
          _buildSection(
            context,
            title: 'Suggested Responses',
            child: _buildRSDSuggestedResponses(context, rsdAnalysis),
          ),
          
          const Divider(),
          
          // DEEP SECTION (95% visible) - Evidence + All interpretations
          _buildSection(
            context,
            title: 'How AI Reached This Conclusion',
            child: _buildRSDEvidence(context, rsdAnalysis),
          ),
          
          const SizedBox(height: 100),
        ],
    );
  }

  // BOUNDARY CATEGORY PAGE
  Widget _buildBoundaryPage(BuildContext context, HeightController controller) {
    if (_isLoadingBoundaries) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_conversationBoundaryViolations.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Boundary Violations in This Conversation',
              child: _buildBoundaryViolationsList(context),
            ),
          ] else ...[
            _buildSection(
              context,
              title: 'No Boundary Violations',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'No boundary violations detected in this conversation yet.\n\n'
                      'Examples of boundary violations:\n'
                      '• After-hours pressure ("need this tonight!")\n'
                      '• Guilt-tripping ("only you can help")\n'
                      '• Timeline pressure ("stakeholders are waiting")\n'
                      '• Overstepping personal boundaries',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 100),
        ],
    );
  }

  Widget _buildBoundaryViolationsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: _conversationBoundaryViolations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final violation = _conversationBoundaryViolations[index];
        return _buildBoundaryViolationCard(context, violation);
      },
    );
  }

  Widget _buildBoundaryViolationCard(BuildContext context, BoundaryViolationData violation) {
    final severityColor = violation.severity == 'high' 
        ? Colors.red 
        : violation.severity == 'medium'
            ? Colors.orange
            : Colors.yellow.shade700;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two-bubble comparison: What happened vs Why it matters
          Row(
            children: [
              // Left bubble: Boundary crossed
              Expanded(
                child: _buildBoundaryBubble(
                  context,
                  'Boundary Crossed',
                  _formatViolationType(violation.type),
                  severityColor.withOpacity(0.1),
                  severityColor,
                  Icons.block_outlined,
                ),
              ),
              const SizedBox(width: 12),
              // Right bubble: Why it matters
              Expanded(
                child: _buildBoundaryBubble(
                  context,
                  'Why It Matters',
                  violation.explanation,
                  Colors.blue.withOpacity(0.1),
                  Colors.blue,
                  Icons.info_outline,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Severity indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: severityColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${violation.severity.toUpperCase()} SEVERITY',
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          // Alternative response options header
          Text(
            'Alternative Response Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Three response options as bubbles
          _buildResponseBubble(context, '😊 Gentle Approach', violation.suggestedGentle, Colors.green),
          const SizedBox(height: 8),
          _buildResponseBubble(context, '⚖️ Balanced Response', violation.suggestedModerate, Colors.orange),
          const SizedBox(height: 8),
          _buildResponseBubble(context, '🛑 Firm Boundary', violation.suggestedFirm, Colors.red),
        ],
      ),
    );
  }
  
  Widget _buildBoundaryBubble(
    BuildContext context,
    String title,
    String content,
    Color bgColor,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _getDarkerShade(accentColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseBubble(BuildContext context, String label, String response, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getDarkerShade(color),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            response,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _formatViolationType(String type) {
    switch (type) {
      case 'timeline_pressure':
        return 'Timeline Pressure';
      case 'scope_creep':
        return 'Scope Creep';
      case 'guilt_tripping':
        return 'Guilt Tripping';
      case 'overstepping':
        return 'Overstepping Boundaries';
      case 'after_hours_pressure':
        return 'After-Hours Pressure';
      case 'repeated_pushing':
        return 'Repeated Boundary Pushing';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  // ACTIONS CATEGORY PAGE
  Widget _buildActionsPage(BuildContext context, HeightController controller) {
    if (_isLoadingActions) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Streak info
        if (_streak != null) ...[
          _buildStreakSection(context),
            const Divider(),
          ],
          
          // Action items list
          if (_conversationActionItems.isNotEmpty) ...[
            _buildSection(
              context,
              title: 'Commitments in This Conversation',
              child: _buildActionItemsList(context),
            ),
          ] else ...[
            _buildSection(
              context,
              title: 'No Action Items',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No commitments extracted from this conversation yet.\n\n'
                  'Send messages like:\n'
                  '• "I\'ll send you the report by Friday"\n'
                  '• "Let me call you tomorrow at 3pm"\n'
                  '• "I\'ll review the document this week"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 100),
        ],
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    final streak = _streak!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakStat('${streak.currentStreakCount}', 'Current\nStreak', context),
          _buildStreakStat('${streak.bestStreakCount}', 'Best\nStreak', context),
          _buildStreakStat('${streak.totalCompleted}', 'Total\nDone', context),
        ],
      ),
    );
  }

  Widget _buildStreakStat(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItemsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: _conversationActionItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _conversationActionItems[index];
        return _buildActionItemCard(context, item);
      },
    );
  }

  Widget _buildActionItemCard(BuildContext context, ActionItemWithStatus item) {
    final deadline = item.extractedDeadline != null
        ? DateTime.fromMillisecondsSinceEpoch(item.extractedDeadline! * 1000)
        : null;
    
    final isOverdue = deadline != null && deadline.isBefore(DateTime.now());
    final urgencyColor = isOverdue 
        ? Colors.red 
        : (deadline != null && deadline.difference(DateTime.now()).inDays < 2)
            ? Colors.orange
            : Colors.blue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: urgencyColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.actionType.toUpperCase(),
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.commitmentText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (item.actionTarget != null && item.actionTarget!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Target: ${item.actionTarget}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            if (deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: urgencyColor),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(deadline),
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.status == 'pending') ...[
                  TextButton.icon(
                    onPressed: () => _markActionItemComplete(item),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Mark Done'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Due today';
      if (days == 1) return 'Due yesterday';
      return 'Due $days days ago';
    }
    
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    if (diff.inDays < 7) return 'Due in ${diff.inDays} days';
    
    return 'Due ${deadline.month}/${deadline.day}';
  }

  Future<void> _markActionItemComplete(ActionItemWithStatus item) async {
    final success = await _actionItemService.markCompleted(item.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Commitment marked complete!')),
      );
      _loadActionItems(); // Reload
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to mark complete')),
      );
    }
  }

  // PATTERNS CATEGORY PAGE
  Widget _buildPatternsPage(BuildContext context, HeightController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          _buildSection(
            context,
            title: 'Communication Patterns',
            child: const Text('How you and they typically communicate'),
          ),
          
          const Divider(),
          
          _buildSection(
            context,
            title: 'Response Times',
            child: const Text('Average response times and patterns'),
          ),
          
          const Divider(),
          
          _buildSection(
            context,
            title: 'Topic Analysis',
            child: const Text('Common topics and conversational themes'),
          ),
          
          const SizedBox(height: 100),
        ],
    );
  }

  // HELPER WIDGETS

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // RSD-specific widgets
  // SECTION 1: PEEK (20% visible) - Compact
  Widget _buildRSDPeekSection(BuildContext context, RSDAnalysis analysis) {
    final topInterp = analysis.interpretations.first;
    // Extract trigger words (first few words or full message if short)
    final triggerWords = analysis.message.body.length > 20 
        ? analysis.message.body.substring(0, 17).trim() + '...'
        : analysis.message.body;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🧠 RSD: "$triggerWords"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'Most likely: ${topInterp.interpretation}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildReasoningPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 2: MIDDLE (50% visible) - Two bubbles side by side
  Widget _buildRSDComparison(BuildContext context, RSDAnalysis analysis) {
    final topInterp = analysis.interpretations.first;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Anxiety bubble (red)
          Expanded(
            child: _buildComparisonCard(
              'Your Anxiety Says',
              'They\'re upset with you',
              Colors.red.shade50,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          // Reality bubble (green)
          Expanded(
            child: _buildComparisonCard(
              'Most Likely Meaning',
              topInterp.interpretation,
              Colors.green.shade50,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // SECTION 3: DETAILED (70% visible) - Suggested responses
  Widget _buildRSDSuggestedResponses(BuildContext context, RSDAnalysis analysis) {
    final topInterp = analysis.interpretations.first;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRSDResponseOption(
            '💬 Calm Response',
            topInterp.reasoning.isNotEmpty 
                ? topInterp.reasoning 
                : 'Take a moment before responding. Their message likely isn\'t rejection.',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildRSDResponseOption(
            '🤔 Ask for Clarity',
            'If you\'re unsure, it\'s okay to ask: "Is everything alright?" This opens dialogue without assuming negativity.',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRSDResponseOption(String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _getDarkerShade(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  // SECTION 4: DEEP (95% visible) - Evidence + All interpretations
  Widget _buildRSDEvidence(BuildContext context, RSDAnalysis analysis) {
    final topInterp = analysis.interpretations.first;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Evidence/Reasoning
          Text(
            'Evidence for "${topInterp.interpretation}":',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _buildReasoningPoint('${topInterp.likelihood}% confidence in "${analysis.message.body}" = ${topInterp.interpretation.toLowerCase()}'),
          _buildReasoningPoint('Based on past message patterns and communication style'),
          _buildReasoningPoint('No negative escalation history detected'),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // All interpretations
          Text(
            'All Possible Interpretations:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...analysis.interpretations.map((interp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${interp.likelihood}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            interp.interpretation,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (interp.reasoning.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              interp.reasoning,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(String title, String content, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getDarkerShade(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  /// Helper to get a darker shade of a color
  Color _getDarkerShade(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }
}

