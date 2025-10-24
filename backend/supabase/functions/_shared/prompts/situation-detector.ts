/**
 * Detects what type of response the user is trying to write
 * So we can suggest appropriate templates
 */

export type SituationType = 
  | 'declining'          // Saying no to something
  | 'boundary_setting'   // Setting or enforcing a boundary
  | 'info_dumping'       // Sharing enthusiasm/info
  | 'apologizing'        // Making an apology
  | 'clarifying'         // Asking for clarification
  | 'casual_chat'        // Just chatting
  | 'work_professional'  // Professional communication
  | 'emotional_support'  // Providing/seeking support
  | 'unknown';           // Can't determine

export interface SituationDetectionResult {
  situation_type: SituationType;
  confidence: number; // 0.0-1.0
  reasoning: string;
  suggested_templates: string[]; // Template IDs that might help
}

export const SITUATION_DETECTION_PROMPT = `Analyze the draft message and determine what type of response the user is trying to write.

**Situation Types:**

1. **declining** - User is saying no, turning down an invitation, or refusing a request
   - Keywords: "can't", "unable to", "won't be able", "have to pass", "sorry but"
   - Context: Following an invitation or request

2. **boundary_setting** - User is setting or enforcing a personal boundary
   - Keywords: "not comfortable", "need", "prefer", "don't", "stop"
   - Context: Asserting limits or needs

3. **info_dumping** - User is enthusiastically sharing detailed information
   - Keywords: "excited", "fascinating", "amazing", "let me explain"
   - Context: Long, detailed message about a topic they care about
   - Length: Usually longer than average

4. **apologizing** - User is making an apology
   - Keywords: "sorry", "apologize", "my fault", "my bad", "messed up"
   - Context: Acknowledging a mistake

5. **clarifying** - User is asking for clarification or checking understanding
   - Keywords: "confused", "not sure", "what do you mean", "can you explain"
   - Context: Seeking clarity

6. **casual_chat** - Just friendly conversation
   - Keywords: "hey", "how are you", "what's up"
   - Context: Social interaction

7. **work_professional** - Professional/business communication
   - Keywords: "regarding", "attached", "deadline", "meeting", "project"
   - Context: Work-related

8. **emotional_support** - Providing or seeking emotional support
   - Keywords: "sorry to hear", "here for you", "feeling", "struggling"
   - Context: Emotional/supportive conversation

**Response Format:**
{
  "situation_type": "declining",
  "confidence": 0.85,
  "reasoning": "Draft contains 'I won't be able to' and 'thanks for the invite', indicating a polite decline",
  "suggested_templates": ["decline_polite", "decline_with_alternative"]
}

**Instructions:**
- Consider both the draft content AND the context of what they're replying to
- Look for explicit keywords but also implicit patterns
- If multiple situations apply, choose the primary one
- Only suggest templates that actually match the situation
- Be honest about low confidence`;

export function detectSituation(
  draftMessage: string,
  conversationContext?: string[]
): string {
  let prompt = `**Draft Message:**\n"${draftMessage}"\n\n`;
  
  if (conversationContext && conversationContext.length > 0) {
    prompt += `**Replying To:**\n`;
    conversationContext.slice(-2).forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
    prompt += '\n';
  }
  
  prompt += `Analyze the situation type and suggest appropriate templates.`;
  
  return prompt;
}

