/**
 * RSD-Focused Message Analysis System
 * Prioritizes Rejection Sensitive Dysphoria support over generic tone classification
 * 
 * Core Features:
 * 1. RSD Trigger Detection - identifies patterns that cause anxiety
 * 2. Alternative Interpretations - provides multiple meanings with confidence
 * 3. Evidence-Based Analysis - shows exact quotes and reasoning
 */

// ============================================================================
// SIMPLIFIED TONE CATEGORIES (5-7, not 23)
// ============================================================================

export type SimpleTone = 
  | 'Friendly'
  | 'Professional'
  | 'Casual'
  | 'Urgent'
  | 'Concerned'
  | 'Sarcastic'
  | 'Neutral';

export const VALID_TONES: SimpleTone[] = [
  'Friendly',
  'Professional',
  'Casual',
  'Urgent',
  'Concerned',
  'Sarcastic',
  'Neutral'
];

// ============================================================================
// RSD-FOCUSED TYPE DEFINITIONS
// ============================================================================

export type RSDSeverity = 'high' | 'medium' | 'low';

export interface RSDTrigger {
  pattern: string;                  // e.g., "k", "ok", "fine"
  severity: RSDSeverity;            // Anxiety intensity
  explanation: string;              // Why this triggers RSD
  reassurance: string;              // Supportive context
}

export interface MessageInterpretation {
  interpretation: string;           // What the message likely means
  tone: SimpleTone;                // Tone category
  likelihood: number;              // 0-100 percentage
  reasoning: string;               // Why we think this
  contextClues: string[];          // Evidence phrases
}

export interface Evidence {
  type: 'keyword' | 'punctuation' | 'emoji' | 'pattern' | 'timing';
  quote: string;                   // Exact text from message
  supports: string;                // What this supports
  reasoning: string;               // Explanation
}

export interface ToneAnalysisResult {
  tone: SimpleTone;
  urgencyLevel?: 'Low' | 'Medium' | 'High' | 'Critical';
  intent?: string;
  confidenceScore: number;         // 0-1 scale
  reasoning?: string;
}

export interface EnhancedToneAnalysisResult extends ToneAnalysisResult {
  rsdTriggers?: RSDTrigger[];
  alternativeInterpretations?: MessageInterpretation[];
  evidence?: Evidence[];
}

// ============================================================================
// VALIDATION FUNCTIONS
// ============================================================================

export function validateTone(tone: any): SimpleTone {
  if (!tone || typeof tone !== 'string') {
    throw new Error('Tone must be a non-empty string');
  }

  // Case-insensitive matching
  const normalizedTone = tone.charAt(0).toUpperCase() + tone.slice(1).toLowerCase();
  if (!VALID_TONES.includes(normalizedTone as SimpleTone)) {
    throw new Error(
      `Invalid tone: "${tone}". Valid tones: ${VALID_TONES.join(', ')}`
    );
  }

  return normalizedTone as SimpleTone;
}

export function validateToneAnalysis(result: any): ToneAnalysisResult {
  if (!result || typeof result !== 'object') {
    throw new Error('Analysis result must be an object');
  }

  return {
    tone: validateTone(result.tone),
    urgencyLevel: result.urgencyLevel,
    intent: result.intent,
    confidenceScore: typeof result.confidenceScore === 'number' 
      ? result.confidenceScore 
      : 0.8,
    reasoning: result.reasoning,
  };
}

