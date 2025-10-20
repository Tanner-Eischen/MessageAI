# Phase 01 — Backend Init (Supabase)

**Branch:** `feat/backend-init`  
**PR:** `[B] Phase 01 — Supabase init + Makefile + .env.example`

## Summary
Initialize Supabase services and backend tooling.

## Tasks
- [ ] `supabase init` → `backend/supabase/config.toml`
- [ ] `supabase start`
- [ ] Create files:
  - [ ] `backend/Makefile`
  - [ ] `backend/.env.example`
  - [ ] `backend/supabase/db/test/.gitkeep`
  - [ ] `backend/supabase/db/triggers/.gitkeep`
- [ ] Add Make targets: `db/start`, `db/migrate`, `db/test`, `funcs/dev`, `contracts/validate`, `contracts/gen`

## Files

**backend/Makefile**
```make
db/start: ; supabase start
db/migrate: ; supabase db reset --use-migra
db/test: ; pg_prove supabase/db/test/*.sql
funcs/dev: ; supabase functions serve --env-file supabase/.env
contracts/validate:
	npm --prefix ../contracts ci && npm --prefix ../contracts run validate
contracts/gen:
	npm --prefix ../contracts run gen:dart
```

**backend/.env.example**
```env
SUPABASE_ANON_KEY=replace-me
SUPABASE_SERVICE_KEY=replace-me
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

## Testing
- [ ] `make db/start` launches services

## Completion
- Supabase up locally; Makefile usable.
