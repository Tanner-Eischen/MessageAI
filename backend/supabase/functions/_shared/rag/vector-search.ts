/**
 * Vector search functionality using pgvector
 */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { EmbeddingGenerator } from './embedding-generator.ts';

export interface SearchResult {
  message_id: string;
  similarity: number;
  message_body: string;
  created_at: string;
}

export interface SearchOptions {
  limit?: number;
  similarity_threshold?: number; // 0.0-1.0
  conversation_id?: string;
}

export class VectorSearch {
  private embeddingGenerator: EmbeddingGenerator;

  constructor() {
    this.embeddingGenerator = new EmbeddingGenerator();
  }

  /**
   * Search for similar messages using semantic search
   */
  async searchMessages(
    query: string,
    userId: string,
    supabase: SupabaseClient,
    options: SearchOptions = {}
  ): Promise<SearchResult[]> {
    const {
      limit = 5,
      similarity_threshold = 0.7,
      conversation_id,
    } = options;

    console.log(`Searching for: "${query}" (threshold: ${similarity_threshold})`);

    // Generate embedding for query
    const preprocessed = this.embeddingGenerator.preprocessText(query);
    const { embedding } = await this.embeddingGenerator.generateEmbedding(preprocessed);

    console.log(`Generated embedding (${embedding.length} dimensions)`);

    // Search using RPC function
    const { data, error } = await supabase.rpc('search_similar_messages', {
      p_user_id: userId,
      p_query_embedding: embedding,
      p_limit: limit * 2, // Get more, filter by threshold
      p_conversation_id: conversation_id || null,
    });

    if (error) {
      console.error('Error searching messages:', error);
      throw error;
    }

    console.log(`Found ${data?.length || 0} results`);

    // Filter by similarity threshold
    const filtered = (data || [])
      .filter((result: SearchResult) => result.similarity >= similarity_threshold)
      .slice(0, limit);

    console.log(`Filtered to ${filtered.length} results above threshold`);

    return filtered;
  }

  /**
   * Find related conversations based on topic
   */
  async findRelatedConversations(
    topic: string,
    userId: string,
    supabase: SupabaseClient
  ): Promise<string[]> {
    const results = await this.searchMessages(topic, userId, supabase, {
      limit: 10,
      similarity_threshold: 0.75,
    });

    // Extract unique conversation IDs
    const conversationIds = new Set<string>();
    for (const result of results) {
      const { data } = await supabase
        .from('messages')
        .select('conversation_id')
        .eq('id', result.message_id)
        .single();
      
      if (data) {
        conversationIds.add(data.conversation_id);
      }
    }

    return Array.from(conversationIds);
  }

  /**
   * Store message embedding
   */
  async storeMessageEmbedding(
    messageId: string,
    messageBody: string,
    userId: string,
    supabase: SupabaseClient
  ): Promise<boolean> {
    try {
      // Check if embedding already exists
      const { data: existing } = await supabase
        .from('message_embeddings')
        .select('id')
        .eq('message_id', messageId)
        .single();

      if (existing) {
        console.log(`Embedding already exists for message ${messageId}`);
        return true;
      }

      // Generate embedding
      const preprocessed = this.embeddingGenerator.preprocessText(messageBody);
      if (!this.embeddingGenerator.isValidText(preprocessed)) {
        console.log(`Message ${messageId} not suitable for embedding`);
        return false;
      }

      const { embedding } = await this.embeddingGenerator.generateEmbedding(preprocessed);

      // Store in database
      const { error } = await supabase
        .from('message_embeddings')
        .insert({
          message_id: messageId,
          user_id: userId,
          embedding: embedding,
          message_length: messageBody.length,
        });

      if (error) {
        console.error('Error storing embedding:', error);
        return false;
      }

      console.log(`Stored embedding for message ${messageId}`);
      return true;
    } catch (error) {
      console.error('Error in storeMessageEmbedding:', error);
      return false;
    }
  }
}

