/**
 * Generates multiple possible interpretations of a message
 * Helps with ambiguity and reduces anxiety from uncertainty
 */

export interface MessageInterpretation {
  interpretation: string;
  tone: string;
  likelihood: number; // 0-100
  reasoning: string;
  context_clues: string[];
}

export const ALTERNATIVE_INTERPRETATIONS_PROMPT = `
**CRITICAL:** For messages that could be interpreted multiple ways, provide 2-3 alternative interpretations ranked by likelihood.

Consider:
1. **Literal interpretation:** What do the exact words mean?
2. **Positive interpretation:** Best-case scenario
3. **Neutral interpretation:** No hidden meaning
4. **Negative interpretation:** Worst-case (if genuinely possible)

For each interpretation, provide:
- The interpretation itself
- What tone it would reflect
- Likelihood (0-100%)
- Reasoning why this interpretation makes sense
- Context clues supporting it

**Example for "ok":**
[
  {
    "interpretation": "Simple acknowledgment, no hidden meaning",
    "tone": "Neutral",
    "likelihood": 70,
    "reasoning": "Most common use of 'ok' is just confirming receipt of information",
    "context_clues": ["No prior conflict", "Normal conversation flow"]
  },
  {
    "interpretation": "Mildly annoyed or disappointed but trying to be polite",
    "tone": "Frustrated",
    "likelihood": 20,
    "reasoning": "Very brief response could indicate frustration",
    "context_clues": ["Shorter than usual", "No warmth markers"]
  },
  {
    "interpretation": "In a rush, typing quickly",
    "tone": "Casual",
    "likelihood": 10,
    "reasoning": "Quick response suggests they're busy",
    "context_clues": ["Fast reply time"]
  }
]

**IMPORTANT:**
- Don't list unlikely interpretations just to fill space
- If message is clearly one tone, say so with high confidence
- For RSD triggers, emphasize most likely interpretation is benign
`;

export function shouldGenerateAlternatives(
  message: string,
  rsdTriggersDetected: number,
  baseConfidence: number
): boolean {
  // Generate alternatives if:
  // 1. RSD triggers present
  // 2. Message is ambiguous (low confidence)
  // 3. Very short message (could be misinterpreted)
  
  if (rsdTriggersDetected > 0) return true;
  if (baseConfidence < 0.7) return true;
  if (message.trim().split(/\s+/).length <= 3) return true;
  
  return false;
}

