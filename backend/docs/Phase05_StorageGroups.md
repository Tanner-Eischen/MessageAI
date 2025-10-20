# Phase 05 — Storage & Groups

**Branch:** `feat/storage-and-groups`  
**PR:** `[B] Phase 05 — storage buckets + optional create_group`

## Summary
Support media via Supabase Storage and optional group creation endpoint.

## Tasks
- [ ] Buckets + policies: `backend/supabase/storage/buckets.sql`
- [ ] (Optional) `create_group` function: `backend/supabase/functions/create_group/index.ts`

## Templates (summarized)
```sql
-- create bucket avatars, media; set policies for signed URLs
```
```ts
// create_group: {title, member_ids[]} -> insert rows under RLS
```

## Commands
```bash
make db/migrate
make funcs/dev
```

## Completion
- Storage functional; group creation path available.
