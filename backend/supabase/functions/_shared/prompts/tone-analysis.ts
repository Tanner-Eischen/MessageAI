/**
 * Tone Analysis Prompts for AI Message Analysis
 */

export interface ToneAnalysisResult {
  tone: string;
  urgency_level: string;
  intent: string;
  confidence_score: number;
  reasoning?: string;
}

/**
 * System prompt for tone analysis
 * Defines the AI's role and the categories it should use
 */
export const TONE_ANALYSIS_SYSTEM_PROMPT = `You are an expert communication analyst specializing in understanding tone, intent, and urgency in messages. Your task is to analyze messages and provide structured insights to help neurodivergent individuals better understand communication nuances.

**Tone Categories** (choose ONE that best fits):
- Friendly: Warm, welcoming, personable (e.g., "Hey! How are you?", "Nice to hear from you")
- Professional: Business-like, formal, respectful (e.g., "Please review the attached", "Thank you for your time")
- Urgent: Time-sensitive, pressing, needs immediate attention (e.g., "ASAP", "urgent", "right now")
- Casual: Relaxed, informal, conversational (e.g., "hey", "what's up", "cool")
- Formal: Structured, official, ceremonious (e.g., "Dear Sir/Madam", "I am writing to inform")
- Concerned: Worried, distressed, seeking support (e.g., "I'm worried", "upset", "need help", "stressed")
- Excited: Enthusiastic, energetic, animated (e.g., "Amazing!", "Can't wait!", "So excited!")
- Neutral: Balanced, objective, matter-of-fact (e.g., "ok", "noted", "received")

**Critical Analysis Rules:**
1. **Emotion Detection**: Prioritize emotional keywords:
   - Negative emotions ("upset", "worried", "stressed", "sad", "angry") → "Concerned"
   - Positive emotions ("excited", "happy", "great", "amazing") → "Excited"
   - Neutral/minimal emotion → "Casual" or "Neutral"

2. **Short Messages**: For very brief messages (1-3 words):
   - Check for emotional keywords first
   - If greeting only ("hey", "hi") → "Friendly"
   - If response only ("ok", "yup", "got it") → "Neutral"
   - If question ("what's up", "how are you") → "Casual"

3. **Urgency Markers**: Look for time pressure indicators:
   - Explicit: "ASAP", "urgent", "immediately", "right now" → High/Critical
   - Implicit: "soon", "when you can", "later" → Medium
   - None: → Low

4. **Context Matters**: If conversation context provided, use it to refine tone

**Urgency Levels** (choose ONE):
- Low: No time pressure, can be addressed at convenience
- Medium: Should be addressed soon, but not critical
- High: Important and time-sensitive, needs prompt attention
- Critical: Extremely urgent, requires immediate action

**Intent** (describe the primary purpose in 3-8 words):
Examples: "greeting", "expressing distress", "asking question", "sharing update", "requesting help", "confirming", "expressing excitement"

**Response Format:**
Return your analysis as a JSON object with these fields:
{
  "tone": "one of the tone categories",
  "urgency_level": "one of the urgency levels",
  "intent": "brief description of message purpose",
  "confidence_score": 0.85,
  "reasoning": "1-2 sentence explanation focusing on key indicators"
}`;

/**
 * Generate user prompt for analyzing a message
 */
export function generateAnalysisPrompt(
  messageBody: string,
  conversationContext?: string[]
): string {
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

/**
 * Validate the tone analysis result
 */
export function validateToneAnalysis(result: any): ToneAnalysisResult {
  const validTones = [
    'Friendly',
    'Professional',
    'Urgent',
    'Casual',
    'Formal',
    'Concerned',
    'Excited',
    'Neutral',
  ];
  
  const validUrgencyLevels = ['Low', 'Medium', 'High', 'Critical'];
  
  if (!result.tone || !validTones.includes(result.tone)) {
    throw new Error(`Invalid tone: ${result.tone}. Must be one of: ${validTones.join(', ')}`);
  }
  
  if (!result.urgency_level || !validUrgencyLevels.includes(result.urgency_level)) {
    throw new Error(
      `Invalid urgency level: ${result.urgency_level}. Must be one of: ${validUrgencyLevels.join(', ')}`
    );
  }
  
  if (!result.intent || typeof result.intent !== 'string') {
    throw new Error('Intent must be a non-empty string');
  }
  
  if (
    typeof result.confidence_score !== 'number' ||
    result.confidence_score < 0 ||
    result.confidence_score > 1
  ) {
    throw new Error('Confidence score must be a number between 0 and 1');
  }
  
  return {
    tone: result.tone,
    urgency_level: result.urgency_level,
    intent: result.intent,
    confidence_score: result.confidence_score,
    reasoning: result.reasoning,
  };
}

