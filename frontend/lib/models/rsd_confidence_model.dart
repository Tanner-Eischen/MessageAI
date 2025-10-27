
/// Tracks confidence data for RSD trigger patterns based on historical observations
class RSDConfidenceData {
  final String senderId;
  final String triggerPattern;  // e.g., "short_message", "delayed_response"
  final int occurrences;        // How many times we've seen this pattern
  final double baselineTriggerProbability;  // 0.0-1.0 (from base RSD patterns)
  final DateTime lastObserved;
  final List<DateTime> historicalInstances;
  
  const RSDConfidenceData({
    required this.senderId,
    required this.triggerPattern,
    required this.occurrences,
    required this.baselineTriggerProbability,
    required this.lastObserved,
    required this.historicalInstances,
  });

  /// Create from Supabase JSON response
  factory RSDConfidenceData.fromJson(Map<String, dynamic> json) {
    return RSDConfidenceData(
      senderId: json['sender_id'] as String,
      triggerPattern: json['trigger_pattern'] as String,
      occurrences: json['occurrences'] as int? ?? 0,
      baselineTriggerProbability: json['baseline_trigger_probability'] as double? ?? 0.5,
      lastObserved: json['last_observed'] != null
          ? DateTime.parse(json['last_observed'] as String)
          : DateTime.now(),
      historicalInstances: (json['historical_instances'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'sender_id': senderId,
    'trigger_pattern': triggerPattern,
    'occurrences': occurrences,
    'baseline_trigger_probability': baselineTriggerProbability,
    'last_observed': lastObserved.toIso8601String(),
    'historical_instances': historicalInstances.map((d) => d.toIso8601String()).toList(),
  };

  /// Calculate adjusted confidence based on occurrences
  /// More occurrences = higher confidence in the pattern
  double getAdjustedConfidence() {
    final occurrenceFactor = (occurrences / 10).clamp(0.0, 1.0); // Cap at 10 observations
    return (baselineTriggerProbability * 0.5) + (occurrenceFactor * 0.5);
  }
}

/// Confidence score for a specific interpretation with evidence
class ConfidenceScore {
  final String interpretation;
  final double confidencePercent;  // 0.0-100.0
  final String reasoning;          // Why we think this is the most likely interpretation
  final List<String> evidenceItems; // Supporting evidence from the message
  final bool isRecommended;        // Should this be shown as primary suggestion?
  
  const ConfidenceScore({
    required this.interpretation,
    required this.confidencePercent,
    required this.reasoning,
    required this.evidenceItems,
    this.isRecommended = false,
  });

  /// Create from Supabase JSON response
  factory ConfidenceScore.fromJson(Map<String, dynamic> json) {
    return ConfidenceScore(
      interpretation: json['interpretation'] as String,
      confidencePercent: json['confidence_percent'] as double? ?? 50.0,
      reasoning: json['reasoning'] as String? ?? '',
      evidenceItems: (json['evidence_items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isRecommended: json['is_recommended'] as bool? ?? false,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'interpretation': interpretation,
    'confidence_percent': confidencePercent,
    'reasoning': reasoning,
    'evidence_items': evidenceItems,
    'is_recommended': isRecommended,
  };

  /// Get human-readable confidence label
  String getConfidenceLabel() {
    if (confidencePercent >= 75) return 'Very Confident';
    if (confidencePercent >= 60) return 'Likely';
    if (confidencePercent >= 40) return 'Possible';
    return 'Uncertain';
  }
}
