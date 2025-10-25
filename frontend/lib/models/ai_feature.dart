import 'package:flutter/material.dart';

/// AI feature types
enum AIFeatureType {
  smartMessageInterpreter,
  adaptiveResponseAssistant,
  smartInboxFilters,
  ragContextPanel,
}

/// Configuration for each AI feature
class AIFeatureConfig {
  final AIFeatureType type;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> whatItDoes;
  final String location;

  const AIFeatureConfig({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.whatItDoes,
    required this.location,
  });

  static const Map<AIFeatureType, AIFeatureConfig> configs = {
    AIFeatureType.smartMessageInterpreter: AIFeatureConfig(
      type: AIFeatureType.smartMessageInterpreter,
      title: 'Smart Message Interpreter',
      icon: Icons.psychology_outlined,
      color: Colors.purple,
      description:
          'Analyzes incoming messages to help you understand tone, detect RSD triggers, explain literal vs figurative language, and identify boundary violations.',
      whatItDoes: [
        'Analyzes emotional tone and sentiment',
        'Detects RSD (Rejection Sensitive Dysphoria) triggers',
        'Explains idioms and figurative language',
        'Identifies boundary violations (after-hours, pressure language, etc.)',
        'Provides evidence for its analysis',
        'Suggests boundary-respecting responses',
      ],
      location: 'Tone badges on each incoming message, expandable detail sheet',
    ),
    AIFeatureType.adaptiveResponseAssistant: AIFeatureConfig(
      type: AIFeatureType.adaptiveResponseAssistant,
      title: 'Adaptive Response Assistant',
      icon: Icons.edit_note_outlined,
      color: Colors.blue,
      description:
          'Provides feedback on your drafted replies when you manually request it, analyzing the situation and suggesting appropriate templates and formatting options.',
      whatItDoes: [
        'Analyzes your draft message when you request it',
        'Detects the situation (declining, setting boundaries, info-dumping, etc.)',
        'Checks tone, clarity, and appropriateness',
        'Suggests social scripts and templates',
        'Offers formatting options (condense, break into chunks)',
        'Warns about potential issues before you send',
      ],
      location: 'Draft feedback panel when composing messages',
    ),
    AIFeatureType.smartInboxFilters: AIFeatureConfig(
      type: AIFeatureType.smartInboxFilters,
      title: 'Smart Inbox Filters',
      icon: Icons.filter_list_outlined,
      color: Colors.indigo,
      description:
          'Automatically categorizes and prioritizes your inbox based on message content, sender, and context to help you focus on the most important communications.',
      whatItDoes: [
        'Categorizes messages by type (email, chat, etc.)',
        'Prioritizes based on urgency and importance',
        'Filters out spam and low-priority messages',
        'Sorts conversations by relevance',
        'Helps identify important follow-ups',
        'Reduces manual sorting time',
      ],
      location: 'Inbox view, filter chips on conversation list',
    ),
    AIFeatureType.ragContextPanel: AIFeatureConfig(
      type: AIFeatureType.ragContextPanel,
      title: 'RAG Context Panel',
      icon: Icons.memory_outlined,
      color: Colors.green,
      description:
          'Provides a rich, context-aware interface for accessing and managing your long-term memory and knowledge base, enabling the AI to draw on past interactions and experiences.',
      whatItDoes: [
        'Accesses and manages your long-term memory',
        'Draws on past interactions and experiences',
        'Provides context for current conversation',
        'Helps the AI understand your preferences and patterns',
        'Enables the AI to learn from past conversations',
        'Improves its ability to provide relevant responses',
      ],
      location: 'Context panel at top of conversation (expandable header)',
    ),
  };
}

/// AI Feature state model
class AIFeature {
  final AIFeatureType type;
  bool isEnabled;

  AIFeature({
    required this.type,
    this.isEnabled = true,
  });

  AIFeatureConfig get config => AIFeatureConfig.configs[type]!;
}
