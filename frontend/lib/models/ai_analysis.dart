/// Simple AI Analysis model - no Drift dependency
/// Fetched directly from Supabase with in-memory session caching
class AIAnalysis {
  final String id;
  final String messageId;
  final String tone;
  final String? urgencyLevel;
  final String? intent;
  final double? confidenceScore;
  final int analysisTimestamp;
  
  // ✅ NEW ENHANCED FIELDS
  final String? intensity;
  final List<String>? secondaryTones;
  final Map<String, dynamic>? contextFlags;
  final Map<String, dynamic>? anxietyAssessment;
  
  // ✅ PHASE 1: Smart Message Interpreter fields
  final List<RSDTrigger>? rsdTriggers;
  final List<MessageInterpretation>? alternativeInterpretations;
  final List<Evidence>? evidence;
  
  const AIAnalysis({
    required this.id,
    required this.messageId,
    required this.tone,
    this.urgencyLevel,
    this.intent,
    this.confidenceScore,
    required this.analysisTimestamp,
    // ✅ NEW
    this.intensity,
    this.secondaryTones,
    this.contextFlags,
    this.anxietyAssessment,
    // ✅ PHASE 1
    this.rsdTriggers,
    this.alternativeInterpretations,
    this.evidence,
  });
  
  /// Create from Supabase JSON response
  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both direct table columns and RPC function results
      final id = json['id'] as String? ?? json['analysis_id'] as String?;
      final messageId = json['message_id'] as String?;
      final tone = json['tone'] as String?;
      
      if (id == null || messageId == null || tone == null) {
        throw FormatException(
          'Missing required fields in AI analysis JSON: '
          'id=$id, message_id=$messageId, tone=$tone. '
          'Full JSON: $json'
        );
      }
      
      return AIAnalysis(
        id: id,
        messageId: messageId,
        tone: tone,
        urgencyLevel: json['urgency_level'] as String?,
        intent: json['intent'] as String?,
        confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
        analysisTimestamp: (json['analysis_timestamp'] as num?)?.toInt() ?? 
                           DateTime.now().millisecondsSinceEpoch ~/ 1000,
        // ✅ Parse new fields
        intensity: json['intensity'] as String?,
        secondaryTones: (json['secondary_tones'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        contextFlags: json['context_flags'] as Map<String, dynamic>?,
        anxietyAssessment: json['anxiety_assessment'] as Map<String, dynamic>?,
        // ✅ PHASE 1: Parse RSD, interpretations, evidence
        rsdTriggers: (json['rsd_triggers'] as List<dynamic>?)
            ?.map((e) => RSDTrigger.fromJson(e as Map<String, dynamic>))
            .toList(),
        alternativeInterpretations: (json['alternative_interpretations'] as List<dynamic>?)
            ?.map((e) => MessageInterpretation.fromJson(e as Map<String, dynamic>))
            .toList(),
        evidence: (json['evidence'] as List<dynamic>?)
            ?.map((e) => Evidence.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw FormatException('Failed to parse AIAnalysis from JSON: $e\nJSON: $json');
    }
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'tone': tone,
      'urgency_level': urgencyLevel,
      'intent': intent,
      'confidence_score': confidenceScore,
      'analysis_timestamp': analysisTimestamp,
      // ✅ Include new fields
      if (intensity != null) 'intensity': intensity,
      if (secondaryTones != null) 'secondary_tones': secondaryTones,
      if (contextFlags != null) 'context_flags': contextFlags,
      if (anxietyAssessment != null) 'anxiety_assessment': anxietyAssessment,
      // ✅ PHASE 1 fields
      if (rsdTriggers != null) 'rsd_triggers': rsdTriggers!.map((e) => e.toJson()).toList(),
      if (alternativeInterpretations != null) 'alternative_interpretations': 
          alternativeInterpretations!.map((e) => e.toJson()).toList(),
      if (evidence != null) 'evidence': evidence!.map((e) => e.toJson()).toList(),
    };
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIAnalysis &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          messageId == other.messageId;
  
  @override
  int get hashCode => id.hashCode ^ messageId.hashCode;
  
  @override
  String toString() {
    return 'AIAnalysis(id: $id, messageId: $messageId, tone: $tone, '
           'urgency: $urgencyLevel, intensity: $intensity, intent: $intent, confidence: $confidenceScore)';
  }
}

// ============================================================================
// PHASE 1: Smart Message Interpreter - Helper Classes
// ============================================================================

/// RSD Trigger model
class RSDTrigger {
  final String pattern;
  final String severity; // high, medium, low
  final String explanation;
  final String reassurance;

  const RSDTrigger({
    required this.pattern,
    required this.severity,
    required this.explanation,
    required this.reassurance,
  });

  factory RSDTrigger.fromJson(Map<String, dynamic> json) {
    return RSDTrigger(
      pattern: json['pattern'] as String,
      severity: json['severity'] as String,
      explanation: json['explanation'] as String,
      reassurance: json['reassurance'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'severity': severity,
      'explanation': explanation,
      'reassurance': reassurance,
    };
  }

  bool get isHighSeverity => severity == 'high';
  bool get isMediumSeverity => severity == 'medium';
  bool get isLowSeverity => severity == 'low';
}

/// Alternative Interpretation model
class MessageInterpretation {
  final String interpretation;
  final String tone;
  final int likelihood; // 0-100
  final String reasoning;
  final List<String> contextClues;

  const MessageInterpretation({
    required this.interpretation,
    required this.tone,
    required this.likelihood,
    required this.reasoning,
    required this.contextClues,
  });

  factory MessageInterpretation.fromJson(Map<String, dynamic> json) {
    return MessageInterpretation(
      interpretation: json['interpretation'] as String,
      tone: json['tone'] as String,
      likelihood: json['likelihood'] as int,
      reasoning: json['reasoning'] as String,
      contextClues: (json['context_clues'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interpretation': interpretation,
      'tone': tone,
      'likelihood': likelihood,
      'reasoning': reasoning,
      'context_clues': contextClues,
    };
  }

  bool get isLikely => likelihood >= 60;
  bool get isPossible => likelihood >= 30 && likelihood < 60;
  bool get isUnlikely => likelihood < 30;
}

/// Evidence model
class Evidence {
  final String type; // keyword, punctuation, emoji, etc.
  final String quote;
  final String supports;
  final String reasoning;

  const Evidence({
    required this.type,
    required this.quote,
    required this.supports,
    required this.reasoning,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      type: json['type'] as String,
      quote: json['quote'] as String,
      supports: json['supports'] as String,
      reasoning: json['reasoning'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'quote': quote,
      'supports': supports,
      'reasoning': reasoning,
    };
  }

  bool get isKeywordEvidence => type == 'keyword';
  bool get isPunctuationEvidence => type == 'punctuation';
  bool get isEmojiEvidence => type == 'emoji';
}

