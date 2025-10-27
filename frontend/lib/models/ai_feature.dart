import 'package:flutter/material.dart';

/// AI feature types - Feature #1 MVP focus only
enum AIFeatureType {
  smartMessageInterpreter, // The core Feature #1 - RSD detection + interpretations
}

/// Configuration for Feature #1: Smart Message Interpreter
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
      color: Color(0xFF7C3AED), // Purple
      description:
          'Analyzes incoming messages to help you understand tone, detect RSD triggers, identify boundary violations, and see alternative interpretations with confidence scores.',
      whatItDoes: [
        'Detects RSD (Rejection Sensitive Dysphoria) triggers like "ok", "fine", short replies',
        'Generates 3 alternative interpretations with confidence percentages',
        'Shows evidence supporting each interpretation (highlighted phrases)',
        'Learns from your feedback to improve accuracy over time',
        'Lets you customize which triggers apply to you personally',
        'Tracks sender patterns to understand their communication style (last 90 days)',
      ],
      location: 'Expandable badge on each incoming message',
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
