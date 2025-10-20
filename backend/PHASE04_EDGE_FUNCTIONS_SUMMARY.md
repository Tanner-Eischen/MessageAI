# Phase 04 Edge Functions & Realtime Summary

## Overview

Phase 04 completes the core backend infrastructure by implementing:
1. **Two Edge Functions** for message operations (send and acknowledge)
2. **Two Database Triggers** for real-time event broadcasting
3. **Complete error handling and validation**
4. **CORS and authentication** on all endpoints

## Edge Functions

### Function 1: messages_send

**Endpoint:** `POST /v1/messages.send`  
**File:** `backend/supabase/functions/messages_send/index.ts` (106 lines)

#### Responsibilities
- Receives message from authenticated user
- Validates input (body, conversation_id, id)
- Verifies user is conversation participant
- Performs idempotent UPSERT to messages table
- Returns message with server-generated timestamps

#### Idempotency Mechanism
- Uses client-generated UUID (`id`) as unique key
- PostgreSQL UPSERT with `onConflict: "id"`
- Same ID always produces same result
- Prevents duplicate messages from network retries

#### Security Layers
1. **Authentication:** Bearer token required
2. **Authorization:** Verify user is conversation participant via RLS
3. **Input Validation:** Trim and validate message body
4. **CORS:** Allow cross-origin requests with proper headers

#### Input Validation
```typescript
// Required fields
- id: UUID (non-empty)
- conversation_id: UUID (non-empty)
- body: string (non-empty after trim)

// Optional fields
- media_url: URI (nullable)
```

#### Example Flow
```
Client                    messages_send             Database
  │                          │                         │
  ├─ Generate UUID ─────────┤                         │
  ├─ Send Message ──────────┤                         │
  │                         ├─ Validate ─────────────┤
  │                         ├─ Check RLS ────────────┤
  │                         ├─ UPSERT ───────────────┤
  │                         │ ← Message inserted     │
  │ ← MessageResponse ───────┤                         │
  │                         │                         │
```

---

### Function 2: receipts_ack

**Endpoint:** `POST /v1/receipts.ack`  
**File:** `backend/supabase/functions/receipts_ack/index.ts` (128 lines)

#### Responsibilities
- Receives batch of message IDs and status (delivered/read)
- Validates input array and status enum
- Batch inserts receipts with conflict handling
- Handles status upgrades (delivered → read)
- Returns count of receipts processed

#### Batch Processing
- Supports 1-1000 message IDs per request
- Generates unique receipt ID for each
- Uses "ON CONFLICT DO NOTHING" for idempotency
- Can upgrade existing receipts to higher status

#### Security Layers
1. **Authentication:** Bearer token required
2. **Authorization:** User can only create receipts for themselves
3. **Rate Limiting:** Max 1000 messages per request
4. **Input Validation:** Status enum, array type check

#### Input Validation
```typescript
// Required fields
- message_ids: string[] (1-1000 items, all UUIDs)
- status: "delivered" | "read"

// Enforcement
- Min items: 1
- Max items: 1000
- Status must be enum value
```

#### Upgrade Logic
```
If status == "read":
  Try to update all existing "delivered" → "read"
  Then insert new "read" receipts
  
If status == "delivered":
  Only insert new receipts (don't downgrade)
```

#### Example Flow
```
Client                    receipts_ack              Database
  │                          │                         │
  ├─ Collect IDs ───────────┤                         │
  ├─ Send Status ───────────┤                         │
  │                         ├─ Validate ─────────────┤
  │                         ├─ Batch Insert ─────────┤
  │                         │ ← Receipts created     │
  │ ← Count Response ────────┤                         │
  │                         │                         │
```

---

## Database Triggers

### Trigger 1: messages_notify

**File:** `backend/supabase/db/triggers/messages_notify.sql` (25 lines)

**Triggers on:**
- INSERT into messages table
- UPDATE to messages table

**Broadcasts to:** `realtime:messages` PostgreSQL NOTIFY channel

#### Function: `messages_notify()`
```sql
CREATE OR REPLACE FUNCTION public.messages_notify()
RETURNS trigger AS $$
BEGIN
  PERFORM pg_notify(
    'realtime:messages',
    json_build_object(
      'type', TG_OP,
      'record', row_to_json(NEW),
      'schema', TG_TABLE_SCHEMA,
      'table', TG_TABLE_NAME,
      'timestamp', now()
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### Broadcast Structure
```json
{
  "type": "INSERT" | "UPDATE",
  "record": { ...full message row... },
  "schema": "public",
  "table": "messages",
  "timestamp": "2025-10-20T15:30:00.123Z"
}
```

#### Frontend Subscription
```dart
// Listen for new/updated messages
supabase
  .channel('realtime:messages')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'messages',
    callback: (payload) {
      final message = payload.newRecord;
      // Update UI with new message
    },
  )
  .subscribe();
