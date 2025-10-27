/**
 * Boundary Violation Detection Engine
 * Identifies messages that violate personal/professional boundaries
 * Supports: After-hours pressure, Guilt-tripping, Overstepping, Repeated pushing
 */

export type ViolationType = 
  | 'after_hours_pressure'
  | 'guilt_tripping'
  | 'overstepping'
  | 'repeated_pushing'
  | 'scope_creep'
  | 'timeline_pressure'
  | 'other';

export type Severity = 'low' | 'medium' | 'high';

export interface BoundaryViolation {
  type: ViolationType;
  severity: Severity;
  explanation: string;
  evidence: string[];
  suggestedGentle: string;
  suggestedModerate: string;
  suggestedFirm: string;
}

export interface BoundaryAnalysisResult {
  hasViolation: boolean;
  type: ViolationType | 'none';
  explanation: string;
  suggestedResponses: {
    gentle?: string;
    moderate?: string;
    firm?: string;
  };
  severity: number; // 0-10 scale
}

// ===========================================================================
// GUILT-TRIPPING PATTERNS
// ===========================================================================

const GUILT_TRIP_PHRASES = [
  'only you can',
  'really need you',
  'nobody else',
  'i depend on you',
  'you always help me',
  'don\'t abandon me',
  'you\'re the only one',
  'if you really cared',
  'how could you',
  'after all i\'ve done',
  'i\'ll be so hurt',
  'nobody understands me like you',
  'you don\'t care about me',
  'you never help when i need you',
];

function detectGuiltTripping(message: string): { detected: boolean; evidence: string[] } {
  const lowerMessage = message.toLowerCase();
  const evidence: string[] = [];

  for (const phrase of GUILT_TRIP_PHRASES) {
    if (lowerMessage.includes(phrase)) {
      const match = message.match(new RegExp(`[^.!?]*${phrase}[^.!?]*[.!?]`, 'i'));
      if (match) evidence.push(`"${match[0].trim()}"`);
    }
  }

  // Additional emotional manipulation patterns
  if ((lowerMessage.match(/[!]{2,}/g) || []).length > 0 && evidence.length === 0) {
    evidence.push('Multiple exclamation marks for emotional intensity');
  }

  if ((lowerMessage.match(/[?]{2,}/g) || []).length > 0 && evidence.length === 0) {
    evidence.push('Multiple question marks suggesting desperation');
  }

  return {
    detected: evidence.length > 0,
    evidence,
  };
}

// ===========================================================================
// OVERSTEPPING PATTERNS (Inappropriate personal questions)
// ===========================================================================

const OVERSTEPPING_PATTERNS = [
  /why are you.*\?/i,
  /what were you.*\?/i,
  /have you.*yet\?/i,
  /tell me about your.*\?/i,
  /how much do you.*\?/i,
  /aren't you.*\?/i,
  /shouldn't you.*\?/i,
  /when are you going to.*\?/i,
  /don't you think.*\?/i,
];

function detectOverstepping(message: string): { detected: boolean; evidence: string[] } {
  const evidence: string[] = [];

  for (const pattern of OVERSTEPPING_PATTERNS) {
    if (pattern.test(message)) {
      const match = message.match(pattern);
      if (match) evidence.push(`"${match[0]}" - pressuring personal question`);
    }
  }

  // Detect inappropriate topic questions (family, finances, relationships)
  const sensitiveTopics = [
    'your family',
    'your relationship',
    'your salary',
    'your weight',
    'your dating',
    'your personal life',
    'why you\'re single',
    'why you don\'t have kids',
  ];

  for (const topic of sensitiveTopics) {
    if (message.toLowerCase().includes(topic)) {
      evidence.push(`Asking about private topic: ${topic}`);
    }
  }

  return {
    detected: evidence.length > 0,
    evidence,
  };
}

// ===========================================================================
// AFTER-HOURS PRESSURE
// ===========================================================================

