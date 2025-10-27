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
  
  // ✅ FEATURES 1-3: Smart Message Interpreter fields
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
    // ✅ FEATURES 1-3
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
      
      // Helper function to safely parse numbers
      num? parseNum(dynamic value) {
        if (value == null) return null;
        if (value is num) return value;
        if (value is String) return num.tryParse(value);
        return null;
      }
      
      // 🔧 Helper to parse JSONB arrays from Supabase
      List<String>? parseJsonbArray(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          // Already a list
          return value.map((e) => e.toString()).toList();
        }
        // If it's not a list, return null (shouldn't happen with our JSONB setup)
        return null;
      }
      
      return AIAnalysis(
        id: id,
        messageId: messageId,
        tone: tone,
        urgencyLevel: json['urgency_level'] as String?,
        intent: json['intent'] as String?,
        confidenceScore: parseNum(json['confidence_score'])?.toDouble(),
        analysisTimestamp: parseNum(json['analysis_timestamp'])?.toInt() ?? 
                           DateTime.now().millisecondsSinceEpoch ~/ 1000,
        // ✅ FEATURES 1-3: Parse RSD, interpretations, evidence (with error handling)
        rsdTriggers: (json['rsd_triggers'] as List<dynamic>?)
            ?.map((e) {
              try {
                return RSDTrigger.fromJson(e as Map<String, dynamic>);
              } catch (err) {
                print('⚠️ Failed to parse RSD trigger: $err');
                return null;
              }
            })
            .whereType<RSDTrigger>()
            .toList(),
        alternativeInterpretations: (json['alternative_interpretations'] as List<dynamic>?)
            ?.map((e) {
              try {
                return MessageInterpretation.fromJson(e as Map<String, dynamic>);
              } catch (err) {
                print('⚠️ Failed to parse interpretation: $err');
                return null;
              }
            })
            .whereType<MessageInterpretation>()
            .toList(),
        evidence: (json['evidence'] as List<dynamic>?)
            ?.map((e) {
              try {
                return Evidence.fromJson(e);
              } catch (err) {
                print('⚠️ Failed to parse evidence: $err');
                return null;
              }
            })
            .whereType<Evidence>()
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
      // ✅ FEATURES 1-3 fields
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
           'urgency: $urgencyLevel, intent: $intent, confidence: $confidenceScore)';
  }
}

// ============================================================================
// PHASE 1: Smart Message Interpreter - Helper Classes
// ============================================================================

// (BoundaryAnalysis removed - use BoundaryViolation directly from backend)

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
      pattern: (json['pattern'] ?? json['trigger']) as String,
      severity: json['severity'] as String,
      explanation: json['explanation'] as String,
      reassurance: (json['reassurance'] ?? 'This is a common concern and doesn\'t reflect your worth.') as String,
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
    // Handle both 'likelihood' as string or int
    int parsedLikelihood;
    final likelihoodValue = json['likelihood'];
    if (likelihoodValue is int) {
      parsedLikelihood = likelihoodValue;
    } else if (likelihoodValue is String) {
      // Map text likelihood to percentage
      switch (likelihoodValue.toLowerCase()) {
        case 'high':
          parsedLikelihood = 80;
          break;
        case 'medium':
          parsedLikelihood = 50;
          break;
        case 'low':
          parsedLikelihood = 20;
          break;
        default:
          parsedLikelihood = 50;
      }
    } else {
      parsedLikelihood = 50;
    }
    
    return MessageInterpretation(
      interpretation: json['interpretation'] as String,
      tone: (json['tone'] ?? 'neutral') as String,
      likelihood: parsedLikelihood,
      reasoning: (json['reasoning'] ?? json['explanation'] ?? '') as String,
      contextClues: (json['context_clues'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
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

  factory Evidence.fromJson(dynamic json) {
    // Handle evidence as either object or simple string
    if (json is String) {
      return Evidence(
        type: 'keyword',
        quote: json,
        supports: 'tone',
        reasoning: 'Key phrase in message',
      );
    }
    
    final jsonMap = json as Map<String, dynamic>;
    return Evidence(
      type: (jsonMap['type'] ?? 'keyword') as String,
      quote: (jsonMap['quote'] ?? jsonMap.toString()) as String,
      supports: (jsonMap['supports'] ?? 'tone') as String,
      reasoning: (jsonMap['reasoning'] ?? '') as String,
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

