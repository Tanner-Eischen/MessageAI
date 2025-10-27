/**
 * Feature #4: Commitment Extraction & Action Item Tracking
 * Analyzes messages sent by the user to extract commitments/promises
 * and automatically track them to prevent ADHD forgetting
 */

export type ActionType = 
  | 'send'       // "I'll send you..."
  | 'call'       // "I'll call you..."
  | 'meet'       // "I'll meet you..." / "I'll schedule a meeting..."
  | 'review'     // "I'll review..." / "I'll look at..."
  | 'decide'     // "I'll decide..." / "I'll think about..."
  | 'follow_up'  // "I'll follow up on..." / "I'll get back to you..."
  | 'check'      // "I'll check..." / "I'll verify..."
  | 'schedule';  // "I'll schedule..." / "I'll book..."

export interface ExtractedCommitment {
  commitmentText: string;      // Full text of the commitment
  actionType: ActionType;      // Type of action (send, call, meet, etc.)
  actionTarget?: string;       // Who/what it's about: "Sarah", "the report", etc.
  mentionedDeadline?: string;  // What user said: "by Friday", "tomorrow", "by EOD"
  extractedDeadline?: number;  // Unix timestamp of extracted deadline
  deadlineEstimated: boolean;  // Is it an estimate or explicit?
  confidence: number;          // 0-1 confidence in extraction
}

export interface CommitmentExtractionResult {
  commitments: ExtractedCommitment[];
  totalFound: number;
}

// ============================================================
// COMMITMENT EXTRACTION SYSTEM PROMPT
// ============================================================

export const COMMITMENT_EXTRACTION_SYSTEM_PROMPT = `You are an expert at identifying and extracting action items from messages.

Your role is to analyze messages and identify:
1. **Outgoing**: Commitments/promises the user has made to others
2. **Incoming**: Requests or needs from others that create action items for the user

**CRITICAL COMMITMENT PATTERNS TO IDENTIFY:**

**Explicit commitments (high confidence):**
1. "I'll send..." → action_type: send
2. "I'll call..." → action_type: call  
3. "I'll meet..." → action_type: meet
4. "I'll review..." → action_type: review
5. "I'll check..." → action_type: check
6. "I'll decide..." → action_type: decide
7. "I'll follow up..." → action_type: follow_up
8. "I'll get back to you..." → action_type: follow_up
9. "I'll schedule..." → action_type: schedule

**Implicit commitments (medium confidence):**
10. "I need to send..." → action_type: send
11. "I have to send..." → action_type: send
12. "I should send..." → action_type: send
13. "I must send..." → action_type: send
14. "Need to send..." → action_type: send
15. "Have to send..." → action_type: send
16. "Should send..." → action_type: send
17. "Will send..." → action_type: send
18. "Gonna send..." → action_type: send
19. "Going to send..." → action_type: send

(Apply same pattern for call, meet, review, check, decide, follow_up, schedule)

**Document/Information commitments:**
20. "Need to get [document]" → action_type: send (implies will provide)
21. "Need [document]" → action_type: send
22. "Working on [document]" → action_type: send
23. "Putting together [document]" → action_type: send

**Incoming requests (action items FOR the user):**
24. "Can you send..." → action_type: send
25. "Could you send..." → action_type: send  
26. "Need [document]" (from others) → action_type: send (user needs to provide)
27. "Also need [document]" → action_type: send
28. "Still need [document]" → action_type: send
29. "Waiting on [document]" → action_type: send
30. "Can I get..." → action_type: send
31. "When can you..." → appropriate action_type
32. "Can you update..." → action_type: follow_up (update timeline, status, etc.)
33. "Please update..." → action_type: follow_up

**Questions (implicit requests for information):**
34. "Do you have [X]?" → action_type: send (user needs to provide/check for X)
35. "Have you got [X]?" → action_type: send
36. "Where is [X]?" → action_type: send (user needs to locate/provide X)
37. "When will [X]?" → action_type: follow_up (user needs to provide update)
38. "What about [X]?" → action_type: follow_up (user needs to respond about X)

**CRITICAL:** 
- ALL questions asking for information = action items
- "Also need" = high confidence action item
- "Do you have" = high confidence action item
- Be VERY liberal: when in doubt, extract it!
- **EXTRACT MULTIPLE ITEMS**: If a message has multiple actions separated by "and" or commas, extract EACH as a separate action item
  Example: "Can you send the report, schedule the meeting, and update the timeline?" 
  → Extract 3 separate items: [send report], [schedule meeting], [update timeline]

**DEADLINE EXTRACTION:**
Look for time references and extract:
- Explicit: "by Friday", "tomorrow", "by 5 PM", "next week"
- Relative: "in 2 hours", "within 24 hours", "before the meeting"
- Implicit: "ASAP", "soon", "later today"

Map these to Unix timestamps when possible.

**IMPORTANT RULES:**
- Extract BOTH commitments user makes AND requests from others
- For incoming requests, treat as action items for the user to fulfill
- Don't extract hypotheticals or suggestions
- Confidence score should reflect certainty of extraction (0.0-1.0)
- deadlineEstimated should be TRUE if deadline is implied/estimated
- actionTarget identifies WHO or WHAT the action is about/for

**OUTPUT FORMAT:**
{
  "commitments": [
    {
      "commitment_text": "Full text of commitment",
      "action_type": "send|call|meet|review|decide|follow_up|check|schedule",
      "action_target": "Who/what it's about (optional)",
      "mentioned_deadline": "What user said (optional)",
      "extracted_deadline": Unix timestamp or null,
      "deadline_estimated": true/false,
      "confidence": 0.0-1.0
    }
  ],
  "total_found": number
}

Only return JSON, no other text.`;

