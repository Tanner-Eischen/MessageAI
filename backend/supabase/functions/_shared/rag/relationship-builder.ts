/**
 * Builds and maintains relationship profiles
 */

import { OpenAIClient } from '../openai-client.ts';

export interface RelationshipProfile {
  participant_name: string;
  relationship_type: string;
  conversation_summary: string;
  safe_topics: string[];
  topics_to_avoid: string[];
  communication_style: string;
}

export const RELATIONSHIP_BUILDER_PROMPT = `Analyze this conversation history and create a relationship profile.

**Your task:**
1. Summarize the relationship in 2-3 sentences
2. Identify the relationship type (boss, colleague, friend, family, client, other)
3. Extract safe topics (topics that led to positive engagement)
4. Identify topics to avoid (if any caused tension)
5. Describe their communication style

**Relationship Types:**
- boss: Manager or supervisor
- colleague: Coworker or professional peer
- friend: Personal friend
- family: Family member
- client: Customer or client
- other: Other relationship type

**Response Format (JSON):**
{
  "relationship_type": "colleague",
  "conversation_summary": "Sarah is a coworker from the marketing team. You collaborate on project launches and she often asks for design feedback. Communication is professional but friendly.",
  "safe_topics": ["project launches", "design feedback", "team events"],
  "topics_to_avoid": [],
  "communication_style": "Direct and efficient. Prefers email for detailed requests, chat for quick questions. Usually responds within an hour during work hours."
}

**Instructions:**
- Be specific and helpful
- Include timing patterns if visible
- Note communication preferences
- Identify at least 3 safe topics
- Only list topics to avoid if there's clear evidence`;

export class RelationshipBuilder {
  private openai: OpenAIClient;

  constructor() {
    this.openai = new OpenAIClient();
  }

  /**
   * Build relationship profile from conversation history
   */
  async buildProfile(
    conversationHistory: Array<{ body: string; sender: string; created_at: number }>,
    participantName: string
  ): Promise<RelationshipProfile> {
    // Take last 50 messages for context
    const recentMessages = conversationHistory.slice(-50);
    
    if (recentMessages.length === 0) {
      throw new Error('No messages to analyze');
    }

    let userPrompt = `**Conversation History with ${participantName}:**\n\n`;
    recentMessages.forEach((msg, idx) => {
      const sender = msg.sender === 'self' ? 'You' : participantName;
      userPrompt += `${idx + 1}. [${sender}]: ${msg.body}\n`;
    });
    
    userPrompt += '\n\nAnalyze this conversation and create a relationship profile in JSON format.';

    console.log(`Building profile for ${participantName} (${recentMessages.length} messages)`);

    const result = await this.openai.sendMessageForJSON<RelationshipProfile>(
      userPrompt,
      RELATIONSHIP_BUILDER_PROMPT,
      { temperature: 0.3, max_tokens: 800 }
    );

    // Validate result
    if (!result.relationship_type || !result.conversation_summary) {
      throw new Error('Invalid relationship profile generated');
    }

    return {
      participant_name: participantName,
      relationship_type: result.relationship_type,
      conversation_summary: result.conversation_summary,
      safe_topics: result.safe_topics || [],
      topics_to_avoid: result.topics_to_avoid || [],
      communication_style: result.communication_style || 'Unknown',
    };
  }

  /**
   * Extract key topics from conversation
   */
  async extractTopics(messages: string[]): Promise<string[]> {
    if (messages.length === 0) return [];

    const prompt = `Extract 3-5 main topics discussed in these messages:\n\n`;
    const recentMessages = messages.slice(-20);
    recentMessages.forEach((msg, idx) => {
      prompt += `${idx + 1}. ${msg}\n`;
    });
    
    prompt += '\n\nReturn ONLY a JSON array of topics: ["topic1", "topic2", "topic3"]';

    try {
      const result = await this.openai.sendMessage(prompt, {
        temperature: 0.3,
        max_tokens: 200,
      });

      const topics = JSON.parse(result);
      if (Array.isArray(topics)) {
        return topics.filter(t => typeof t === 'string');
      }
      return [];
    } catch (error) {
      console.error('Error extracting topics:', error);
      return [];
    }
  }

  /**
   * Update profile with new conversation data
   */
  async updateProfile(
    existingProfile: RelationshipProfile,
    recentMessages: Array<{ body: string; sender: string }>,
    participantName: string
  ): Promise<Partial<RelationshipProfile>> {
    const prompt = `**Existing Profile for ${participantName}:**
${JSON.stringify(existingProfile, null, 2)}

**Recent Messages:**
${recentMessages.map((m, i) => `${i + 1}. [${m.sender}]: ${m.body}`).join('\n')}

Update the profile based on these new messages. Return ONLY the fields that have changed.
If nothing needs updating, return an empty object {}.

Response format (JSON):
{
  "conversation_summary": "updated summary if needed",
  "safe_topics": ["new topics to add"],
  "communication_style": "updated style if needed"
}`;

    try {
      const result = await this.openai.sendMessageForJSON(
        prompt,
        'You are updating a relationship profile. Only include fields that have changed.',
        { temperature: 0.3, max_tokens: 500 }
      );

      return result;
    } catch (error) {
      console.error('Error updating profile:', error);
      return {};
    }
  }

  /**
   * Calculate typical response time from conversation history
   */
  calculateResponseTime(
    messages: Array<{ sender: string; created_at: number }>
  ): number | null {
    const responseTimes: number[] = [];
    
    for (let i = 1; i < messages.length; i++) {
      const prev = messages[i - 1];
      const curr = messages[i];
      
      // Check if this is a response (different sender)
      if (prev.sender !== curr.sender && curr.sender !== 'self') {
        const timeDiff = curr.created_at - prev.created_at;
        // Only count responses within 24 hours
        if (timeDiff > 0 && timeDiff < 86400) {
          responseTimes.push(timeDiff);
        }
      }
    }

    if (responseTimes.length === 0) return null;

    // Return median response time
    responseTimes.sort((a, b) => a - b);
    const mid = Math.floor(responseTimes.length / 2);
    return responseTimes[mid];
  }
}

