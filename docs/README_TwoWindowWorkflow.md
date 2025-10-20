# 🧭 MessageAI — Two-Window Workflow Overview

This repository uses a **dual-window development model** for rapid parallel progress between the **Flutter frontend** and **Supabase backend**.

## 🪟 Window A: Flutter Frontend

- Directory: `/frontend`
- Toolchain: Flutter 3.x, Riverpod, Drift, Supabase client
- Responsibilities:
  - Local offline persistence (Drift)
  - Optimistic message queue
  - Realtime presence & receipts
  - UI & state management
  - FCM foreground notifications
- Lives completely isolated; only consumes generated client from `/frontend/lib/gen/api`.

## 🪟 Window B: Supabase Backend

- Directory: `/backend` + `/contracts`
- Toolchain: Supabase CLI, Postgres, Edge Functions (Deno), SQL migrations, OpenAPI
- Responsibilities:
  - Database schema & RLS
  - Edge Functions (`/messages.send`, `/receipts.ack`)
  - Realtime channels
  - Contracts (OpenAPI + JSON Schemas)
  - Codegen for Dart client
  - Push notifications

## 🔗 Shared Bridge: `/contracts`

- Defines the OpenAPI spec and JSON event schemas.
- Generates a typed Dart client → `/frontend/lib/gen/api`.
- Validated automatically via:
  ```bash
  npm --prefix contracts run validate
  npm --prefix contracts run gen:dart
  ```

## 🧩 Workflow Summary

| Step | Window B (Backend) | Window A (Frontend) |
|------|--------------------|--------------------|
| 0 | Bootstrap contracts | Use stub client for local dev |
| 1 | Initialize Supabase | Create Flutter skeleton |
| 2 | Implement DB & RLS | Implement Drift mirror schema |
| 3 | Finalize contracts + codegen | Integrate generated Dart client |
| 4 | Build Edge Functions | Add optimistic send + realtime |
| 5 | Add storage & group logic | Add presence, media, groups |
| 6 | Implement push notifications | Hook FCM foreground |
| 7 | Freeze contracts & write docs | Polish UI + finalize testing |