function isAfterHours(timestamp: number): boolean {
  const date = new Date(timestamp * 1000);
  const hour = date.getHours();
  // After hours: 6 PM - 8 AM
  return hour >= 18 || hour < 8;
}

const URGENCY_PHRASES = [
  'asap',
  'urgent',
  'immediately',
  'right now',
  'need it now',
  'cannot wait',
  'don\'t have time',
  'hurry',
  'quickly',
  'emergency',
  'critical',
  'important',
];

function detectAfterHoursPressure(
  message: string,
  timestamp: number
): { detected: boolean; evidence: string[]; isAfterHours: boolean } {
  const afterHours = isAfterHours(timestamp);
  const lowerMessage = message.toLowerCase();
  const evidence: string[] = [];

  if (!afterHours) {
    return { detected: false, evidence, isAfterHours: false };
  }

  for (const phrase of URGENCY_PHRASES) {
    if (lowerMessage.includes(phrase)) {
      evidence.push(`Urgent pressure: "${phrase}"`);
    }
  }

  // Check for any command/request combined with after-hours timing
  if ((lowerMessage.match(/can you|could you|will you|please|help/i) || []).length > 0) {
    evidence.push(`Request sent outside work hours (${new Date(timestamp * 1000).toLocaleTimeString()})`);
  }

  return {
    detected: evidence.length > 0,
    isAfterHours: true,
    evidence,
  };
}

// ===========================================================================
// REPEATED PUSHING (requires context from database)
// ===========================================================================

export function detectRepeatedPushing(
  violationCount: number,
  timeWindowDays: number = 30
): { detected: boolean; severity: Severity; explanation: string } {
  if (violationCount === 0) {
    return { detected: false, severity: 'low', explanation: '' };
  }

  if (violationCount === 1) {
    return {
      detected: false,
      severity: 'low',
      explanation: 'First violation from this sender',
    };
  }

  if (violationCount === 2) {
    return {
      detected: true,
      severity: 'medium',
      explanation: `This is the 2nd boundary violation from this person in the last ${timeWindowDays} days`,
    };
  }

  // 3+ violations = repeat offender
  return {
    detected: true,
    severity: 'high',
    explanation: `This is the ${violationCount}th boundary violation from this person in the last ${timeWindowDays} days. This is a repeat pattern.`,
  };
}

// ===========================================================================
// MAIN DETECTION FUNCTION
// ===========================================================================

