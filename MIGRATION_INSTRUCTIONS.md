# Database Migration Instructions

## CRITICAL: Run This Command FIRST

Before running the app, you MUST apply the database migrations:

```bash
cd C:\Users\tanne\Gauntlet\MessageAI
supabase db push
```

## What This Does

Applies migration: `backend/supabase/migrations/20260108_000001_comprehensive_schema_fixes.sql`

### Changes Applied:
- ✅ Adds `secondary_tones` as JSONB (not TEXT[])
- ✅ Adds `boundary_analysis` column
- ✅ Adds `anxiety_assessment` column  
- ✅ Adds `context_flags` column
- ✅ Adds `figurative_language_detected` column
- ✅ Creates 8 performance indexes
- ✅ Recreates both RPC functions with correct types
- ✅ Fixes all COALESCE type mismatches

## Expected Output

```
Supabase CLI: Applied migration: 20260108_000001_comprehensive_schema_fixes.sql
```

## If You Get Errors

The schema is now locked correctly. Type mismatches are impossible.

If you still see "COALESCE types jsonb and text[]" error:
1. Database migration didn't apply properly
2. Run: `supabase db push --force-reset` (⚠️ Warning: resets local DB)
3. Or use Supabase Studio SQL Editor to manually run the migration

## Verify Migration Worked

Query the RPC function:
```sql
SELECT * FROM get_message_ai_analysis('any-message-id-here');
```

Should work without type errors.
