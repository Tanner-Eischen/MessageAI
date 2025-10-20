# Phase 02 — DB Schema & RLS

## Summary

This phase creates the complete PostgreSQL database schema with Row Level Security (RLS) policies, enabling secure multi-tenant data isolation.

## Database Schema

### Tables

#### 1. **profiles**
Stores user profile information linked to Firebase Auth.

```sql
profiles (
  id UUID PRIMARY KEY,
  user_id UUID UNIQUE,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

#### 2. **conversations**
Stores individual or group conversations.

```sql
conversations (
  id UUID PRIMARY KEY,
  title TEXT,
  description TEXT,
  is_group BOOLEAN,
  created_by UUID (FK → profiles.user_id),
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

#### 3. **conversation_participants**
Tracks membership and read status for conversations.

```sql
conversation_participants (
  id UUID PRIMARY KEY,
  conversation_id UUID (FK → conversations.id),
  user_id UUID (FK → profiles.user_id),
  joined_at TIMESTAMPTZ,
  last_read_at TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
)
```

#### 4. **messages**
Stores all messages in conversations.

```sql
messages (
  id UUID PRIMARY KEY,
  conversation_id UUID (FK → conversations.id),
  sender_id UUID (FK → profiles.user_id),
  body TEXT,
  media_url TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  INDEX: (conversation_id, created_at DESC)
)
```

#### 5. **message_receipts**
Tracks read/delivery status of messages.

```sql
message_receipts (
  id UUID PRIMARY KEY,
  message_id UUID (FK → messages.id),
  user_id UUID (FK → profiles.user_id),
  status TEXT ('delivered' | 'read'),
  at TIMESTAMPTZ,
  UNIQUE(message_id, user_id),
  INDEX: (user_id, message_id)
)
```

## Row Level Security (RLS) Policies

### Profiles
- ✅ **SELECT**: Everyone can view all profiles
- ✅ **INSERT**: Users can create their own profile
- ✅ **UPDATE**: Users can only update their own profile

### Conversations
- ✅ **SELECT**: Users can view conversations they participate in
- ✅ **INSERT**: Users can create conversations
- ✅ **UPDATE**: Only creators can update conversations
- ✅ **DELETE**: Only creators can delete conversations

### Conversation Participants
- ✅ **SELECT**: Users can view participants of conversations they're in
- ✅ **INSERT**: Users can join conversations
- ✅ **UPDATE**: Users can update their own participation (last_read_at)
- ✅ **DELETE**: Users can leave conversations

### Messages
- ✅ **SELECT**: Users can read messages from conversations they're in
- ✅ **INSERT**: Users can send messages only to conversations they participate in
- ✅ **UPDATE**: Users can only edit their own messages
- ✅ **DELETE**: Users can only delete their own messages

### Message Receipts
- ✅ **SELECT**: Users can view receipts for messages in their conversations
- ✅ **INSERT**: Users can create receipts only for messages in their conversations
- ✅ **UPDATE**: Users can only update their own receipts
- ✅ **DELETE**: Users can only delete their own receipts

## File Structure

```
backend/supabase/
├── migrations/
│   └── 2025_10_21_000001_init.sql       # Main schema with RLS policies
├── policies/
│   ├── conversations.sql                 # Conversation policies (reference)
│   ├── participants.sql                  # Participant policies (reference)
│   ├── messages.sql                      # Message policies (reference)
│   └── receipts.sql                      # Receipt policies (reference)
└── db/test/
    ├── rls_messages_tap.sql              # Tests for message RLS
    └── rls_participants_tap.sql          # Tests for participant RLS
```

## Deployment

### Apply Migration

```bash
# Start Supabase if not running
make db/start

# Apply migrations
make db/migrate
```

### Run Tests

```bash
# Run all pgTAP tests
make db/test
```

### Verify Schema

```bash
# Connect to Supabase PostgreSQL
psql postgresql://postgres:postgres@localhost:54322/postgres

-- Check tables
\dt

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check policies
SELECT tablename, policyname, permissive 
FROM pg_policies 
WHERE schemaname = 'public';
```

## Security Model

### Multi-Tenant Isolation
- Users can only access data in conversations they participate in
- Foreign key constraints ensure referential integrity
- RLS policies prevent unauthorized access at the database layer
- No application-level access control needed

### Key Security Principles
1. **User Verification**: All policies use `auth.uid()` to verify the authenticated user
2. **Relationship Checking**: Access is verified through `conversation_participants` table
3. **Ownership**: Users can only modify their own content
4. **Transitive Access**: Users cannot access related data outside their conversations

## Next Steps

→ **Phase 03: Contracts Sync & Codegen** - Update OpenAPI specs to match the schema and regenerate Dart client

## Completion Checklist

- [x] Core tables created (profiles, conversations, participants, messages, receipts)
- [x] Indexes created for performance
- [x] RLS enabled on all tables
- [x] RLS policies defined for all operations
- [x] pgTAP tests created
- [ ] Migration applied (`make db/migrate`)
- [ ] Tests passing (`make db/test`)
- [ ] Schema verified in production database
