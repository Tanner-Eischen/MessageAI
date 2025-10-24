/// Result of message interpretation (Phase 1: Smart Message Interpreter)
class MessageInterpretation {
  final String originalMessage;
  final String literalMeaning;
  final List<String> alternativeInterpretations;
  final List<String> rsdTriggers;
  final List<String> evidencePoints;
  final String recommendedResponse;

  MessageInterpretation({
    required this.originalMessage,
    required this.literalMeaning,
    required this.alternativeInterpretations,
    required this.rsdTriggers,
    required this.evidencePoints,
    required this.recommendedResponse,
  });

  factory MessageInterpretation.fromJson(Map<String, dynamic> json) {
    return MessageInterpretation(
      originalMessage: json['original_message'] as String? ?? '',
      literalMeaning: json['literal_meaning'] as String,
      alternativeInterpretations:
          (json['alternative_interpretations'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      rsdTriggers: (json['rsd_triggers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      evidencePoints: (json['evidence_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendedResponse: json['recommended_response'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_message': originalMessage,
      'literal_meaning': literalMeaning,
      'alternative_interpretations': alternativeInterpretations,
      'rsd_triggers': rsdTriggers,
      'evidence_points': evidencePoints,
      'recommended_response': recommendedResponse,
    };
  }

  bool get hasRsdTriggers => rsdTriggers.isNotEmpty;
  bool get hasAlternatives => alternativeInterpretations.isNotEmpty;
  bool get hasEvidence => evidencePoints.isNotEmpty;

  @override
  String toString() {
    return 'MessageInterpretation(literal: $literalMeaning, alternatives: ${alternativeInterpretations.length}, rsdTriggers: ${rsdTriggers.length})';
  }
}

