# Phase 01 — Backend Init (Supabase)

## Setup Instructions

### Prerequisites
- Install Supabase CLI: `npm install -g supabase`
- Docker installed and running (required by Supabase)

### Initial Setup

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```
   Update `.env` with your actual credentials if needed.

2. **Start Supabase:**
   ```bash
   make db/start
   # or directly:
   # supabase start
   ```

3. **Verify services are running:**
   - PostgreSQL: localhost:54322
   - PostgREST API: http://localhost:54321
   - Studio: http://localhost:54323
   - Inbucket (email): http://localhost:54324

### Make Targets

- `make db/start` - Start local Supabase services
- `make db/migrate` - Apply migrations and reset database
- `make db/test` - Run pgTAP tests
- `make funcs/dev` - Run Edge Functions development server
- `make contracts/validate` - Validate OpenAPI contracts
- `make contracts/gen` - Generate Dart client from contracts

### File Structure

```
backend/
├── Makefile                    # Development task automation
├── .env.example               # Environment variables template
├── README_Phase01.md          # This file
└── supabase/
    ├── config.toml            # Supabase local configuration
    └── db/
        ├── test/              # pgTAP test files (.gitkeep)
        └── triggers/          # Database trigger definitions (.gitkeep)
```

## Completion Checklist

- [x] Makefile created with all required targets
- [x] .env.example created with placeholder credentials
- [x] Supabase configuration (config.toml) created
- [x] Directory structure for migrations, tests, and triggers ready
- [ ] Run `make db/start` to verify setup (requires Supabase CLI)
- [ ] Environment variables configured in `.env`

## Next Steps

→ **Phase 02: DB Schema & RLS** - Create database schema with Row Level Security policies