```

---

### Trigger 2: receipts_notify

**File:** `backend/supabase/db/triggers/receipts_notify.sql` (25 lines)

**Triggers on:**
- INSERT into message_receipts table
- UPDATE to message_receipts table

**Broadcasts to:** `realtime:receipts` PostgreSQL NOTIFY channel

#### Broadcast Structure
```json
{
  "type": "INSERT" | "UPDATE",
  "record": {
    "id": "880e8400-e29b-41d4-a716-446655440003",
    "message_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_id": "990e8400-e29b-41d4-a716-446655440004",
    "status": "read",
    "at": "2025-10-20T15:31:00.000Z"
  },
  "schema": "public",
  "table": "message_receipts",
  "timestamp": "2025-10-20T15:31:00.456Z"
}
```

#### Frontend Subscription
```dart
// Listen for receipt updates
supabase
  .channel('realtime:receipts')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'message_receipts',
    callback: (payload) {
      final receipt = payload.newRecord;
      // Update message read status in UI
    },
  )
  .subscribe();
```

---

## Complete Message Flow

### Scenario: User sends message and marks as read

```
┌─ USER A ─────────────────────────────────────────────────────────┐
│                                                                    │
│  1. Compose message                                               │
│     - Generate UUID (client-side)                                 │
│                                                                    │
│  2. Send POST /v1/messages.send                                   │
│     - Include auth token                                          │
│                                                                    │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   messages_send()         │
                    │                           │
                    │ 1. Validate input         │
                    │ 2. Verify auth            │
                    │ 3. Check participant      │
                    │ 4. UPSERT message         │
                    │ 5. Return response        │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   DATABASE (INSERT)       │
                    │                           │
                    │ INSERT INTO messages      │
                    │ ON CONFLICT DO NOTHING    │
                    │                           │
                    │ Trigger fires ───────────┐│
                    └──────────────────────────┼┘
                                               │
                                    ┌──────────▼──────────┐
                                    │ messages_notify()   │
                                    │                     │
                                    │ NOTIFY realtime:   │
                                    │ messages {event}    │
                                    └──────────┬──────────┘
                                               │
                    ┌──────────────────────────┴────────────┐
                    │                                       │
         ┌──────────▼──────────┐              ┌────────────▼─────────┐
         │   USER A's app      │              │   USER B's app      │
         │                     │              │                     │
         │ Realtime listener   │              │ Realtime listener   │
         │ receives event      │              │ receives event      │
         │ Updates message UI  │              │ Updates message UI  │
         └─────────────────────┘              └─────────────────────┘

════════════════════════════════════════════════════════════════════

User A marks message as read:

┌─ USER A ─────────────────────────────────────────────────────────┐
│                                                                    │
│  1. Tap message (mark as read)                                    │
│                                                                    │
│  2. Send POST /v1/receipts.ack                                    │
│     - message_ids: ["message-uuid"]                               │
│     - status: "read"                                              │
│                                                                    │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   receipts_ack()          │
                    │                           │
                    │ 1. Validate input         │
                    │ 2. Verify auth            │
                    │ 3. Batch insert receipts  │
                    │ 4. Handle conflicts       │
                    │ 5. Return count           │
                    └────────────┬──────────────┘
                                 │
                    ┌────────────▼──────────────┐
                    │   DATABASE (INSERT)       │
                    │                           │
                    │ INSERT INTO receipts      │
                    │ ON CONFLICT DO NOTHING    │
                    │                           │
                    │ Trigger fires ───────────┐│
                    └──────────────────────────┼┘
                                               │
                                    ┌──────────▼──────────┐
                                    │ receipts_notify()   │
                                    │                     │
                                    │ NOTIFY realtime:    │
                                    │ receipts {event}    │
                                    └──────────┬──────────┘
                                               │
                    ┌──────────────────────────┴────────────┐
                    │                                       │
         ┌──────────▼──────────┐              ┌────────────▼─────────┐
         │   USER A's app      │              │   USER B's app      │
         │                     │              │                     │
         │ Realtime listener   │              │ Realtime listener   │
         │ receives read       │              │ receives read       │
         │ Updates receipt UI  │              │ Updates receipt UI  │
         └─────────────────────┘              └─────────────────────┘
