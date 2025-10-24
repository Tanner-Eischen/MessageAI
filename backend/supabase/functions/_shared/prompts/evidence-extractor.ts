/**
 * Extracts specific evidence from messages to support analysis
 * Helps neurodivergent users understand WHY the analysis is what it is
 */

export interface Evidence {
  type: 'keyword' | 'punctuation' | 'length' | 'emoji' | 'timing' | 'pattern';
  quote: string; // The actual evidence from message
  supports: string; // What it supports (e.g., "positive tone", "urgency")
  reasoning: string; // Why this is evidence
}

export const EVIDENCE_EXTRACTION_PROMPT = `
**EVIDENCE-BASED ANALYSIS:**
For your tone analysis, cite SPECIFIC evidence from the message that supports your conclusion.

Evidence types to look for:
1. **Keywords:** Specific words that indicate emotion ("love", "hate", "worried", "excited")
2. **Punctuation:** Exclamation marks (enthusiasm), question marks (inquiry), ellipsis (uncertainty)
3. **Capitalization:** ALL CAPS (strong emotion), mixed case (casual)
4. **Emoji:** 😊 (friendly), ❤️ (caring), 🙄 (sarcastic)
5. **Length:** Very short (busy/dismissive), very long (info-dumping/anxious)
6. **Tone indicators:** /j (joking), /srs (serious), /s (sarcastic)

**Format evidence as:**
[
  {
    "type": "keyword",
    "quote": "ASAP",
    "supports": "urgency",
    "reasoning": "Explicit urgency marker indicates time-sensitive need"
  },
  {
    "type": "punctuation",
    "quote": "!!!",
    "supports": "high intensity",
    "reasoning": "Multiple exclamation marks show strong emotion"
  }
]

**IMPORTANT:**
- Quote the exact text from the message
- Explain HOW it supports your analysis
- If there's NO evidence for something, say so explicitly
`;

export function formatEvidence(evidence: Evidence[]): string {
  if (evidence.length === 0) {
    return 'No specific evidence found in message';
  }

  return evidence.map(e => 
    `- "${e.quote}" (${e.type}): ${e.reasoning}`
  ).join('\n');
}

