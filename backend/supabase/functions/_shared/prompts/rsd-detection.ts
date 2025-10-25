/**
 * RSD (Rejection Sensitive Dysphoria) Trigger Detection
 * Identifies messages that might be misinterpreted as rejection/criticism
 */

export interface RSDTrigger {
  pattern: string;
  severity: 'high' | 'medium' | 'low';
  explanation: string;
  reassurance: string;
}

export const RSD_TRIGGER_PATTERNS: RSDTrigger[] = [
  {
    pattern: 'ok',
    severity: 'high',
    explanation: 'Single-word responses like "ok" can trigger RSD as they feel dismissive',
    reassurance: 'This is likely just a quick acknowledgment, not disappointment'
  },
  {
    pattern: 'fine',
    severity: 'high',
    explanation: '"Fine" often feels passive-aggressive or dismissive',
    reassurance: 'They might genuinely mean "that works for me" without hidden meaning'
  },
  {
    pattern: 'we need to talk',
    severity: 'high',
    explanation: 'This phrase strongly triggers anxiety about impending criticism',
    reassurance: 'This doesn\'t always mean bad news - they may just want to discuss something'
  },
  {
    pattern: 'k',
    severity: 'high',
    explanation: 'Even shorter than "ok", feels very dismissive',
    reassurance: 'Some people just text quickly - not necessarily upset'
  },
  {
    pattern: 'whatever',
    severity: 'medium',
    explanation: 'Can feel like giving up or being annoyed',
    reassurance: 'Could mean "I\'m flexible" rather than "I don\'t care"'
  },
  {
    pattern: 'sure',
    severity: 'medium',
    explanation: 'Can sound sarcastic or unenthusiastic',
    reassurance: 'Often means genuine agreement, just casual phrasing'
  },
  {
    pattern: 'no worries',
    severity: 'low',
    explanation: 'Meant to be reassuring but can feel dismissive',
    reassurance: 'They\'re trying to make you feel better, not minimize your concern'
  },
];

export function detectRSDTriggers(message: string): RSDTrigger[] {
  const lowerMessage = message.toLowerCase().trim();
  const detected: RSDTrigger[] = [];

  for (const trigger of RSD_TRIGGER_PATTERNS) {
    // Match exact phrase or phrase within message
    if (lowerMessage === trigger.pattern || lowerMessage.includes(trigger.pattern)) {
      detected.push(trigger);
    }
  }

  // Additional checks for RSD patterns
  // Very short messages (1-3 words, no punctuation, no emoji)
  const words = message.trim().split(/\s+/);
  const hasWarmthIndicators = 
    message.includes('!') || 
    message.includes('😊') || 
    message.includes('❤️') ||
    message.includes('😄') ||
    message.includes('💕') ||
    message.includes('👍');

  if (words.length <= 3 && !hasWarmthIndicators) {
    detected.push({
      pattern: 'short_response',
      severity: 'medium',
      explanation: 'Very short responses without warmth indicators can feel cold',
      reassurance: 'Brief doesn\'t always mean upset - they might be busy or texting quickly'
    });
  }

  // Delayed response without explanation
  // (This would require timestamp comparison - implement in Edge Function)

  return detected;
}

export function generateRSDPromptAddition(triggers: RSDTrigger[]): string {
  if (triggers.length === 0) return '';

  return `
**RSD ALERT:** This message contains potential RSD triggers:
${triggers.map(t => `- "${t.pattern}" (${t.severity} severity): ${t.explanation}`).join('\n')}

When analyzing, consider:
1. Is the message genuinely negative or just brief/casual?
2. Are there hidden cues suggesting actual criticism?
3. What evidence supports a negative vs neutral interpretation?

Provide reassurance if this is likely not rejection/criticism.
`;
}

