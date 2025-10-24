import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  validateToneAnalysis,
  extractToneIndicators,
  detectFigurativeLanguage,
  assessResponseAnxietyRisk,
  generateAnalysisPrompt,
  VALID_TONES,
  type ToneAnalysisResult,
} from "../enhanced-tone-analysis.ts";

// ============================================================================
// UNIT TESTS: Tone Indicator Extraction
// ============================================================================

Deno.test("extractToneIndicators - detects single tone indicator", () => {
  const message = "I'm just joking /j";
  const indicators = extractToneIndicators(message);
  assertEquals(indicators.length, 1);
  assertEquals(indicators[0], "/j");
});

Deno.test("extractToneIndicators - detects multiple tone indicators", () => {
  const message = "I'm serious about this /srs and not mad /nm";
  const indicators = extractToneIndicators(message);
  assertEquals(indicators.length, 2);
  assertEquals(indicators, ["/srs", "/nm"]);
});

Deno.test("extractToneIndicators - handles message with no indicators", () => {
  const message = "This is a normal message";
  const indicators = extractToneIndicators(message);
  assertEquals(indicators.length, 0);
});

Deno.test("extractToneIndicators - detects sarcasm indicator", () => {
  const message = "Oh great, another meeting /s";
  const indicators = extractToneIndicators(message);
  assertEquals(indicators, ["/s"]);
});

// ============================================================================
// UNIT TESTS: Figurative Language Detection
// ============================================================================

Deno.test("detectFigurativeLanguage - detects common idiom", () => {
  const message = "Let's break the ice with introductions";
  const result = detectFigurativeLanguage(message);
  assertEquals(result.has_figurative_language, true);
  assertEquals(result.examples.length, 1);
  assertEquals(result.examples[0], 'Idiom: "break the ice"');
});

Deno.test("detectFigurativeLanguage - detects multiple idioms", () => {
  const message = "This project is a piece of cake, I'm not under the weather";
  const result = detectFigurativeLanguage(message);
  assertEquals(result.has_figurative_language, true);
  assertEquals(result.examples.length, 2);
});

Deno.test("detectFigurativeLanguage - handles message with no idioms", () => {
  const message = "I will complete the task today";
  const result = detectFigurativeLanguage(message);
  assertEquals(result.has_figurative_language, false);
  assertEquals(result.examples.length, 0);
});

// ============================================================================
// UNIT TESTS: Validation
// ============================================================================

Deno.test("validateToneAnalysis - accepts valid result", () => {
  const validResult = {
    tone: "Friendly",
    intensity: "medium",
    urgency_level: "Low",
    intent: "greeting and checking in",
    confidence_score: 0.85,
    context_flags: {
      sarcasm_detected: false,
      tone_indicator_present: false,
    },
  };

  const validated = validateToneAnalysis(validResult);
  assertEquals(validated.tone, "Friendly");
  assertEquals(validated.intensity, "medium");
  assertEquals(validated.urgency_level, "Low");
});

Deno.test("validateToneAnalysis - accepts all 23 valid tones", () => {
  const testTones = [
    "Friendly", "Professional", "Urgent", "Casual", "Formal", "Concerned",
    "Excited", "Neutral", "Apologetic", "Appreciative", "Frustrated", "Playful",
    "Sarcastic", "Empathetic", "Inquisitive", "Assertive", "Tentative", "Defensive",
    "Encouraging", "Disappointed", "Overwhelmed", "Relieved", "Confused"
  ];

  testTones.forEach(tone => {
    const result = {
      tone,
      urgency_level: "Low",
      intent: "test intent",
      confidence_score: 0.8,
    };
    const validated = validateToneAnalysis(result);
    assertEquals(validated.tone, tone);
  });
});

Deno.test("validateToneAnalysis - rejects invalid tone", () => {
  const invalidResult = {
    tone: "InvalidTone",
    urgency_level: "Low",
    intent: "test",
    confidence_score: 0.8,
  };

  let errorThrown = false;
  try {
    validateToneAnalysis(invalidResult);
  } catch (e) {
    errorThrown = true;
    assertEquals(e.message.includes("Invalid tone"), true);
  }
  assertEquals(errorThrown, true);
});

Deno.test("validateToneAnalysis - rejects invalid intensity", () => {
  const invalidResult = {
    tone: "Friendly",
    intensity: "super_high",
    urgency_level: "Low",
    intent: "test",
    confidence_score: 0.8,
  };

  let errorThrown = false;
  try {
    validateToneAnalysis(invalidResult);
  } catch (e) {
    errorThrown = true;
    assertEquals(e.message.includes("Invalid intensity"), true);
  }
  assertEquals(errorThrown, true);
});

Deno.test("validateToneAnalysis - rejects invalid urgency", () => {
  const invalidResult = {
    tone: "Friendly",
    urgency_level: "SuperUrgent",
    intent: "test",
    confidence_score: 0.8,
  };

  let errorThrown = false;
  try {
    validateToneAnalysis(invalidResult);
  } catch (e) {
    errorThrown = true;
    assertEquals(e.message.includes("Invalid urgency level"), true);
  }
  assertEquals(errorThrown, true);
});

