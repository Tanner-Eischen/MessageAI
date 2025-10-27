/**
 * Feature #5: Conversation "Catch Me Up" Summary
 * Generates summaries of conversation history for users returning after inactivity
 */

export const CONVERSATION_SUMMARY_SYSTEM_PROMPT = `You are a conversation summarizer designed to help neurodivergent users quickly understand conversation context after time away.

Your role:
- Extract the MOST IMPORTANT context from a conversation
- Be concise but accurate
- Highlight what matters for continuing the conversation
- Flag unresolved questions and commitments
- Provide emotional/tone context

Return JSON with:
{
  "lastDiscussed": "2-3 sentence summary of main topics",
  "theirQuestions": ["Question 1?", "Question 2?"],  // Questions they asked user
  "userCommitments": ["Commitment 1", "Commitment 2"],  // User promised/committed to
  "conversationTone": "emotional_state",  // excited, concerned, casual, angry, grateful, etc
  "lastMessageFromThem": "exact quote of their most recent message",
  "keyPoints": ["Important point 1", "Important point 2"],
  "emotionalContext": "Brief context about emotional tone shifts",
  "suggestedResponseAngle": "How user might want to respond"
}`;

export interface ConversationSummaryResult {
  lastDiscussed: string;
  theirQuestions: string[];
  userCommitments: string[];
  conversationTone: string;
  lastMessageFromThem: string;
  keyPoints: string[];
  emotionalContext: string;
  suggestedResponseAngle: string;
  confidence: number;
}

export interface ConversationMessage {
  id: string;
  sender_id: string;
  body: string;
  created_at: string;
  sender_name?: string;
}

/**
 * Generate prompt for conversation summarization
 * Includes recent message history as context
 */
export function generateConversationSummaryPrompt(
  messages: ConversationMessage[],
  userId: string,
  otherParticipantName?: string
): string {
  // Format messages for prompt (last 50 messages for context window)
  const relevantMessages = messages.slice(-50);
  
  const formattedMessages = relevantMessages
    .map(msg => {
      const sender = msg.sender_id === userId ? "You" : (otherParticipantName || "Them");
      return `[${new Date(msg.created_at).toLocaleDateString()}] ${sender}: ${msg.body}`;
    })
    .join("\n");

  return `Please analyze this conversation and provide a quick "catch me up" summary.

Focus on:
1. What were the main topics discussed?
2. Any questions they asked the user?
3. Any commitments/promises the user made?
4. Overall tone and emotional context
5. Most recent message for memory jogging

Conversation history:
\`\`\`
${formattedMessages}
\`\`\`

Important: 
- Be accurate - quote them directly when possible
- Be concise - this is for quickly catching up
- Flag action items and unanswered questions
- Consider emotional tone shifts`;
}

/**
 * Validate conversation summary result
 */
export function validateConversationSummary(
  result: any
): ConversationSummaryResult {
  if (!result) {
    throw new Error("No summary generated");
  }

  const validated: ConversationSummaryResult = {
    lastDiscussed: (result.lastDiscussed as string) || "",
    theirQuestions: Array.isArray(result.theirQuestions) 
      ? (result.theirQuestions as string[])
      : [],
    userCommitments: Array.isArray(result.userCommitments)
      ? (result.userCommitments as string[])
      : [],
    conversationTone: (result.conversationTone as string) || "neutral",
    lastMessageFromThem: (result.lastMessageFromThem as string) || "",
    keyPoints: Array.isArray(result.keyPoints)
      ? (result.keyPoints as string[])
      : [],
    emotionalContext: (result.emotionalContext as string) || "",
    suggestedResponseAngle: (result.suggestedResponseAngle as string) || "",
    confidence: Math.min(1.0, Math.max(0.0, (result.confidence as number) || 0.85)),
  };

  if (!validated.lastDiscussed) {
    throw new Error("Summary must include lastDiscussed");
  }

  return validated;
}

/**
 * Extract commitment phrases from conversation for Feature #4 integration
 */