export function detectBoundaryViolations(
  message: string,
  timestamp: number,
  senderViolationCount: number = 0
): BoundaryViolation[] {
  const violations: BoundaryViolation[] = [];

  // Check guilt-tripping
  const guiltTrip = detectGuiltTripping(message);
  if (guiltTrip.detected) {
    violations.push({
      type: 'guilt_tripping',
      severity: 'medium',
      explanation:
        'This message uses emotional manipulation or guilt-tripping to get compliance. It\'s okay to set boundaries even if someone "really needs" you.',
      evidence: guiltTrip.evidence,
      suggestedGentle:
        'I care about you, and I\'m here to help when I can. Right now, I need to focus on my own needs too.',
      suggestedModerate:
        'I understand you\'re going through a lot. I can help, but I need to do it in a way that works for me too.',
      suggestedFirm:
        'I need you to know that I\'m not responsible for your emotions. I\'m happy to help if I can, but not if it means sacrificing my wellbeing.',
    });
  }

  // Check overstepping
  const overstepping = detectOverstepping(message);
  if (overstepping.detected) {
    violations.push({
      type: 'overstepping',
      severity: 'medium',
      explanation:
        'This message asks invasive personal questions or makes assumptions about your life. You don\'t owe anyone explanations about your private matters.',
      evidence: overstepping.evidence,
      suggestedGentle: 'That\'s pretty personal. I\'d prefer to keep that private.',
      suggestedModerate:
        'I appreciate the interest, but that\'s not something I\'m comfortable discussing.',
      suggestedFirm:
        'That\'s not something I discuss. If you have work-related questions, I\'m happy to help with those.',
    });
  }

  // Check after-hours pressure
  const afterHours = detectAfterHoursPressure(message, timestamp);
  if (afterHours.detected && afterHours.isAfterHours) {
    violations.push({
      type: 'after_hours_pressure',
      severity: 'medium',
      explanation: `This request came after work hours (${new Date(timestamp * 1000).toLocaleTimeString()}). It's healthy to have boundaries around work time. You don't have to respond immediately.`,
      evidence: afterHours.evidence,
      suggestedGentle:
        'I\'ll get to this during work hours tomorrow. Thanks for understanding!',
      suggestedModerate:
        'I appreciate the urgency, but I only respond to work requests during business hours to maintain balance.',
      suggestedFirm:
        'I don\'t respond to work requests after 6 PM or before 8 AM. I\'ll get back to you during business hours.',
    });
  }

  // Check repeated pushing
  if (senderViolationCount >= 2) {
    const repeatedPush = detectRepeatedPushing(senderViolationCount);
    if (repeatedPush.detected) {
      const severityMap = {
        low: 'This person has crossed your boundaries before.' as const,
        medium:
          'This is part of a pattern. This person regularly violates your boundaries.' as const,
        high:
          'WARNING: This person is a repeat boundary violator. Consider having a direct conversation about expectations.' as const,
      };

      violations.push({
        type: 'repeated_pushing',
        severity: repeatedPush.severity,
        explanation: severityMap[repeatedPush.severity],
        evidence: [
          `${senderViolationCount} boundary violations in the last 30 days from this sender`,
        ],
        suggestedGentle: "I've noticed this is a pattern. Can we talk about how we work together?",
        suggestedModerate:
          'This is the third time this week you\'ve pushed past my boundaries. I need you to respect my limits.',
        suggestedFirm:
          'I\'ve told you multiple times what my boundaries are. If you can\'t respect them, I need to reconsider this relationship.',
      });
    }
  }

  return violations;
}

// ===========================================================================
// PROMPT FOR AI BOUNDARY DETECTION
// ===========================================================================

export const BOUNDARY_DETECTION_PROMPT = `
**BOUNDARY VIOLATION DETECTION SYSTEM**

Analyze this message for boundary violations using these patterns:

1. **Guilt-Tripping**: Phrases like "only you can help", "I really need you", emotional manipulation
2. **Overstepping**: Invasive personal questions, unsolicited advice, inappropriate interest
3. **After-Hours Pressure**: Urgent requests sent after 6 PM or before 8 AM
4. **Repeated Pushing**: Pattern of boundary violations from same person (3+ violations in 30 days)
5. **Scope Creep**: Adding requirements, changing deliverables, expanding project without discussion
6. **Timeline Pressure**: Moving up deadlines, changing schedules, creating artificial urgency, using external pressure ("stakeholders", "boss needs it")

**IMPORTANT**: "Would it be possible to..." or "Quick question..." often mask demands/boundary violations. Look for schedule changes without negotiation, using external pressure as leverage, asking to compress timelines without discussing trade-offs.

For each violation detected:
- Explain WHY it's a violation in user-friendly language
- Provide 3 response templates: Gentle, Moderate, Firm
- Include supporting evidence from the message

Output format:
{
  "violations": [
    {
      "type": "guilt_tripping|overstepping|after_hours_pressure|repeated_pushing|scope_creep|timeline_pressure",
      "severity": "low|medium|high",
      "explanation": "Plain English explanation",
      "evidence": ["specific phrases or patterns"],
      "suggested_gentle": "Gentle boundary-setting response",
      "suggested_moderate": "Moderate boundary-setting response",
      "suggested_firm": "Firm boundary-setting response"
    }
  ],
  "overall_severity": "low|medium|high",
  "recommendations": ["What the user should do"]
}
`;

/**
 * Generate AI prompt for boundary analysis
 */