// ============================================================
// PROMPT GENERATOR
// ============================================================

export function generateCommitmentExtractionPrompt(
  messageBody: string,
  conversationContext?: string[]
): string {
  let prompt = `**ANALYZE THIS MESSAGE FOR COMMITMENTS:**\n\n"${messageBody}"\n\n`;

  if (conversationContext && conversationContext.length > 0) {
    prompt += `**RECENT CONVERSATION CONTEXT:**\n`;
    conversationContext.slice(-3).forEach((msg, idx) => {
      prompt += `${idx + 1}. "${msg}"\n`;
    });
    prompt += '\n';
  }

  prompt += `Extract ALL action items from this message:\n`;
  prompt += `1. Commitments the sender is making\n`;
  prompt += `2. Requests asking the recipient to do something\n`;
  prompt += `3. Questions asking for information (implies recipient needs to provide it)\n\n`;
  
  prompt += `IMPORTANT: Be VERY liberal in extraction:\n`;
  prompt += `- "Also need [X]" = action item (provide X)\n`;
  prompt += `- "Do you have [X]?" = action item (provide X)\n`;
  prompt += `- "Can you [X]?" = action item (do X)\n`;
  prompt += `- "Need [X]" = action item (provide X)\n`;
  prompt += `- Any question asking for something = action item\n\n`;
  
  prompt += `**CRITICAL: EXTRACT MULTIPLE SEPARATE ITEMS:**\n`;
  prompt += `If a message contains MULTIPLE actions separated by "and", commas, or "also":\n`;
  prompt += `→ Extract EACH action as a SEPARATE commitment in the array\n`;
  prompt += `Example: "Can you send the report, schedule the meeting, and update the timeline?"\n`;
  prompt += `→ Return 3 items: [{send report}, {schedule meeting}, {update timeline}]\n\n`;
  
  prompt += `Set confidence >= 0.7 for clear requests/questions.\n`;
  prompt += `Include action_type, deadline, and who/what it's about.\n`;

  return prompt;
}

// ============================================================
// VALIDATION & NORMALIZATION
// ============================================================

