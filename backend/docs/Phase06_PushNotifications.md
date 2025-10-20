# Phase 06 — Push Notifications

**Branch:** `feat/push-notify`  
**PR:** `[B] Phase 06 — devices table + push_notify`

## Summary
Add FCM device registration and a notification trigger function.

## Tasks
- [ ] Migration: `backend/supabase/migrations/2025_10_21_000002_devices.sql`
- [ ] Function: `backend/supabase/functions/push_notify/index.ts`

## Templates (summarized)
```sql
-- profile_devices(user_id uuid, fcm_token text, platform text, last_seen timestamptz)
```
```ts
// push_notify: notify inactive participants about new messages
```

## Commands
```bash
make db/migrate
make funcs/dev
```

## Completion
- push_notify callable; logs show attempts.
