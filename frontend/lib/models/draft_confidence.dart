/// Result of draft confidence analysis (Phase 2: Response Assistant)
class DraftConfidence {
  final String draft;
  final int overallScore;
  final Map<String, int> scores;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final bool readyToSend;

  DraftConfidence({
    required this.draft,
    required this.overallScore,
    required this.scores,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
    required this.readyToSend,
  });

  factory DraftConfidence.fromJson(Map<String, dynamic> json) {
    return DraftConfidence(
      draft: json['draft'] as String? ?? '',
      overallScore: json['overall_score'] as int? ?? 0,
      scores: (json['scores'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      readyToSend: json['ready_to_send'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draft': draft,
      'overall_score': overallScore,
      'scores': scores,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'suggestions': suggestions,
      'ready_to_send': readyToSend,
    };
  }

  /// Get confidence level as a string
  String get confidenceLevel {
    if (overallScore >= 80) return 'High';
    if (overallScore >= 60) return 'Medium';
    return 'Low';
  }

  /// Get color for confidence level
  String get confidenceColor {
    if (overallScore >= 80) return 'green';
    if (overallScore >= 60) return 'orange';
    return 'red';
  }

  bool get hasStrengths => strengths.isNotEmpty;
  bool get hasWeaknesses => weaknesses.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;

  @override
  String toString() {
    return 'DraftConfidence(score: $overallScore%, level: $confidenceLevel, ready: $readyToSend)';
  }
}

