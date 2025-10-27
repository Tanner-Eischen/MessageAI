import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:messageai/services/test_data_service.dart';
import 'package:messageai/services/ai_analysis_service.dart';
import 'package:messageai/services/boundary_violation_service.dart';
import 'package:messageai/data/drift/app_db.dart';

/// Floating Action Button with test menu for showcasing AI features
class TestMenuFab extends StatefulWidget {
  final String conversationId;
  final VoidCallback onMessageSent;

  const TestMenuFab({
    super.key,
    required this.conversationId,
    required this.onMessageSent,
  });

  @override
  State<TestMenuFab> createState() => _TestMenuFabState();
}

class _TestMenuFabState extends State<TestMenuFab>
    with SingleTickerProviderStateMixin {
  final _testDataService = TestDataService();
  final _aiAnalysisService = AIAnalysisService();
  final _boundaryService = BoundaryViolationService();
  
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  Future<void> _sendTestMessage(String messageType, String label) async {
    try {
      _closeMenu();
      
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending test message: $label'),
          duration: const Duration(seconds: 1),
        ),
      );

      final message = await _testDataService.sendTestMessage(
        widget.conversationId,
        messageType,
      );

      // Trigger the appropriate AI analysis
      if (messageType.startsWith('rsd')) {
        await _analyzeRSD(message);
      } else if (messageType.startsWith('boundary')) {
        await _analyzeBoundary(message);
      }

      widget.onMessageSent();
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Test sent: $label'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _analyzeRSD(Message message) async {
    try {
      final analysis = await _aiAnalysisService.requestAnalysis(
        message.id,
        message.body,
        isFromCurrentUser: false,
        messageTimestamp: message.createdAt,
      );
      
      if (mounted) {
        if (analysis != null && analysis.alternativeInterpretations != null && analysis.alternativeInterpretations!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🧠 RSD Analysis found ${analysis.alternativeInterpretations!.length} interpretations!'),
              backgroundColor: const Color(0xFF7C3AED),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No RSD patterns detected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('RSD analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSD analysis failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _analyzeBoundary(Message message) async {
    try {
      final violations = await _boundaryService.detectViolations(
        messageId: message.id,
        messageBody: message.body,
        senderId: message.senderId,
        messageTimestamp: message.createdAt,
      );
      
      if (mounted) {
        if (violations != null && violations.violations.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Found ${violations.violations.length} boundary violation(s)!'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No boundary violations detected'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Boundary analysis error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Boundary analysis failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadScenario(String scenario) async {
    try {
      _closeMenu();
      
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading test scenario...'),
          duration: Duration(seconds: 2),
        ),
      );

      await _testDataService.populateTestScenario(
        widget.conversationId,
        scenario,
      );

      widget.onMessageSent();
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        final description = _testDataService.getScenarioDescription(scenario);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded: $description'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error loading scenario: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Menu items
        if (_isExpanded) ...[
          _buildMenuSection(
            title: '🧠 RSD Analysis',
            items: [
              _TestMenuItem(
                icon: Icons.psychology,
                label: 'Send "k"',
                onTap: () => _sendTestMessage('rsd', 'RSD: "k"'),
              ),
              _TestMenuItem(
                icon: Icons.psychology,
                label: 'Aggressive',
                onTap: () => _sendTestMessage('rsd_aggressive', 'RSD: Aggressive'),
              ),
              _TestMenuItem(
                icon: Icons.psychology,
                label: 'Sarcastic',
                onTap: () => _sendTestMessage('rsd_sarcastic', 'RSD: Sarcastic'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildMenuSection(
            title: '⚠️ Boundary Violations',
            items: [
              _TestMenuItem(
                icon: Icons.warning,
                label: 'Threat',
                onTap: () => _sendTestMessage('boundary_threat', 'Boundary: Threat'),
              ),
              _TestMenuItem(
                icon: Icons.warning,
                label: 'Guilt Trip',
                onTap: () => _sendTestMessage('boundary_guilt', 'Boundary: Guilt'),
              ),
              _TestMenuItem(
                icon: Icons.warning,
                label: 'Demand',
                onTap: () => _sendTestMessage('boundary_demand', 'Boundary: Demand'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildMenuSection(
            title: '📋 Action Items',
            items: [
              _TestMenuItem(
                icon: Icons.checklist,
                label: 'Simple',
                onTap: () => _sendTestMessage('action_items_simple', 'Action: Simple'),
              ),
              _TestMenuItem(
                icon: Icons.checklist,
                label: 'Multiple',
                onTap: () => _sendTestMessage('action_items_multiple', 'Action: Multiple'),
              ),
              _TestMenuItem(
                icon: Icons.checklist,
                label: 'Complex',
                onTap: () => _sendTestMessage('action_items_complex', 'Action: Complex'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildMenuSection(
            title: '🔍 Context/RAG',
            items: [
              _TestMenuItem(
                icon: Icons.search,
                label: 'Load Long History',
                onTap: () => _loadScenario('context_rag'),
              ),
              _TestMenuItem(
                icon: Icons.search,
                label: 'Ask Question',
                onTap: () => _sendTestMessage('context_question', 'Context: Question'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildMenuSection(
            title: '🚀 Full Scenarios',
            items: [
              _TestMenuItem(
                icon: Icons.rocket_launch,
                label: 'Combined Test',
                onTap: () => _loadScenario('combined_stress_test'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleMenu,
          backgroundColor: const Color(0xFF7C3AED),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _expandAnimation,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_TestMenuItem> items,
  }) {
    return FadeTransition(
      opacity: _expandAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(_expandAnimation),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              ...items.map((item) => _buildMenuItem(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(_TestMenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TestMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

