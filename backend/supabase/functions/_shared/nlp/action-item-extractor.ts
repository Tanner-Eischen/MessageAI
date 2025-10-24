/**
 * Extracts action items from messages
 * Detects implicit commitments like "I'll send you..."
 */

import { OpenAIClient } from '../openai-client.ts';

export interface ActionItem {
  action_type: string; // send, call, meet, review, etc.
  action_target: string; // What/who
  commitment_text: string; // Original text
  mentioned_deadline?: string; // "this afternoon"
  confidence: number; // 0.0-1.0
}

export const ACTION_ITEM_EXTRACTION_PROMPT = `You are an expert at identifying commitments and action items in conversations.

**Your task:** Extract action items from messages where someone commits to doing something.

**Action Types:**
- **send**: Sending something (email, file, link, message)
- **call**: Making a phone call
- **meet**: Meeting in person or video
- **review**: Reviewing/reading something
- **decide**: Making a decision
- **follow_up**: Following up later
- **check**: Checking on something
- **schedule**: Scheduling something
- **other**: Other commitment

**Examples:**

Input: "I'll send you the report this afternoon"
Output:
{
  "action_type": "send",
  "action_target": "report",
  "commitment_text": "I'll send you the report this afternoon",
  "mentioned_deadline": "this afternoon",
  "confidence": 0.95
}

Input: "Let me check and get back to you tomorrow"
Output:
{
  "action_type": "follow_up",
  "action_target": "answer to question",
  "commitment_text": "Let me check and get back to you tomorrow",
  "mentioned_deadline": "tomorrow",
  "confidence": 0.90
}

Input: "We should grab coffee sometime"
Output:
{
  "action_type": "meet",
  "action_target": "coffee meeting",
  "commitment_text": "We should grab coffee sometime",
  "mentioned_deadline": null,
  "confidence": 0.70
}

**Commitment Indicators:**
- "I'll", "I will"
- "Let me"
- "I can"
- "I'm going to"
- "I need to"
- "I should"
- "We should"

**Response Format:**
Return array of action items. If no commitments found, return empty array: []`;

export class ActionItemExtractor {
  private openai: OpenAIClient;

  constructor() {
    this.openai = new OpenAIClient();
  }

  /**
   * Extract action items from message
   */
  async extractActionItems(
    messageBody: string,
    senderId: string,
    currentUserId: string
  ): Promise<ActionItem[]> {
    // Only extract from user's own messages
    if (senderId !== currentUserId) {
      return [];
    }

    // Quick check for commitment indicators
    const hasCommitment = [
      "i'll", "i will", "let me", "i can", "i'm going to",
      "i need to", "i should", "we should"
    ].some(indicator => messageBody.toLowerCase().includes(indicator));

    if (!hasCommitment) {
      return [];
    }

    try {
      const userPrompt = `Extract action items from this message:\n\n"${messageBody}"`;
      
      const result = await this.openai.sendMessageForJSON<ActionItem[]>(
        userPrompt,
        ACTION_ITEM_EXTRACTION_PROMPT,
        { temperature: 0.2, max_tokens: 500 }
      );

      // Filter by confidence threshold
      return (Array.isArray(result) ? result : [])
        .filter(item => item.confidence >= 0.7);
    } catch (error) {
      console.error('Error extracting action items:', error);
      return [];
    }
  }

  /**
   * Parse deadline from natural language
   */
  parseDeadline(deadlineText: string): number | null {
    const now = Math.floor(Date.now() / 1000);
    const lowerText = deadlineText.toLowerCase();

    // Today
    if (lowerText.includes('today') || lowerText.includes('this afternoon')) {
      return now + 6 * 3600; // 6 hours from now
    }

    // Tomorrow
    if (lowerText.includes('tomorrow')) {
      return now + 24 * 3600;
    }

    // This week
    if (lowerText.includes('this week') || lowerText.includes('by friday')) {
      return now + 5 * 24 * 3600; // 5 days
    }

    // Next week
    if (lowerText.includes('next week')) {
      return now + 7 * 24 * 3600;
    }

    // Fallback: 2 days
    return now + 2 * 24 * 3600;
  }
}

