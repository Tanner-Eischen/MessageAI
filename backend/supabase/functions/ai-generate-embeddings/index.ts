import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { VectorSearch } from '../_shared/rag/vector-search.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      throw new Error('Unauthorized');
    }

    const body = await req.json();
    const { message_id, message_body, conversation_id, batch_mode } = body;

    console.log('🔮 Generating embeddings...');

    const vectorSearch = new VectorSearch();
    const results = {
      success: true,
      processed: 0,
      failed: 0,
      skipped: 0,
    };

    if (batch_mode && conversation_id) {
      // Batch mode: Generate embeddings for all messages in conversation
      console.log(`Batch processing conversation ${conversation_id}`);

      // Get all messages without embeddings
      const { data: messages } = await supabase
        .from('messages')
        .select('id, body, sender_id')
        .eq('conversation_id', conversation_id)
        .order('created_at', { ascending: true });

      if (!messages || messages.length === 0) {
        throw new Error('No messages found');
      }

      console.log(`Processing ${messages.length} messages`);

      for (const message of messages) {
        try {
          // Check if embedding exists
          const { data: existing } = await supabase
            .from('message_embeddings')
            .select('id')
            .eq('message_id', message.id)
            .single();

          if (existing) {
            results.skipped++;
            continue;
          }

          // Generate and store embedding
          const success = await vectorSearch.storeMessageEmbedding(
            message.id,
            message.body,
            message.sender_id,
            supabase
          );

          if (success) {
            results.processed++;
          } else {
            results.failed++;
          }

          // Rate limiting: small delay between requests
          await new Promise(resolve => setTimeout(resolve, 100));
        } catch (error) {
          console.error(`Error processing message ${message.id}:`, error);
          results.failed++;
        }
      }

      console.log(`✅ Batch complete: ${results.processed} processed, ${results.skipped} skipped, ${results.failed} failed`);
    } else if (message_id && message_body) {
      // Single message mode
      console.log(`Processing single message ${message_id}`);

      const success = await vectorSearch.storeMessageEmbedding(
        message_id,
        message_body,
        user.id,
        supabase
      );

      if (success) {
        results.processed = 1;
        console.log('✅ Embedding generated and stored');
      } else {
        results.failed = 1;
        throw new Error('Failed to generate embedding');
      }
    } else {
      throw new Error('Either provide message_id + message_body OR conversation_id with batch_mode=true');
    }

    return new Response(
      JSON.stringify(results),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('❌ Error generating embeddings:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});

