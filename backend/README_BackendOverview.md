# 🧭 MessageAI — Backend Overview

**Directory:** `/backend`  
**Role:** Provides Supabase-powered backend (Postgres + Edge Functions + RLS + Realtime) and maintains the shared `/contracts` API specification.

## 🔧 Stack

| Layer | Tech |
|-------|------|
| Database | Postgres 15 (Supabase local instance) |
| Auth | Supabase Auth (email / OAuth) |
| Edge Functions | Deno 1.43+ |
| API Spec | OpenAPI 3.1 via `/contracts/openapi.yaml` |
| Events | JSON Schemas (`/contracts/events/*.json`) |
| Realtime | Supabase Postgres Changes + Presence |
| Storage | Supabase Buckets (avatars, media) |
| Testing | pgTAP + Deno tests |

## 📁 Folder Structure

```
backend/
├── supabase/
│   ├── migrations/
│   ├── policies/
│   ├── db/
│   │   ├── triggers/
│   │   └── test/
│   ├── functions/
│   │   ├── messages_send/
│   │   ├── receipts_ack/
│   │   └── push_notify/
│   └── storage/
├── Makefile
└── .env.example
```

## ⚙️ Make Targets (Summary)

| Command | Description |
|----------|--------------|
| `make db/start` | Start Supabase local services |
| `make db/migrate` | Reset + apply migrations |
| `make db/test` | Run pgTAP tests |
| `make funcs/dev` | Serve Edge Functions locally |
| `make contracts/validate` | Validate OpenAPI + event schemas |
| `make contracts/gen` | Generate Dart client to `/frontend/lib/gen/` |
