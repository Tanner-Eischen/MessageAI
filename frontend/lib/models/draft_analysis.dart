import 'package:flutter/material.dart';
import 'package:messageai/models/situation_type.dart';
import 'package:messageai/models/response_template.dart';

/// Model for draft message analysis results
/// Extends tone analysis with confidence scoring and suggestions
class DraftAnalysis {
  // Tone analysis fields
  final String tone;
  final String? intensity;
  final String? urgencyLevel;
  final String? intent;
  final Map<String, dynamic>? contextFlags;
  final String? reasoning;
  
  // Draft-specific fields
  final int confidenceScore; // 0-100
  final AppropriatenessLevel appropriateness;
  final List<String> suggestions;
  final List<String> warnings;
  final List<String> strengths;
  
  // ✅ NEW: Phase 2 fields
  final SituationDetection? situationDetection;
  final List<ResponseTemplate>? suggestedTemplates;

  const DraftAnalysis({
    required this.tone,
    this.intensity,
    this.urgencyLevel,
    this.intent,
    this.contextFlags,
    this.reasoning,
    required this.confidenceScore,
    required this.appropriateness,
    required this.suggestions,
    required this.warnings,
    required this.strengths,
    // NEW
    this.situationDetection,
    this.suggestedTemplates,
  });

  factory DraftAnalysis.fromJson(Map<String, dynamic> json) {
    return DraftAnalysis(
      // Tone fields
      tone: json['tone'] as String,
      intensity: json['intensity'] as String?,
      urgencyLevel: json['urgency_level'] as String?,
      intent: json['intent'] as String?,
      contextFlags: json['context_flags'] as Map<String, dynamic>?,
      reasoning: json['reasoning'] as String?,
      
      // Draft fields
      confidenceScore: json['confidence_score'] as int,
      appropriateness: AppropriatenessLevel.fromString(
        json['appropriateness'] as String,
      ),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      warnings: (json['warnings'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      strengths: (json['strengths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      
      // NEW: Phase 2 fields
      situationDetection: json['situation_detection'] != null
          ? SituationDetection.fromJson(json['situation_detection'] as Map<String, dynamic>)
          : null,
      suggestedTemplates: (json['suggested_templates'] as List<dynamic>?)
          ?.map((e) => ResponseTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get color based on confidence score
  Color getConfidenceColor() {
    if (confidenceScore >= 90) return Colors.green;
    if (confidenceScore >= 75) return Colors.lightGreen;
    if (confidenceScore >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Get icon based on appropriateness
  IconData getAppropriatenessIcon() {
    switch (appropriateness) {
      case AppropriatenessLevel.excellent:
        return Icons.check_circle;
      case AppropriatenessLevel.good:
        return Icons.thumb_up;
      case AppropriatenessLevel.okay:
        return Icons.info;
      case AppropriatenessLevel.needsWork:
        return Icons.warning;
    }
  }

  /// Get brief status message
  String getStatusMessage() {
    if (confidenceScore >= 90) return 'Ready to send!';
    if (confidenceScore >= 75) return 'Looking good';
    if (confidenceScore >= 60) return 'Could be improved';
    return 'Needs revision';
  }
}

enum AppropriatenessLevel {
  excellent('excellent'),
  good('good'),
  okay('okay'),
  needsWork('needs_work');

  final String value;
  const AppropriatenessLevel(this.value);

  static AppropriatenessLevel fromString(String value) {
    return AppropriatenessLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppropriatenessLevel.okay,
    );
  }

  String get displayName {
    switch (this) {
      case AppropriatenessLevel.excellent:
        return 'Excellent';
      case AppropriatenessLevel.good:
        return 'Good';
      case AppropriatenessLevel.okay:
        return 'Okay';
      case AppropriatenessLevel.needsWork:
        return 'Needs Work';
    }
  }
}

enum RelationshipType {
  boss('boss', 'Boss/Manager'),
  colleague('colleague', 'Colleague'),
  friend('friend', 'Friend'),
  family('family', 'Family'),
  client('client', 'Client'),
  none('none', 'Not specified');

  final String value;
  final String displayName;
  const RelationshipType(this.value, this.displayName);

  static RelationshipType fromString(String? value) {
    if (value == null) return RelationshipType.none;
    return RelationshipType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RelationshipType.none,
    );
  }

  IconData get icon {
    switch (this) {
      case RelationshipType.boss:
        return Icons.business;
      case RelationshipType.colleague:
        return Icons.people;
      case RelationshipType.friend:
        return Icons.emoji_people;
      case RelationshipType.family:
        return Icons.family_restroom;
      case RelationshipType.client:
        return Icons.handshake;
      case RelationshipType.none:
        return Icons.help_outline;
    }
  }
}

