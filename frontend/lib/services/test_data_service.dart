import 'package:uuid/uuid.dart';
import 'package:messageai/data/drift/app_db.dart';
import 'package:messageai/services/message_service.dart';

/// Service for populating test data to showcase AI features
class TestDataService {
  static final TestDataService _instance = TestDataService._internal();
  factory TestDataService() => _instance;
  TestDataService._internal();

  final _messageService = MessageService();
  final _db = AppDb.instance;

  /// Test messages that trigger different AI features
  static const Map<String, List<String>> testScenarios = {
    'rsd_analysis': [
      'Hey, just wanted to check in. How have you been?',
      'I\'m doing okay, thanks for asking.',
      'That\'s great! I was thinking about our conversation yesterday.',
      'Yeah, me too. I appreciate you taking the time.',
      'Of course! I always enjoy our talks.',
      'k', // RSD TRIGGER: Passive-aggressive, dismissive
    ],
    'boundary_violation': [
      'Good morning! Ready for the meeting today?',
      'Yes, I\'ve prepared all the materials.',
      'Perfect! I think this will go really well.',
      'I agree. The team has been working hard.',
      'Absolutely. Everyone has been so dedicated.',
      'You MUST finish this by tonight or you\'re fired!', // BOUNDARY TRIGGER: Threatening, demanding
    ],
    'action_items': [
      'We need to discuss the project timeline.',
      'Sure, what are you thinking?',
      'I think we should break it into phases.',
      'That makes sense. How many phases?',
      'Probably three: planning, development, and testing.',
      'Can you send me the budget report by Friday, schedule a meeting with the design team next week, and update the project timeline by EOD Thursday?', // ACTION ITEMS TRIGGER
    ],
    'context_rag': [
      'I\'ve been working on the authentication system for our app.',
      'Oh nice! What framework are you using?',
      'I\'m using Firebase Auth with custom JWT tokens.',
      'Interesting choice. How are you handling refresh tokens?',
      'I implemented a token rotation strategy with 7-day expiry.',
      'We also set up role-based access control using custom claims.',
      'The claims are validated on every request to ensure security.',
      'I added rate limiting to prevent brute force attacks.',
      'The system logs all authentication attempts for auditing.',
      'We integrated with OAuth providers like Google and GitHub.',
      'Multi-factor authentication is now available for admins.',
      'Password reset flows use time-limited magic links.',
      'Session management is handled through secure HTTP-only cookies.',
      'I\'ve documented everything in the team wiki.',
      'The test suite covers all authentication scenarios.',
      'We\'re monitoring failed login attempts with alerts.',
      'User data is encrypted at rest using AES-256.',
      'The database uses row-level security policies.',
      'API endpoints are protected with middleware validation.',
      'We perform regular security audits quarterly.',
      'What did we decide about the token expiry time?', // CONTEXT TRIGGER: Requires RAG to answer from history
    ],
    'combined_stress_test': [
      'Morning! How was your weekend?',
      'It was great, thanks! Went hiking with friends.',
      'That sounds amazing! Which trail did you take?',
      'We did the Eagle Peak trail. The views were incredible.',
      'I love that trail! The sunset from the top is breathtaking.',
      'k', // RSD
      'Anyway, we need to talk about the project.',
      'Sure, what\'s on your mind?',
      'You need to finish ALL the work by tomorrow or else!', // BOUNDARY
      'That seems unreasonable. Can we discuss the timeline?',
      'Fine. Can you at least send the report, update the docs, and call the client?', // ACTION ITEMS
      'I\'ll do my best. What were the specs we discussed last week?', // CONTEXT
      'You know what? Just forget it.',
      'I\'m trying to help. Communication is important.',
      'Whatever.', // RSD
    ],
  };

  /// Populate a conversation with test messages for a specific scenario
  Future<void> populateTestScenario(
    String conversationId,
    String scenario, {
    String? otherUserId,
  }) async {
    final messages = testScenarios[scenario];
    if (messages == null) {
      throw ArgumentError('Unknown scenario: $scenario');
    }

    final currentUserId = _messageService.getCurrentUserId();
    if (currentUserId == null) {
      throw Exception('No current user');
    }

    // Use provided userId or create a test user
    final otherUser = otherUserId ?? 'test-user-${const Uuid().v4()}';
    
    // Clear existing messages in conversation (for clean test)
    await _clearConversationMessages(conversationId);

    // Insert messages, alternating between users
    for (var i = 0; i < messages.length; i++) {
      final isCurrentUser = i % 2 == 0; // Alternate senders
      final senderId = isCurrentUser ? currentUserId : otherUser;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final messageId = const Uuid().v4();

      final message = Message(
        id: messageId,
        conversationId: conversationId,
        senderId: senderId,
        body: messages[i],
        createdAt: now - (messages.length - i) * 60, // Space messages 1 minute apart
        updatedAt: now - (messages.length - i) * 60,
        isSynced: true, // Mark as synced so they don't get sent to backend
      );

      await _db.messageDao.upsertMessage(message);
      
      // Small delay for realistic timing
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Update conversation timestamp
    await _db.conversationDao.updateLastMessageTime(conversationId);
  }

  /// Send a single test message that triggers a specific AI feature
  Future<Message> sendTestMessage(
    String conversationId,
    String messageType,
  ) async {
    final testMessages = {
      'rsd': 'k', // Passive-aggressive, dismissive
      'rsd_aggressive': 'Whatever. Do what you want.', // More aggressive
      'rsd_sarcastic': 'Oh great, another brilliant idea.', // Sarcastic
      
      'boundary_threat': 'You MUST do this now or you\'re fired!',
      'boundary_guilt': 'If you cared about me at all, you would do this.',
      'boundary_demand': 'I don\'t care what you think. Just do it!',
      'boundary_manipulation': 'Everyone else agrees with me. You\'re the only one being difficult.',
      
      'action_items_simple': 'Please send me the report by Friday.',
      'action_items_multiple': 'Can you send the report, schedule the meeting, and update the timeline?',
      'action_items_complex': 'We need to finalize the budget by EOD, get approval from stakeholders by Tuesday, schedule a team meeting for Wednesday, prepare the presentation by Thursday, and submit everything by Friday at 5 PM.',
      
      'context_question': 'What were the main points we discussed about authentication security?',
      'context_reference': 'Can you remind me about the token expiry strategy we decided on?',
      'context_summary': 'What has been our approach to user data protection?',
    };

    final body = testMessages[messageType];
    if (body == null) {
      throw ArgumentError('Unknown message type: $messageType');
    }

    return await _messageService.sendMessage(
      conversationId: conversationId,
      body: body,
    );
  }

  /// Clear all messages in a conversation (for testing)
  Future<void> _clearConversationMessages(String conversationId) async {
    final messages = await _db.messageDao.getMessagesByConversation(conversationId);
    for (final message in messages) {
      await _db.messageDao.deleteMessage(message.id);
    }
  }

  /// Get list of available scenarios
  List<String> getAvailableScenarios() => testScenarios.keys.toList();

  /// Get description for a scenario
  String getScenarioDescription(String scenario) {
    switch (scenario) {
      case 'rsd_analysis':
        return 'RSD Tone Analysis - Message ending with "k"';
      case 'boundary_violation':
        return 'Boundary Violation - Threatening message';
      case 'action_items':
        return 'Action Items - Multiple tasks in message';
      case 'context_rag':
        return 'Context/RAG - Long conversation history';
      case 'combined_stress_test':
        return 'Combined Test - All features in one conversation';
      default:
        return scenario;
    }
  }
}

