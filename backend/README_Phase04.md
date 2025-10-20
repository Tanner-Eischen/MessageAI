# Phase 04 — Edge Functions & Realtime

## Summary

This phase implements the core API endpoints as Supabase Edge Functions and adds database triggers for real-time event broadcasting. These functions handle message sending (idempotently) and receipt acknowledgement (in batches), while triggers ensure all clients receive updates instantly.

## Edge Functions

### 1. messages_send

**Location:** `backend/supabase/functions/messages_send/index.ts`

**Purpose:** Handles sending messages to conversations with idempotent semantics.

#### Request Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "conversation_id": "660e8400-e29b-41d4-a716-446655440001",
  "body": "Hello, world!",
  "media_url": "https://example.com/image.jpg"
}
```

**Fields:**
- `id` (UUID, required) - Client-generated message ID for idempotency
- `conversation_id` (UUID, required) - Target conversation
- `body` (string, required) - Message text (non-empty after trim)
- `media_url` (URI, optional) - URL to attached media

#### Response Format

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "conversation_id": "660e8400-e29b-41d4-a716-446655440001",
  "sender_id": "770e8400-e29b-41d4-a716-446655440002",
  "body": "Hello, world!",
  "media_url": "https://example.com/image.jpg",
  "created_at": "2025-10-20T15:30:00.000Z",
  "server_time": "2025-10-20T15:30:00.123Z",
  "status": "created"
}
```

**Response Fields:**
- `status`: "created" (new message) or "already_exists" (duplicate)
- `server_time`: Server-generated timestamp for clock synchronization

#### Features

✅ **Idempotent:** Same message ID always returns same result  
✅ **Participant Verification:** Only conversation members can send  
✅ **UPSERT Semantics:** Uses PostgreSQL UPSERT for conflict handling  
✅ **Input Validation:** Trim and validate message body  
✅ **Media Support:** Optional media URL field  
✅ **Error Handling:** Proper HTTP status codes (400, 401, 403, 500)  

#### Error Responses

| Status | Error | Cause |
|--------|-------|-------|
| 400 | Missing required fields | id, conversation_id, or body missing |
| 400 | Message body cannot be empty | Body is empty after trim |
| 401 | Invalid token | Missing or expired auth |
| 403 | Not a participant | User not in conversation |
| 500 | Failed to send message | Database error |

---

### 2. receipts_ack

**Location:** `backend/supabase/functions/receipts_ack/index.ts`

**Purpose:** Handles batch acknowledgement of message receipts with conflict handling.

#### Request Format

```json
{
  "message_ids": [
    "550e8400-e29b-41d4-a716-446655440000",
    "550e8400-e29b-41d4-a716-446655440001",
    "550e8400-e29b-41d4-a716-446655440002"
  ],
  "status": "read"
}
```

**Fields:**
- `message_ids` (array of UUIDs, required) - Messages to acknowledge
- `status` (enum: "delivered" | "read", required) - Status to set

#### Response Format

```json
{
  "success": true,
  "count": 3,
  "status": "read",
  "server_time": "2025-10-20T15:30:00.123Z"
}
```

**Response Fields:**
- `count`: Number of new receipts created
- `status`: The status that was set
- `server_time`: Server timestamp

#### Features

✅ **Batch Processing:** Up to 1000 message IDs per request  
✅ **Conflict Handling:** Gracefully handles duplicate receipts  
✅ **Status Upgrades:** Can upgrade "delivered" → "read"  
✅ **Idempotent:** Same request always succeeds  
✅ **Abuse Prevention:** Limited to 1000 messages per request  
✅ **Error Handling:** Validates input, returns meaningful errors  

#### Error Responses

| Status | Error | Cause |
|--------|-------|-------|
| 400 | Invalid message_ids | Empty array or not array type |
| 400 | Invalid status | Not "delivered" or "read" |
| 400 | Too many message IDs | More than 1000 items |
| 401 | Invalid token | Missing or expired auth |
| 500 | Internal server error | Database error |

---

## Database Triggers

### 1. messages_notify

**Location:** `backend/supabase/db/triggers/messages_notify.sql`

**Purpose:** Broadcasts realtime events when messages are created or updated.

#### How It Works

1. **Event:** INSERT or UPDATE on `messages` table
2. **Trigger:** `messages_notify_insert` or `messages_notify_update`
3. **Function:** `messages_notify()` processes the event
4. **Channel:** Broadcasts to `realtime:messages` PostgreSQL channel
5. **Client:** Receives via Supabase Realtime subscription

#### Broadcast Payload

