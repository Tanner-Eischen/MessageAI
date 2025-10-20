# Phase 04 — Edge Functions & Realtime

**Branch:** `feat/edge-functions-v1`  
**PR:** `[B] Phase 04 — messages_send, receipts_ack + triggers`

## Summary
Implement idempotent message send and batched receipts; emit realtime events.

## Tasks
- [ ] Edge Functions:
  - [ ] `backend/supabase/functions/messages_send/index.ts`
  - [ ] `backend/supabase/functions/receipts_ack/index.ts`
- [ ] Triggers:
  - [ ] `backend/supabase/db/triggers/messages_notify.sql`
  - [ ] `backend/supabase/db/triggers/receipts_notify.sql`

## Templates (summarized)
```ts
// messages_send: parse {id, conversation_id, body?, media_url?}; UPSERT; return {status, server_time}
```
```ts
// receipts_ack: parse {message_ids, status}; batch insert on conflict do nothing
```
```sql
-- triggers: notify on insert to messages/receipts
```

## Commands
```bash
make funcs/dev
make db/migrate
```

## Completion
- Functions work; realtime visible.
