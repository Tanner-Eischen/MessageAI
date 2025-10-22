/**
 * Quick check of messages table status
 * This doesn't require authentication
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function checkMessagesTable() {
  console.log('🔍 Checking Messages Table Configuration\n');
  console.log('═'.repeat(60));
  
  try {
    // Try to count messages (this will tell us if RLS is working)
    console.log('\n📊 Testing anonymous access to messages table...');
    const { data, error, count } = await supabase
      .from('messages')
      .select('*', { count: 'exact', head: false })
      .limit(0);
    
    if (error) {
      if (error.message.includes('JWT')) {
        console.log('✅ Table exists, RLS is enabled (expected)');
        console.log('   Error:', error.message);
      } else if (error.message.includes('relation') && error.message.includes('does not exist')) {
        console.log('❌ Messages table does NOT exist!');
        console.log('   You need to run migrations');
      } else {
        console.log('⚠️  Unexpected error:', error.message);
      }
    } else {
      console.log('⚠️  Warning: Anonymous access to messages is allowed');
      console.log('   This means RLS might not be properly configured');
    }
    
    console.log('\n' + '═'.repeat(60));
    console.log('📋 Next Steps:');
    console.log('═'.repeat(60));
    console.log('\n1. Check Flutter app logs when sending a message');
    console.log('2. Look for these log lines:');
    console.log('   📤 Attempting to sync message to backend: <message-id>');
    console.log('   ✅ Message synced to backend successfully');
    console.log('   OR');
    console.log('   ❌ Error syncing message to backend: <error>');
    console.log('\n3. Share the error message and I can help fix it!');
    
    console.log('\n💡 Most common issues:');
    console.log('   • User not authenticated (auth token expired)');
    console.log('   • User not a participant in conversation');
    console.log('   • RLS policy blocking insert');
    console.log('   • Network connectivity issue');
    
  } catch (error) {
    console.error('\n💥 Error:', error.message);
  }
}

checkMessagesTable();


