# Phase 00 — Contracts Bootstrap (Frontend Consumer)

**Branch:** `feat/frontend-contracts-consume`  
**PR:** `[A] Phase 00 — contracts consumption scaffolding`

## Summary
Prepare Flutter to consume the generated client.

## Tasks
- [ ] Create dirs: `frontend/lib/{core,data/{drift,remote,models},features/{auth,conversations/{list,detail,widgets}},state,gen}`
- [ ] Create files: `frontend/Makefile`, `frontend/lib/core/env.dart`, `frontend/lib/data/remote/supabase_client.dart`
- [ ] `make contracts/gen` to pull client

## Files (templates)

**frontend/Makefile**
```make
contracts/gen: ; npm --prefix ../contracts run gen:dart
fmt: ; dart format .
dev: ; flutter run --dart-define-from-file=.env.dev.json
test: ; flutter test
```

**env.dart (outline)**
```dart
// read SUPABASE_URL and SUPABASE_ANON_KEY from defines or .env.dev.json
```

**supabase_client.dart (outline)**
```dart
// Supabase.initialize(...); expose a singleton client
```

## Completion
- Frontend ready to consume contracts.
