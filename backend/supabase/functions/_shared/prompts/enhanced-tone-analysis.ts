/**
 * Enhanced Tone Analysis System for Neurodivergent Communication
 * Based on 2025 research: GoEmotions, Plutchik, neurodivergent communication studies
 */

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

export type IntensityLevel = 'very_low' | 'low' | 'medium' | 'high' | 'very_high' | 'High' | 'Medium' | 'Low' | 'Very Low';
export type UrgencyLevel = 'Low' | 'Medium' | 'High' | 'Critical' | 'critical' | 'low' | 'high' | 'medium';
export type EmotionalShift = 'escalating' | 'de-escalating' | 'stable' ;
export type NeurodivergentProfile = 'ADHD' | 'autism' | 'both' | 'social_anxiety' | 'none';

export interface ToneAnalysisResult {
  tone: string;
  intensity?: IntensityLevel;
  urgency_level: UrgencyLevel;
  intent: string;
  confidence_score: number;
  reasoning?: string;
  secondary_tones?: string[];
  emotion_blend?: EmotionCombination;
  context_flags?: ContextFlags;
  is_ambiguous?: boolean;
  alternative_interpretations?: AlternativeInterpretation[];
  response_anxiety_assessment?: ResponseAnxietyAssessment;
  figurative_language_detected?: FigurativeLanguageDetection;
}

export interface EmotionCombination {
  primary_emotion: string;
  secondary_emotion?: string;
  plutchik_blend?: string; // e.g., "love" = joy + trust
}

export interface ContextFlags {
  sarcasm_detected?: boolean;
  figurative_language?: boolean;
  tone_indicator_present?: boolean;
  ambiguous?: boolean;
  implicit_emotion?: boolean;
  emotional_shift?: EmotionalShift;
  urgency_mismatch?: boolean;
}

export interface AlternativeInterpretation {
  tone: string;
  intensity: IntensityLevel;
  probability: number;
  reasoning: string;
}

export interface ResponseAnxietyAssessment {
  risk_level: 'low' | 'medium' | 'high';
  mitigation_suggestions: string[];
}

export interface FigurativeLanguageDetection {
  has_figurative_language: boolean;
  examples: string[];
}

export interface ConversationMessage {
  message: string;
  timestamp: Date;
  tone_analysis?: ToneAnalysisResult;
  sender: 'user' | 'other';
}

export interface UserEmotionalBaseline {
  typical_tones: string[];
  average_intensity: IntensityLevel;
  neurodivergent_profile?: NeurodivergentProfile;
  preferences: string;
  baseline_indicators: string[];
}

export interface ToneDefinition {
  description: string;
  markers?: string[];
  intensity_variants?: string[];
  neurodivergent_consideration?: string;
}

// ============================================================================
// ENHANCED TONE CATEGORIES (23 TOTAL)
// ============================================================================

export const VALID_TONES = [
  'Friendly', 'Professional', 'Urgent', 'Casual', 'Formal', 'Concerned',
  'Excited', 'Neutral', 'Apologetic', 'Appreciative', 'Frustrated', 'Playful',
  'Sarcastic', 'Empathetic', 'Inquisitive', 'Assertive', 'Tentative', 'Defensive',
  'Encouraging', 'Disappointed', 'Overwhelmed', 'Relieved', 'Confused'
] as const;

export type ToneName = typeof VALID_TONES[number];

export const TONE_DEFINITIONS: Record<ToneName, ToneDefinition> = {
  Friendly: { description: "Warm, welcoming, personable" },
  Professional: { description: "Business-like, formal, respectful" },
  Urgent: { description: "Time-sensitive, pressing, immediate" },
  Casual: { description: "Relaxed, informal, conversational" },
  Formal: { description: "Structured, official, ceremonious" },
  Concerned: { description: "Worried, distressed, seeking support" },
  Excited: { description: "Enthusiastic, energetic, animated" },
  Neutral: { description: "Balanced, objective, matter-of-fact" },
  Apologetic: { description: "Expressing regret or sorry" },
  Appreciative: { description: "Showing gratitude or recognition" },
  Frustrated: { description: "Annoyed or irritated by obstacles" },
  Playful: { description: "Teasing, joking, lighthearted" },
  Sarcastic: { description: "Mocking tone with opposite meaning" },
  Empathetic: { description: "Understanding and supportive" },
  Inquisitive: { description: "Curious and seeking information" },
  Assertive: { description: "Confident and direct" },
  Tentative: { description: "Uncertain or hesitant" },
  Defensive: { description: "Protective or justifying actions" },
  Encouraging: { description: "Supportive and motivating" },
  Disappointed: { description: "Let down or dissatisfied" },
  Overwhelmed: { description: "Feeling excessive pressure or emotion" },
  Relieved: { description: "Feeling reassured or unburdened" },
  Confused: { description: "Unclear or uncertain about meaning" }
};