export function generateBoundaryAnalysisPrompt(
  messageBody: string,
  senderRepeatedViolations: number = 0
): string {
  let prompt = `${BOUNDARY_DETECTION_PROMPT}\n\n`;
  prompt += `**Message to Analyze**: "${messageBody}"\n\n`;

  if (senderRepeatedViolations > 0) {
    prompt += `**Context**: This sender has ${senderRepeatedViolations} previous boundary violations on record.\n\n`;
  }

  prompt += `Analyze for boundary violations and suggest appropriate response templates.`;

  return prompt;
}

/**
 * System prompt for AI-based boundary analysis
 */
export const BOUNDARY_ANALYSIS_SYSTEM_PROMPT = `You are an expert at identifying boundary violations in messages. Your role is to help users recognize when someone is:

1. **Guilt-Tripping**: Using emotional manipulation ("only you can help", "I really need you")
2. **Overstepping**: Asking invasive personal questions or making inappropriate assumptions
3. **After-Hours Pressure**: Sending urgent requests outside business hours
4. **Repeated Pushing**: Following a pattern of boundary violations
5. **Scope Creep**: Adding requirements, expanding project scope without proper discussion
6. **Timeline Pressure**: Changing deadlines/schedules without negotiation, using external pressure ("stakeholders want it", "boss needs it sooner")

**PAY SPECIAL ATTENTION TO**:
- Polite-sounding requests that actually violate boundaries ("would it be possible to move the deadline up?")
- Using third-party pressure as leverage ("stakeholders are getting antsy", "the team is waiting")
- Schedule changes presented as questions but expecting yes
- Adding urgency without discussing trade-offs or what can be removed

For each message, analyze and provide:
- Whether a violation exists (hasViolation: true/false)
- The type of violation detected
- A clear explanation in user-friendly language
- Suggested response templates (gentle, moderate, firm)
- Severity rating (0-10)

CRITICAL: Respond ONLY with valid JSON, no markdown or extra text. Follow this exact format:

{
  "hasViolation": boolean,
  "type": "guilt_tripping|overstepping|after_hours_pressure|repeated_pushing|scope_creep|timeline_pressure|none",
  "explanation": "User-friendly explanation",
  "suggestedResponses": {
    "gentle": "Optional gentle response",
    "moderate": "Optional moderate response",
    "firm": "Optional firm response"
  },
  "severity": 0-10
}`;

/**
 * Validate boundary analysis result from AI
 */
export function validateBoundaryAnalysis(result: any): BoundaryAnalysisResult {
  if (!result || typeof result !== 'object') {
    throw new Error('Invalid boundary analysis result: result must be an object');
  }

  const validTypes: Array<ViolationType | 'none'> = [
    'guilt_tripping',
    'overstepping',
    'after_hours_pressure',
    'repeated_pushing',
    'scope_creep',
    'timeline_pressure',
    'none',
  ];

  if (typeof result.hasViolation !== 'boolean') {
    throw new Error('Invalid boundary analysis: hasViolation must be boolean');
  }

  if (!validTypes.includes(result.type)) {
    throw new Error(`Invalid boundary analysis: type must be one of ${validTypes.join(', ')}`);
  }

  if (typeof result.explanation !== 'string') {
    throw new Error('Invalid boundary analysis: explanation must be a string');
  }

  if (typeof result.severity !== 'number' || result.severity < 0 || result.severity > 10) {
    throw new Error('Invalid boundary analysis: severity must be a number between 0 and 10');
  }

  const suggestedResponses: { gentle?: string; moderate?: string; firm?: string } = {};
  if (result.suggestedResponses?.gentle) {
    suggestedResponses.gentle = result.suggestedResponses.gentle;
  }
  if (result.suggestedResponses?.moderate) {
    suggestedResponses.moderate = result.suggestedResponses.moderate;
  }
  if (result.suggestedResponses?.firm) {
    suggestedResponses.firm = result.suggestedResponses.firm;
  }

  return {
    hasViolation: result.hasViolation,
    type: result.type,
    explanation: result.explanation,
    suggestedResponses,
    severity: result.severity,
  };
}
