# 🧭 MessageAI — Frontend Overview

**Directory:** `/frontend`  
**Role:** Cross-platform Flutter app (Android / iOS / Web) providing the messaging UI, offline cache, and realtime interactions.

## 🔧 Stack

| Layer | Tech |
|-------|------|
| Framework | Flutter 3.x |
| State Mgmt | Riverpod v2 |
| Local DB | Drift + sqlite3_flutter_libs |
| Network / API | Supabase Flutter + Dio client (generated) |
| Notifications | Firebase Messaging |
| Media Upload | Supabase Storage |
| Testing | `flutter test` + Widget Tests |

## 📁 Folder Structure

```
frontend/
├── lib/
│   ├── core/
│   ├── data/
│   │   ├── drift/
│   │   ├── remote/
│   │   └── models/
│   ├── features/
│   │   ├── auth/
│   │   └── conversations/
│   │       ├── list/
│   │       ├── detail/
│   │       └── widgets/
│   ├── state/
│   └── gen/
├── test/
├── Makefile
└── .env.dev.json
```

## ⚙️ Make Targets (Summary)

| Command | Description |
|----------|-------------|
| `make contracts/gen` | Generate Dart API client from contracts |
| `make fmt` | Format code |
| `make dev` | Run app with `.env.dev.json` |
| `make test` | Run unit + widget tests |
