# 🚀 MessageAI Frontend — Quick Start

## Prerequisites

- **Flutter** 3.10+ ([install](https://flutter.dev/docs/get-started/install))
- **Dart** 3.0+ (included with Flutter)
- **Supabase Project** with credentials

## 1️⃣ Setup Environment

### Configure Development Credentials
Update `frontend/.env.dev.json` with your Supabase project details:
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

### Install Dependencies
```bash
cd frontend
flutter pub get
```

## 2️⃣ Development Workflow

### Run the App
```bash
flutter run --dart-define-from-file=.env.dev.json
# or use the Makefile:
make dev
```

### Format Code
```bash
make fmt
# or:
dart format .
```

### Run Tests
```bash
make test
# or:
flutter test
```

## 3️⃣ Regenerate API Client

If the backend OpenAPI schema changes:
```bash
make contracts/gen
# or:
npm --prefix ../contracts run gen:dart
```

> **Note**: Requires Java 11+ installed. Currently using manual client (Phase 00).

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── core/          # Core config (env, constants)
│   ├── data/          # Data layer (API, local DB)
│   ├── features/      # Feature screens (auth, conversations)
│   ├── state/         # Riverpod providers
│   └── gen/           # Generated API client
├── test/              # Unit and widget tests
├── pubspec.yaml       # Dependencies
└── .env.dev.json      # Dev environment config
```

## 🔗 API Integration

### Send a Message
```dart
import 'package:messageai/gen/api/api.dart';

final messagesApi = MessagesApi(
  dio: dioClient,
  baseUrl: supabaseUrl,
);

final message = MessagePayload(
  id: 'msg-123',
  conversationId: 'conv-456',
  body: 'Hello, World!',
);

await messagesApi.send(message);
```

### Acknowledge Receipts
```dart
final receiptsApi = ReceiptsApi(
  dio: dioClient,
  baseUrl: supabaseUrl,
);

final receipt = ReceiptPayload(
  messageIds: ['msg-1', 'msg-2'],
  status: ReceiptStatus.read,
);

await receiptsApi.ack(receipt);
```

## 🎯 Current Phase

**Phase 00 — Contracts Bootstrap** ✅
- Directory structure created
- Core environment config ready
- API models and clients initialized
- Dependencies configured

**Next**: Phase 01 — Frontend Skeleton (Flutter app initialization)

## 📚 Documentation

- [Phase 00: Contracts Bootstrap](docs/Phase00_ContractsBootstrap.md)
- [Phase 01: Frontend Skeleton](docs/Phase01_FrontendSkeleton.md)
- [Frontend Overview](README_FrontendOverview.md)
- [Completion Details](PHASE00_COMPLETION.md)

## ✨ Tips

- Use `flutter doctor` to verify your setup
- Check `pubspec.yaml` for all available dependencies
- Run `flutter pub upgrade` to update packages
- Use Android Emulator / iOS Simulator or physical device for testing
