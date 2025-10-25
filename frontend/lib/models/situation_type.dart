import 'package:flutter/material.dart';

/// Types of situations for response templates
enum SituationType {
  declining('declining', 'Saying No', Icons.cancel),
  boundarySetting('boundary_setting', 'Setting Boundary', Icons.shield),
  infoDumping('info_dumping', 'Sharing Info', Icons.lightbulb),
  apologizing('apologizing', 'Apologizing', Icons.handshake),
  clarifying('clarifying', 'Clarifying', Icons.help_outline),
  casualChat('casual_chat', 'Casual Chat', Icons.chat),
  workProfessional('work_professional', 'Professional', Icons.work),
  emotionalSupport('emotional_support', 'Support', Icons.favorite),
  unknown('unknown', 'Unknown', Icons.question_mark);

  final String value;
  final String displayName;
  final IconData icon;

  const SituationType(this.value, this.displayName, this.icon);

  static SituationType fromString(String value) {
    return SituationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SituationType.unknown,
    );
  }

  Color getColor() {
    switch (this) {
      case SituationType.declining:
        return Colors.red;
      case SituationType.boundarySetting:
        return Colors.orange;
      case SituationType.infoDumping:
        return Colors.purple;
      case SituationType.apologizing:
        return Colors.blue;
      case SituationType.clarifying:
        return Colors.teal;
      case SituationType.casualChat:
        return Colors.green;
      case SituationType.workProfessional:
        return Colors.indigo;
      case SituationType.emotionalSupport:
        return Colors.pink;
      case SituationType.unknown:
        return Colors.grey;
    }
  }
}

/// Situation detection result
class SituationDetection {
  final SituationType situationType;
  final double confidence;
  final String reasoning;
  final List<String> suggestedTemplateIds;

  SituationDetection({
    required this.situationType,
    required this.confidence,
    required this.reasoning,
    required this.suggestedTemplateIds,
  });

  factory SituationDetection.fromJson(Map<String, dynamic> json) {
    return SituationDetection(
      situationType: SituationType.fromString(json['situation_type'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
      suggestedTemplateIds: (json['suggested_templates'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'situation_type': situationType.value,
      'confidence': confidence,
      'reasoning': reasoning,
      'suggested_templates': suggestedTemplateIds,
    };
  }

  @override
  String toString() {
    return 'SituationDetection(type: ${situationType.displayName}, confidence: ${(confidence * 100).toInt()}%)';
  }
}