export function validateEnhancedAnalysis(result: any): EnhancedToneAnalysisResult {
  const baseValidation = validateToneAnalysis(result);

  // Validate RSD triggers
  const rsdTriggers = (result.rsdTriggers as any[])?.map((trigger: any) => {
    if (!trigger.pattern || !trigger.severity || !trigger.explanation) {
      throw new Error('RSD trigger missing required fields');
    }
    return trigger as RSDTrigger;
  }) || [];

  // Validate interpretations
  const interpretations = (result.alternativeInterpretations as any[])?.map((interp: any) => {
    if (!interp.interpretation || !interp.tone || typeof interp.likelihood !== 'number') {
      throw new Error('Interpretation missing required fields');
    }
    return interp as MessageInterpretation;
  }) || [];

  // Validate evidence
  const evidence = (result.evidence as any[])?.map((e: any) => {
    if (!e.type || !e.quote || !e.reasoning) {
      throw new Error('Evidence missing required fields');
    }
    return e as Evidence;
  }) || [];

  return {
    ...baseValidation,
    rsdTriggers,
    alternativeInterpretations: interpretations,
    evidence,
  };
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

export function extractToneIndicators(message: string): string[] {
  const toneIndicatorRegex = /\/([a-zA-Z]+)/g;
  const matches = message.match(toneIndicatorRegex) || [];
  return matches;
}

// ============================================================================
// SYSTEM PROMPTS: RSD-FOCUSED ANALYSIS
// ============================================================================

/**
 * Main system prompt for RSD-aware message analysis
 * Focuses on: RSD triggers, alternative interpretations, evidence
 */
export const RSD_FOCUSED_ANALYSIS_PROMPT = `You are an expert in neurodivergent communication, specifically trained to help people with Rejection Sensitive Dysphoria (RSD) understand ambiguous messages.

Your role is to:
1. DETECT RSD TRIGGERS - Patterns like "k", "ok", "fine" that commonly cause anxiety
2. PROVIDE ALTERNATIVES - Show 2-3 possible meanings with confidence percentages
3. SHOW EVIDENCE - Quote the exact text and explain your reasoning

**RESPONSE FORMAT (STRICT JSON ONLY):**
{
  "tone": "one of: Friendly|Professional|Casual|Urgent|Concerned|Sarcastic|Neutral",
  "urgencyLevel": "Low|Medium|High|Critical (optional)",
  "intent": "2-5 word description of sender's intent (optional)",
  "confidenceScore": 0.75,
  "reasoning": "Brief explanation of overall tone",
  
  "rsdTriggers": [
    {
      "pattern": "exact text from message",
      "severity": "high|medium|low",
      "explanation": "Why this triggers RSD (2-3 sentences)",
      "reassurance": "Reassuring context (2-3 sentences)"
    }
  ],
  
  "alternativeInterpretations": [
    {
      "interpretation": "What the message likely means",
      "tone": "Friendly|Professional|...",
      "likelihood": 85,
      "reasoning": "Why we think this (2-3 sentences)",
      "contextClues": ["phrase 1", "phrase 2"]
    }
  ],
  
  "evidence": [
    {
      "type": "keyword|punctuation|emoji|pattern|timing",
      "quote": "exact text from message",
      "supports": "what this supports (tone/urgency/etc)",
      "reasoning": "explanation (1-2 sentences)"
    }
  ]
}

**CRITICAL RULES:**
1. NEVER use markdown code blocks
2. Return ONLY valid JSON
3. Always include at least 2 alternative interpretations
4. Provide evidence for your conclusions
5. If trigger pattern exists (k, ok, fine, etc), always include RSD trigger
6. Be compassionate - RSD users catastrophize easily
7. Show your reasoning transparently

**RSD TRIGGER PATTERNS:**
- Single letter responses: "k", "ok", "m", "yeah"
- Short dismissive words: "fine", "sure", "whatever"  
- Lack of warmth: no emoji, no greeting
- Delayed response: sudden change in response time
- Tone shift: different from their usual style

**HOW TO WRITE REASSURANCE:**
- Acknowledge the concern
- Provide statistical context ("X% of people who write 'k' mean neutral")
- Cite evidence from conversation history if available
- Never dismiss the anxiety as invalid`;

// ============================================================================
// PROMPT GENERATORS
// ============================================================================

export function generateRSDAnalysisPrompt(
  messageBody: string,
  conversationContext?: string[],
  senderPatternContext?: string
): string {
  let prompt = RSD_FOCUSED_ANALYSIS_PROMPT;
  
  prompt += `\n\n**MESSAGE TO ANALYZE:**\n"${messageBody}"`;

  if (conversationContext && conversationContext.length > 0) {
    prompt += `\n\n**CONVERSATION CONTEXT (recent messages):**\n`;
    conversationContext.slice(-5).forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
  }

  if (senderPatternContext) {
    prompt += `\n\n**SENDER'S COMMUNICATION PATTERN:**\n${senderPatternContext}`;
    prompt += `\nUse this to adjust your interpretation. For example, if this sender typically sends short messages that are neutral, boost your confidence in neutral interpretations.`;
  }

  return prompt;
}

// ============================================================================
// EXPORTS
// ============================================================================

export default {
  VALID_TONES,
  validateTone,
  validateToneAnalysis,
  validateEnhancedAnalysis,
  extractToneIndicators,
  generateRSDAnalysisPrompt,
  RSD_FOCUSED_ANALYSIS_PROMPT,
};
