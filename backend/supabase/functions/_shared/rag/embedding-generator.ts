/**
 * Generates OpenAI embeddings for semantic search
 */

export interface EmbeddingResult {
  embedding: number[];
  model: string;
  tokens_used: number;
}

export class EmbeddingGenerator {
  private apiKey: string;

  constructor() {
    const key = Deno.env.get('OPENAI_API_KEY');
    if (!key) {
      throw new Error('OPENAI_API_KEY not found in environment');
    }
    this.apiKey = key;
  }

  /**
   * Generate embedding for a single text
   */
  async generateEmbedding(text: string): Promise<EmbeddingResult> {
    try {
      const response = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          input: text,
          model: 'text-embedding-ada-002',
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenAI API error: ${response.statusText} - ${errorText}`);
      }

      const data = await response.json();
      
      return {
        embedding: data.data[0].embedding,
        model: data.model,
        tokens_used: data.usage.total_tokens,
      };
    } catch (error) {
      console.error('Error generating embedding:', error);
      throw error;
    }
  }

  /**
   * Generate embeddings for multiple texts (batch)
   */
  async generateEmbeddings(texts: string[]): Promise<EmbeddingResult[]> {
    // OpenAI allows batch embeddings
    try {
      const response = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          input: texts,
          model: 'text-embedding-ada-002',
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenAI API error: ${response.statusText} - ${errorText}`);
      }

      const data = await response.json();
      
      return data.data.map((item: any) => ({
        embedding: item.embedding,
        model: data.model,
        tokens_used: Math.ceil(data.usage.total_tokens / texts.length),
      }));
    } catch (error) {
      console.error('Error generating embeddings:', error);
      throw error;
    }
  }

  /**
   * Preprocess text for embedding
   * Removes noise and normalizes
   */
  preprocessText(text: string): string {
    // Remove excessive whitespace
    let processed = text.replace(/\s+/g, ' ').trim();
    
    // Remove URLs (they don't add semantic meaning)
    processed = processed.replace(/https?:\/\/\S+/g, '[link]');
    
    // Remove emails
    processed = processed.replace(/[\w.+-]+@[\w-]+\.[\w.-]+/g, '[email]');
    
    // Truncate to max tokens (8191 for ada-002)
    // Rough estimate: 1 token ≈ 4 characters
    const maxChars = 8191 * 4;
    if (processed.length > maxChars) {
      processed = processed.substring(0, maxChars);
    }
    
    return processed;
  }

  /**
   * Check if text is suitable for embedding
   */
  isValidText(text: string): boolean {
    if (!text || text.trim().length === 0) return false;
    if (text.length < 10) return false; // Too short
    if (text.length > 50000) return false; // Too long
    return true;
  }
}