export function extractCommitmentsFromConversation(
  messages: ConversationMessage[],
  userId: string
): string[] {
  const userMessages = messages.filter(m => m.sender_id === userId);
  
  const commitmentPatterns = [
    /i['ll]* (?:send|email|forward|share|give)/gi,
    /i['ll]* (?:call|text|message|reach out)/gi,
    /i['ll]* (?:check|verify|look at|review|examine)/gi,
    /i['ll]* (?:decide|choose|think about|consider)/gi,
    /i['ll]* (?:get back|follow up|update) (?:to|on)/gi,
    /i ['ll]* (?:schedule|book|plan|arrange|set up)/gi,
    /(?:should|can|will) [^.!?]*(?:send|call|check|decide|follow|schedule)/gi,
  ];

  const commitments: string[] = [];

  for (const msg of userMessages) {
    for (const pattern of commitmentPatterns) {
      const matches = msg.body.match(pattern);
      if (matches) {
        // Find the sentence containing the match
        const sentences = msg.body.split(/[.!?]+/);
        for (const sentence of sentences) {
          if (pattern.test(sentence)) {
            commitments.push(sentence.trim());
            pattern.lastIndex = 0; // Reset regex
          }
        }
      }
    }
  }

  return [...new Set(commitments)]; // Remove duplicates
}

/**
 * Extract unanswered questions from conversation
 */
export function extractUnansweredQuestions(
  messages: ConversationMessage[],
  userId: string
): string[] {
  const otherParticipantMessages = messages.filter(m => m.sender_id !== userId);
  
  const questions: string[] = [];

  for (const msg of otherParticipantMessages) {
    // Find sentences ending with ?
    const sentenceRegex = /[^.!?]*\?/g;
    const found = msg.body.match(sentenceRegex);
    
    if (found) {
      questions.push(...found.map(q => q.trim()));
    }
  }

  // Return unique questions
  return [...new Set(questions)];
}

/**
 * Determine conversation tone
 */
export function analyzeConversationTone(
  messages: ConversationMessage[]
): string {
  const toneIndicators: { [key: string]: number } = {
    excited: 0,
    concerned: 0,
    casual: 0,
    angry: 0,
    grateful: 0,
    sarcastic: 0,
    supportive: 0,
  };

  for (const msg of messages) {
    const text = msg.body.toLowerCase();

    // Simple pattern matching for tone
    if (/!!!|wow|amazing|love|great|awesome|fantastic/i.test(text)) {
      toneIndicators.excited += 2;
    }
    if (/\?\?|hmm|not sure|worried|concerned|anxious|sorry/i.test(text)) {
      toneIndicators.concerned += 2;
    }
    if (/lol|haha|joke|kidding|funny/i.test(text)) {
      toneIndicators.casual += 1;
    }
    if (/!!|really|absolutely|absolutely not|furious/i.test(text)) {
      toneIndicators.angry += 2;
    }
    if (/thank|thanks|appreciate|grateful/i.test(text)) {
      toneIndicators.grateful += 2;
    }
    if (/sure|yeah|ok|fine|totally|definitely/i.test(text)) {
      toneIndicators.supportive += 1;
    }
  }

  // Find dominant tone
  let dominantTone = "neutral";
  let maxScore = 0;

  for (const [tone, score] of Object.entries(toneIndicators)) {
    if (score > maxScore) {
      maxScore = score;
      dominantTone = tone;
    }
  }

  return dominantTone;
}

/**
 * Calculate confidence score for summary
 */
export function calculateSummaryConfidence(
  messagesCount: number,
  summaryCompleteness: number, // 0.0 to 1.0
  toneDominance: number // 0.0 to 1.0
): number {
  // More messages = more context = higher confidence
  const messageConfidence = Math.min(1.0, messagesCount / 50);
  
  // Average the factors
  const confidence = (messageConfidence + summaryCompleteness + toneDominance) / 3;
  
  return Math.min(1.0, Math.max(0.5, confidence)); // Between 0.5 and 1.0
}

/**
 * Format summary for display
 */
export function formatSummaryForDisplay(summary: ConversationSummaryResult): {
  quick: string;
  full: string;
} {
  const quick = `
📌 **Last Discussed:** ${summary.lastDiscussed}
💬 **Their Questions:** ${summary.theirQuestions.length > 0 ? summary.theirQuestions.join(", ") : "None"}
✅ **Your Commitments:** ${summary.userCommitments.length > 0 ? summary.userCommitments.join(", ") : "None"}
😊 **Tone:** ${summary.conversationTone}
  `.trim();

  const full = `
${quick}

📍 **Key Points:** ${summary.keyPoints.join(", ")}
❤️ **Emotional Context:** ${summary.emotionalContext}
💡 **How to Respond:** ${summary.suggestedResponseAngle}
"${summary.lastMessageFromThem}"
  `.trim();

  return { quick, full };
}