Deno.test("validateToneAnalysis - rejects invalid confidence score", () => {
  const invalidResult = {
    tone: "Friendly",
    urgency_level: "Low",
    intent: "test",
    confidence_score: 1.5, // > 1
  };

  let errorThrown = false;
  try {
    validateToneAnalysis(invalidResult);
  } catch (e) {
    errorThrown = true;
    assertEquals(e.message.includes("Confidence score"), true);
  }
  assertEquals(errorThrown, true);
});

// ============================================================================
// UNIT TESTS: Anxiety Assessment
// ============================================================================

Deno.test("assessResponseAnxietyRisk - high urgency triggers high risk", () => {
  const analysis: ToneAnalysisResult = {
    tone: "Urgent",
    urgency_level: "Critical",
    intent: "needs immediate response",
    confidence_score: 0.9,
  };

  const assessment = assessResponseAnxietyRisk(analysis);
  assertEquals(assessment.risk_level, "high");
  assertEquals(assessment.mitigation_suggestions.length > 0, true);
});

Deno.test("assessResponseAnxietyRisk - sarcasm triggers medium risk", () => {
  const analysis: ToneAnalysisResult = {
    tone: "Sarcastic",
    urgency_level: "Low",
    intent: "making a joke",
    confidence_score: 0.85,
    context_flags: {
      sarcasm_detected: true,
    },
  };

  const assessment = assessResponseAnxietyRisk(analysis);
  assertEquals(assessment.risk_level, "medium");
  assertEquals(assessment.mitigation_suggestions.length > 0, true);
});

Deno.test("assessResponseAnxietyRisk - friendly message is low risk", () => {
  const analysis: ToneAnalysisResult = {
    tone: "Friendly",
    urgency_level: "Low",
    intent: "casual greeting",
    confidence_score: 0.9,
  };

  const assessment = assessResponseAnxietyRisk(analysis);
  assertEquals(assessment.risk_level, "low");
});

// ============================================================================
// UNIT TESTS: Prompt Generation
// ============================================================================

Deno.test("generateAnalysisPrompt - creates prompt without context", () => {
  const message = "Hello, how are you?";
  const prompt = generateAnalysisPrompt(message);
  
  assertEquals(prompt.includes(message), true);
  assertEquals(prompt.includes("Analyze the following message"), true);
});

Deno.test("generateAnalysisPrompt - includes conversation context", () => {
  const message = "That sounds great!";
  const context = ["Want to get coffee?", "I'm free at 3pm"];
  const prompt = generateAnalysisPrompt(message, context);
  
  assertEquals(prompt.includes(message), true);
  assertEquals(prompt.includes("Conversation Context"), true);
  assertEquals(prompt.includes("Want to get coffee?"), true);
  assertEquals(prompt.includes("I'm free at 3pm"), true);
});

// ============================================================================
// INTEGRATION TESTS: Full Analysis Flow
// ============================================================================

Deno.test("INTEGRATION - analyze playful message with tone indicator", () => {
  const message = "Oh sure, that's a great idea /j";
  
  // Extract indicators
  const indicators = extractToneIndicators(message);
  assertEquals(indicators, ["/j"]);
  
  // Check figurative language
  const figurative = detectFigurativeLanguage(message);
  assertEquals(figurative.has_figurative_language, false);
  
  // Validate mock analysis result
  const mockResult = {
    tone: "Playful",
    intensity: "medium",
    urgency_level: "Low",
    intent: "joking about suggestion",
    confidence_score: 0.92,
    context_flags: {
      tone_indicator_present: true,
      sarcasm_detected: false,
    },
  };
  
  const validated = validateToneAnalysis(mockResult);
  assertEquals(validated.tone, "Playful");
  assertEquals(validated.context_flags?.tone_indicator_present, true);
  
  // Assess anxiety
  const anxiety = assessResponseAnxietyRisk(validated);
  assertEquals(anxiety.risk_level, "low");
});

Deno.test("INTEGRATION - analyze overwhelmed message", () => {
  const message = "I'm SO stressed about this deadline /srs";
  
  // Extract indicators
  const indicators = extractToneIndicators(message);
  assertEquals(indicators, ["/srs"]);
  
  // Validate mock analysis
  const mockResult = {
    tone: "Overwhelmed",
    intensity: "very_high",
    urgency_level: "High",
    intent: "expressing severe stress",
    confidence_score: 0.95,
    context_flags: {
      tone_indicator_present: true,
    },
  };
  
  const validated = validateToneAnalysis(mockResult);
  assertEquals(validated.tone, "Overwhelmed");
  assertEquals(validated.intensity, "very_high");
  
  // High urgency should trigger anxiety warning
  const anxiety = assessResponseAnxietyRisk(validated);
  assertEquals(anxiety.risk_level, "high");
});

console.log("✅ All enhanced tone analysis tests passed!");

