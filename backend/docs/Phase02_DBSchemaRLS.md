# Phase 02 — DB Schema & RLS

**Branch:** `feat/db-schema-rls`  
**PR:** `[B] Phase 02 — Postgres schema + RLS + pgTAP`

## Summary
Create core tables and secure them via Row Level Security.

## Tasks
- [ ] Create migration:
  - [ ] `backend/supabase/migrations/2025_10_21_000001_init.sql`
- [ ] Policies:
  - [ ] `backend/supabase/policies/conversations.sql`
  - [ ] `backend/supabase/policies/participants.sql`
  - [ ] `backend/supabase/policies/messages.sql`
  - [ ] `backend/supabase/policies/receipts.sql`
- [ ] Tests:
  - [ ] `backend/supabase/db/test/rls_messages_tap.sql`
  - [ ] `backend/supabase/db/test/rls_participants_tap.sql`
- [ ] Apply & test

## Templates (summarized)
```sql
-- tables: profiles, conversations, conversation_participants, messages, message_receipts
-- enable RLS; indexes on messages(conversation_id, created_at desc)
```
```sql
-- policies/messages.sql: select/insert allowed if user is participant
```
```sql
-- rls_messages_tap.sql: verify member vs non-member access
```

## Commands
```bash
make db/migrate
make db/test
```

## Completion
- Schema created, RLS tested.