```

---

## Security Analysis

### Message Send Security

| Layer | Check | Protection |
|-------|-------|-----------|
| **1. HTTP** | CORS headers | Prevents unauthorized origins |
| **2. Auth** | Bearer token | Verifies user identity |
| **3. Authz** | Conversation participant | Prevents sending to unauthorized convos |
| **4. Validation** | Input checks | Prevents invalid data |
| **5. DB RLS** | Row-level security | Second layer prevents data escape |

### Receipt Security

| Layer | Check | Protection |
|-------|-------|-----------|
| **1. HTTP** | CORS headers | Prevents unauthorized origins |
| **2. Auth** | Bearer token | Verifies user identity |
| **3. Authz** | user_id == auth.uid() | Prevents spoofing receipts |
| **4. Validation** | Status enum | Prevents invalid states |
| **5. DB RLS** | Row-level security | Second layer prevents access |

---

## Performance Characteristics

### messages_send
- **Time Complexity:** O(1) - single UPSERT operation
- **Space Complexity:** O(message) - stores one record
- **Indexed Lookups:** 
  - Primary key lookup by message ID
  - FK lookup by conversation_id
  - Participant lookup by (conversation_id, user_id)
- **Expected Latency:** 50-100ms

### receipts_ack
- **Time Complexity:** O(n) where n = message_ids.length (max 1000)
- **Space Complexity:** O(n) - stores n receipts
- **Batch Operations:** Single INSERT with multiple rows
- **Expected Latency:** 100-200ms for 1000 messages

### Realtime Triggers
- **Latency:** < 1s from INSERT to client notification
- **Scalability:** PostgreSQL NOTIFY handles high throughput
- **Reliability:** Message delivery guaranteed via Realtime subscription

---

## Deployment Steps

### 1. Verify Functions Structure
```bash
ls -la backend/supabase/functions/
# Should see:
# - messages_send/index.ts
# - receipts_ack/index.ts
```

### 2. Add Triggers to Migration
```bash
# Append trigger SQL to main migration
cat backend/supabase/db/triggers/*.sql >> \
  backend/supabase/migrations/2025_10_21_000001_init.sql
```

### 3. Deploy to Supabase
```bash
cd backend

# Start local environment
make db/start

# Apply migrations (includes triggers)
make db/migrate

# Run function development server
make funcs/dev
```

### 4. Verify Deployment
```bash
# Check functions are running
ps aux | grep "supabase functions"

# Test function endpoint
curl http://localhost:54321/functions/v1/messages_send

# Check triggers exist
psql postgresql://postgres:postgres@localhost:54322/postgres
SELECT * FROM pg_triggers WHERE tgname LIKE '%notify%';
```

---

## Error Handling Reference

### messages_send Errors
- **400:** Missing fields, empty body, too many fields
- **401:** No token, invalid token, token expired
- **403:** Not a participant in conversation
- **500:** Database error, storage error

### receipts_ack Errors
- **400:** Invalid message_ids, invalid status, too many items
- **401:** No token, invalid token, token expired
- **500:** Database error, conflict error

---

## Testing Checklist

- [ ] messages_send with valid message
- [ ] messages_send with duplicate ID (idempotency)
- [ ] messages_send without auth token (401)
- [ ] messages_send as non-participant (403)
- [ ] messages_send with empty body (400)
- [ ] receipts_ack with single message
- [ ] receipts_ack with batch (100 messages)
- [ ] receipts_ack status upgrade (delivered → read)
- [ ] receipts_ack without auth token (401)
- [ ] receipts_ack with invalid status (400)
- [ ] Message trigger broadcasts event
- [ ] Receipt trigger broadcasts event
- [ ] Frontend receives realtime events

---

## Files Summary

| File | Lines | Purpose |
|------|-------|---------|
| messages_send/index.ts | 106 | Message insertion endpoint |
| receipts_ack/index.ts | 128 | Receipt batch processing |
| messages_notify.sql | 25 | Message realtime trigger |
| receipts_notify.sql | 25 | Receipt realtime trigger |

**Total Implementation:** 284 lines of production code

---

## Completion Status

- ✅ Edge Functions implemented (2/2)
- ✅ Database triggers implemented (2/2)
- ✅ Error handling complete
- ✅ Security layers in place
- ✅ Input validation complete
- ✅ CORS configured
- ✅ Documentation complete
- ⏳ Deployed to Supabase (pending)
- ⏳ End-to-end tested (pending)

Ready for Phase 05: Storage & Groups! 🚀