// ============================================================================
// TONE INDICATOR MAPPINGS
// ============================================================================

export const TONE_INDICATOR_MAP: Record<string, string> = {
  '/j': 'Playful',
  '/joking': 'Playful',
  '/srs': 'Assertive',
  '/serious': 'Assertive',
  '/s': 'Sarcastic',
  '/sarcasm': 'Sarcastic',
  '/nm': 'Neutral',
  '/notmad': 'Neutral',
  '/lh': 'Friendly',
  '/lighthearted': 'Friendly',
  '/gen': 'Inquisitive'
};

// ============================================================================
// VALIDATION FUNCTIONS
// ============================================================================

export function validateToneAnalysis(result: any): ToneAnalysisResult {
  const validIntensities: IntensityLevel[] = ['very_low', 'low', 'medium', 'high', 'very_high'];
  const validUrgencyLevels: UrgencyLevel[] = ['Low', 'Medium', 'High', 'Critical'];
  
  console.log("🔍 Validating tone analysis result...");
  console.log("Received result:", JSON.stringify(result, null, 2));
  
  // 🔧 FIXED: Normalize tone to correct capitalization (case-insensitive matching)
  let tone = result.tone;
  if (typeof tone === 'string') {
    // Try to find matching tone (case-insensitive)
    const matchedTone = VALID_TONES.find((t) => t.toLowerCase() === tone.toLowerCase());
    if (matchedTone) {
      tone = matchedTone; // Use correctly capitalized version
      console.log(`✅ Tone normalized: "${result.tone}" -> "${tone}"`);
    }
  }
  
  if (!tone || !VALID_TONES.includes(tone)) {
    console.error(`❌ Invalid tone: "${result.tone}"`);
    console.error(`Valid tones: ${VALID_TONES.join(', ')}`);
    throw new Error(`Invalid tone: ${result.tone}. Valid tones: ${VALID_TONES.join(', ')}`);
  }
  
  if (!result.urgency_level || !validUrgencyLevels.includes(result.urgency_level)) {
    console.error(`❌ Invalid urgency level: "${result.urgency_level}"`);
    console.error(`Valid urgency levels: ${validUrgencyLevels.join(', ')}`);
    throw new Error(`Invalid urgency level: ${result.urgency_level}.`);
  }
  if (!result.intent || typeof result.intent !== 'string') {
    console.error("❌ Invalid intent - must be non-empty string");
    throw new Error('Intent must be a non-empty string.');
  }
  if (
    typeof result.confidence_score !== 'number' ||
    result.confidence_score < 0 ||
    result.confidence_score > 1
  ) {
    console.error(`❌ Invalid confidence score: ${result.confidence_score}`);
    throw new Error('Confidence score must be a number between 0 and 1.');
  }
  if (result.intensity !== undefined && !validIntensities.includes(result.intensity)) {
    console.error(`❌ Invalid intensity: "${result.intensity}"`);
    console.error(`Valid intensities: ${validIntensities.join(', ')}`);
    throw new Error(`Invalid intensity: ${result.intensity}`);
  }
  
  // 🔧 FIXED: Normalize secondary tones too
  let secondaryTones = result.secondary_tones;
  if (result.secondary_tones) {
    if (!Array.isArray(result.secondary_tones)) {
      console.error("❌ Secondary tones must be an array");
      throw new Error('secondary_tones must be an array');
    }
    secondaryTones = result.secondary_tones.map((secondaryTone: string) => {
      const matchedTone = VALID_TONES.find((t) => t.toLowerCase() === secondaryTone.toLowerCase());
      return matchedTone || secondaryTone;
    });
    
    for (const secondaryTone of secondaryTones) {
      if (!VALID_TONES.includes(secondaryTone)) {
        console.error(`❌ Invalid secondary tone: "${secondaryTone}"`);
        throw new Error(`Invalid secondary tone: ${secondaryTone}`);
      }
    }
  }
  
  console.log("✅ Validation passed!");
  return {
    ...result,
    tone, // Use normalized tone
    secondary_tones: secondaryTones, // Use normalized secondary tones
  };
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Extracts explicit tone indicators (e.g., /j, /s) from a message
export function extractToneIndicators(message: string): string[] {
  const toneIndicatorRegex = /\/([a-zA-Z]+)/g;
  const matches = message.match(toneIndicatorRegex) || [];
  return matches;
}

// Detects known figurative language idioms
export function detectFigurativeLanguage(message: string): { has_figurative_language: boolean, examples: string[] } {
  const idioms = ['break the ice', 'piece of cake', 'under the weather', 'spill the beans'];
  const detected: string[] = [];
  for (const idiom of idioms) {
    if (message.toLowerCase().includes(idiom)) {
      detected.push(`Idiom: "${idiom}"`);
    }
  }
  return { has_figurative_language: detected.length > 0, examples: detected };
}

// Assesses anxiety risk for neurodivergent users based on tone analysis
export function assessResponseAnxietyRisk(
  analysis: ToneAnalysisResult
): { risk_level: 'low' | 'medium' | 'high'; mitigation_suggestions: string[] } {
  let risk_level: 'low' | 'medium' | 'high' = 'low';
  const suggestions: string[] = [];
  if (analysis.urgency_level === 'High' || analysis.urgency_level === 'Critical') {
    risk_level = 'high';
    suggestions.push('Urgent tone detected. Consider asking for a specific timeline.');
  }
  if (analysis.context_flags?.sarcasm_detected) {
    risk_level = 'medium';
    suggestions.push('Sarcasm detected. Literal meaning may differ.');
  }
  return { risk_level, mitigation_suggestions: suggestions };
}

// Basic prompt generation, context optional
export function generateAnalysisPrompt(messageBody: string, conversationContext?: string[]): string {
  let prompt = `Analyze the following message:\n\n"${messageBody}"\n\n`;
  if (conversationContext && conversationContext.length > 0) {
    prompt += `**Conversation Context** (recent messages for context):\n`;
    conversationContext.forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
    prompt += '\n';
  }
  prompt += `Provide your analysis in JSON format as specified.`;
  return prompt;
}

// ============================================================================
// ENHANCED SYSTEM PROMPT
// ============================================================================

/**
 * Enhanced system prompt with 23 tones and neurodivergent support
 */
export const ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT = `You are an expert communication analyst specializing in understanding tone, intent, and urgency in messages, with specific expertise in neurodivergent communication patterns.

**CRITICAL: RESPONSE FORMAT REQUIREMENTS**

You MUST respond with ONLY valid JSON (no markdown, no extra text). The response must be exactly:

{
  "tone": "one of 23 valid categories ONLY",
  "urgency_level": "one of exactly: Low, Medium, High, Critical",
  "intent": "3-8 word description of what sender is trying to accomplish",
  "confidence_score": 0.85,
  "intensity": "one of: very_low, low, medium, high, very_high",
  "secondary_tones": ["optional", "array", "of", "valid", "tones"],
  "context_flags": {
    "sarcasm_detected": false,
    "tone_indicator_present": false,
    "ambiguous": false
  },
  "reasoning": "Explanation citing specific phrases and context"
}

**VALID TONE CATEGORIES (Choose ONE primary tone):**

Friendly, Professional, Urgent, Casual, Formal, Concerned, Excited, Neutral, Apologetic, Appreciative, Frustrated, Playful, Sarcastic, Empathetic, Inquisitive, Assertive, Tentative, Defensive, Encouraging, Disappointed, Overwhelmed, Relieved, Confused

**VALID URGENCY LEVELS (Choose ONE - exact capitalization required):**
- Low (no time pressure)
- Medium (should be addressed soon)
- High (important and time-sensitive)  
- Critical (extremely urgent, immediate action needed)

**VALID INTENSITY LEVELS (Choose ONE - lowercase required):**
- very_low (minimal expression)
- low (mild expression)
- medium (moderate expression)
- high (strong expression)
- very_high (extreme expression)

**CRITICAL PRIORITY: Neurodivergent Communication Considerations**

1. **Tone Indicator Detection** (HIGHEST PRIORITY):
   - If message contains /tone tags (e.g., "/j", "/srs", "/nm"), ALWAYS respect and cite them
   - These are explicit intent markers used by neurodivergent communities

2. **When in doubt**:
   - Default to lower intensity/urgency if message is ambiguous
   - Mark "ambiguous": true if meaning is unclear
   - Provide reassurance in reasoning if no clear negative indicators

3. **Response Quality Checks**:
   - tone: MUST match exactly one from the 23 categories above
   - urgency_level: MUST be exactly one of: Low, Medium, High, Critical
   - confidence_score: MUST be a number between 0 and 1
   - intensity: MUST be one of: very_low, low, medium, high, very_high
   - DO NOT use alternative spellings or capitalization
   - DO NOT include markdown code blocks
   - DO NOT add any text outside the JSON`;

// ============================================================================
// RSD & ALTERNATIVE INTERPRETATIONS (Feature 1 Enhancement)
// ============================================================================

import { 
  detectRSDTriggers, 
  generateRSDPromptAddition,
  type RSDTrigger 
} from './rsd-detection.ts';

import {
  shouldGenerateAlternatives,
  ALTERNATIVE_INTERPRETATIONS_PROMPT,
  type MessageInterpretation
} from './alternative-interpretations.ts';

import {
  EVIDENCE_EXTRACTION_PROMPT,
  formatEvidence,
  type Evidence
} from './evidence-extractor.ts';

// Extended result type with RSD/alternatives/evidence
export interface EnhancedToneAnalysisResult extends ToneAnalysisResult {
  rsd_triggers?: RSDTrigger[];
  message_interpretations?: MessageInterpretation[];
  evidence?: Evidence[];
}

// Enhanced system prompt that includes RSD detection
export const SMART_MESSAGE_INTERPRETER_PROMPT = `
${ENHANCED_TONE_ANALYSIS_SYSTEM_PROMPT}

${ALTERNATIVE_INTERPRETATIONS_PROMPT}

${EVIDENCE_EXTRACTION_PROMPT}

**NEURODIVERGENT-SPECIFIC ENHANCEMENTS:**

1. **RSD (Rejection Sensitive Dysphoria) Awareness:**
   - If analyzing short/ambiguous messages, explicitly address RSD concerns
   - Provide reassurance when messages are likely benign
   - Highlight lack of negative evidence when appropriate

2. **Literal Language Support:**
   - Explain idioms, metaphors, sarcasm literally
   - Flag when meaning differs from literal words
   - Provide "what they probably mean" translation

3. **Multiple Interpretations:**
   - For ambiguous messages, provide 2-3 interpretations
   - Rank by likelihood
   - Explain what context clues support each

4. **Evidence-Based:**
   - Always cite specific evidence
   - If no evidence exists, say so
   - Don't infer meaning without textual support

**Response Format:**
{
  "tone": "one of 23 categories",
  "intensity": "one of 5 levels",
  "urgency_level": "one of 4 levels",
  "intent": "3-8 word description",
  "confidence_score": 0.85,
  "context_flags": {...},
  "reasoning": "explanation",
  "rsd_triggers": [...], // If any detected
  "message_interpretations": [...], // If ambiguous
  "evidence": [...] // Always include
}
`;

// Enhanced prompt generator
export function generateSmartInterpretationPrompt(
  messageBody: string,
  conversationContext?: string[]
): string {
  // Detect RSD triggers
  const rsdTriggers = detectRSDTriggers(messageBody);
  const rsdAddition = generateRSDPromptAddition(rsdTriggers);

  let prompt = `Analyze the following message with RSD awareness:\n\n`;
  prompt += `**Message:** "${messageBody}"\n\n`;
  
  if (rsdAddition) {
    prompt += rsdAddition + '\n\n';
  }
  
  if (conversationContext && conversationContext.length > 0) {
    prompt += `**Conversation Context:**\n`;
    conversationContext.forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
    prompt += '\n';
  }
  
  prompt += `Provide comprehensive analysis including tone, RSD considerations, alternative interpretations (if ambiguous), and specific evidence.`;
  
  return prompt;
}

// Validation for enhanced result
export function validateEnhancedToneAnalysis(result: any): EnhancedToneAnalysisResult {
  // First validate base tone analysis
  const baseValidation = validateToneAnalysis(result);
  
  // Return with additional fields
  return {
    ...baseValidation,
    rsd_triggers: result.rsd_triggers || [],
    message_interpretations: result.message_interpretations || [],
    evidence: result.evidence || [],
  };
}

// ============================================================================
// EXPORT DEFAULTS
// ============================================================================

export default {
  VALID_TONES,
  TONE_DEFINITIONS,
  TONE_INDICATOR_MAP,
  validateToneAnalysis,
  extractToneIndicators,
  detectFigurativeLanguage,
  assessResponseAnxietyRisk,
  generateAnalysisPrompt,
  // Enhanced exports
  generateSmartInterpretationPrompt,
  validateEnhancedToneAnalysis,
};
