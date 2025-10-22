/**
 * Message Insert Diagnostic Test
 * 
 * Tests specifically why messages aren't inserting into Supabase
 */

const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function testMessageInsert() {
  console.log('🔍 Testing Message Insert to Supabase\n');
  console.log('═'.repeat(60));
  
  try {
    // Step 1: Sign in (use an existing user email)
    console.log('\n📝 Step 1: Enter your test user credentials');
    console.log('Use the email you logged in with on the emulator');
    
    // You'll need to replace these with actual credentials
    const testEmail = 'tannereischen@gmail.com';
    const testPassword = 'password';
    
    console.log(`\n🔐 Signing in as: ${testEmail}`);
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: testEmail,
      password: testPassword
    });
    
    if (authError) {
      console.log('❌ Authentication failed:', authError.message);
      console.log('\n💡 TIP: Update testEmail and testPassword in test_message_insert.js');
      return;
    }
    
    console.log('✅ Authenticated as:', authData.user.email);
    console.log('   User ID:', authData.user.id);
    
    // Step 2: Check if user has any conversations
    console.log('\n📋 Step 2: Checking conversations...');
    const { data: conversations, error: convError } = await supabase
      .from('conversation_participants')
      .select('conversation_id, conversations(*)')
      .eq('user_id', authData.user.id);
    
    if (convError) {
      console.log('❌ Error fetching conversations:', convError.message);
      return;
    }
    
    console.log(`✅ Found ${conversations.length} conversation(s)`);
    
    if (conversations.length === 0) {
      console.log('\n⚠️  No conversations found!');
      console.log('   You need to create a conversation first in the app.');
      return;
    }
    
    const conversationId = conversations[0].conversation_id;
    console.log('   Using conversation:', conversationId);
    
    // Step 3: Check RLS policies
    console.log('\n🔒 Step 3: Checking RLS policies...');
    
    // Try to read messages (should work if user is participant)
    const { data: readTest, error: readError } = await supabase
      .from('messages')
      .select('*')
      .eq('conversation_id', conversationId)
      .limit(1);
    
    if (readError) {
      console.log('❌ Cannot read messages:', readError.message);
      console.log('   This means RLS is blocking SELECT');
    } else {
      console.log('✅ Can read messages - RLS SELECT policy OK');
    }
    
    // Step 4: Try to insert a test message
    console.log('\n📤 Step 4: Attempting to insert test message...');
    
    const testMessage = {
      id: uuidv4(), // Proper UUID format
      conversation_id: conversationId,
      sender_id: authData.user.id,
      body: 'Test message from diagnostic script',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    console.log('   Message payload:');
    console.log('   ', JSON.stringify(testMessage, null, 2));
    
    const { data: insertData, error: insertError } = await supabase
      .from('messages')
      .insert(testMessage)
      .select();
    
    if (insertError) {
      console.log('\n❌ MESSAGE INSERT FAILED!');
      console.log('   Error:', insertError.message);
      console.log('   Code:', insertError.code);
      console.log('   Details:', insertError.details);
      console.log('   Hint:', insertError.hint);
      
      // Common issues and solutions
      console.log('\n🔍 Common Issues:');
      
      if (insertError.message.includes('row-level security')) {
        console.log('\n   🔴 RLS Policy Issue');
        console.log('   The user is blocked from inserting messages.');
        console.log('\n   Possible causes:');
        console.log('   1. User is not a participant in the conversation');
        console.log('   2. RLS policy is too restrictive');
        console.log('   3. Policy check is failing');
        
        // Check if user is actually a participant
        const { data: partCheck } = await supabase
          .from('conversation_participants')
          .select('*')
          .eq('conversation_id', conversationId)
          .eq('user_id', authData.user.id);
        
        if (partCheck && partCheck.length > 0) {
          console.log('\n   ✅ User IS a participant');
          console.log('   🔴 But RLS policy is still blocking!');
          console.log('\n   FIX: Check the messages RLS policy in Supabase Dashboard');
          console.log('   Go to: Database > Tables > messages > RLS Policies');
        } else {
          console.log('\n   ❌ User is NOT a participant!');
          console.log('   FIX: Add user as participant to the conversation');
        }
      }
      
      if (insertError.message.includes('duplicate key')) {
        console.log('\n   ⚠️  Duplicate ID');
        console.log('   The message ID already exists');
      }
      
      if (insertError.message.includes('foreign key')) {
        console.log('\n   ⚠️  Foreign Key Violation');
        console.log('   The conversation or user does not exist');
      }
    } else {
      console.log('\n✅ MESSAGE INSERTED SUCCESSFULLY!');
      console.log('   Message ID:', insertData[0].id);
      console.log('   Body:', insertData[0].body);
      
      // Clean up - delete test message
      await supabase.from('messages').delete().eq('id', testMessage.id);
      console.log('   (Test message deleted)');
    }
    
    // Step 5: Summary
    console.log('\n' + '═'.repeat(60));
    console.log('📊 SUMMARY');
    console.log('═'.repeat(60));
    
    if (insertError) {
      console.log('❌ Messages are NOT inserting into Supabase');
      console.log('🔴 Issue:', insertError.message);
      console.log('\n💡 NEXT STEPS:');
      console.log('   1. Check RLS policies for messages table');
      console.log('   2. Verify user is a participant in conversations');
      console.log('   3. Check Flutter app logs for similar errors');
    } else {
      console.log('✅ Messages CAN insert into Supabase');
      console.log('🎯 The database configuration is correct!');
      console.log('\n💡 If messages still don\'t sync from Flutter:');
      console.log('   1. Check Flutter app logs for errors');
      console.log('   2. Verify network connectivity');
      console.log('   3. Check if auth token is valid');
    }
    
  } catch (error) {
    console.error('\n💥 Unexpected error:', error);
  }
}

// Run the test
testMessageInsert();

