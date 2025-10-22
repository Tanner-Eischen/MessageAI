/**
 * MessageAI Comprehensive Diagnostic Test Suite
 * 
 * Tests:
 * 1. Database Connectivity
 * 2. Authentication
 * 3. Realtime Configuration
 * 4. Message Operations (CRUD)
 * 5. RLS Policies
 * 6. Subscriptions
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Test results storage
const results = {
  passed: [],
  failed: [],
  warnings: []
};

function pass(test, message) {
  results.passed.push({ test, message });
  console.log(`✅ ${test}: ${message}`);
}

function fail(test, message, error) {
  results.failed.push({ test, message, error: error?.message || error });
  console.log(`❌ ${test}: ${message}`);
  if (error) console.log(`   Error: ${error.message || error}`);
}

function warn(test, message) {
  results.warnings.push({ test, message });
  console.log(`⚠️  ${test}: ${message}`);
}

// Helper to create test user
async function createTestUser(email, password) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        email_verified: true
      }
    }
  });
  return { data, error };
}

// Helper to sign in
async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  return { data, error };
}

// Test 1: Database Connectivity
async function testDatabaseConnectivity() {
  console.log('\n🔍 TEST 1: Database Connectivity');
  console.log('━'.repeat(50));
  
  try {
    const { data, error } = await supabase.from('profiles').select('count');
    if (error) throw error;
    pass('Database Connection', 'Successfully connected to Supabase');
  } catch (error) {
    fail('Database Connection', 'Failed to connect to database', error);
  }
}

// Test 2: Authentication
async function testAuthentication() {
  console.log('\n🔍 TEST 2: Authentication');
  console.log('━'.repeat(50));
  
  const testEmail = `test_${Date.now()}@messageai.test`;
  const testPassword = 'TestPassword123!';
  
  try {
    // Test signup
    const { data: signUpData, error: signUpError } = await createTestUser(testEmail, testPassword);
    
    if (signUpError) {
      if (signUpError.message.includes('Email signups are disabled')) {
        fail('Signup', 'Email signups are disabled in Supabase Dashboard', signUpError);
        warn('Signup', 'Go to Authentication > Providers > Email and enable it');
        return null;
      }
      throw signUpError;
    }
    
    pass('Signup', `Created test user: ${testEmail}`);
    
    // Test signin
    const { data: signInData, error: signInError } = await signIn(testEmail, testPassword);
    if (signInError) throw signInError;
    
    pass('Signin', 'Successfully signed in');
    
    return signInData.user;
  } catch (error) {
    fail('Authentication', 'Failed authentication tests', error);
    return null;
  }
}

// Test 3: Realtime Configuration
async function testRealtimeConfiguration() {
  console.log('\n🔍 TEST 3: Realtime Configuration');
  console.log('━'.repeat(50));
  
  try {
    // Check if realtime is enabled by attempting to subscribe
    const channel = supabase.channel('test_channel');
    
    let subscribed = false;
    await new Promise((resolve) => {
      channel.subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          subscribed = true;
          pass('Realtime Basic', 'Realtime channels are working');
        } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
          fail('Realtime Basic', `Channel status: ${status}`);
        }
        resolve();
      });
      
      // Timeout after 5 seconds
      setTimeout(() => resolve(), 5000);
    });
    
    await supabase.removeChannel(channel);
    
    if (!subscribed) {
      warn('Realtime Basic', 'Realtime subscription timed out or failed');
    }
  } catch (error) {
    fail('Realtime Configuration', 'Failed to test realtime', error);
  }
}

// Test 4: Message Operations
async function testMessageOperations(user) {
  console.log('\n🔍 TEST 4: Message Operations');
  console.log('━'.repeat(50));
  
  if (!user) {
    warn('Message Operations', 'Skipped - no authenticated user');
    return null;
  }
  
  let conversationId = null;
  
  try {
    // Create a test conversation
    const { data: convData, error: convError } = await supabase
      .from('conversations')
      .insert({
        title: 'Test Conversation',
        is_group: false
      })
      .select()
      .single();
    
    if (convError) throw convError;
    conversationId = convData.id;
    pass('Create Conversation', `Created conversation: ${conversationId}`);
    
    // Add user as participant
    const { error: partError } = await supabase
      .from('conversation_participants')
      .insert({
        conversation_id: conversationId,
        user_id: user.id
      });
    
    if (partError) throw partError;
    pass('Add Participant', 'Added user as participant');
    
    // Insert a test message
    const { data: msgData, error: msgError } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        sender_id: user.id,
        body: 'Test message for diagnostics'
      })
      .select()
      .single();
    
    if (msgError) throw msgError;
    pass('Insert Message', `Inserted message: ${msgData.id}`);
    
    // Read the message back
    const { data: readMsg, error: readError } = await supabase
      .from('messages')
      .select('*')
      .eq('id', msgData.id)
      .single();
    
    if (readError) throw readError;
    pass('Read Message', 'Successfully read message back');
    
    // Update the message
    const { error: updateError } = await supabase
      .from('messages')
      .update({ body: 'Updated test message' })
      .eq('id', msgData.id);
    
    if (updateError) throw updateError;
    pass('Update Message', 'Successfully updated message');
    
    return conversationId;
  } catch (error) {
    fail('Message Operations', 'Failed message operations', error);
    return conversationId;
  }
}

// Test 5: RLS Policies
async function testRLSPolicies(user, conversationId) {
  console.log('\n🔍 TEST 5: Row Level Security (RLS) Policies');
  console.log('━'.repeat(50));
  
  if (!user || !conversationId) {
    warn('RLS Policies', 'Skipped - no authenticated user or conversation');
    return;
  }
  
  try {
    // Test: Can read own messages
    const { data: ownMessages, error: ownError } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId);
    
    if (ownError) throw ownError;
    pass('RLS Read Own Messages', `Can read own messages (${ownMessages.length} found)`);
    
    // Test: Can read conversation participants
    const { data: participants, error: partError } = await supabase
      .from('conversation_participants')
      .select('*')
      .eq('conversation_id', conversationId);
    
    if (partError) throw partError;
    pass('RLS Read Participants', `Can read participants (${participants.length} found)`);
    
  } catch (error) {
    fail('RLS Policies', 'Failed RLS policy tests', error);
  }
}

// Test 6: Realtime Subscriptions
async function testRealtimeSubscriptions(conversationId) {
  console.log('\n🔍 TEST 6: Realtime Message Subscriptions');
  console.log('━'.repeat(50));
  
  if (!conversationId) {
    warn('Realtime Subscriptions', 'Skipped - no conversation available');
    return;
  }
  
  try {
    let messageReceived = false;
    
    const channel = supabase
      .channel(`messages:${conversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${conversationId}`
        },
        (payload) => {
          messageReceived = true;
          pass('Realtime Message Insert', 'Received realtime message insert event');
        }
      );
    
    await new Promise((resolve) => {
      channel.subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          pass('Realtime Subscribe', 'Successfully subscribed to messages channel');
        } else if (status === 'CLOSED') {
          fail('Realtime Subscribe', 'Channel closed - Realtime may not be enabled for messages table');
          warn('Realtime Subscribe', 'Go to Database > Replication and enable "messages" table');
        } else if (status === 'CHANNEL_ERROR') {
          fail('Realtime Subscribe', 'Channel error - check Realtime configuration');
        }
        
        setTimeout(() => resolve(), 2000);
      });
    });
    
    await supabase.removeChannel(channel);
    
  } catch (error) {
    fail('Realtime Subscriptions', 'Failed realtime subscription test', error);
  }
}

// Test 7: Check Supabase Configuration
async function testSupabaseConfiguration() {
  console.log('\n🔍 TEST 7: Supabase Configuration');
  console.log('━'.repeat(50));
  
  // Check if URL and keys are valid
  if (SUPABASE_URL.includes('localhost')) {
    warn('Supabase URL', 'Using localhost - make sure local Supabase is running');
  } else if (SUPABASE_URL.includes('.supabase.co')) {
    pass('Supabase URL', 'Using hosted Supabase instance');
  } else {
    warn('Supabase URL', 'Non-standard Supabase URL detected');
  }
  
  if (SUPABASE_ANON_KEY.length > 100) {
    pass('Supabase Keys', 'Anon key format looks valid');
  } else {
    warn('Supabase Keys', 'Anon key seems too short - verify it is correct');
  }
}

// Test 8: Database Schema
async function testDatabaseSchema() {
  console.log('\n🔍 TEST 8: Database Schema');
  console.log('━'.repeat(50));
  
  const tables = ['profiles', 'conversations', 'conversation_participants', 'messages', 'message_receipts'];
  
  for (const table of tables) {
    try {
      const { data, error } = await supabase.from(table).select('*').limit(0);
      if (error) throw error;
      pass(`Schema: ${table}`, `Table exists and is accessible`);
    } catch (error) {
      fail(`Schema: ${table}`, `Table missing or not accessible`, error);
    }
  }
}

// Cleanup function
async function cleanup(conversationId) {
  console.log('\n🧹 Cleaning up test data...');
  
  try {
    if (conversationId) {
      // Delete messages
      await supabase.from('messages').delete().eq('conversation_id', conversationId);
      // Delete participants
      await supabase.from('conversation_participants').delete().eq('conversation_id', conversationId);
      // Delete conversation
      await supabase.from('conversations').delete().eq('id', conversationId);
    }
    
    // Sign out
    await supabase.auth.signOut();
    
    console.log('✅ Cleanup completed');
  } catch (error) {
    console.log('⚠️  Cleanup had errors (non-critical):', error.message);
  }
}

// Print summary
function printSummary() {
  console.log('\n');
  console.log('═'.repeat(50));
  console.log('📊 DIAGNOSTIC SUMMARY');
  console.log('═'.repeat(50));
  console.log(`✅ Passed: ${results.passed.length}`);
  console.log(`❌ Failed: ${results.failed.length}`);
  console.log(`⚠️  Warnings: ${results.warnings.length}`);
  console.log('═'.repeat(50));
  
  if (results.failed.length > 0) {
    console.log('\n🔴 CRITICAL ISSUES:');
    results.failed.forEach(({ test, message, error }) => {
      console.log(`\n❌ ${test}`);
      console.log(`   ${message}`);
      if (error) console.log(`   Error: ${error}`);
    });
  }
  
  if (results.warnings.length > 0) {
    console.log('\n⚠️  WARNINGS:');
    results.warnings.forEach(({ test, message }) => {
      console.log(`\n⚠️  ${test}`);
      console.log(`   ${message}`);
    });
  }
  
  if (results.failed.length === 0 && results.warnings.length === 0) {
    console.log('\n🎉 All tests passed! Your MessageAI setup looks great!');
  } else {
    console.log('\n💡 RECOMMENDATIONS:');
    
    if (results.failed.some(r => r.test.includes('Realtime'))) {
      console.log('   1. Enable Realtime for "messages" table:');
      console.log('      → Go to Supabase Dashboard > Database > Replication');
      console.log('      → Enable the "messages" table');
    }
    
    if (results.failed.some(r => r.test.includes('Signup'))) {
      console.log('   2. Enable Email Authentication:');
      console.log('      → Go to Supabase Dashboard > Authentication > Providers');
      console.log('      → Enable Email provider');
      console.log('      → Disable "Confirm Email" if testing locally');
    }
    
    if (results.failed.some(r => r.test.includes('RLS'))) {
      console.log('   3. Check Row Level Security policies:');
      console.log('      → Ensure policies are applied to all tables');
      console.log('      → Run migrations if needed');
    }
  }
  
  console.log('\n');
}

// Main test runner
async function runAllTests() {
  console.log('🚀 MessageAI Comprehensive Diagnostic Test Suite');
  console.log('═'.repeat(50));
  console.log(`📍 Testing against: ${SUPABASE_URL}`);
  console.log('═'.repeat(50));
  
  let user = null;
  let conversationId = null;
  
  try {
    await testSupabaseConfiguration();
    await testDatabaseConnectivity();
    await testDatabaseSchema();
    user = await testAuthentication();
    await testRealtimeConfiguration();
    conversationId = await testMessageOperations(user);
    await testRLSPolicies(user, conversationId);
    await testRealtimeSubscriptions(conversationId);
  } catch (error) {
    console.error('\n💥 Unexpected error during tests:', error);
  } finally {
    await cleanup(conversationId);
    printSummary();
  }
}

// Run tests
runAllTests().catch(console.error);


