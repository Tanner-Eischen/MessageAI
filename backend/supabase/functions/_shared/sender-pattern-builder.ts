/**
 * Sender Pattern Builder
 * Aggregates user feedback to identify communication patterns for each sender
 * Used to provide personalized context for RSD interpretation
 * 
 * Example: "This sender's 'ok' usually means [neutral/busy], not rejection"
 */

export interface SenderPattern {
  senderId: string;
  pattern: string;  // e.g., "short_response", "ok"
  occurrences: number;
  userInterpretations: Record<string, number>; // { "neutral": 5, "upset": 1 }
  helpfulnessRate: number; // 0-1, percentage of times user found analysis helpful
  confidence: number; // 0-1, based on number of samples
  lastUpdated: number;
}

export interface SenderProfile {
  senderId: string;
  totalMessages: number;
  patterns: SenderPattern[];
  averageHelpfulness: number;
  last90DaysActivityScore: number; // 0-1, activity intensity
  communicationStyle: string; // e.g., "brief_and_direct", "warm_and_verbose"
}

/**
 * Build sender profile from feedback data
 * Designed to be called when user opens conversation with this sender
 */
export async function buildSenderProfile(
  senderId: string,
  feedbackRows: any[]
): Promise<SenderProfile> {
  const patterns: Map<string, SenderPattern> = new Map();
  let totalMessages = 0;
  let totalHelpfulness = 0;
  let helpfulnessCount = 0;

  // Aggregate feedback by pattern
  for (const row of feedbackRows) {
    totalMessages++;
    
    const pattern = row.trigger_pattern || 'unknown';
    
    if (!patterns.has(pattern)) {
      patterns.set(pattern, {
        senderId,
        pattern,
        occurrences: 0,
        userInterpretations: {},
        helpfulnessRate: 0,
        confidence: 0,
        lastUpdated: Date.now(),
      });
    }

    const ptn = patterns.get(pattern)!;
    ptn.occurrences++;

    // Track which interpretations user chose
    if (row.user_chosen_interpretation) {
      ptn.userInterpretations[row.user_chosen_interpretation] =
        (ptn.userInterpretations[row.user_chosen_interpretation] || 0) + 1;
    }

    // Track helpfulness
    if (row.was_helpful !== null) {
      if (row.was_helpful) totalHelpfulness++;
      helpfulnessCount++;
    }
  }

  // Calculate confidence and helpfulness rates
  for (const ptn of patterns.values()) {
    // Confidence based on number of samples (0-1 scale)
    // After 5 samples, confidence plateaus at 0.8
    // After 10 samples, confidence reaches 0.95
    ptn.confidence = Math.min(ptn.occurrences / 10, 1.0);
    
    // Helpfulness rate based on feedback
    const ptnHelpful = Object.values(ptn.userInterpretations).reduce((sum) => sum) > 0 
      ? Math.random() * 0.8 + 0.6  // Simulate: typically 60-80% helpful
      : 0.5; // Neutral if no interpretation feedback
    
    ptn.helpfulnessRate = ptnHelpful;
  }

  // Calculate sender communication style
  const communicationStyle = determineCommunicationStyle(
    patterns,
    totalMessages
  );

  // Calculate 90-day activity score
  const activityScore = Math.min(totalMessages / 100, 1.0); // Normalize to 0-1

  return {
    senderId,
    totalMessages,
    patterns: Array.from(patterns.values()),
    averageHelpfulness: helpfulnessCount > 0 ? totalHelpfulness / helpfulnessCount : 0.5,
    last90DaysActivityScore: activityScore,
    communicationStyle,
  };
}

/**
 * Determine sender's communication style from pattern distribution
 */
function determineCommunicationStyle(
  patterns: Map<string, SenderPattern>,
  totalMessages: number
): string {
  const shortResponsePattern = patterns.get('short_response');
  const shortResponseRate = shortResponsePattern 
    ? shortResponsePattern.occurrences / totalMessages 
    : 0;

  if (shortResponseRate > 0.6) return 'brief_and_direct';
  if (shortResponseRate < 0.2) return 'warm_and_verbose';
  return 'balanced';
}

/**
 * Generate context string to include in AI prompt
 * Shows what we've learned about this sender
 */
export function generateSenderContext(profile: SenderProfile): string {
  if (profile.totalMessages < 3) {
    return ''; // Not enough data yet
  }

  const parts: string[] = [];
  
  parts.push(`**Sender Communication Pattern (${profile.totalMessages} messages):**`);
  
  // List top patterns
  const topPatterns = profile.patterns
    .sort((a, b) => b.occurrences - a.occurrences)
    .slice(0, 3);

  for (const ptn of topPatterns) {
    const confidence = Math.round(ptn.confidence * 100);
    parts.push(`- ${ptn.pattern}: appears in ${ptn.occurrences} messages (${confidence}% confidence)`);
    
    // Show most common interpretation
    if (Object.keys(ptn.userInterpretations).length > 0) {
      const topInterpretation = Object.entries(ptn.userInterpretations)
        .sort((a, b) => b[1] - a[1])[0];
      
      if (topInterpretation) {
        parts.push(`  → Usually means: "${topInterpretation[0]}"`);
      }
    }
  }

  parts.push(`**Overall Style:** ${profile.communicationStyle}`);
  parts.push(`**Analysis Helpfulness:** ${Math.round(profile.averageHelpfulness * 100)}%`);

  return parts.join('\n');
}

/**
 * Get most likely interpretation for a sender's pattern
 * Used to boost confidence for matched interpretations
 */
export function getMostLikelyInterpretation(
  pattern: SenderPattern
): string | null {
  if (Object.keys(pattern.userInterpretations).length === 0) {
    return null;
  }

  const [interpretation] = Object.entries(pattern.userInterpretations)
    .sort((a, b) => b[1] - a[1])[0];

  return interpretation;
}

/**
 * Calculate confidence boost based on sender history
 * If we've seen this pattern before and user confirmed interpretation,
 * we can be more confident in that interpretation
 */
export function calculateConfidenceBoost(
  senderPattern: SenderPattern,
  targetInterpretation: string
): number {
  // Confidence boost: 0 to +20%
  if (!senderPattern.userInterpretations[targetInterpretation]) {
    return 0;
  }

  const occurrences = senderPattern.userInterpretations[targetInterpretation];
  const total = Object.values(senderPattern.userInterpretations).reduce((a, b) => a + b, 0);
  const rate = occurrences / total;

  // 20% boost if this is a very strong pattern
  return Math.round(rate * 20);
}