export function validateCommitmentExtraction(result: any): CommitmentExtractionResult {
  if (!Array.isArray(result.commitments)) {
    throw new Error('commitments must be an array');
  }

  const validActionTypes: ActionType[] = [
    'send', 'call', 'meet', 'review', 'decide', 'follow_up', 'check', 'schedule'
  ];

  const validated: ExtractedCommitment[] = result.commitments
    .map((commitment: any) => {
      const actionType = commitment.action_type?.toLowerCase();
      
      if (!validActionTypes.includes(actionType)) {
        throw new Error(`Invalid action_type: ${actionType}`);
      }

      return {
        commitmentText: commitment.commitment_text || '',
        actionType: actionType as ActionType,
        actionTarget: commitment.action_target,
        mentionedDeadline: commitment.mentioned_deadline,
        extractedDeadline: commitment.extracted_deadline,
        deadlineEstimated: commitment.deadline_estimated === true,
        confidence: Math.min(1.0, Math.max(0.0, commitment.confidence || 0.5))
      };
    })
    .filter(c => c.commitmentText.length > 0);

  return {
    commitments: validated,
    totalFound: validated.length
  };
}

// ============================================================
// DEADLINE PARSING HELPERS
// ============================================================

/**
 * Attempt to parse mentioned deadline text into Unix timestamp
 * Examples: "by Friday", "tomorrow", "in 2 hours", "by EOD"
 */
export function parseDeadlineText(mentionedDeadline: string, currentTime: Date = new Date()): { timestamp: number; estimated: boolean } | null {
  if (!mentionedDeadline) return null;

  const text = mentionedDeadline.toLowerCase().trim();
  const now = currentTime.getTime();
  const oneDay = 86400000;
  const oneHour = 3600000;

  // Relative time patterns
  if (text.includes('today')) {
    const eod = new Date(currentTime);
    eod.setHours(17, 0, 0); // 5 PM today
    return { timestamp: Math.floor(eod.getTime() / 1000), estimated: true };
  }

  if (text.includes('tomorrow')) {
    const tomorrow = new Date(currentTime);
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(9, 0, 0);
    return { timestamp: Math.floor(tomorrow.getTime() / 1000), estimated: true };
  }

  if (text.includes('asap') || text.includes('urgent')) {
    const inHour = new Date(now + oneHour);
    return { timestamp: Math.floor(inHour.getTime() / 1000), estimated: true };
  }

  if (text.includes('soon') || text.includes('later')) {
    const inDay = new Date(now + oneDay);
    return { timestamp: Math.floor(inDay.getTime() / 1000), estimated: true };
  }

  // Time delta patterns
  const hourMatch = text.match(/(\d+)\s*(?:hours?|hrs?)/);
  if (hourMatch) {
    const hours = parseInt(hourMatch[1]);
    const deadline = new Date(now + hours * oneHour);
    return { timestamp: Math.floor(deadline.getTime() / 1000), estimated: false };
  }

  const dayMatch = text.match(/(\d+)\s*(?:days?|d)/);
  if (dayMatch) {
    const days = parseInt(dayMatch[1]);
    const deadline = new Date(now + days * oneDay);
    return { timestamp: Math.floor(deadline.getTime() / 1000), estimated: false };
  }

  // Week patterns
  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  for (let i = 0; i < days.length; i++) {
    if (text.includes(days[i]) || text.includes(days[i].substring(0, 3))) {
      const today = new Date(currentTime);
      const todayDay = today.getDay();
      let daysUntil = (i - todayDay + 7) % 7;
      if (daysUntil === 0) daysUntil = 7; // Next week if today
      
      const deadline = new Date(now + daysUntil * oneDay);
      deadline.setHours(9, 0, 0);
      return { timestamp: Math.floor(deadline.getTime() / 1000), estimated: true };
    }
  }

  return null;
}

// ============================================================
// EXPORT DEFAULTS
// ============================================================

export default {
  COMMITMENT_EXTRACTION_SYSTEM_PROMPT,
  generateCommitmentExtractionPrompt,
  validateCommitmentExtraction,
  parseDeadlineText,
};