```json
{
  "type": "INSERT",
  "record": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "conversation_id": "660e8400-e29b-41d4-a716-446655440001",
    "sender_id": "770e8400-e29b-41d4-a716-446655440002",
    "body": "Hello, world!",
    "media_url": null,
    "created_at": "2025-10-20T15:30:00.000Z",
    "updated_at": "2025-10-20T15:30:00.000Z"
  },
  "schema": "public",
  "table": "messages",
  "timestamp": "2025-10-20T15:30:00.123Z"
}
```

#### Usage

```typescript
// In Flutter/Dart frontend:
supabase
  .channel('realtime:messages')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'messages',
    callback: (payload) {
      print('New message: ${payload.newRecord}');
    },
  )
  .subscribe();
```

---

### 2. receipts_notify

**Location:** `backend/supabase/db/triggers/receipts_notify.sql`

**Purpose:** Broadcasts realtime events when receipts are created or updated.

#### How It Works

Same as `messages_notify`, but for `message_receipts` table on `realtime:receipts` channel.

#### Broadcast Payload

```json
{
  "type": "INSERT",
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

---

## File Structure

```
backend/supabase/
├── functions/
│   ├── messages_send/
│   │   └── index.ts                 # Message sending function
│   └── receipts_ack/
│       └── index.ts                 # Receipt acknowledgement function
└── db/
    └── triggers/
        ├── messages_notify.sql      # Message realtime trigger
        └── receipts_notify.sql      # Receipt realtime trigger
```

---

## Deployment

### 1. Add Triggers to Migration

Add trigger definitions to Phase 2 migration or create new migration:

```bash
# Edit migration to include triggers
vim backend/supabase/migrations/2025_10_21_000001_init.sql
# Append: cat backend/supabase/db/triggers/*.sql >> migration.sql
```

### 2. Deploy Functions

```bash
# Start local environment
make db/start

# Run migration
make db/migrate

# Start function development server
make funcs/dev

# Functions are now available at:
# http://localhost:54321/functions/v1/messages_send
# http://localhost:54321/functions/v1/receipts_ack
```

### 3. Test Functions

```bash
# Send a message (requires valid auth token)
curl -X POST http://localhost:54321/functions/v1/messages_send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "conversation_id": "660e8400-e29b-41d4-a716-446655440001",
    "body": "Hello!"
  }'

# Acknowledge receipts
curl -X POST http://localhost:54321/functions/v1/receipts_ack \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message_ids": ["550e8400-e29b-41d4-a716-446655440000"],
    "status": "read"
  }'
```

---

## Security

### Authentication

- All functions require Bearer token in `Authorization` header
- Token is validated using Supabase Auth
- User ID is extracted from token for authorization

### Authorization

- **Message Send:** User must be conversation participant (verified via RLS)
- **Receipt Ack:** User can only create receipts for themselves
- **Database RLS:** Second layer of security prevents unauthorized access

### Input Validation

- Message body validated (non-empty, trimmed)
- Status enum checked ("delivered" or "read")
- Array size limited (max 1000 messages)
- UUID format validation

---

## Performance

### Database Indexes

| Table | Index | Purpose |
|-------|-------|---------|
| messages | (conversation_id, created_at DESC) | Efficient query sorting |
| message_receipts | (user_id, message_id) | Efficient status lookups |

### Batching

- Receipts processed in batches (up to 1000)
- Reduces round trips to database
- Handles conflicts gracefully

### Realtime Broadcasting

- Triggered immediately on database change
- Uses PostgreSQL NOTIFY for efficiency
- Only broadcasts to subscribed clients

---

## Troubleshooting

### "Not a participant in this conversation"

- Verify user is in conversation_participants table
- Check user_id matches authenticated token
- Verify conversation_id exists

### "Invalid token"

- Include Bearer token in Authorization header
- Token must be valid Supabase Auth JWT
- Token may be expired

### No realtime events received

- Verify triggers are created: `SELECT * FROM pg_triggers WHERE tgname LIKE '%notify%'`
- Check function exists: `SELECT * FROM pg_proc WHERE proname = 'messages_notify'`
- Verify channel subscription is correct: `'realtime:messages'`

---

## Next Steps

→ **Phase 05: Storage & Groups** - Add file upload support and group creation functionality

## Completion Checklist

- [x] messages_send Edge Function implemented
- [x] receipts_ack Edge Function implemented
- [x] messages_notify trigger created
- [x] receipts_notify trigger created
- [x] CORS headers configured
- [x] Input validation implemented
- [x] Error handling complete
- [ ] Triggers added to migration
- [ ] Functions deployed (`make funcs/dev`)
- [ ] End-to-end message flow tested
- [ ] Realtime events verified
