/**
 * OpenAI API Client
 * Provides type-safe wrapper for GPT-4 interactions
 */

export interface OpenAIMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

export interface OpenAIResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: {
      role: string;
      content: string;
    };
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export interface OpenAIRequestOptions {
  model?: string;
  temperature?: number;
  max_tokens?: number;
  response_format?: { type: 'json_object' };
}

export class OpenAIClient {
  private apiKey: string;
  private baseUrl = 'https://api.openai.com/v1/chat/completions';
  private defaultModel = 'gpt-4-turbo-preview';

  constructor(apiKey: string) {
    if (!apiKey) {
      throw new Error('OpenAI API key is required');
    }
    this.apiKey = apiKey;
  }

  /**
   * Send messages to GPT-4 and get a response
   */
  async sendMessages(
    messages: OpenAIMessage[],
    options: OpenAIRequestOptions = {}
  ): Promise<OpenAIResponse> {
    const {
      model = this.defaultModel,
      temperature = 0.7,
      max_tokens = 1000,
      response_format,
    } = options;

    const requestBody: any = {
      model,
      messages,
      temperature,
      max_tokens,
    };

    if (response_format) {
      requestBody.response_format = response_format;
    }

    try {
      const response = await fetch(this.baseUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(
          `OpenAI API error (${response.status}): ${errorBody}`
        );
      }

      const data: OpenAIResponse = await response.json();
      return data;
    } catch (error) {
      if (error instanceof Error) {
        throw new Error(`Failed to call OpenAI API: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Extract text content from the response
   */
  extractTextContent(response: OpenAIResponse): string {
    const content = response.choices[0]?.message?.content || '';
    if (!content) {
      console.warn("⚠️ Empty response content from OpenAI");
    }
    return content;
  }

  /**
   * Send a simple single-turn message and get text response
   */
  async sendSimpleMessage(
    userMessage: string,
    systemPrompt?: string,
    options: Partial<OpenAIRequestOptions> = {}
  ): Promise<string> {
    const messages: OpenAIMessage[] = [];
    
    if (systemPrompt) {
      messages.push({
        role: 'system',
        content: systemPrompt,
      });
    }
    
    messages.push({
      role: 'user',
      content: userMessage,
    });

    const response = await this.sendMessages(messages, options);
    return this.extractTextContent(response);
  }

  /**
   * Parse JSON from GPT's response
   * Handles cases where GPT wraps JSON in markdown code blocks
   */
  parseJSONResponse<T>(responseText: string): T {
    // Remove markdown code blocks if present
    let cleaned = responseText.trim();
    
    // Log the raw response for debugging
    console.log("🔍 Raw response from OpenAI:", cleaned.substring(0, 200) + (cleaned.length > 200 ? "..." : ""));
    
    // Remove ```json and ``` markers
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.slice(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.slice(3);
    }
    
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.slice(0, -3);
    }
    
    cleaned = cleaned.trim();
    
    console.log("✨ Cleaned response:", cleaned.substring(0, 200) + (cleaned.length > 200 ? "..." : ""));
    
    try {
      const parsed = JSON.parse(cleaned) as T;
      console.log("✅ JSON parsed successfully");
      return parsed;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      const contextSize = 500;
      const errorContext = cleaned.length > contextSize 
        ? cleaned.substring(0, contextSize) + "\n... [truncated]"
        : cleaned;
      
      console.error("❌ JSON parsing failed!");
      console.error("Error:", errorMsg);
      console.error("Response context:", errorContext);
      
      throw new Error(
        `Failed to parse JSON response: ${errorMsg}\n` +
        `Response preview: ${errorContext}`
      );
    }
  }

  /**
   * Send a message and parse JSON response
   * Uses OpenAI's structured JSON output mode for reliable formatting
   */
  async sendMessageForJSON<T>(
    userMessage: string,
    systemPrompt: string,
    options: Partial<OpenAIRequestOptions> = {}
  ): Promise<T> {
    try {
      console.log("📤 Preparing JSON request to OpenAI...");
      console.log("System prompt length:", systemPrompt.length);
      console.log("User message length:", userMessage.length);
      
      const responseText = await this.sendSimpleMessage(
        userMessage,
        systemPrompt,
        {
          ...options,
          temperature: 0.3, // Lower temperature for more consistent JSON
          response_format: { type: 'json_object' }, // Request JSON format
        }
      );

      console.log("📥 Received response from OpenAI, attempting to parse...");
      const result = this.parseJSONResponse<T>(responseText);
      console.log("🎯 Successfully parsed JSON response");
      return result;
    } catch (error) {
      console.error("💥 Failed to get JSON response:", error);
      throw error;
    }
  }
}

/**
 * Create an OpenAI client with API key from environment
 */
export function createOpenAIClient(): OpenAIClient {
  const apiKey = Deno.env.get('OPENAI_API_KEY');
  
  if (!apiKey) {
    throw new Error(
      'OPENAI_API_KEY environment variable is not set. ' +
      'Please configure it in Supabase Edge Function secrets.'
    );
  }

  return new OpenAIClient(apiKey);
}


